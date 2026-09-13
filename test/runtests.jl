using MermaidCallGraph
using Test

@testset "MermaidCallGraph.jl" begin
    @testset "Regression against known-good output" begin
        input_dir = joinpath(@__DIR__, "..", "src")
        output_file = tempname() * ".md"
        mermaid_call_graph(input_dir=input_dir, output_file=output_file)
        actual = read(output_file, String)
        expected = read(joinpath(@__DIR__, "expected_callgraph.md"), String)
        @test actual == expected
    end
end
