module MermaidCallGraph

import JuliaSyntax
using JuliaSyntax: parseall, SyntaxNode, sourcetext

export main

"""
Return the children of a syntax node as a vector.
"""
function get_children(node::SyntaxNode)::Vector{SyntaxNode}
    children = JuliaSyntax.children(node)
    return children === nothing ? SyntaxNode[] : children
end

"""
Return the string representation of the syntax node's kind.
"""
function get_kind(node::SyntaxNode)::String
    return string(JuliaSyntax.kind(node))
end

"""
Attempt to extract the name of a function definition from its signature.
"""
function extract_function_name(sig::SyntaxNode)::Union{String, Nothing}

    children = get_children(sig)
    
    isempty(children) && return nothing
    
    first_child = children[1]
    call_node = get_kind(first_child) in ("call", "call-") ? first_child :
                get_kind(sig) in ("call", "call-") ? sig : return nothing
    
    call_children = get_children(call_node)

    isempty(call_children) && return nothing
    
    name_node = call_children[1]

    get_kind(name_node) == "Identifier" && return string(name_node)
    
    return nothing
end

"""
Recursively traverse the CST to find function definitions and their bodies.
"""
function collect_definitions(
    node::SyntaxNode, 
    defs::Set{String}, 
    bodies::Vector{Tuple{String, String, String}}, 
    path::String
)::Nothing

    kind = get_kind(node)
    is_func = kind == "function"
    is_assign = kind == "=" && JuliaSyntax.numchildren(node) == 2
    
    if (is_func || is_assign) && length(get_children(node)) >= 2
        sig = get_children(node)[1]
        name = extract_function_name(sig)
        if name !== nothing
            push!(defs, name)
            body_text = sourcetext(get_children(node)[2])
            push!(bodies, (name, path, body_text))
        end
    end
    
    foreach(child -> collect_definitions(child, defs, bodies, path), get_children(node))
    
    return nothing
end

"""
Find all internal function calls within the collected bodies.
"""
function find_internal_calls(
    bodies::Vector{Tuple{String, String, String}}, 
    defs::Set{String}
)::Set{Tuple{String, String}}

    call_pattern = r"([A-Za-z_][A-Za-z0-9_]*!?)\s*\("
    return Set(
        (caller, callee) for (caller, _, body) in bodies
                         for m in eachmatch(call_pattern, body)
                         for callee in m.captures
                         if callee in defs && caller != callee
    )
end

"""
Generate the Mermaid flowchart markdown string.
"""
function generate_mermaid_markdown(
    bodies::Vector{Tuple{String, String, String}}, 
    edges::Set{Tuple{String, String}},
    orientation::String,
    input_dir::String
)::String

    lines = String["flowchart $(orientation)"]
    paths = sort(unique(path for (_, path, _) in bodies))

    for path in paths
        subgraph_name = replace(path, input_dir * "/" => "")
        push!(lines, "    subgraph $(subgraph_name)")
        funcs = sort(unique(name for (name, p, _) in bodies if p == path))
        append!(lines, "        $f[\"$f\"]" for f in funcs)
        push!(lines, "    end")
    end
    
    sorted_edges = sort(collect(edges))
    append!(lines, "    $a --> $b" for (a, b) in sorted_edges)
    
    return join(lines, "\n")
end

"""
Recursively find all Julia source files in a directory.
"""
function find_jl_files(dir::String)::Vector{String}
    entries = readdir(dir, join=true)
    return vcat(
        [find_jl_files(f) for f in entries if isdir(f)]...,
        [f for f in entries if endswith(f, ".jl")],
    )
end

"""
    main(; input_dir="src", output_file="MermaidCallGraph.md", orientation="LR")

Main entry point to analyze project source and write the flow graph.
All arguments are keyword arguments; a positional variant
`main(input_dir, output_file, orientation)` is also available.
"""
function main(; input_dir::String="src", output_file::String="MermaidCallGraph.md", orientation::String="LR")::Nothing
    return _generate(input_dir, output_file, orientation)
end

function main(input_dir::String, output_file::String, orientation::String)::Nothing
    return _generate(input_dir, output_file, orientation)
end

function _generate(input_dir::String, output_file::String, orientation::String)::Nothing

    defs = Set{String}()
    bodies = Tuple{String, String, String}[]
    src_files = sort(find_jl_files(input_dir))

    for path in src_files
        content = read(path, String)
        collect_definitions(parseall(SyntaxNode, content), defs, bodies, path)
    end
    
    edges = find_internal_calls(bodies, defs)
    mermaid_content = generate_mermaid_markdown(bodies, edges, orientation, input_dir)
    output = "```mermaid\n" * mermaid_content * "\n```\n"
    isfile(output_file) && rm(output_file)
    write(output_file, output)

    return nothing
end

end
