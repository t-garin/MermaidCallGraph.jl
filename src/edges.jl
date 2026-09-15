"""
Return the repo-defined full function names a callee node can refer to.
"""
function get_callee_full_names(callee, functions_in_scope, module_paths, all_functions_defined)
    if get_kind(callee) === "Identifier"
        name = string(callee)
        return Set(full_name for full_name in functions_in_scope if get_local_name(full_name) === name)
    elseif get_kind(callee) === "."
        mod, func = get_children(callee)
        mod_path = get(module_paths, string(mod), nothing)
        if mod_path === nothing
            return Set{String}()
        end
        # only draw an edge if the qualified name is an actual repo function,
        # not e.g. a struct used as a constructor
        full_name = mod_path * ":" * string(func)
        return full_name in all_functions_defined ? Set([full_name]) : Set{String}()
    else
        return Set{String}()
    end
end

"""
Return the call edges between repo-defined functions:
(caller full name, callee full name, whether the edge is implicit).
"""
function get_edges(defs_and_calls, rel_path, functions_in_scope, explicit_functions, implicit_functions, module_paths, all_functions_defined)
    edges = Set{Tuple{String, String, Bool}}()
    for (caller_name, callees) in defs_and_calls
        caller_full = get_full_func_name(caller_name, rel_path)
        for callee in callees
            # function like import math; math.sin
            is_qualified = get_kind(callee) === "."
            for callee_full in get_callee_full_names(callee, functions_in_scope, module_paths, all_functions_defined)
                # skip recursion: a call to itself is not an edge
                callee_full == caller_full && continue
                implicit = !is_qualified && callee_full in implicit_functions && !(callee_full in explicit_functions)
                push!(edges, (caller_full, callee_full, implicit))
            end
        end
    end
    return edges
end
