module stuff
export same_name, print_stuff

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
macro twice(expr)
    return esc(:(2 * $expr))
end

# abstract types define no function nodes
abstract type Shape end

end
