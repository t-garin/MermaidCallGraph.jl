module weird
export same_name, print_weird

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

end