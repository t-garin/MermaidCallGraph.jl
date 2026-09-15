# MermaidCallGraph.jl

[![Build Status](https://github.com/t-garin/MermaidCallGraph.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/t-garin/MermaidCallGraph.jl/actions/workflows/CI.yml?query=branch%3Amain)

## Description

MermaidCallGraph.jl analyzes a Julia project's source code and generates a
[Mermaid](https://mermaid.js.org/) flowchart of the internal call graph: which
functions call which other functions. It creates one subgraph per source file,
grouping the functions defined in that file, and draws edges for calls between
functions of the project.

```mermaid
flowchart LR
    subgraph "/MermaidCallGraph.jl"
        _MermaidCallGraph_jl_mermaid_call_graph["mermaid_call_graph"]
    end
    subgraph "/edges.jl"
        _edges_jl_get_callee_full_names["get_callee_full_names"]
        _edges_jl_get_edges["get_edges"]
    end
    subgraph "/genmd.jl"
        _genmd_jl_generate_mermaid_markdown["generate_mermaid_markdown"]
        _genmd_jl_get_node_id["get_node_id"]
    end
    subgraph "/parse.jl"
        _parse_jl_parse["parse"]
    end
    subgraph "/scope.jl"
        _scope_jl_compute_scope_groups["compute_scope_groups"]
        _scope_jl_get_imported_functions_in_scope["get_imported_functions_in_scope"]
        _scope_jl_get_scope_group_functions["get_scope_group_functions"]
    end
    subgraph "/utils.jl"
        _utils_jl_find_jl_files["find_jl_files"]
        _utils_jl_get_children["get_children"]
        _utils_jl_get_full_func_name["get_full_func_name"]
        _utils_jl_get_full_func_path["get_full_func_path"]
        _utils_jl_get_function_name["get_function_name"]
        _utils_jl_get_import_module_name["get_import_module_name"]
        _utils_jl_get_internal_calls_["get_internal_calls!"]
        _utils_jl_get_kind["get_kind"]
        _utils_jl_get_local_name["get_local_name"]
        _utils_jl_is_export["is_export"]
        _utils_jl_is_function_call["is_function_call"]
        _utils_jl_is_function_definition["is_function_definition"]
        _utils_jl_is_import["is_import"]
        _utils_jl_is_include["is_include"]
        _utils_jl_unwrap_definition["unwrap_definition"]
    end
    _MermaidCallGraph_jl_mermaid_call_graph --> _edges_jl_get_edges
    _MermaidCallGraph_jl_mermaid_call_graph --> _genmd_jl_generate_mermaid_markdown
    _MermaidCallGraph_jl_mermaid_call_graph --> _parse_jl_parse
    _MermaidCallGraph_jl_mermaid_call_graph --> _scope_jl_compute_scope_groups
    _MermaidCallGraph_jl_mermaid_call_graph --> _scope_jl_get_imported_functions_in_scope
    _MermaidCallGraph_jl_mermaid_call_graph --> _scope_jl_get_scope_group_functions
    _MermaidCallGraph_jl_mermaid_call_graph --> _utils_jl_find_jl_files
    _MermaidCallGraph_jl_mermaid_call_graph --> _utils_jl_get_full_func_name
    _edges_jl_get_callee_full_names --> _utils_jl_get_children
    _edges_jl_get_callee_full_names --> _utils_jl_get_kind
    _edges_jl_get_callee_full_names --> _utils_jl_get_local_name
    _edges_jl_get_edges --> _edges_jl_get_callee_full_names
    _edges_jl_get_edges --> _utils_jl_get_full_func_name
    _edges_jl_get_edges --> _utils_jl_get_kind
    _genmd_jl_generate_mermaid_markdown --> _genmd_jl_get_node_id
    _genmd_jl_generate_mermaid_markdown --> _utils_jl_get_full_func_path
    _genmd_jl_generate_mermaid_markdown --> _utils_jl_get_local_name
    _parse_jl_parse --> _utils_jl_get_children
    _parse_jl_parse --> _utils_jl_get_function_name
    _parse_jl_parse --> _utils_jl_get_internal_calls_
    _parse_jl_parse --> _utils_jl_get_kind
    _parse_jl_parse --> _utils_jl_is_export
    _parse_jl_parse --> _utils_jl_is_function_definition
    _parse_jl_parse --> _utils_jl_is_import
    _parse_jl_parse --> _utils_jl_is_include
    _parse_jl_parse --> _utils_jl_unwrap_definition
    _scope_jl_get_imported_functions_in_scope --> _utils_jl_get_children
    _scope_jl_get_imported_functions_in_scope --> _utils_jl_get_full_func_name
    _scope_jl_get_imported_functions_in_scope --> _utils_jl_get_import_module_name
    _scope_jl_get_imported_functions_in_scope --> _utils_jl_get_kind
    _utils_jl_get_function_name --> _utils_jl_get_children
    _utils_jl_get_function_name --> _utils_jl_get_kind
    _utils_jl_get_import_module_name --> _utils_jl_get_children
    _utils_jl_get_internal_calls_ --> _utils_jl_get_children
    _utils_jl_get_internal_calls_ --> _utils_jl_is_function_call
    _utils_jl_is_export --> _utils_jl_get_kind
    _utils_jl_is_function_call --> _utils_jl_get_kind
    _utils_jl_is_function_definition --> _utils_jl_get_kind
    _utils_jl_is_import --> _utils_jl_get_kind
    _utils_jl_is_include --> _utils_jl_get_kind
    _utils_jl_unwrap_definition --> _utils_jl_get_children
    _utils_jl_unwrap_definition --> _utils_jl_get_kind
    _utils_jl_unwrap_definition --> _utils_jl_is_function_definition
```




## Usage

From the project root, run:

```bash
julia --project=. -e 'using MermaidCallGraph; mermaid_call_graph()'
```

This analyzes all Julia files under `src/` and writes `MermaidCallGraph.md` in
the current directory.

### Arguments

`mermaid_call_graph` accepts three optional keyword arguments:

| Argument      | Default                 | Description                                 |
|---------------|-------------------------|---------------------------------------------|
| `input_dir`   | `"src"`                 | Directory to scan for `.jl` files           |
| `output_file` | `"MermaidCallGraph.md"` | Output markdown file                        |
| `orientation` | `"LR"`                  | Mermaid graph orientation (e.g. `LR`, `TD`) |

### Examples

```bash
julia --project=. -e 'using MermaidCallGraph; mermaid_call_graph("lib", "callgraph.md", "TD")'
```

Or using keyword arguments:

```bash
julia --project=. -e 'using MermaidCallGraph; mermaid_call_graph(input_dir="lib", output_file="graph.md", orientation="TB")'
```

## Quirks

- If multiple function methods are defined in the same file, they will be merged into one node.
- Only explicit imports have a clear arrow pointing to a function, implicit imports have a "?"-marked arrow.
- If multiple function methods are in scope at the same time, edges will be drawn towards all with a a "?"-marked arrow
- Files `include`d into the same module or script share each other's functions; an included file that defines its own module keeps its own scope.
- Recursive calls are not drawn: a function calling itself does not produce an edge.
- Nested functions are not represented, and calls inside a nested function are attributed to the enclosing function.

## Contributing

Any help, feedback, or improvement is welcome! Feel free to open an issue or
submit a pull request on [GitHub](https://github.com/t-garin/MermaidCallGraph.jl).

This is my first-ever public and registered repo, I've probably made some mistakes, don't hesitate to point them out!
