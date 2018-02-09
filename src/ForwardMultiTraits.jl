"""
    @forwardtraitmethod fun

Generate a forwarding trait method for the function `fun`. Traits inside the
  signature should be indicated with `::::` rather than `::`. Any type that
  includes these types as fields will be able to use these methods without
  accessing the field explicitly.
"""
macro forwardtraitmethod(def)
  # Break function into pieces
  fun = splitdef(def)
  lhs = deepcopy(fun)
  rhs = deepcopy(lhs)
  rhs[:whereparams] = ()
  # Loop over arguments and, for each argument with "::::", generate additional
  # argument with type singleton and field access on rhs
  traits = Expr[]
  for i in 1:length(lhs[:args])
    arg = splitannotation(lhs[:args][i])
    if arg[:typ] isa Expr && arg[:typ].head == :(::)
      traittype = arg[:typ].args[1]
      push!(traits, :(::Type{$traittype}))
      fun[:args][i] = Expr(:(::), arg[:name], arg[:typ].args[1])
      lhs[:args][i] = arg[:name]
      # Need to remove all module prefixing from the type
      cleantyp = cleantype(arg[:typ].args[1]) # (argument of ::)
      rhs[:args][i] = Expr(:., arg[:name], QuoteNode(Symbol(string(:field,cleantyp))))
    else
      rhs[:args][i] = arg[:name]
    end
  end
  # Add the single types to args
  prepend!(lhs[:args], traits)
  # Return original method and the forwarding trait dispatch method
  return esc(quote
    $(MacroTools.combinedef(fun))
    $(combinesig(lhs)) = $(combinesig(rhs))
  end)
end

"""
    @contains trait1, [trait2, ...] type

Modify a type definition to include a series of types as inputs and implement
  the associated forwarding traits.
"""
macro contains(args...)
  length(args) == 1 && error("Must provide traits and type definition")
  traits = args[1:(end-1)]
  def = args[end]
  name = def.args[2]
  hastraits = :()
  # Generate the fields and the hastrait statements
  for trait in traits
    traitclass = trait.args[1]
    traittype = trait.args[2]
    cleantyp = cleantype(traittype)
    fieldname = Symbol(string(:field, cleantyp))
    push!(def.args[3].args, :($fieldname::$traittype))
    hastraits = :($hastraits; ModularTypes.@hastrait $name $traitclass{$traittype})
  end
  return esc(quote
    $def
    $hastraits
  end)
end

"""
    @contains_kw type1, [type2, ...] def

Modify a type definition to include a series of types as inputs and implement
  the associated forwarding traits. The type definition can use all the features
  from the `@with_kw` macro of the package `Parameters`.
"""
macro contains_kw(args...)
  length(args) == 1 && error("Must provide traits and type definition")
  traits = args[1:(end-1)]
  def = args[end]
  name = def.args[2]
  hastraits = :()
  # Generate the fields and the hastrait statements
  for trait in traits
    if trait.head == :(=)
      traitinfo = trait.args[1]
      default = trait.args[2]
      traitclass = traitinfo.args[1]
      traittype = traitinfo.args[2]
      cleantyp = cleantype(traittype)
      fieldname = Symbol(string(:field, cleantyp))
      push!(def.args[3].args, :($fieldname::$traittype = $default))
    else
      traitclass = trait.args[1]
      traittype = trait.args[2]
      cleantyp = cleantype(traittype)
      fieldname = Symbol(string(:field, cleantyp))
      push!(def.args[3].args, :($fieldname::$traittype))
    end
    hastraits = :($hastraits; ModularTypes.@hastrait $name $traitclass{$traittype})
  end
  return esc(quote
    Parameters.@with_kw $def
    $hastraits
  end)
end
