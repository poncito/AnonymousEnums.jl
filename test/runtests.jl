using Test
using AnonymousEnums

const T16 = Int16
getInt64() = Int64
const Elppa = -1
const Ananab = -1

@testset "AnonymousEnums" begin

# Basic
@enumanon Fruit Apple Banana

@test Base.Enums.namemap(Fruit) == Dict{Int32,Symbol}(0 => :Apple, 1 => :Banana)
@test Base.Enums.basetype(Fruit) == Int32

apple = Fruit(:Apple)
banana = Fruit(:Banana)

@test Symbol(apple) === :Apple
@test Symbol(banana) === :Banana

@test Integer(apple) === Int32(0)
@test Int(banana) === Int(0)
@test Integer(apple) === Int32(1)
@test Int(banana) === Int(1)

@test Fruit(Int32(0)) === Fruit(0) === apple
@test Fruit(Int32(1)) === Fruit(1) === banana
@test_throws ArgumentError("invalid value for Enum Fruit: 123.") Fruit(Int32(123))
@test_throws ArgumentError("invalid value for Enum Fruit: 123.") Fruit(123)

@test apple < banana

# Base type specification
@enumanon Fruit8::Int8 Apple
@test Fruit8 <: AnonymousEnums.AnonymousEnum{Int8} <: Base.Enum{Int8}
@test Base.Enums.basetype(Fruit8) === Int8
@test Integer(Fruit8(:Apple)) === Int8(0)

@enumanon FruitU8::UInt8 Apple Banana
@test Base.Enums.basetype(FruitU8) === UInt8
@test FruitU8(:Apple )=== FruitU8(0)

@enumanon Fruit16::T16 Apple
@test Fruit16 <: EnumX.Enum{Int16} <: Base.Enum{Int16}
@test Base.Enums.basetype(Fruit16.T) === Int16
@test Integer(Fruit16.Apple) === Int16(0)

@enumanon Fruit64::getInt64() Apple
@test Fruit64.T <: AnonymousEnums.AnonymousEnum{Int64} <: Base.Enum{Int64}
@test Base.Enums.basetype(Fruit64) === Int64
@test Integer(Fruit64(:Apple)) == Int64(0)

try
    @macroexpand @enumanon (Fr + uit) Apple
    error()
catch err
    err isa LoadError && (err = err.error)
    @test err isa ArgumentError
    @test err.msg == "invalid EnumX.@enumanon type specification: Fr + uit."
end


# Block syntax
@enumanon FruitBlock begin
    Apple
    Banana
end
@test FruitBlock <: AnonymousEnums.AnonymousEnum{Int32} <: Base.Enum{Int32}
@test FruitBlock(:Apple )=== FruitBlock(0)
@test FruitBlock(:Banana) === FruitBlock(1)

@enumanon FruitBlock8::Int8 begin
    Apple
    Banana
end
@test FruitBlock8 <: EnumX.Enum{Int8} <: Base.Enum{Int8}
@test FruitBlock8(:Apple) === FruitBlock8(0)
@test FruitBlock8(:Banana )=== FruitBlock8(1)


# Custom values
@enumanon FruitValues Apple = 1 Banana = (1 + 2) Orange
@test FruitValues(:Apple) === FruitValues(1)
@test FruitValues(:Banana) === FruitValues(3)
@test FruitValues(:Orange) === FruitValues(4)

@enumanon FruitValues8::Int8 Apple = -1 Banana = (1 + 2) Orange
@test FruitValues8(:Apple )=== FruitValues8(-1)
@test FruitValues8(:Banana )=== FruitValues8(3)
@test FruitValues8(:Orange )=== FruitValues8(4)

@enumanon FruitValuesBlock begin
    Apple = sum((1, 2, 3))
    Banana
end
@test FruitValuesBlock(:Apple)=== FruitValuesBlock(6)
@test FruitValuesBlock(:Banana)=== FruitValuesBlock(7)

