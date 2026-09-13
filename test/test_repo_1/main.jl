include("misc/stuff.jl")
include("misc/weird.jl")
include("utils/io.jl")
include("utils/math.jl")

import .stuff: print_stuff
import .weird: print_weird, f
import .io:stuff_same_name
import .math: weird_same_name, broadcast_double_mean

function main()
    print_stuff()
    print("\n")
    print_weird()
    print("\n")
    print(stuff_same_name())
    print("\n")
    print(weird_same_name())
    print("\n")
    print(broadcast_double_mean([1, 2, 3], [4, 5, 6]))
    print("\n")
    print(f(6769))
    print("\n")
    print(f(6769.0))
end

main()