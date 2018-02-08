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
@traitdispatch bam(x::::OMT.TC, y::TY)::TY where {TY}
@traitmethod bam(X::::OMT.T, y::TY)::TY where {TY} = y
@traitdispatch fbam(x::::OMT.TC, y::TY)::TY where {TY}
@forwardtraitmethod fbam(X::::OMT.T, y::TY)::TY where {TY} = y
@test bam(OMT.timpl(1),3) === 3
@test bam(OMT.timpl(1),[1.0,3.5]) == [1.0,3.5]
@test fbam(OMT.ftimpl(),3) === 3
@test fbam(OMT.ftimpl(),[1.0,3.5]) == [1.0,3.5]

# Trait dispatch on parametric methods with without return type annotation
@traitdispatch bam2(x::::OMT.TC, y::TY) where {TY}
@traitmethod bam2(X::::OMT.T, y::TY) where {TY} = y
@traitdispatch fbam2(x::::OMT.TC, y::TY) where {TY}
@forwardtraitmethod fbam2(X::::OMT.T, y::TY) where {TY} = y
@test bam2(OMT.timpl(1),3) === 3
@test bam2(OMT.timpl(1),[1.0,3.5]) == [1.0,3.5]
@test fbam2(OMT.ftimpl(),3) === 3
@test fbam2(OMT.ftimpl(),[1.0,3.5]) == [1.0,3.5]

# Trait dispatch on function with return type annotation
@traitdispatch bam3(x::::OMT.TC, y)::TY
@traitmethod bam3(X::::OMT.T, y)::TY = y
@traitdispatch fbam3(x::::OMT.TC, y)::TY
@forwardtraitmethod fbam3(X::::OMT.T, y)::TY = y
@test bam(OMT.timpl(1),3) === 3
@test bam(OMT.timpl(1),[1.0,3.5]) == [1.0,3.5]
@test fbam(OMT.ftimpl(),3) === 3
@test fbam(OMT.ftimpl(),[1.0,3.5]) == [1.0,3.5]

# Trait dispatch on function with optional argument
@traitdispatch baah(x::::OMT.TC, y = 1)
@traitmethod baah(X::::OMT.T, y = 1) = y
@traitdispatch fbaah(x::::OMT.TC, y = 1)
@forwardtraitmethod fbaah(X::::OMT.T, y = 1) = y
@test baah(OMT.timpl(1)) == baah(OMT.timpl(1),1)
@test fbaah(OMT.ftimpl()) == fbaah(OMT.ftimpl(),1)

# Trait dispatch on function with optional argument and keyword argument
@traitdispatch baah(x::::OMT.TC, y = 1; z = 1)
@traitmethod baah(X::::OMT.T, y = 1; z = 1) = y + z
@traitdispatch fbaah(x::::OMT.TC, y = 1; z = 1)
@traitmethod fbaah(X::::OMT.T, y = 1; z = 1) = y + z
@test baah(OMT.timpl(1)) == baah(OMT.timpl(1),1) == baah(OMT.timpl(1),1, z = 1)
@test fbaah(OMT.ftimpl()) == fbaah(OMT.ftimpl(),1) == fbaah(OMT.ftimpl(),1, z = 1)

# Trait dispatch on function with optional argument and sevearl keyword arguments
@traitdispatch baah2(x::::OMT.TC, y = 1; z = 1, w = 2)
@traitmethod baah2(X::::OMT.T, y = 1; z = 1, w = 2) = y + z
@traitdispatch fbaah2(x::::OMT.TC, y = 1; z = 1, w = 2)
@traitmethod fbaah2(X::::OMT.T, y = 1; z = 1, w = 2) = y + z
@test baah2(OMT.timpl(1)) == baah2(OMT.timpl(1),1) == baah2(OMT.timpl(1),1, z = 1) ==
  baah2(OMT.timpl(1),1, w = 2) == baah2(OMT.timpl(1),1, w = 2, z = 1)
@test fbaah2(OMT.ftimpl()) == fbaah2(OMT.ftimpl(),1) == fbaah2(OMT.ftimpl(),1, z = 1) ==
        fbaah2(OMT.ftimpl(),1, w = 2) == fbaah2(OMT.ftimpl(),1, w = 2, z = 1)
