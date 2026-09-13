module math
export weird_same_name, broadcast_double_mean
include("../misc/weird.jl")
import .weird: same_name

ϕ(x) = ((1 + sqrt(5))/2) * x
ψ(x) = ((1 - sqrt(5))/2) * x

# test non-ascii characterw
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

end