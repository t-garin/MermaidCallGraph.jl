"""
Return the file path part of a full function name.
"""
function get_full_func_path(full_name::String)::String
    return split(full_name, ":")[1]
end

"""
Return a mermaid-safe node id for a full function name.
Non-ASCII characters are encoded as `u` + their hex code point to keep ids unique.
"""
function get_node_id(full_name::String)::String
    id_chars = Char[]
    for c in full_name
        if c == '_' || (isascii(c) && (isletter(c) || isdigit(c)))
            # safe as-is: underscore, ASCII letter or digit
            push!(id_chars, c)
        elseif isascii(c)
            # e.g. `/`, `:`, `.` -> underscore
            push!(id_chars, '_')
        else
            # non-ASCII, e.g. `ψ` -> `u3c8`
            encoded = lowercase(string(UInt32(c), base=16))
            append!(id_chars, "u" * encoded)
        end
    end
    return String(id_chars)
end

"""
Generate the Mermaid flowchart markdown from the repo functions and call edges.
Edges are tuples (caller, callee, implicit); implicit edges use a dotted arrow.
"""
function generate_mermaid_markdown(all_functions, edges, orientation)
    lines = String["flowchart $(orientation)"]
    paths = sort(unique([get_full_func_path(f) for f in all_functions]))
    for path in paths
        push!(lines, "    subgraph \"$(path)\"")
        funcs = sort([f for f in all_functions if get_full_func_path(f) == path])
        append!(lines, "        $(get_node_id(f))[\"$(get_local_name(f))\"]" for f in funcs)
        push!(lines, "    end")
    end
    for (caller, callee, implicit) in sort(collect(edges))
        arrow = implicit ? "-.->" : "-->"
        push!(lines, "    $(get_node_id(caller)) $arrow $(get_node_id(callee))")
    end
    return join(lines, "\n")
end
