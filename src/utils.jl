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
True if function export, False otherwise.
"""
function is_export(node::SyntaxNode)::Bool
    return get_kind(node) === "export" ? true : false
end

"""
True if function import, False otherwise.
"""
function is_import(node::SyntaxNode)::Bool
    kind = get_kind(node)
    if (kind === "import") || (kind === "using")
        return true
    else
        return false
    end
end

"""
True if function include, False otherwise.
"""
function is_include(node::SyntaxNode)::Bool
    return get_kind(node) === "call" ? string(node[1]) === "include" : false
end

"""
Resursively finds all the calls in the lower nodes.
"""
function get_internal_calls!(node::SyntaxNode, calls::Set{SyntaxNode})::Nothing
    for child in get_children(node)
        if is_function_call(child)
            push!(calls, child[1])
        end
        get_internal_calls!(child, calls)
    end
end

"""
Get full function name: /path/to/file.jl:func_name
"""
function get_full_func_name(func_name, path, input_dir)
    return replace(path, input_dir => "") * ":" * func_name
end

"""
Return the module name from an importpath node like `..stuff` or `.math`.
"""
function get_import_module_name(node::SyntaxNode)::String
    return string(get_children(node)[end])
end