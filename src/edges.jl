"""
Return the repo-defined full function names a callee node can refer to.
"""
function get_callee_full_names(callee, functions_in_scope, aliases, module_paths, all_functions_defined)
    if get_kind(callee) === "Identifier"
        name = string(callee)
        # an aliased import (`import Mod: foo as f`) binds `f` to a repo function
        haskey(aliases, name) && return aliases[name]
        return Set(full_name for full_name in functions_in_scope if get_local_name(full_name) === name)
    elseif get_kind(callee) === "."
        mod, func = get_children(callee)
        mod_path = get(module_paths, string(mod), nothing)
        if mod_path === nothing
            return Set{String}()
        end
        # only draw an edge if the qualified name is an actual repo function,
        # not e.g. a struct used as a constructor
        full_name = get_full_func_name(string(func), mod_path)
        return full_name in all_functions_defined ? Set([full_name]) : Set{String}()
    else
        return Set{String}()
    end
end

"""
Return the call edges between repo-defined functions:
(caller full name, callee full name, whether the call is ambiguous).
An edge is ambiguous when several same-named functions are in scope, so we
cannot tell which one is actually called.
"""
function get_edges(defs_and_calls, rel_path, functions_in_scope, aliases, module_paths, all_functions_defined)
    edges = Set{Tuple{String, String, Bool}}()
    for (caller_name, callees) in defs_and_calls
        caller_full = get_full_func_name(caller_name, rel_path)
        for callee in callees
            candidates = get_callee_full_names(callee, functions_in_scope, aliases, module_paths, all_functions_defined)
            ambiguous = length(candidates) > 1
            for callee_full in candidates
                # skip recursion: a call to itself is not an edge
                callee_full == caller_full && continue
                push!(edges, (caller_full, callee_full, ambiguous))
            end
        end
    end
    return edges
end