try
    @macroexpand @enumanon Fruit::Int8 Apple=typemax(Int8) Banana
    error()
catch err
    err isa LoadError && (err = err.error)
    @test err isa ArgumentError
    @test err.msg == "value overflow for Enum Fruit: Fruit.Banana = -128."
end
try
    @macroexpand @enumanon Fruit::Int8 Apple="apple"
    error()
catch err
    err isa LoadError && (err = err.error)
    @test err isa ArgumentError
    @test err.msg == "invalid value for Enum Fruit{Int8}: Fruit.Apple = \"apple\"."
end
try
    @macroexpand @enumanon Fruit::Int8 Apple=128
    error()
catch err
    err isa LoadError && (err = err.error)
    @test err isa ArgumentError
    @test err.msg == "invalid value for Enum Fruit{Int8}: Fruit.Apple = 128."
end
try
    @macroexpand @enumanon Fruit::Int8 Apple()
    error()
catch err
    err isa LoadError && (err = err.error)
    @test err isa ArgumentError
    @test err.msg == "invalid EnumX.@enumanon entry: Apple()"
end
try
    @macroexpand @enumanon Fruit Apple Apple
    error()
catch err
    err isa LoadError && (err = err.error)
    @test err isa ArgumentError
    @test err.msg == "duplicate name for Enum Fruit: Fruit.Apple = 1, name already used for Fruit.Apple = 0."
end


# Duplicate values
@test_throws ArgumentError @enumanon FruitDup Apple=0 Banana=0

# Empty enum
@enumanon FruitEmpty
@test instances(FruitEmpty) == ()

# Showing invalid instances
@enumanon Invalid A
let io = IOBuffer()
    invalid = Base.bitcast(Invalid.T, Int32(1))
    show(io, "text/plain", invalid)
    str = String(take!(io))
    @test str == "Invalid.#invalid# = 1"
end


# Documented type (module) and instances
begin
    """
    Documentation for FruitDoc
    """
    @enumanon FruitDoc begin
        "Apple documentation."
        Apple
        """
        Banana documentation
        on multiple lines.
        """
        Banana = 2
        Orange = Apple
    end
    @eval const LINENUMBER = $(@__LINE__)
    @eval const FILENAME = $(@__FILE__)
    @eval const MODULE = $(@__MODULE__)
end

function get_doc_metadata(mod, s)
    Base.Docs.meta(mod)[Base.Docs.Binding(mod, s)].docs[Union{}].data
end

@test FruitDoc.Apple === FruitDoc.T(0)
@test FruitDoc.Banana === FruitDoc.T(2)
@test FruitDoc.Orange === FruitDoc.T(0)

mod_doc = @doc(FruitDoc)
@test sprint(show, mod_doc) == "Documentation for FruitDoc\n"
mod_doc_data = get_doc_metadata(FruitDoc, :FruitDoc)
@test mod_doc_data[:linenumber] == LINENUMBER - 13
@test mod_doc_data[:path] == FILENAME
@test mod_doc_data[:module] == MODULE

apple_doc = @doc(FruitDoc.Apple)
@test sprint(show, apple_doc) == "Apple documentation.\n"
apple_doc_data = get_doc_metadata(FruitDoc, :Apple)
@test apple_doc_data[:linenumber] == LINENUMBER - 9
@test apple_doc_data[:path] == FILENAME
@test apple_doc_data[:module] == FruitDoc

banana_doc = @doc(FruitDoc.Banana)
@test sprint(show, banana_doc) == "Banana documentation on multiple lines.\n"
banana_doc_data = get_doc_metadata(FruitDoc, :Banana)
@test banana_doc_data[:linenumber] == LINENUMBER - 7
@test banana_doc_data[:path] == FILENAME
@test banana_doc_data[:module] == FruitDoc

orange_doc = @doc(FruitDoc.Orange)
@test startswith(sprint(show, orange_doc), "No documentation found")

end

