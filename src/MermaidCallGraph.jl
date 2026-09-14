module MermaidCallGraph

import JuliaSyntax
using JuliaSyntax: parseall, SyntaxNode, sourcetext

export mermaid_call_graph

include("utils.jl")
include("parse.jl")

"""
"""
function mermaid_call_graph()
    input_dir = "test/test_repo_1"
    paths = find_jl_files(input_dir)
    # first pass: register modules -> paths
    module_paths = Dict{String, String}()
    for path in paths
        _, _, _, _, modname = parse(path)
        if modname !== nothing
            module_paths[modname] = replace(path, input_dir => "")
        end
    end
    # walk the ast a to find:
    # - function defs + bodies
    # - function imports
    # - function exports
    all_functions_defined = Set{String}()
    for path in paths
        defs_and_calls, imports, includes, exports, _ = parse(path)
        full_func_names = [
            get_full_func_name(func_name, path, input_dir)
            for func_name in keys(defs_and_calls)
        ]
        all_functions_defined = union(all_functions_defined, full_func_names)
        print(imports, "\n")
        
        # module-func pair
        
        for imp in imports
            first_child, other_children... = get_children(imp)
            # explicit imports
            if get_kind(first_child) === ":"
                mod, funcs... = get_children(first_child)
                mod_name = get_import_module_name(mod)
                mod_path = get(module_paths, mod_name, nothing)
                print(mod, " ", mod_path, "\n")
            # implicit imports
            else
                continue
            end
        end
    end
    print(all_functions_defined)


end

end