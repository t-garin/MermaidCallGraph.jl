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
    if !isdir(input_dir)
        @warn "input directory $(input_dir) does not exist, nothing to do"
        return nothing
    end
    paths = [joinpath(root, f) for (root, _, files) in walkdir(input_dir) for f in files if endswith(f, ".jl")]
    if isempty(paths)
        @warn "no .jl files found under $(input_dir), nothing to do"
        return nothing
    end
    markdown = build_mermaid_call_graph(paths, input_dir, orientation)
    write(output_file, "```mermaid\n" * markdown * "\n```\n")
    return nothing
end

function mermaid_call_graph(input_dir::String, output_file::String, orientation::String)::Nothing
    return mermaid_call_graph(input_dir=input_dir, output_file=output_file, orientation=orientation)
end

"""
Build the Mermaid markdown of the internal call graph of the given Julia files.
"""
function build_mermaid_call_graph(paths, input_dir, orientation)::String
    files = [parse(path, input_dir) for path in paths]
    module_paths, all_functions_defined = collect_function_info(files)
    scope_groups = compute_scope_groups(files)
    all_edges = compute_edges(files, module_paths, all_functions_defined, scope_groups)
    return generate_mermaid_markdown(all_functions_defined, all_edges, orientation)
end

"""
Collect, from all parsed files, the module-name → file mapping and the full
names of every defined function.
"""
function collect_function_info(files)
    module_paths = Dict{String, String}()
    all_functions_defined = Set{String}()
    for file in files
        file.modname !== nothing && (module_paths[file.modname] = file.rel_path)
        union!(all_functions_defined, (get_full_func_name(name, file.rel_path) for name in keys(file.defs_and_calls)))
    end
    return module_paths, all_functions_defined
end

"""
Compute all call edges between repo-defined functions.
"""
function compute_edges(files, module_paths, all_functions_defined, scope_groups)
    all_edges = Set{Tuple{String, String, Bool}}()
    for file in files
        explicit_functions, implicit_functions, aliases = get_imported_functions_in_scope(file.imports, module_paths, all_functions_defined)
        functions_in_scope = union(
            explicit_functions,
            implicit_functions,
            get_scope_group_functions(scope_groups, all_functions_defined, file.rel_path),
            (get_full_func_name(name, file.rel_path) for name in keys(file.defs_and_calls)),
        )
        union!(all_edges, get_edges(file.defs_and_calls, file.rel_path, functions_in_scope, aliases, module_paths, all_functions_defined))
    end
    return all_edges
end

end