using ModularTypes
using Base.Test

### Single parameter ###

# Trait class
struct TC end
# Type to be used as trait
struct bar{T}
  x::T
end
# Type that implements a trait
struct impl{T}
  x::T
end

@hastrait impl{T} TC{bar{T}}
tf = impl(1.0)
ti = impl(1)
@test TC(typeof(tf)) == bar{Float64}
@test TC(typeof(ti)) == bar{Int64}



### Multiple parameters ###

# Type to be used as trait
struct bar2{T,S}
  x::T
  y::S
end
# Type that implements a trait
struct impl2{T,S}
  x::T
  y::S
end

@hastrait impl2{T,S} TC{bar2{T,S}}
tf2 = impl2(1.0,1)
ti2 = impl2(1,1.0)
@test TC(typeof(tf2)) == bar2{Float64, Int64}
@test TC(typeof(ti2)) == bar2{Int64, Float64}
