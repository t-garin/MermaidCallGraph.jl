# Display this message
help:
    just --list

# Run the test suite
test:
    julia --project=. -e 'using Pkg; Pkg.test()'

# Generate the call graph and write MermaidCallGraph.md
run:
    julia --project=. -e 'using MermaidCallGraph; main()'
