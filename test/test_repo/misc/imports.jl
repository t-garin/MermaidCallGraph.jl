module imports
using ..math, ..weird
import ..math.weird_same_name
import ..math: broadcast_double_mean as bdm

# `using ..math, ..weird`: several modules in a single `using`
# `import ..math.weird_same_name`: dot import of a single function
# `import ..math: broadcast_double_mean as bdm`: aliased import, `bdm` is an alias
function use_imports()
    print(weird_same_name())          # explicit: dot import
    print(bdm([1, 2], [3, 4]))        # explicit: aliased import
    print_weird()                     # implicit: via the multi-module `using`
end
end
