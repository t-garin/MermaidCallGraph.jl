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
Assign each function a unique mermaid node id. Base ids come from
`get_node_id`; when several functions map to the same id (e.g. file paths
differing only by punctuation, such as `a-b.jl` and `a_b.jl`), the later ones
get a numeric suffix. Iterating in sorted order keeps the output deterministic.
"""
function assign_node_ids(all_functions)::Dict{String, String}
    taken = Set{String}()
    id_of = Dict{String, String}()
    for f in sort(collect(all_functions))
        base = get_node_id(f)
        id = base
        n = 2
        while id in taken
            id = base * "_" * string(n)
            n += 1
        end
        push!(taken, id)
        id_of[f] = id
    end
    return id_of
end

"""
Generate the Mermaid flowchart markdown from the repo functions and call edges.
Edges are tuples (caller, callee, ambiguous); ambiguous edges use a dotted,
"?"-marked arrow.
"""
function generate_mermaid_markdown(all_functions, edges, orientation)
    lines = String["flowchart $(orientation)"]
    paths = sort(unique([get_full_func_path(f) for f in all_functions]))
    id_of = assign_node_ids(all_functions)
    for path in paths
        push!(lines, "    subgraph \"$(path)\"")
        funcs = sort([f for f in all_functions if get_full_func_path(f) == path])
        append!(lines, "        $(id_of[f])[\"$(get_local_name(f))\"]" for f in funcs)
        push!(lines, "    end")
    end
    for (caller, callee, implicit) in sort(collect(edges))
        arrow = implicit ? "-. ? .->" : "-->"
        push!(lines, "    $(id_of[caller]) $arrow $(id_of[callee])")
    end
    return join(lines, "\n")
end
