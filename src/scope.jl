"""
Return the repo-defined functions in scope through the given imports, and the
name aliases introduced by `as` imports (alias → full function name).
"""
function get_imported_functions_in_scope(imports, module_paths, all_functions_defined)
    explicit_functions = Set{String}()
    implicit_functions = Set{String}()
    aliases = Dict{String, Set{String}}()
    for imp in imports
        # a `using`/`import` statement can name several modules (`using A, B`)
        for child in get_children(imp)
            if get_kind(child) === ":"
                # explicit import list: `using Mod: a, b` / `import Mod: a as b`
                handle_explicit_import_list(child, module_paths, all_functions_defined, explicit_functions, aliases)
            else
                # single-module import: `using A` (implicit) or `import Mod.func` (explicit)
                handle_bare_module_import(child, imp, module_paths, all_functions_defined, explicit_functions, implicit_functions)
            end
        end
    end
    return explicit_functions, implicit_functions, aliases
end

"""
Handle an explicit import list: `using Mod: a, b` / `import Mod: a as b`.
Records the imported repo functions and any `as` aliases (alias → full name).
"""
function handle_explicit_import_list(child, module_paths, all_functions_defined, explicit_functions, aliases)
    mod, funcs... = get_children(child)
    mod_path = get(module_paths, string(get_children(mod)[end]), nothing)
    mod_path === nothing && return
    for func in funcs
        if get_kind(func) === "as"
            original = get_children(func)[1]
            alias = string(get_children(func)[end])
            func_name = string(get_children(original)[end])
        else
            func_name = string(get_children(func)[end])
            alias = nothing
        end
        full_name = get_full_func_name(func_name, mod_path)
        full_name in all_functions_defined || continue
        push!(explicit_functions, full_name)
        if alias !== nothing
            push!(get!(aliases, alias, Set{String}()), full_name)
        end
    end
end

"""
Handle a single-module import: `using A` (implicit, every repo function of the
module in scope) or `import Mod.func` (explicit, one function). Relative
markers (`.`, `..`) are children of the import too, so only the identifiers
are considered.
"""
function handle_bare_module_import(child, imp, module_paths, all_functions_defined, explicit_functions, implicit_functions)
    identifiers = [c for c in get_children(child) if get_kind(c) === "Identifier"]
    if length(identifiers) > 1
        # `import Mod.func`: import the last identifier from the first (the module)
        get_kind(imp) === "import" || return
        mod_path = get(module_paths, string(identifiers[1]), nothing)
        mod_path === nothing && return
        full_name = get_full_func_name(string(identifiers[end]), mod_path)
        full_name in all_functions_defined && push!(explicit_functions, full_name)
    else
        # `using A`: every repo function of the module is implicitly in scope
        get_kind(imp) === "using" || return
        mod_path = get(module_paths, string(identifiers[1]), nothing)
        mod_path === nothing && return
        for func_name in all_functions_defined
            if startswith(func_name, mod_path * ":")
                push!(implicit_functions, func_name)
            end
        end
    end
end

"""
Return, for each file, the set of files that share its scope through transitive
`include`s. Files that define their own module, or that no file includes, are
scope roots; a module boundary is not crossed, so an included module file keeps
its own scope.
"""
function compute_scope_groups(files)
    all_paths = Set(file.rel_path for file in files)
    includes_by_path = Dict(file.rel_path => file.includes for file in files)
    is_module = Set(file.rel_path for file in files if file.modname !== nothing)
    included = Set{String}()
    for rel in all_paths, sub in includes_by_path[rel]
        push!(included, sub)
    end
    # roots are module files, which keep their own scope even when included (an
    # included module is never descended into, so it would otherwise get no group),
    # plus flat files that no one includes (script roots)
    roots = [rel for rel in all_paths if rel in is_module || !(rel in included)]
    # gather a root and all flat files reachable from it through includes
    function collect_group!(file, group)
        # guard against cyclic includes (a -> b -> a), which would recurse forever
        file in group && return
        push!(group, file)
        for sub in includes_by_path[file]
            # an include may point outside the analyzed paths (e.g. ../external.jl
            # or a nonexistent file); skip it instead of failing on is_module[sub]
            sub in all_paths || continue
            # do not cross module boundaries: an included module keeps its own scope
            sub in is_module || collect_group!(sub, group)
        end
    end
    group_of = Dict{String, Set{String}}()
    for root in roots
        group = Set{String}()
        collect_group!(root, group)
        for file in group
            # a flat file included by several modules belongs to all their groups
            group_of[file] = union(get(group_of, file, Set{String}()), group)
        end
    end
    return group_of
end

"""
Return the full function names defined in the files sharing the given file's scope.
"""
function get_scope_group_functions(scope_groups, all_functions_defined, rel_path)
    functions = Set{String}()
    for rel in get(scope_groups, rel_path, Set{String}())
        for func_name in all_functions_defined
            if startswith(func_name, rel * ":")
                push!(functions, func_name)
            end
        end
    end
    return functions
end
