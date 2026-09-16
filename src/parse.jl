"""
Parsed content of one source file.
"""
struct ParsedFile
    path::String
    rel_path::String
    defs_and_calls::Dict{String, Set{SyntaxNode}}
    imports::Vector{SyntaxNode}
    includes::Vector{String}
    modname::Union{Nothing, String}
end

"""
Parse a file to find:
- function definitions and internal calls
- imports
- includes (as normalized relative paths)
- the module name, if the file defines one
"""
function parse(path, input_dir)::ParsedFile
    defs_and_calls = Dict{String, Set{SyntaxNode}}()
    modname = nothing
    tree = parseall(SyntaxNode, read(path, String))
    children = get_children(tree)
    # strip module if any (may be wrapped in a docstring or macro call)
    if !isempty(children)
        first = unwrap(children[1], "module")
        if get_kind(first) === "module"
            # child 1 is the module name, child 2 is the body block
            modname, tree = get_children(first)
            modname = string(modname)
            children = get_children(tree)
        end
    end
    imports = [node for node in get_children(tree) if get_kind(node) in ("import", "using")]
    includes = [node for node in get_children(tree) if get_kind(node) === "call" && string(node[1]) === "include"]
    # docstrings and macro-call wrappers (e.g. `@inline`, `@doc`) wrap their
    # target; unwrap them to find the function definitions
    toplevel_function_definitions = [
        unwrap(node, "function")
        for node in get_children(tree)
        if get_kind(unwrap(node, "function")) === "function"
    ]
    for func_def_node in toplevel_function_definitions
        # first child holds the function signature (name + arguments)
        first_child, other_children... = get_children(func_def_node)
        # get the function name, descending through where clauses, type annotations ...
        func_name = get_function_name(first_child)
        # parse internal calls
        internal_calls = Set{SyntaxNode}()
        for child in other_children
            get_internal_calls!(child, internal_calls)
        end
        # if multiple methods in the same file
        if haskey(defs_and_calls, func_name)
            union!(defs_and_calls[func_name], internal_calls)
        else
            defs_and_calls[func_name] = internal_calls
        end
    end
    rel_path = replace(path, input_dir => "")
    included_paths = [
        normpath(joinpath(dirname(rel_path), strip(string(include[2][1]), ['"'])))
        for include in includes
    ]
    return ParsedFile(path, rel_path, defs_and_calls, imports, included_paths, modname)
end
