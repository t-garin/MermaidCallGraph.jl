"""
Return the repo-defined functions in scope through the given imports.
"""
function get_imported_functions_in_scope(imports, module_paths, all_functions_defined, input_dir)
    functions_in_scope = Set{String}()
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
                    push!(functions_in_scope, get_full_func_name(func_name, mod_path, input_dir))
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
                        push!(functions_in_scope, func_name)
                    end
                end
            end
        end
    end
    return functions_in_scope
end
