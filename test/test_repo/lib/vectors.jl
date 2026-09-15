# flat file, included into the `geometry` module:
# calls `distance` from points.jl, another file of the same module scope

function norm(v)
    return distance([0, 0], v)
end
