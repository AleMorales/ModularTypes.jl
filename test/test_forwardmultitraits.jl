using ModularTypes
using Base.Test
import Parameters

module FMT
    # Trait class
    struct TC end
    # One trait
    struct T
        x::Int64
    end
    # A second trait
    struct T2
        y::Int64
    end

    # Trait class
    struct TCa end
    # One trait
    struct Ta
        x::Int64
    end
    # A second trait
    struct Ta2
        y::Int64
    end
end

module FMT2
    import FMT
    # A specific type
    struct Bar
        fieldT::FMT.T
        fieldTa::FMT.Ta
    end
    # A second specific type
    struct Baz
        fieldT2::FMT.T2
        fieldTa2::FMT.Ta2
    end
end

# Dispatch function foo for two traits under trait class TC
@traitdispatch function ffoo(x::::FMT.TC) end
@forwardtraitmethod ffoo(x::::FMT.T) = x.x
@forwardtraitmethod ffoo(x::::FMT.T2) = 2*x.y

# Dispatch function fooz for two traits under trait class TCa
@traitdispatch function ffooz(x::::FMT.TCa) end
@forwardtraitmethod ffooz(x::::FMT.Ta) = x.x
@forwardtraitmethod ffooz(x::::FMT.Ta2) = 2*x.y


# Check that the right number of methods is created
@test length(methods(ffoo)) == 5


# Add traits to the types
@hastrait FMT2.Bar FMT.TC{FMT.T}
@hastrait FMT2.Bar FMT.TCa{FMT.Ta}
@hastrait FMT2.Baz FMT.TC{FMT.T2}
@hastrait FMT2.Baz FMT.TCa{FMT.Ta2}

# Check the right number of methods are created (2 come from TC definition)
@test length(methods(FMT.TC)) == 4

# Check that methods are dispatched correctly
const B = FMT2.Bar(FMT.T(1), FMT.Ta(1))
const Bz = FMT2.Baz(FMT.T2(1), FMT.Ta2(1))
@test ffoo(B) == 1
@test ffooz(B) == 1
@test ffoo(Bz) == 2
@test ffooz(Bz) == 2

# Multiple trait-dispatch across trait classes (also, traits have been assigned already)
@traitdispatch function ffoo2(x::::FMT.TC, y::::FMT.TCa) end
@forwardtraitmethod ffoo2(x::::FMT.T, y::::FMT.Ta2) = x.x + 2*y.y

@test ffoo2(B, Bz) == 3

# Check that @contains works
@contains FMT.TC{FMT.T2} FMT.TCa{FMT.Ta2} struct FBaz2 end
@contains_kw FMT.TC{FMT.T2} = FMT.T2(1) FMT.TCa{FMT.Ta2} = FMT.Ta2(1) struct FBaz2kw end

const Bz2 = FBaz2(FMT.T2(1), FMT.Ta2(1))
@test ffoo(Bz2) == 2
@test ffooz(Bz2) == 2
@test ffoo(FBaz2kw()) == 2
@test ffooz(FBaz2kw()) == 2
