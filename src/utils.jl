# This is like combinedef from MacroTools but only works with signature, ignoring
# the body and return type. We coudl rely on combinedef but then need to remove
# some stuff included in the final expression
"""
    combinesig(dict::Dict)
`combinesig` takes a dictionary as generated by `splitdef` and constructs an expression
with the signature of the function. """
function combinesig(dict::Dict)
  if !haskey(dict, :whereparams)
      if haskey(dict, :rtype)
          :($(dict[:name])($(dict[:args]...); $(dict[:kwargs]...))::$(dict[:rtype]))
      else
          :($(dict[:name])($(dict[:args]...); $(dict[:kwargs]...)))
      end
  else
      if haskey(dict, :rtype)
          :($(dict[:name])($(dict[:args]...); $(dict[:kwargs]...))::$(dict[:rtype]) where {$(dict[:whereparams]...)})
      else
          :($(dict[:name])($(dict[:args]...); $(dict[:kwargs]...)) where {$(dict[:whereparams]...)})
      end
  end
end


"""
    splitannotation(ex)
`splitannotation` takes an expression describing a type anotation and returns a
dict with the name of the variable being annotated, the type and its parameters (if any)
"""
function splitannotation(ex)
  # Do not annotate arguments that were not annotated in the original signature
  ex isa Symbol && (return Dict(:name => ex, :typ => nothing))
  # Optional parameters handled specially (may or may not be annotated)
  if ex.head == :kw
      ex = ex.args[1]
      ex isa Symbol && (return Dict(:name => ex, :typ => nothing))
  elseif ex.head != :(::)
      error("Could not parse argument ",ex)
  end
  # Get name and type
  MacroTools.@capture(ex, name_::typ_)
  out = Dict(:name => name, :typ => Symbol(), :params => :())
  # Split type if it is "curly"
  if typ isa Expr && typ.head == :curly
    out[:typ] = typ.args[1]
    out[:params] = typ.args[2]
  else
    out[:typ] = typ
  end
  return out
end

# Deal with trait types that are not visible and required module prefixes
# Also deal with parametric types
function cleantype(ex)
    if MacroTools.@capture(ex, (M_.name_{pars__}) | (name_{pars__}) |
                                     (M_.name_) | (name_))
        return name
    else
        error("I could not parse correctly the trait type ", ex)
    end
end
