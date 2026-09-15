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
    isempty(paths) && @warn "no .jl files found under $(input_dir), nothing to do"
    # first pass:
    # - modules
    # - all function definitions
    # - includes, to build scope groups
    module_paths = Dict{String, String}()
    all_functions_defined = Set{String}()
    modname_by_path = Dict{String, Union{Nothing, String}}()
    includes_by_path = Dict{String, Vector{String}}()
    for path in paths
        defs_and_calls, _, includes, _, modname = parse(path)
        rel_path = replace(path, input_dir => "")
        modname_by_path[rel_path] = modname
        if modname !== nothing
            module_paths[modname] = rel_path
        end
        included_paths = String[]
        for include in includes
            include_target = strip(string(include[2][1]), ['"'])
            push!(included_paths, normpath(joinpath(dirname(rel_path), include_target)))
        end
        includes_by_path[rel_path] = included_paths
        full_func_names = [
            get_full_func_name(func_name, path, input_dir)
            for func_name in keys(defs_and_calls)
        ]
        all_functions_defined = union(all_functions_defined, full_func_names)
    end
    scope_groups = compute_scope_groups(paths, includes_by_path, modname_by_path, input_dir)
    # second pass:
    # - function defs + bodies
    # - function imports
    # - function exports
    all_edges = Set{Tuple{String, String, Bool}}()
    for path in paths
        defs_and_calls, imports, includes, exports, _ = parse(path)
        rel_path = replace(path, input_dir => "")
        full_func_names = [
            get_full_func_name(func_name, path, input_dir)
            for func_name in keys(defs_and_calls)
        ]
        explicit_functions, implicit_functions = get_imported_functions_in_scope(imports, module_paths, all_functions_defined, input_dir)
        # functions of the files sharing this file's scope through includes
        scope_group_functions = get_scope_group_functions(scope_groups, all_functions_defined, rel_path)
        functions_in_scope = union(explicit_functions, implicit_functions, scope_group_functions, full_func_names)
        edges = get_edges(defs_and_calls, path, functions_in_scope, explicit_functions, implicit_functions, module_paths, all_functions_defined, input_dir)
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