module MermaidCallGraph

import JuliaSyntax
using JuliaSyntax: parseall, SyntaxNode, sourcetext

export mermaid_call_graph

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
True if function definition, False otherwise.
"""
function is_function_definition(node::SyntaxNode)::Bool
    return get_kind(node) === "function" ? true : false
end

"""
True if function call, False otherwise.
"""
function is_function_call(node::SyntaxNode)::Bool
    kind = get_kind(node)
    if (kind === "call") || (kind === "dotcall")
        return true
    else
        return false
    end
end

"""
Resursively finds all the calls in the lower nodes.
"""
function get_internal_calls!(node::SyntaxNode, calls::Set{String})::Nothing
    for child in get_children(node)
        if is_function_call(child)
            push!(calls, string(child[1]))
        end
        get_internal_calls!(child, calls)
    end
end

"""
Find all functions defined per path.
"""
function find_all_defined_functions(path::String)::Set{String}
    functions_defined_in_this_file = Set{String}()
    tree = parseall(SyntaxNode, read(path, String))
    children = get_children(tree)
    # strip module if any
    if get_kind(children[1]) === "module"
        tree = get_children(children[1])[2]
        children = get_children(tree)
        # module is defined in a block
        # arg 1 is the name, arg 2 is the block
        if get_kind(children[2]) === "block"
            # tree becomes the content of the block
            tree = get_children(children[2])[1]
        end
    end
    toplevel_function_definitions = [
        node for node in 
            get_children(tree)
            if is_function_definition(node)
    ]
    for func_def_node in toplevel_function_definitions
        # first child holds the function name
        first_child = get_children(func_def_node)[1]
        # get the function name
        if get_kind(first_child) == "call"
            func_name = string(first_child[1])
        # if the call is nested
        # where clauses, type annotations ...
        else
            first_child_calls = Set{String}()
            get_internal_calls!(first_child, first_child_calls)
            func_name = string(only(first_child_calls))
        end
        push!(functions_defined_in_this_file, func_name)
    end
    return functions_defined_in_this_file
end


"""
"""
function mermaid_call_graph()
    input_dir = "test/test_repo_1"
    # walk the ast a first time for function defs
    for path in find_jl_files(input_dir)
        print(path, ": ", find_all_defined_functions(path), "\n")
    end
end

end