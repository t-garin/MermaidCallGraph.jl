using MermaidCallGraph
using Test

@testset "MermaidCallGraph.jl" begin
    @testset "Regression against known-good output on src" begin
        input_dir = joinpath(@__DIR__, "..", "src")
        output_file = tempname() * ".md"
        mermaid_call_graph(input_dir=input_dir, output_file=output_file)
        actual = read(output_file, String)
        expected = read(joinpath(@__DIR__, "expected_mermaid_call_graph.md"), String)
        @test actual == expected
    end

    @testset "Regression against known-good output on test_repo" begin
        input_dir = joinpath(@__DIR__, "test_repo")
        output_file = tempname() * ".md"
        mermaid_call_graph(input_dir=input_dir, output_file=output_file)
        actual = read(output_file, String)
        expected = read(joinpath(@__DIR__, "expected_test_repo.md"), String)
        @test actual == expected
    end
end
