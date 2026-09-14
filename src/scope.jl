"""
Return the repo-defined functions in scope through the given imports and includes.
"""
function get_imported_functions_in_scope(imports, includes, module_paths, all_functions_defined, input_dir, path)
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
                    push!(explicit_functions, get_full_func_name(func_name, mod_path, input_dir))
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
    # includes are treated like implicit imports
    for include in includes
        include_target = strip(string(include[2][1]), ['"'])
        included_path = normpath(joinpath(dirname(replace(path, input_dir => "")), include_target))
        for func_name in all_functions_defined
            if startswith(func_name, included_path * ":")
                push!(implicit_functions, func_name)
            end
        end
    end
    return explicit_functions, implicit_functions
end
