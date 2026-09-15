module geometry
include("points.jl")
include("vectors.jl")

# calls `norm` from vectors.jl, included in the same module scope
function polygon_perimeter(vertices)
    n = length(vertices)
    total = 0.0
    for i in 1:n
        total += norm(vertices[i] .- vertices[mod1(i + 1, n)])
    end
    return total
end

end
