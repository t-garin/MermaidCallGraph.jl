module stuff
export same_name, print_stuff, twice

# test with functions that have
# the same name in different files
# other one is in ./weird.jl
function same_name()::Int
    return 2
end

# test with private function
"""
    print_stuff()

Print a super string.
"""
function print_stuff()
    function get_super_string()::String
        return "nuchnibi"
    end
    print(get_super_string())
end

# macro definition: `macro` blocks are not function nodes, so not drawn
# doubles its argument by adding it to itself, so it also exercises the
# repo-defined `Base.:+` method on `Point` at runtime
macro twice(expr)
    return esc(:($expr + $expr))
end

# abstract types define no function nodes
abstract type Shape end

end
