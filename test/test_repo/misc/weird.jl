# top-level code before the module: the module must still be detected
using ..stuff

module weird
export same_name, print_weird, Point, describe_point, shift
# `@twice` comes from `stuff`; the top-level `using ..stuff` above only
# affects `Main`, and `using` does not import macros, so import it explicitly
using ..stuff
import ..stuff: @twice

# test with functions that have
# the same name in different files
# other one is in ./stuff.jl
function same_name()::Int
    return 3
end

# test with string literal
function print_weird()
    print("y = f(x)")
end

# test with generic type
function f(x::T)::T where {T}
    return x * 1312
end

# varargs + keyword args: a second method of `f`, same-file merge
function f(xs...; kw=1)
    return sum(xs) + kw
end

# struct: `Point(...)` is a constructor call, not a function call
struct Point
    x::Float64
    y::Float64
end

# callable struct: `(p::Point)(k)` registers a method on the type `Point`
(p::Point)(k::Float64) = Point(k * p.x, k * p.y)

# operator overloading: `a + b` resolves to this repo method
Base.:+(a::Point, b::Point) = Point(a.x + b.x, a.y + b.y)

# `@inline` wrappers are unwrapped to find the function definition
@inline function describe_point(p)
    return "($(p.x), $(p.y))"
end

# macro calls are transparent: the inner `Point(...)` call is still found
function shift(p, dx, dy)
    @twice Point(p.x + dx, p.y + dy)
end

end
