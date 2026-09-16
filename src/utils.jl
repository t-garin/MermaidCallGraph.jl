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
Return the `target`-kind node (a function definition, a module, ...) wrapped
inside docstring (`doc`) or macro-call (`macrocall`, e.g. `@inline`, `@doc`)
nodes, if any; otherwise return the node unchanged. Handles stacked wrappers
recursively.
"""
function unwrap(node::SyntaxNode, target::String)::SyntaxNode
    kind = get_kind(node)
    if kind === "doc" || kind === "macrocall"
        for child in get_children(node)
            child_kind = get_kind(child)
            if child_kind === target || child_kind === "doc" || child_kind === "macrocall"
                return unwrap(child, target)
            end
        end
    end
    return node
end

"""
Return the callee node of a call: the first child, except for infix (`a + b`)
and postfix (`x'`) calls where the operator is the second child.
"""
function get_callee(node::SyntaxNode)::SyntaxNode
    children = get_children(node)
    if JuliaSyntax.is_infix_op_call(node) || JuliaSyntax.is_postfix_op_call(node)
        return children[2]
    end
    return children[1]
end

"""
Resursively finds all the calls in the lower nodes.
"""
function get_internal_calls!(node::SyntaxNode, calls::Set{SyntaxNode})
    # the node itself may be a call: a short-form body like `f(x) = bar(x)` is a
    # single call whose outermost callee would otherwise be missed
    get_kind(node) in ("call", "dotcall") && push!(calls, get_callee(node))
    for child in get_children(node)
        get_internal_calls!(child, calls)
    end
end

"""
Get full function name: /path/to/file.jl:func_name
"""
function get_full_func_name(func_name, rel_path)
    return rel_path * ":" * func_name
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
    # split on the last `:` only, so names or paths containing `:` survive
    return rsplit(full_name, ":", limit=2)[end]
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
        if get_kind(callee) === "::"
            return string(get_children(callee)[end])
        end
        # qualified definitions like `Base.:+(...)`: keep only the function or
        # operator name (a trailing `:+` quote node means the operator `+`)
        if get_kind(callee) === "."
            last = get_children(callee)[end]
            return get_kind(last) === "quote" ? string(get_children(last)[end]) : string(last)
        end
        return string(callee)
    else
        return get_function_name(get_children(sig)[1])
    end
end