module stuff
export same_name, print_stuff

# test with functions that have
# the same name in different files
# other one is in ./weird.jl
function same_name()::Int
    return 2
end

# test with private function 
function print_stuff()
    function get_super_string()::String
        return "nuchnibi"
    end
    print(get_super_string())
end 

end