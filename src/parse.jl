"""
Parsed content of one source file.
"""
struct ParsedFile
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
    rel_path = replace(path, input_dir => "")
    # a single file failing to parse should not abort the whole analysis:
    # warn and skip it instead
    tree = try
        parseall(SyntaxNode, read(path, String))
    catch err
        err isa JuliaSyntax.ParseError || rethrow()
        @warn "skipping $(rel_path): could not parse this file, no call graph information extracted"
        return ParsedFile(rel_path, defs_and_calls, SyntaxNode[], String[], nothing)
    end
    children = get_children(tree)
    # strip the top-level module if any (may be wrapped in a docstring or macro
    # call, and may not be the first child: scan all children for it)
    module_node = nothing
    for child in children
        unwrapped = unwrap(child, "module")
        if get_kind(unwrapped) === "module"
            module_node = unwrapped
            break
        end
    end
    if module_node !== nothing
        # child 1 is the module name, child 2 is the body block
        modname, tree = get_children(module_node)
        modname = string(modname)
        children = get_children(tree)
    end
    imports = [node for node in get_children(tree) if get_kind(node) in ("import", "using")]
    includes = [node for node in get_children(tree) if get_kind(node) === "call" && get_function_name(node) === "include"]
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
    # only string-literal includes can be resolved statically, e.g.
    # `include("a.jl")` or `Base.include("a.jl")`; any other form
    # (`include()`, `Base.include(Main, "a.jl")`, `include(joinpath(...))`,
    # interpolated strings) is skipped with a warning instead of crashing
    included_paths = String[]
    for include in includes
        args = get_children(include)
        is_literal = length(args) >= 2 && get_kind(args[2]) === "string" && length(get_children(args[2])) == 1
        if !is_literal
            @warn "skipping include call in $(rel_path): only string-literal includes are resolved"
            continue
        end
        push!(included_paths, normpath(joinpath(dirname(rel_path), strip(string(args[2][1]), ['"']))))
    end
    return ParsedFile(rel_path, defs_and_calls, imports, included_paths, modname)
end
