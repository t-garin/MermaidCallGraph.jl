# flat file, included into the `geometry` module:
# its functions are in scope for the other files of that module

function distance(p1, p2)
    return sqrt((p2[1] - p1[1])^2 + (p2[2] - p1[2])^2)
end
