# MermaidCallGraph.jl

[![Build Status](https://github.com/t-garin/MermaidCallGraph.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/t-garin/MermaidCallGraph.jl/actions/workflows/CI.yml?query=branch%3Amain)

## Description

MermaidCallGraph.jl analyzes a Julia project's source code and generates a
[Mermaid](https://mermaid.js.org/) flowchart of the internal call graph: which
functions call which other functions. It creates one subgraph per source file,
grouping the functions defined in that file, and draws edges for calls between
functions of the project.

```mermaid
flowchart TD
    subgraph MermaidCallGraph.jl
        _generate["_generate"]
        collect_definitions["collect_definitions"]
        extract_function_name["extract_function_name"]
        find_internal_calls["find_internal_calls"]
        find_jl_files["find_jl_files"]
        generate_mermaid_markdown["generate_mermaid_markdown"]
        get_children["get_children"]
        get_kind["get_kind"]
        mermaid_call_graph["mermaid_call_graph"]
    end
    _generate --> collect_definitions
    _generate --> find_internal_calls
    _generate --> find_jl_files
    _generate --> generate_mermaid_markdown
    collect_definitions --> extract_function_name
    collect_definitions --> get_children
    collect_definitions --> get_kind
    extract_function_name --> get_children
    extract_function_name --> get_kind
    mermaid_call_graph --> _generate
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
- `include` is treated like an implicit `using`.
- Recursive calls are not drawn: a function calling itself does not produce an edge.

## Contributing

Any help, feedback, or improvement is welcome! Feel free to open an issue or
submit a pull request on [GitHub](https://github.com/t-garin/MermaidCallGraph.jl).

This is my first-ever public and registered repo, I've probably made some mistakes, don't hesitate to point them out!
