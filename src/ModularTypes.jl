module ModularTypes

import MacroTools
using Parameters

export @hastrait, @traitdispatch, @traitmethod, @forwardtraitmethod,
       @contains, @contains_kw, @implements, @implements_kw

# Include the different source files
include("utils.jl")
include("MultiTraits.jl")
include("ForwardMultiTraits.jl")

end
