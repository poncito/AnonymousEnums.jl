# AnonymousEnums.jl

Enums without named instances.

The macro `Base.@enum` creates _named_ instances for the subtypes of `Enum`.
Having to provide a unique names to those instances can be problematic sometimes.
This is particularly true for code generation.

In order to circumvent those issues, some packages (see e.g. [EnumX.jl](https://github.com/fredrikekre/EnumX.jl))
provide alternatives to the `Base.@enum` macro,
where the strategy consists in implementing those instances in
a module.

This package goes one step further and simply does not name the instances at all!
The idea is that knowing the subtype of `Enum` should be enough to make sense of the values
of an enum.
Hence, it is should be possible to manipulate the instance through their symbol.
Also, since the Julia compiler propagates constant symbols, no performance impact
should be expected.

## Usage

The package provides the (exported) `@anonymousenum` macro to create an `Enum` subtype.
The macro can be used like `Base.@enum`.

```julia
julia> @anonymousenum Fruit::UInt8 begin
           apple
           banana
       end
julia> apple = Fruit(:apple)
julia> @assert apple == Fruit(0)
julia> @assert apple == :apple
julia> @ssert instances(Fruit) == (:apple, :banana)
```

## Code generation use case

This package was developped to be able to generate enums from type schemas,
while keeping the generated types and scopes a code generator implementation detail.

This package allows to generate this kind of API:
```julia
julia> writer.fruit.type = :apple
julia> if reader.fruit.type == :apple
           # do something
       elseif reader.fruit.type == :banana
           # do something else
       end
```
Note in the example above, that the symbols `:apple` and `:banana` are
_constant_, which allows for the same performance as classical enum.

## See also

- [EnumX.jl](ha)/Wnumctps://github.com/fredrikekre/EnumX.jl): this package implements
the scoped enum as mentioned above.
