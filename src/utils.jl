
# Extract type parameters that make use of "where" syntax
# Modified from MacroTools in order to support return type annotation
function gatherwheres(ex)
  if MacroTools.@capture(ex, (f_ where {params1__}))
    f2, params2 = gatherwheres(f)
    (f2, (params1..., params2...))
  elseif MacroTools.@capture(ex, (f_::rtype_ where {params1__}))
      f2, params2 = gatherwheres(:($f::$rtype))
      (f2, (params1..., params2...))
  else
    (ex, ())
  end
end

# This is based on combinedef from MacroTools but only works with signature, not
# the full definition
"""
    splitsig(sig)
`splitsig` converts a method signature into a dictionary structure. """
function splitsig(sig::Expr)
  error_msg = "Not a signature: $sig"
  fcall_nowhere, whereparams = gatherwheres(sig)
  @assert(MacroTools.@capture(fcall_nowhere, ((func_(args__; kwargs__)) |
                                              (func_(args__; kwargs__)::rtype_) |
                                              (func_(args__)) |
                                              (func_(args__)::rtype_))),
          error_msg)
  @assert(MacroTools.@capture(func, (fname_{params__} | fname_)), error_msg)
  di = Dict(:name=>fname, :args=>args,
            :kwargs=>(kwargs===nothing ? [] : kwargs))
  if rtype !== nothing; di[:rtype] = rtype end
  if whereparams !== nothing; di[:whereparams] = whereparams end
  if params !== nothing; di[:params] = params end
  di
end

# This is the same function as in MacroTools, but it uses the enhanced version of
# gatherwheres
function splitdef(fdef)
  error_msg = "Not a function definition: $fdef"
  @assert(MacroTools.@capture(MacroTools.longdef1(fdef),
                   function (fcall_ | fcall_) body_ end),
          "Not a function definition: $fdef")
  fcall_nowhere, whereparams = gatherwheres(fcall)
  @assert(MacroTools.@capture(fcall_nowhere, ((func_(args__; kwargs__)) |
                                   (func_(args__; kwargs__)::rtype_) |
                                   (func_(args__)) |
                                   (func_(args__)::rtype_))),
          error_msg)
  @assert(MacroTools.@capture(func, (fname_{params__} | fname_)), error_msg)
  di = Dict(:name=>fname, :args=>args,
            :kwargs=>(kwargs===nothing ? [] : kwargs), :body=>body)
  if rtype !== nothing; di[:rtype] = rtype end
  if whereparams !== nothing; di[:whereparams] = whereparams end
  if params !== nothing; di[:params] = params end
  di
end


# This is based on combinedef from MacroTools but only works with signature, not
# the full definition
"""
    combinesig(dict::Dict)
`combinesig` takes a dictionary as generated by `splitsig` and constructs a
new method signature. """
function combinesig(dict::Dict)
  wparams = get(dict, :whereparams, [])
  name = dict[:name]
  if isempty(wparams)
      :($name($(dict[:args]...); $(dict[:kwargs]...)))
  else
      :($name($(dict[:args]...); $(dict[:kwargs]...)) where {$(wparams...)})
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
