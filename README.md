[![CI](https://github.com/poncito/AnonymousEnums.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/poncito/AnonymousEnums.jl/actions/workflows/ci.yml)

# AnonymousEnums.jl

Enums without named instances.

The `Base.@enum` macro creates _named_ instances for the subtypes of `Enum`. However, providing unique names for those instances can sometimes be problematic, especially when it comes to code generation.

To address these issues, some packages (such as [EnumX.jl](https://github.com/fredrikekre/EnumX.jl)) offer alternatives to the `Base.@enum` macro. These alternatives involve implementing instances in a module.

This package takes it a step further by not naming the instances at all! The idea is that knowing the subtype of `Enum` should be sufficient to understand the values of an enum. Therefore, it should be possible to manipulate the instances using their symbols. Additionally, since the Julia compiler propagates constant symbols, no performance impact is expected.

## Usage

The package provides the exported `@anonymousenum` macro for creating an `Enum` subtype. This macro can be used similarly to `Base.@enum`.

```julia
julia> @anonymousenum Fruit::UInt8 begin
           apple
           banana
       end
julia> apple = Fruit(:apple)
julia> @assert apple == Fruit(0)
julia> @assert apple == :apple
julia> @assert instances(Fruit) == (:apple, :banana)
```

## Use case: Code generation

This package was developed to generate enums from type schemas while keeping the generated types and scopes as implementation details of the code generator.

Using this package allows generating an API like the following:

```julia
julia> writer.fruit.type = :apple
julia> if reader.fruit.type == :apple
           # do something
       elseif reader.fruit.type == :banana
           # do something else
       end
```

Note that in the example above, the symbols `:apple` and `:banana` are constant, enabling the same performance as traditional enums.

## See also

- [EnumX.jl](https://github.com/fredrikekre/EnumX.jl): This package implements scoped enums, as mentioned above.
