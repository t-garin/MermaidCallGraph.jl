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
    # walk the ast a to find:
    # - function defs + bodies
    # - function imports
    # - function exports
    for path in find_jl_files(input_dir)
        defs_and_calls, imports, exports = parse(path)
        print("\n\n\n", path, ":\n\n", defs_and_calls, "\n\n", imports, "\n\n", exports, "\n\n\n")
    end
end

end