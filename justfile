# Display this message
help:
    just --list

[private]
instantiate:
    julia --project=. -e 'using Pkg; Pkg.instantiate()'

# Run the test suite
test: instantiate
    julia --project=. -e 'using Pkg; Pkg.test()'

# Generate the call graph, write MermaidCallGraph.md and embed it in README.md
run: instantiate
    julia --project=. scripts/embed_readme.jl
