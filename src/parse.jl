"""
Parse the code to find:
- function definitions and internal calls
- imports
- includes
- exports
- the module name, if the file defines one
"""
function parse(path)
    defs_and_calls = Dict{String, Set{SyntaxNode}}()
    modname = nothing
    tree = parseall(SyntaxNode, read(path, String))
    children = get_children(tree)
    # strip module if any
    if get_kind(children[1]) === "module"
        # child 1 is the module name, child 2 is the block
        modname = string(get_children(children[1])[1])
        tree = get_children(children[1])[2]
        children = get_children(tree)
        # module is defined in a block
        # arg 1 is the name, arg 2 is the block
        if get_kind(children[2]) === "block"
            # tree becomes the content of the block
            tree = get_children(children[2])[1]
        end
    end
    imports = [
        node for node in 
            get_children(tree)
            if is_import(node)
    ]
    includes = [
        node for node in 
            get_children(tree)
            if is_include(node)
    ]
    exports = [
        node for node in 
            get_children(tree)
            if is_export(node)
    ]
    # docstrings wrap their target in a `doc` node; unwrap them to find functions
    toplevel_function_definitions = [
        unwrap_doc(node) for node in 
            get_children(tree)
            if is_function_definition(unwrap_doc(node))
    ]
    for func_def_node in toplevel_function_definitions
        # first child holds the function name
        first_child, other_children... = get_children(func_def_node)
        # get the function name
        if get_kind(first_child) == "call"
            func_name = string(first_child[1])
        # if the call is nested
        # where clauses, type annotations ...
        else
            first_child_calls = Set{SyntaxNode}()
            get_internal_calls!(first_child, first_child_calls)
            func_name = string(only(first_child_calls))
        end
        # parse internal calls
        internal_calls = Set{SyntaxNode}()
        for child in other_children
            get_internal_calls!(child, internal_calls)
        end
        # if multiple methods in the same file
        if func_name in keys(defs_and_calls)
            defs_and_calls[func_name] = union(defs_and_calls[func_name], internal_calls)
        else
            defs_and_calls[func_name] = internal_calls
        end
    end
    return defs_and_calls, imports, includes, exports, modname
end
