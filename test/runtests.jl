using Base.Iterators
using Test

using Arbitrary



function dotest(::Type{T}) where {T}
    arb = arbitrary(T)
    values = take(arb, 100)
    values = collect(take(arb, 100))
    @test length(values) == 100
    @test all([typeof(v) === T for v in values])
    arb2 = arbitrary(T)
    values2 = collect(take(arb2, 100))
    @test all(values .=== values2) === (T === Nothing)
end

for T in [Nothing, Bool, Char,
          Int8, Int16, Int32, Int64, Int128,
          UInt8, UInt16, UInt32, UInt64, UInt128,
          Float16, Float32, Float64,
          BigInt, BigFloat,
          Rational{BigInt}]
    dotest(T)
end
