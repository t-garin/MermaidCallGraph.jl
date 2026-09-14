module MermaidCallGraph

import JuliaSyntax
using JuliaSyntax: parseall, SyntaxNode, sourcetext

export mermaid_call_graph

include("utils.jl")
include("parse.jl")
include("scope.jl")
include("edges.jl")
include("genmd.jl")

"""
    mermaid_call_graph(; input_dir="src", output_file="MermaidCallGraph.md", orientation="LR")

Analyze the Julia files under `input_dir` and write a Mermaid flowchart of the
internal call graph to `output_file`. A positional variant
`mermaid_call_graph(input_dir, output_file, orientation)` is also available.
"""
function mermaid_call_graph(; input_dir::String="src", output_file::String="MermaidCallGraph.md", orientation::String="LR")::Nothing
    paths = find_jl_files(input_dir)
    # first pass:
    # - modules
    # - all function definitions
    module_paths = Dict{String, String}()
    all_functions_defined = Set{String}()
    for path in paths
        defs_and_calls, _, _, _, modname = parse(path)
        if modname !== nothing
            module_paths[modname] = replace(path, input_dir => "")
        end
        full_func_names = [
            get_full_func_name(func_name, path, input_dir)
            for func_name in keys(defs_and_calls)
        ]
        all_functions_defined = union(all_functions_defined, full_func_names)
    end
    # second pass:
    # - function defs + bodies
    # - function imports
    # - function exports
    all_edges = Set{Tuple{String, String, Bool}}()
    for path in paths
        defs_and_calls, imports, includes, exports, _ = parse(path)
        full_func_names = [
            get_full_func_name(func_name, path, input_dir)
            for func_name in keys(defs_and_calls)
        ]
        explicit_functions, implicit_functions = get_imported_functions_in_scope(imports, includes, module_paths, all_functions_defined, input_dir, path)
        functions_in_scope = union(explicit_functions, implicit_functions, full_func_names)
        edges = get_edges(defs_and_calls, path, functions_in_scope, explicit_functions, implicit_functions, module_paths, input_dir)
        all_edges = union(all_edges, edges)
    end
    mermaid_markdown = generate_mermaid_markdown(all_functions_defined, all_edges, orientation)
    output = "```mermaid\n" * mermaid_markdown * "\n```\n"
    isfile(output_file) && rm(output_file)
    write(output_file, output)
    return nothing
end

function mermaid_call_graph(input_dir::String, output_file::String, orientation::String)::Nothing
    return mermaid_call_graph(input_dir=input_dir, output_file=output_file, orientation=orientation)
end

end