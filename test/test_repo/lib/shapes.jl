# flat file, included into the `geometry` module:
# its functions are in scope for the other files of that module

# test non-ascii characters
ϕ(x) = ((1 + sqrt(5))/2) * x
ψ(x) = ((1 - sqrt(5))/2) * x

"""
    ϕψ_mean(x)

Return the mean of `ϕ(x)` and `ψ(x)`.
"""
function ϕψ_mean(x)
    return (ϕ(x) + ψ(x))/2
end

function distance(p1, p2)
    return sqrt((p2[1] - p1[1])^2 + (p2[2] - p1[2])^2)
end

# calls `distance` from the same included scope
function norm(v)
    return distance([0, 0], v)
end

# short-form function whose whole body is a single call: the edge must be drawn
sqnorm(v) = norm(v)

# recursion is not drawn as an edge
function fact(n)
    n <= 1 && return 1
    return n * fact(n - 1)
end

# `p(k)` calls a value, not a repo function name: no edge expected
function scale(p, k)
    return p(k)
end

# anonymous function assigned to a variable is not a top-level function node
double = x -> 2x
