"""
Return the repo-defined functions in scope through the given imports.
"""
function get_imported_functions_in_scope(imports, module_paths, all_functions_defined)
    explicit_functions = Set{String}()
    implicit_functions = Set{String}()
    for imp in imports
        first_child, other_children... = get_children(imp)
        # explicit imports
        if get_kind(first_child) === ":"
            mod, funcs... = get_children(first_child)
            mod_name = get_import_module_name(mod)
            mod_path = get(module_paths, mod_name, nothing)
            if mod_path !== nothing
                for func in funcs
                    func_name = string(get_children(func)[end])
                    push!(explicit_functions, get_full_func_name(func_name, mod_path))
                end
            end
        # implicit imports: only `using` brings all functions of the module in scope
        else
            if get_kind(imp) !== "using"
                continue
            end
            mod_name = get_import_module_name(first_child)
            mod_path = get(module_paths, mod_name, nothing)
            if mod_path !== nothing
                for func_name in all_functions_defined
                    if startswith(func_name, mod_path * ":")
                        push!(implicit_functions, func_name)
                    end
                end
            end
        end
    end
    return explicit_functions, implicit_functions
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
