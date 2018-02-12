using ModularTypes
import Parameters
using Base.Test

module MT
    # Trait class
    struct TC end
    # One trait
    struct T end
    # A second trait
    struct T2 end

    # Trait class
    struct TCa end
    # One trait
    struct Ta end
    # A second trait
    struct Ta2 end
end

module MT2
    # A specific type
    struct Bar
        x::Int64
    end
    # A second specific type
    struct Baz
        y::Int64
    end
end


# Dispatch function foo for two traits under trait class TC
@traitdispatch function foo(x::::MT.TC) end
@traitmethod foo(x::::MT.T) = x.x
@traitmethod foo(x::::MT.T2) = 2*x.y

# Dispatch function fooz for two traits under trait class TCa
@traitdispatch function fooz(x::::MT.TCa) end
@traitmethod fooz(x::::MT.Ta) = x.x
@traitmethod fooz(x::::MT.Ta2) = 2*x.y

# Check that the right number of methods is created
@test length(methods(foo)) == 5

# Add traits to the types
@hastrait MT2.Bar MT.TC{MT.T}
@hastrait MT2.Bar MT.TCa{MT.Ta}
@hastrait MT2.Baz MT.TC{MT.T2}
@hastrait MT2.Baz MT.TCa{MT.Ta2}

# Check the right number of methods are created (2 come from TC definition)
@test length(methods(MT.TC)) == 4

# Check that methods are dispatched correctly
@test foo(MT2.Bar(1)) == 1
@test fooz(MT2.Bar(1)) == 1
@test foo(MT2.Baz(1)) == 2
@test fooz(MT2.Baz(1)) == 2

# Multiple trait-dispatch across trait classes (also, traits have been assigned already)
@traitdispatch function foo2(x::::MT.TC, y::::MT.TCa) end
@traitmethod foo2(x::::MT.T, y::::MT.Ta2) = x.x + 2*y.y

@test foo2(MT2.Bar(1), MT2.Baz(1)) == 3

# Check that @implements works
@implements MT.TC{MT.T2} MT.TCa{MT.Ta2} struct Baz2
    y::Int64
end
@implements_kw MT.TC{MT.T2} MT.TCa{MT.Ta2} struct Baz2kw
    y::Int64 = 1
end
@test foo(Baz2(1)) == 2
@test fooz(Baz2(1)) == 2
@test foo(Baz2kw()) == 2
@test fooz(Baz2kw()) == 2
