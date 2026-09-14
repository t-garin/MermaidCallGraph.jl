module io
export stuff_same_name
import ..stuff: same_name

# call a function with same_name
"""
    stuff_same_name()

Return `same_name()` minus 4.
"""
function stuff_same_name()
    return same_name() - 4
end

end