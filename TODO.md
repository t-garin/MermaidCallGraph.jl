- [x] rename main to mermaid_call_graph
- [ ] fix functions inside strings
- [ ] fix broadcast calls
- [ ] fix non-ascii function name calls
- [ ] fix function call with type generic
- [ ] fix nested function calls
- [ ] fix function with same names in different files

Feedback from goerz on JuliaRegistries, PR 167869
-------------------------------------------------
```md
Thank you for submitting your package! I'm a bit concerned about the package exporting a function named `main`. That is a very generic name, and it also has a special meaning as the [entry point of a script](https://docs.julialang.org/en/v1/manual/command-line-interface/#The-Main.main-entry-point). For example, a script that does `using MermaidCallGraph` and then defines `function (@main)(args)` fails with "Symbol `main` is already a resolved import in module Main". I would recommend a more descriptive name, something like `write_callgraph`.

Since the call detection is based on a regex over the source text of each function body, there are quite a few situations where the graph comes out wrong. In a quick test, I found that:

* a function name followed by a parenthesis inside a string literal shows up as a call
* broadcasted calls `f.(x)`, and calls to functions with non-ASCII names (`ψ(x)`) are missed
* a definition like `function f(x::T)::T where {T}` is not picked up at all
* calls inside a nested function are also attributed to the enclosing function
* functions with the same name defined in different files are declared as the same node in multiple subgraphs, and Mermaid only draws a single node for them (this happens a lot when running on the `src` folder of JuliaSyntax, for example)

Some of these may be acceptable limitations, but they should be documented in the README, and the test suite (which currently only runs the package on its own source code) should cover these kinds of cases. Please also collect coverage information in your CI workflow. See https://modernjuliaworkflows.org/sharing/ for a tutorial on best practices.

Note that you can always update a pending registration: just keep the version number the same, and retrigger the registration based on a new commit (by commenting `@JuliaRegistrator register` on that commit). This will update the existing registration PR. Changing the version number (or the name / repo URL) would create a _new_ PR, which then has to be manually closed in favor of the new one.
```