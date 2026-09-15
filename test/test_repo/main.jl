include("misc/stuff.jl")
include("misc/weird.jl")
include("utils/io.jl")
include("utils/math.jl")
include("lib/geometry.jl")

import ..stuff: print_stuff
using ..weird
using .io: stuff_same_name
import .math
import .geometry

"""
    main()

Run all the test functions and print their output.
"""
function main()
    print_stuff()
    print("\n")
    print_weird()
    print("\n")
    print(stuff_same_name())
    print("\n")
    print(math.weird_same_name())
    print("\n")
    print(math.weird_same_name(7))
    print("\n")
    print(math.broadcast_double_mean([1, 2, 3], [4, 5, 6]))
    print("\n")
    print(weird.f(6769))
    print("\n")
    print(weird.f(6769.0))
    print("\n")
    print(geometry.polygon_perimeter([[0.0, 0.0], [1.0, 0.0], [1.0, 1.0]]))
end

main()
