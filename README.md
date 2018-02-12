# ModularTypes

[![Travis](https://travis-ci.org/AleMorales/ModularTypes.jl.svg?branch=master)](https://travis-ci.org/AleMorales/ModularTypes.jl)
[![AppVeyor](https://ci.appveyor.com/api/projects/status/y5v7b53nyb0hwucd?svg=true)](https://ci.appveyor.com/project/AleMorales/modulartypes-jl)
[![Codecov](https://codecov.io/gh/AleMorales/ModularTypes.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/AleMorales/ModularTypes.jl)


ModularTypes allows creating Julia types by making use of  type composition and
a multitrait-dispatch system. This package those situations where, unlike in
generic programming, an algorithm and its associated data should not be decoupled.
A common situation where such deocupling is not adequate is when building models
by reusing modules (e.g. in agent based modelling), hence the name of the package.

## What is the problem?

Type composition may fit naturally the concept of modular building (i.e. the
model *has a* module rather than *is a* module). Even in examples that are used
to introduce inheritance, type composition may be more powerful. For example,
rather than saying "a teacher is a person" and a "student is a person" one may
say that a person may "have the ability to teach" or "have the ability to learn".
In this case, modules would be defined for "Teaching" and "Learning" that provide
all the methods and data required to implement such abilities. This avoids having
to redesign the type hierarchy whenever a change is introduced in the system (i.e.
reuse of data and functionality is horizontal rather than hierarchical).

```julia
struct Teacher
  teaching::Teaching
  ...
end
struct Student
  learning::Learning
  ...
end
```

Where `...` represents other abilities we may want to confer to `Teacher`s and
`Student`s, such `Eating`, `Driving`, etc. A hierarchical relationship can still
be emulated by composing types at multiple levels (like a matryoshka doll).

However, with type composition, the person would not really acquire the
ability to teach or learn, which remain attached to the fields to which the Teaching
or Learning modules were attached. That is, instead of `teach(t::Teacher, s::Student)`
one would have to say `teach(t.teaching::Teaching, s.learning::Learning)`. This
code suffers from a *semantic displacement* as the original intention was to make
the teacher teach, and the fields teaching and learning do not represent an actual
entity. This can get particularly complicated if types are nested at multiple levels.
The solution to this problem is to generate *forwarding methods* that corrects the
semantic displacement as in:

```julia
teach(t::Teacher, s::Student) = teach(t.teaching, s.learning)
```

## What does this package do?

ModularTypes provides macros that automatically generate these forwarding
methods for any existing Julia type and make them available when included
in other types as described in the above. This is achieved by using a multitraits
system, similar in nature to the package [SimpleTraits.jl](https://github.com/mauro3/SimpleTraits.jl).

### Multitraits

The main difference with respect to SimpleTraits.jl is that traits are organized
into trait classes and that a trait is a property defined when generating the methods
(i.e. any existing type can be used as a trait).

A trait class is then use to dispatch the same function for different traits
included in the class. Both traits and trait classes are single parameter but
multiple traits may be used within a function signature. Four colons (`::::`)
are used to denote function arguments that are traits or trait classes. This is
inspired by [Traitor.jl](https://github.com/andyferris/Traitor.jl).

The multitrait system may be used independent of type composition. The trait
dispatch method and the specific trait methods are implement by the macros
`@traitdispatch` and `@traitmethod`. For example:

```julia
# Type to be used for trait dispatching
struct TC end
# Create a dispatch method associated to a trait class
@traitdispatch function foo(x::::TC) end
# Type to be used as trait
struct T end
# Create a method for trait T
@traitmethod foo(x::::T) = x.x
```
The macro `@hastrait` is then used to indicate than a given type implements a
given trait. It is necessary to specify both the trait class and the trait
being implement, as in the following example:

```julia
struct bar
    x::Int64
end
# Declare that bar has the trait T from trait class TC
@hastrait bar TC{T}
foo(bar(3))
```

Note that only one trait per trait class should be implemented. Traits can be
added to a type at any moment after its definitions, and trait methods will become
available even if their are created after a trait is assigned to a type. If the
traits to be implemented are known at the time of type definition, the `@implements`
macro comes in handy:

```julia
@implements TC{T} struct baz
    y::Int64
end
```

If you are used to define your types with `@with_kw` from the [Parameters.jl](https://github.com/mauro3/Parameters.jl)
package, you can use `@implements_kw`, which will automatically call `@with_kw`

### Modular types

In the case that we want to create forwarding methods to correct the semantic
displacement of type composition, the procedure is exactly the same as for
multitraits (see previous section) with the differences:

* The `@forwardtraitmethod` macro should be used instead of `@traitmethod`
* The type must be assigned to a field with the name `field<typename>` where `<typename>` is the name of the type.

For example:

```julia
# Type to be used for trait dispatching
struct fTC end
# Create a dispatch method associated to a trait class
@traitdispatch function fooz(x::::fTC) end
# Just a regular type, for which a forwarding method will be created
struct fT
    x::Int64
end
# Create a method for fT
@forwardtraitmethod fooz(x::::fT) = x.x
# Type that includes fT in fieldfT
struct fbar
    fieldfT::fT
end
@hastrait fbar fTC{fT}
fooz(fbar(fT(3)))
```

Similarly to multitraits, if the traits are known at the moment of type definition,
the keywords `@contains` and `@contains_kw` may be used. The latter is particularly
handy as type composition can result in complex object construction. For example:

```julia
@contains_kw fTC{fT} = fT(1) struct fbarkw
end
fooz(fbarkw())
```

### Compatibility across modules

Note that traits may live in a different module to the module where the forward methods
are defined and/or the module where the container types are defined. Normal module
prefixing may be used if the symbols are no imported in all the macros described
in the above. However, the name of the field to which a type with forwarding methods
is assigned should strip out all the module prefixing.

### Containing multiple types

A type may implement multiple traits and contain multiple types. When using `@implements`, `@contains` or their
`kw` equivalents,  all the traits should be listed as different arguments of the macro call.
`@contains` and its `kw` equivalent will insert the instances of the type-traits
in the order in which they are listed after all the fields already existing. Then
it will add the traits to the type in the same order. That is,

```julia
@contains TC1{T1} TC{T2} struct bar2
  y::Int64
end
```

is equivalent to:

```julia
@contains TC1{T1} TC{T2} struct bar2
  y::Int64
  fieldT1::T1
  fieldT2::T2
end
@hastrait bar2 TC1{T1}
@hastrait bar2 TC2{T2}
```

Only one trait class can dispatch a given method on a given namespace. That is,
```julia
@traitdispatch function foo(x::::TC, y) end
@traitdispatch function foo(x::::TC2, y) end
```
will result in the second definition overwriting the first. However,
```julia
@traitmethod function foo(x::::T, y) end
@traitmethod function foo(x::::T2, y) end
```
will work.

### Keyword and optional arguments

Methods and function signatures used with `@traitdispatch`, `@traitmethod` and
`@forwardtraitmethod` may contain optional and keyword arguments. However, these
arguments cannot be used for trait dispatch. Also, the default values assigned
in the `@traitdispatch` method will override any default values assigned in the
`@traitmethod` or `@forwardtraitmethod` methods.

### Parametric types

Parametric types may be used as traits and trait dispatch will correctly propagate
the type parameters. When composing a type from parametric types, the name of
the field should not take into account the type parameters. But the type parameters
still need to be considered in the type definition. That is:

```julia
@contains TC{T{T1,S1}} struct bar{T1,S1} end
```
is equivalent to:

```julia
struct bar{T1,S1}
  fieldT::T{T1,S1}
end
@hastraits bar{T1,S1} TC{T{T1,S1}}
```

Note that the `T1`s and `S1`s must coincide within the type definition and
within the `@hastrait` macro. Type parameters may also be used in methods
modified by `@traitdispatch`, `@traitmethod` or `@forwardtraitmethod` and they
will be respected in the generated methods.

## How does this work?

This is an implementation of inspired on the packages SimpleTraits.jl and Traitor.jl.

`@traitdispatch` will takes an empty function, extract its signature and generates
a method where each argument qualified with `::::` is converted into a type parameter
in the method signature. The body of the generated method is a call to the same
function but with an extra argument for each trait used for dispatch. These
arguments are calls to a constructor with the same name as the trait class and
taking the type parameter as input. The extra argument go first, as otherwise it
would not be possible to use optional and keyword arguments. That is:

```julia
@traitdispatch function fun(x::::TC1, y::Int64, z::::TC2) end
```

will generate

```julia
fun(x::traitTC1, y::Int64, z::traitTC2) where {traitTC1, traitTC2} =
    fun(TC1(traitTC1), TC2(traitTC2), x, y, z)
```

`@traitmethod` will add new method definition based on its argument. In the signature
of the extra method, each argument qualified with `::::` is left unqualified. In
addition, a value type argument is added for each trait, matching the extra arguments generated by `@traitdispatch`. The body of the method remains unchanged. For example:

```julia
@traitmethod fun(x::::T1, y::Int64, z::::T2) = x+y+z
```

will generate 2 methods

```julia
fun(x::T1, y::Int64, z::T2) = x+y+z
fun(::Type{T1}, ::Type{T2}, x, y::Int64, z) = x + y + z
```

The first method allows to bypass trait dispatch when using objects of type `T1` and `T2`. The second method is the one that will be executed when `x` and `z` are objects
that have the traits `T1` and `T2` (i.e. that behave as if they were of type `T1` and
`T2` as far as `fun` is concerned).

`@hastrait` will define the constructors required by `@traitdispatch`, that
returns the type associated to a trait when taking as argument the
type implementing the trait. That is

```julia
@hastrait bar TC{T}
```

will generate

```julia
TC(::Type{bar}) = T
```

`@forwardtraitmethod` will take a method definition and add an extra method.
The signature of the extra method is modified as in `@traitmethod`. However,
the body of the method is subtituted by a call to the original method, but
substituying any argument that is qualified by a trait with a reference to
the field of the correct name (i.e. `field<trait_name>`). For example:

```julia
@forwardtraitmethod fun(x::::T1, y::Int64, z::::T2) = x+y+z
```

will generate

```julia
fun(x::T1, y::Int64, z::T2) = x+y+z
fun(::Type{T1}, ::Type{T2}, x, y::Int64, z) = fun(x.fieldT1, y, z.fieldT2)
```
