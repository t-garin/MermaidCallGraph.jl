# Display this message
help:
    just --list

[private]
instantiate:
    julia --project=. -e 'using Pkg; Pkg.instantiate()'

# Run the test suite
test: instantiate
    julia --project=. -e 'using Pkg; Pkg.test()'

# Generate the call graph and write MermaidCallGraph.md
run: instantiate
    julia --project=. -e 'using MermaidCallGraph; mermaid_call_graph()'
