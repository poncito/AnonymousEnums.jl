module AnonymousEnums

export @enumanon

abstract type SymbolEnum{T<:Integer} <: Enum{T} end

Base.:(==)(s::Symbol, x::SymbolEnum) = ==(x, s)
Base.:(==)(x::T, s::Symbol) where {T<:SymbolEnum} = ==(x, T(s))

macro enumanon(T, syms...)
    if isempty(syms)
        throw(ArgumentError("no arguments given for SymbolEnum $T"))
    end
    basetype = Int32
    typename = T
    if isa(T, Expr) && T.head === :(::) && length(T.args) == 2 && isa(T.args[1], Symbol)
        typename = T.args[1]
        basetype = Core.eval(__module__, T.args[2])
        if !isa(basetype, DataType) || !(basetype <: Integer) || !isbitstype(basetype)
            throw(ArgumentError("invalid base type for SymbolEnum $typename, $T=::$basetype; base type must be an integer primitive type"))
        end
    elseif !isa(T, Symbol)
        throw(ArgumentError("invalid type expression for SymbolEnum $T"))
    end
    values = basetype[]
    seen = Set{Symbol}()
    namemap = Dict{basetype,Symbol}()
    lo = hi = 0
    i = zero(basetype)
    hasexpr = false

    if length(syms) == 1 && syms[1] isa Expr && syms[1].head === :block
        syms = syms[1].args
    end
    for s in syms
        s isa LineNumberNode && continue
        if isa(s, Symbol)
            if i == typemin(basetype) && !isempty(values)
                throw(ArgumentError("overflow in value \"$s\" of SymbolEnum $typename"))
            end
        elseif isa(s, Expr) &&
               (s.head === :(=) || s.head === :kw) &&
               length(s.args) == 2 && isa(s.args[1], Symbol)
            i = Core.eval(__module__, s.args[2]) # allow exprs, e.g. uint128"1"
            if !isa(i, Integer)
                throw(ArgumentError("invalid value for SymbolEnum $typename, $s; values must be integers"))
            end
            i = convert(basetype, i)
            s = s.args[1]
            hasexpr = true
        else
            throw(ArgumentError(string("invalid argument for SymbolEnum ", typename, ": ", s)))
        end
        if !Base.isidentifier(s)
            throw(ArgumentError("invalid name for SymbolEnum $typename; \"$s\" is not a valid identifier"))
        end
        if hasexpr && haskey(namemap, i)
            throw(ArgumentError("both $s and $(namemap[i]) have value $i in SymbolEnum $typename; values must be unique"))
        end
        namemap[i] = s
        push!(values, i)
        if s in seen
            throw(ArgumentError("name \"$s\" in SymbolEnum $typename is not unique"))
        end
        push!(seen, s)
        if length(values) == 1
            lo = hi = i
        else
            lo = min(lo, i)
            hi = max(hi, i)
        end
        i += oneunit(i)
    end
    _typename_str = string(typename)

    expr_symbol_constructor = :(function $(esc(typename))(x::Symbol) end)
    expr_symbol_constructor_body = last(expr_symbol_constructor.args).args
    for (k, v) in namemap
        push!(expr_symbol_constructor_body, :(x==$(Meta.quot(v)) && return $(esc(typename))($k)))
    end
    push!(expr_symbol_constructor_body, :(Base.Enums.enum_argument_error($(Expr(:quote, typename)), x)))

    blk = quote
        # enum definition
        primitive type $(esc(typename)) <: SymbolEnum{$(basetype)} $(sizeof(basetype) * 8) end
        function $(esc(typename))(x::Integer)
            $(Base.Enums.membershiptest(:x, values)) || Base.Enums.enum_argument_error($(Expr(:quote, typename)), x)
            return Core.bitcast($(esc(typename)), convert($(basetype), x))
        end
        $expr_symbol_constructor
        if isdefined(Base.Enums, :namemap)
            Base.Enums.namemap(::Type{$(esc(typename))}) = $(esc(namemap))
        end
        Base.typemin(x::Type{$(esc(typename))}) = $(esc(typename))($lo)
        Base.typemax(x::Type{$(esc(typename))}) = $(esc(typename))($hi)
        let insts = (Any[ $(esc(typename))(v) for v in $values ]...,)
            Base.instances(::Type{$(esc(typename))}) = insts
        end
    end
    push!(blk.args, :nothing)
    blk.head = :toplevel
    return blk
end

end # module AnonymousEnums
