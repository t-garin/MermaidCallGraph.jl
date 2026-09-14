module MermaidCallGraph

import JuliaSyntax
using JuliaSyntax: parseall, SyntaxNode, sourcetext

export mermaid_call_graph

include("utils.jl")
include("parse.jl")
include("scope.jl")
include("edges.jl")

"""
"""
function mermaid_call_graph()
    input_dir = "test/test_repo_1"
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
    for path in paths
        defs_and_calls, imports, includes, exports, _ = parse(path)
        full_func_names = [
            get_full_func_name(func_name, path, input_dir)
            for func_name in keys(defs_and_calls)
        ]
        print(imports, "\n")
        print(defs_and_calls, "\n")
        explicit_functions, implicit_functions = get_imported_functions_in_scope(imports, includes, module_paths, all_functions_defined, input_dir, path)
        functions_in_scope = union(explicit_functions, implicit_functions, full_func_names)
        print(functions_in_scope, "\n")
        edges = get_edges(defs_and_calls, path, functions_in_scope, explicit_functions, implicit_functions, module_paths, input_dir)
        print(edges, "\n\n\n")
    end
    print(all_functions_defined)


end

end