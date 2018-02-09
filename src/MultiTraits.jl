
"""
    @hastrait typ  trait

Declare that type `typ` implements trait `trait`. A trait is declared as `traitclass{trait}`
where `traitclass` is the trait class that `trait` belongs to.
"""
macro hastrait(typ, traitdecl)
    if  MacroTools.@capture(traitdecl, class_{trait_})
      if MacroTools.@capture(typ, name_{pars__})
          return esc(:($class(::Type{$typ}) where {$(pars...)} = $trait))
      else
          return esc(:($class(::Type{$typ}) = $trait))
      end
    else
      error("Trait was not specified correctly")
    end
end

"""
    @traitdispatch sig

Generate a trait dispatch method for the function signature `sig`. Trait classes
  inside the signature should be indicated with `::::` rather than `::`
"""
macro traitdispatch(sig)
    # We need lhs and rhs versions of the signature.
    lhs = splitsig(sig)
    rhs = deepcopy(lhs)
    rhs[:whereparams] = ()
    traitcons = Expr[]
    traitparams = Symbol[]
    # Loop through each argument of the method signature and id trait classes from :::: syntax
    # Keep track of new type parameters that new to be added to the where clause
    # Keep track of trait constructors to be used on rhs
    c = 0
    for i in 1:length(lhs[:args])
      arg = splitannotation(lhs[:args][i])
      if arg[:typ] == nothing
          rhs[:args][i] = arg[:name]
      elseif arg[:typ] isa Expr && arg[:typ].head == :(::)
        # Construct trait parameter
        c += 1
        traitpar = Symbol(string(:trait,c))
        push!(traitparams, traitpar)
        # RHS: Pass the argument without type qualification
        rhs[:args][i] = arg[:name]
        # RHS: Add an argument with a trait class constructor to the type parameter
        push!(traitcons, Expr(:call, arg[:typ].args[1], traitpar))
        # LHS: Substitute trait type for type parameter
        lhs[:args][i] = Expr(:(::), arg[:name], traitpar)
      else
        rhs[:args][i] = arg[:name]
      end
    end
    # Add trait class constructor to rhs
    prepend!(rhs[:args], traitcons)

    # Add type parameters in where clause of lhs
    lhs[:whereparams] = (lhs[:whereparams]..., traitparams...)

    # Add rhs as body to lhs
    lhs[:body] = combinesig(rhs)
    # Return the dispatch method
    return esc(:($(MacroTools.combinedef(lhs))))
end

"""
    @traitmethod fun

Generate a trait method for the function `fun`. Traits inside the
  signature should be indicated with `::::` rather than `::`
"""
macro traitmethod(def)
  # Break function into pieces
  orig = splitdef(def)
  fun = splitdef(def)
  # Loop over arguments and, for each argument with "::::", generate additional
  # argument with type singleton
  traits = Expr[]
  for i in 1:length(fun[:args])
    arg = splitannotation(fun[:args][i])
    if arg[:typ] isa Expr && arg[:typ].head == :(::)
      traittype = arg[:typ].args[1]
      push!(traits, :(::Type{$traittype}))
      fun[:args][i] = arg[:name]
      orig[:args][i] = :($(arg[:name])::$traittype)
    end
  end
  # Add the single types to args
  prepend!(fun[:args], traits)
  # Return the reconstructed function definition
  newdef = MacroTools.combinedef(fun)
  origdef = MacroTools.combinedef(orig)
  return esc(quote
    $origdef
    $newdef
end)
end


"""
    @implements trait1, [trait2, ...] type

Add to a type definition the implementation of several traits.
"""
macro implements(args...)
  def, hastraits = implements_struct(args)
  return esc(quote
    $def
    $hastraits
  end)
end

"""
    @implements_kw trait1, [trait2, ...] type

Add to a type definition the implementation of several traits.. The type definition
  can use all the features from the `@with_kw` macro of the package `Parameters`
"""
macro implements_kw(args...)
  def, hastraits = implements_struct(args)
  return esc(quote
    Parameters.@with_kw $def
    $hastraits
  end)
end


function implements_struct(args)
    length(args) == 1 && error("Must provide traits and type definition")
    traits = args[1:(end-1)]
    def = args[end]
    name = def.args[2]
    hastraits = :()
    # Generate the fields and the hastrait statements
    for trait in traits
      traitclass = trait.args[1]
      traittype = trait.args[2]
      hastraits = :($hastraits; ModularTypes.@hastrait $name $traitclass{$traittype})
    end
    return def, hastraits
end
