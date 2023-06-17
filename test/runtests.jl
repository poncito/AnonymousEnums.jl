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
@test Int(apple) === Int(0)
@test Integer(banana) === Int32(1)
@test Int(banana) === Int(1)

@test Fruit(Int32(0)) === Fruit(0) === apple
@test Fruit(Int32(1)) === Fruit(1) === banana
@test_throws ArgumentError("invalid value for Enum Fruit: 123") Fruit(Int32(123))
@test_throws ArgumentError("invalid value for Enum Fruit: 123") Fruit(123)

@test apple < banana

# Base type specification
@enumanon Fruit8::Int8 Apple
@test Fruit8 <: AnonymousEnums.AnonymousEnum{Int8} <: Base.Enum{Int8}
@test Base.Enums.basetype(Fruit8) === Int8
@test Integer(Fruit8(:Apple)) === Int8(0)

@enumanon FruitU8::UInt8 Apple Banana
@test Base.Enums.basetype(FruitU8) === UInt8
@test FruitU8(:Apple)=== FruitU8(0)

@enumanon Fruit16::T16 Apple
@test Fruit16 <: AnonymousEnums.AnonymousEnum{Int16} <: Base.Enum{Int16}
@test Base.Enums.basetype(Fruit16) === Int16
@test Integer(Fruit16(:Apple)) === Int16(0)

@enumanon Fruit64::getInt64() Apple
@test Fruit64 <: AnonymousEnums.AnonymousEnum{Int64} <: Base.Enum{Int64}
@test Base.Enums.basetype(Fruit64) === Int64
@test Integer(Fruit64(:Apple)) == Int64(0)

try
    @macroexpand @enumanon (Fr + uit) Apple
    error()
catch err
    err isa LoadError && (err = err.error)
    @test err isa ArgumentError
    @test err.msg == "invalid type expression for AnonymousEnum Fr + uit"
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
@test FruitBlock8 <: AnonymousEnums.AnonymousEnum{Int8} <: Base.Enum{Int8}
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
    @test err.msg == "overflow in value \"Banana\" of AnonymousEnum Fruit"
end
try
    @macroexpand @enumanon Fruit::Int8 Apple="apple"
    error()
catch err
    err isa LoadError && (err = err.error)
    @test err isa ArgumentError
    @test err.msg == "invalid value for AnonymousEnum Fruit, Apple = \"apple\"; values must be integers"
end
try
    @macroexpand @enumanon Fruit::Int8 Apple=128
    error()
catch err
    err isa LoadError && (err = err.error)
    @test err isa InexactError
end
try
    @macroexpand @enumanon Fruit::Int8 Apple()
    error()
catch err
    err isa LoadError && (err = err.error)
    @test err isa ArgumentError
    @test err.msg == "invalid argument for AnonymousEnum Fruit: Apple()"
end
try
    @macroexpand @enumanon Fruit Apple Apple
    error()
catch err
    err isa LoadError && (err = err.error)
    @test err isa ArgumentError
    @test err.msg == "name \"Apple\" in AnonymousEnum Fruit is not unique"
end


# Duplicate values
@test_throws LoadError eval(:(@enumanon FruitDup Apple=0 Banana=0))

# Empty enum
@test_throws LoadError eval(:(@enumanon FruitDup))

end

