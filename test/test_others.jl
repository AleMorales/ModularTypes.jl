using ModularTypes
import Parameters
using Base.Test

module OMT
    using ModularTypes
    import Parameters
    # Trait class
    struct TC end
    # One trait
    struct T
        x::Int64
    end
    struct timpl
        x::Int64
    end
    @hastrait timpl TC{T}
    @contains_kw TC{T} = T(1) struct ftimpl end
end

# Trait dispatch on parametric methods with return type annotation
@traitdispatch function bam(x::::OMT.TC, y::TY)::TY where {TY} end
@traitmethod function bam(X::::OMT.T, y::TY)::TY where {TY} y end
@traitdispatch function fbam(x::::OMT.TC, y::TY)::TY where {TY} end
@forwardtraitmethod function fbam(X::::OMT.T, y::TY)::TY where {TY} y end
@test bam(OMT.timpl(1),3) === 3
@test bam(OMT.timpl(1),[1.0,3.5]) == [1.0,3.5]
@test fbam(OMT.ftimpl(),3) === 3
@test fbam(OMT.ftimpl(),[1.0,3.5]) == [1.0,3.5]

# Trait dispatch on parametric methods with without return type annotation
@traitdispatch function bam2(x::::OMT.TC, y::TY) where {TY} end
@traitmethod function bam2(X::::OMT.T, y::TY) where {TY} y end
@traitdispatch function fbam2(x::::OMT.TC, y::TY) where {TY} end
@forwardtraitmethod function fbam2(X::::OMT.T, y::TY) where {TY} y end
@test bam2(OMT.timpl(1),3) === 3
@test bam2(OMT.timpl(1),[1.0,3.5]) == [1.0,3.5]
@test fbam2(OMT.ftimpl(),3) === 3
@test fbam2(OMT.ftimpl(),[1.0,3.5]) == [1.0,3.5]

# Trait dispatch on function with return type annotation
@traitdispatch function bam3(x::::OMT.TC, y)::TY end
@traitmethod function bam3(X::::OMT.T, y)::TY  y end
@traitdispatch function fbam3(x::::OMT.TC, y)::TY end
@forwardtraitmethod function fbam3(X::::OMT.T, y)::TY  y end
@test bam(OMT.timpl(1),3) === 3
@test bam(OMT.timpl(1),[1.0,3.5]) == [1.0,3.5]
@test fbam(OMT.ftimpl(),3) === 3
@test fbam(OMT.ftimpl(),[1.0,3.5]) == [1.0,3.5]

# Trait dispatch on function with optional argument
@traitdispatch function baah(x::::OMT.TC, y = 1) end
@traitmethod function baah(X::::OMT.T, y = 1)  y end
@traitdispatch function fbaah(x::::OMT.TC, y = 1) end
@forwardtraitmethod function fbaah(X::::OMT.T, y = 1)  y end
@test baah(OMT.timpl(1)) == baah(OMT.timpl(1),1)
@test fbaah(OMT.ftimpl()) == fbaah(OMT.ftimpl(),1)

# Trait dispatch on function with optional argument and keyword argument
@traitdispatch function baah(x::::OMT.TC, y = 1; z = 1) end
@traitmethod function baah(X::::OMT.T, y = 1; z = 1) y + z end
@traitdispatch function fbaah(x::::OMT.TC, y = 1; z = 1) end
@traitmethod function fbaah(X::::OMT.T, y = 1; z = 1) y + z end
@test baah(OMT.timpl(1)) == baah(OMT.timpl(1),1) == baah(OMT.timpl(1),1, z = 1)
@test fbaah(OMT.ftimpl()) == fbaah(OMT.ftimpl(),1) == fbaah(OMT.ftimpl(),1, z = 1)

# Trait dispatch on function with optional argument and sevearl keyword arguments
@traitdispatch function baah2(x::::OMT.TC, y = 1; z = 1, w = 2) end
@traitmethod function baah2(X::::OMT.T, y = 1; z = 1, w = 2) y + z end
@traitdispatch function fbaah2(x::::OMT.TC, y = 1; z = 1, w = 2) end
@traitmethod function fbaah2(X::::OMT.T, y = 1; z = 1, w = 2) y + z end
@test baah2(OMT.timpl(1)) == baah2(OMT.timpl(1),1) == baah2(OMT.timpl(1),1, z = 1) ==
  baah2(OMT.timpl(1),1, w = 2) == baah2(OMT.timpl(1),1, w = 2, z = 1)
@test fbaah2(OMT.ftimpl()) == fbaah2(OMT.ftimpl(),1) == fbaah2(OMT.ftimpl(),1, z = 1) ==
        fbaah2(OMT.ftimpl(),1, w = 2) == fbaah2(OMT.ftimpl(),1, w = 2, z = 1)
