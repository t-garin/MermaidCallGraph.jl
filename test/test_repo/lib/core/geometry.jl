module geometry
# qualified include: must be detected as an include of shapes.jl
Base.include("../shapes.jl")
import ..stuff: same_name

# explicit import of a same-named function: clear edge to stuff.same_name
function stuff_same_name()
    return same_name() - 4
end

# two methods inside the same file are merged into one node
function weird_same_name()::Int
    return same_name() + 4
end
function weird_same_name(x::Int)::Int
    return Int(round(ϕψ_mean(x)))
end

# test for broadcasting call
function broadcast_double_mean(x, y)
    return (ϕψ_mean.(x) + ϕψ_mean.(y))/2
end

# calls `norm` from shapes.jl, included in the same module scope
function polygon_perimeter(vertices)
    n = length(vertices)
    total = 0.0
    for i in 1:n
        total += norm(vertices[i] .- vertices[mod1(i + 1, n)])
    end
    return total
end

end
