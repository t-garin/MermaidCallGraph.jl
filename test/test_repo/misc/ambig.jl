module ambig
using ..stuff
using ..weird

# both `stuff` and `weird` define a `same_name`; an unqualified call finds all of
# them in scope, so edges are drawn towards each (with a "?"-marked arrow)
function resolve()
    return same_name()
end

end
