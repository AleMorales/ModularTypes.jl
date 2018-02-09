using ModularTypes
using Base.Test

module PMT
    using ModularTypes
    # Trait class
    struct TC end

    ### Single parameter ###
    # Type to be used as trait
    struct bar{T}
      x::T
    end
    # Type that implements a trait
    struct impl{T}
      x::T
    end

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

    # Implementing parametric traits
    @implements TC{bar2{T1,S1}} struct impl3{T1,S1}
      x::T1
      y::S1
    end

    # Containing parametric traits
    @contains TC{bar2{T1,S1}} struct impl4{T1,S1} end
end


### Single parameter ###
@hastrait PMT.impl{T} PMT.TC{PMT.bar{T}}
tf = PMT.impl(one(Float64))
ti = PMT.impl(one(Int64))
@test PMT.TC(typeof(tf)) == PMT.bar{Float64}
@test PMT.TC(typeof(ti)) == PMT.bar{Int64}

@traitdispatch pfoo(x::::PMT.TC)
@traitmethod function pfoo(x::::PMT.bar{T})::DataType where {T} T end
@test pfoo(PMT.bar(1)) == pfoo(PMT.impl(1))


### Multiple parameters ###
@hastrait PMT.impl2{T,S} PMT.TC{PMT.bar2{T,S}}
tf2 = PMT.impl2(one(Float64),one(Int64))
ti2 = PMT.impl2(one(Int64),one(Float64))
@test PMT.TC(typeof(tf2)) == PMT.bar2{Float64, Int64}
@test PMT.PMT.TC(typeof(ti2)) == PMT.bar2{Int64, Float64}

@traitdispatch pfoo2(x::::PMT.TC)
@traitmethod function pfoo2(x::::PMT.bar2{T,S})::DataType where {T,S} S end
@test pfoo2(PMT.bar2(1,1.0)) == pfoo2(PMT.impl2(1,1.0))

# Implementing parametric traits
tf3 = PMT.impl3(one(Float64),one(Int64))
ti3 = PMT.impl3(one(Int64),one(Float64))
@test PMT.TC(typeof(tf3)) == PMT.bar2{Float64, Int64}
@test PMT.TC(typeof(ti3)) == PMT.bar2{Int64, Float64}


# Containing parametric traits
tf4 = PMT.impl4(PMT.bar2(one(Float64),one(Int64)))
ti4 = PMT.impl4(PMT.bar2(one(Int64),one(Float64)))
@test PMT.TC(typeof(tf4)) == PMT.bar2{Float64, Int64}
@test PMT.TC(typeof(ti4)) == PMT.bar2{Int64, Float64}

@traitdispatch pfoo4(x::::PMT.TC)
@forwardtraitmethod function pfoo4(x::::PMT.bar2{T,S})::DataType where {T,S} S end
@test pfoo4(PMT.bar2(1,1.0)) == pfoo4(PMT.impl4(PMT.bar2(1,1.0)))
