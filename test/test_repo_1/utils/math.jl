module math
export weird_same_name, broadcast_double_mean
import ..weird: same_name

ϕ(x) = ((1 + sqrt(5))/2) * x
ψ(x) = ((1 - sqrt(5))/2) * x

# test non-ascii characterw
"""
    ϕψ_mean(x)

Return the mean of `ϕ(x)` and `ψ(x)`.
"""
function ϕψ_mean(x)
    return (ϕ(x) + ψ(x))/2
end

# test for broadcasting call
function broadcast_double_mean(x, y)
    return (ϕψ_mean.(x) + ϕψ_mean.(y))/2
end

# call a function with same_name
function weird_same_name()::Int
    return same_name() + 4
end
# two methods inside the same file
function weird_same_name(x::Int)::Int
    return Int(round(ϕψ_mean(x)))
end

end