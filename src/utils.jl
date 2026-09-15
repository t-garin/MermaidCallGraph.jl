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
    return get_kind(node) === "function"
end

"""
Return the function definition wrapped inside a docstring (`doc`) or macro-call
(`macrocall`, e.g. `@inline`, `@noinline`, `@doc`) node, if any; otherwise
return the node unchanged. Handles stacked wrappers recursively.
"""
function unwrap_definition(node::SyntaxNode)::SyntaxNode
    kind = get_kind(node)
    if kind === "doc" || kind === "macrocall"
        for child in get_children(node)
            child_kind = get_kind(child)
            if is_function_definition(child) || child_kind === "doc" || child_kind === "macrocall"
                return unwrap_definition(child)
            end
        end
    end
    return node
end

"""
True if function call, False otherwise.
"""
function is_function_call(node::SyntaxNode)::Bool
    return get_kind(node) in ("call", "dotcall")
end

"""
True if function export, False otherwise.
"""
function is_export(node::SyntaxNode)::Bool
    return get_kind(node) === "export"
end

"""
True if function import, False otherwise.
"""
function is_import(node::SyntaxNode)::Bool
    return get_kind(node) in ("import", "using")
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
        is_function_call(child) && push!(calls, child[1])
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
Return the file path part of a full function name.
"""
function get_full_func_path(full_name::String)::String
    # split on the last `:` only, so Windows drive letters (e.g. `C:\...`) survive
    return rsplit(full_name, ":", limit=2)[1]
end

"""
Return the local function name of a full function name.
"""
function get_local_name(full_name::String)::String
    return split(full_name, ":")[end]
end

"""
Return the module name from an importpath node like `..stuff` or `.math`.
"""
function get_import_module_name(node::SyntaxNode)::String
    return string(get_children(node)[end])
end

"""
Return the function name from a definition signature, descending through wrapper
nodes (`where` clauses, return-type annotations) to the inner call or identifier.
"""
function get_function_name(sig::SyntaxNode)::String
    kind = get_kind(sig)
    if kind == "Identifier"
        return string(sig)
    elseif kind == "call" || kind == "dotcall"
        callee = sig[1]
        # callable objects: `(F::Foo)(x)` is a method of the type `Foo`
        return get_kind(callee) === "::" ? string(get_children(callee)[end]) : string(callee)
    else
        return get_function_name(get_children(sig)[1])
    end
end