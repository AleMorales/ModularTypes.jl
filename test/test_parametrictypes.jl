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
struct impl2{T1,S1}
  x::T1
  y::S1
end

@hastrait impl2{T,S} TC{bar2{T,S}}
tf2 = impl2(1.0,1)
ti2 = impl2(1,1.0)
@test TC(typeof(tf2)) == bar2{Float64, Int64}
@test TC(typeof(ti2)) == bar2{Int64, Float64}

# Implementing parametric traits

# Type to be used as trait
struct bar2{T,S}
  x::T
  y::S
end
# Type that implements a parametric trait
@implements TC{bar2{T1,S1}} struct impl3{T1,S1}
  x::T1
  y::S1
end

tf3 = impl3(1.0,1)
ti3 = impl3(1,1.0)
@test TC(typeof(tf3)) == bar2{Float64, Int64}
@test TC(typeof(ti3)) == bar2{Int64, Float64}
