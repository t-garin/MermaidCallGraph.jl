include("misc/stuff.jl")
include("misc/weird.jl")
include("lib/core/geometry.jl")

# `using ..stuff, ..weird`: several modules in a single `using`
# `import ..weird: print_weird as pw`: aliased import, `pw` is an alias
# `import ..weird.same_name`: dot import of a single function
# `using .geometry: stuff_same_name`: explicit import of a single function
using ..stuff, ..weird
import ..weird: print_weird as pw
import ..weird.same_name
using .geometry: stuff_same_name
import .geometry

# both `stuff` and `weird` define a `same_name`; an unqualified call finds all
# of them in scope, so edges are drawn towards each (with a "?"-marked arrow)
function resolve()
    return same_name()
end

"""
    main()

Run all the test functions and print their output.
"""
function main()
    print_stuff()
    println(pw())
    println(stuff_same_name())
    println(resolve())
    println(geometry.weird_same_name())
    println(geometry.broadcast_double_mean([1, 2, 3], [4, 5, 6]))
    println(weird.f(6769))
    p = Point(1.0, 2.0)
    println(describe_point(p))
    println(shift(p, 1.0, 1.0))
    println(geometry.polygon_perimeter([[0.0, 0.0], [1.0, 0.0], [1.0, 1.0]]))
end

main()
