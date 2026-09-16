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
    # only string-literal includes can be resolved statically. The path is the
    # plain string-literal argument, wherever it appears: `include("a.jl")`,
    # `Base.include("a.jl")`, or the module-qualified forms
    # `include(mod, "a.jl")` / `Base.include(mod, "a.jl")`. Anything else
    # (`include()`, `include(joinpath(...))`, interpolated strings) is skipped
    # with a warning instead of crashing
    included_paths = resolve_included_paths(includes, rel_path)
    return ParsedFile(rel_path, defs_and_calls, imports, included_paths, modname)
end

"""
Resolve string-literal `include` calls to normalized relative paths.
"""
function resolve_included_paths(includes, rel_path)
    included_paths = String[]
    for include in includes
        path_arg = find_string_literal_arg(include)
        if path_arg === nothing
            @warn "skipping include call in $(rel_path): no string-literal include path found"
            continue
        end
        push!(included_paths, normpath(joinpath(dirname(rel_path), string_literal_value(path_arg))))
    end
    return included_paths
end

"""
Return the single plain string-literal argument of a call, or nothing if the
call has none.
"""
function find_string_literal_arg(call)
    for arg in get_children(call)[2:end]
        if get_kind(arg) === "string" && length(get_children(arg)) == 1
            return arg
        end
    end
    return nothing
end

"""
Return the content of a string-literal syntax node (the literal text without
the surrounding quotes).
"""
function string_literal_value(node)
    # the first child holds the literal content, still including the quotes
    return strip(string(get_children(node)[1]), ['"'])
end
