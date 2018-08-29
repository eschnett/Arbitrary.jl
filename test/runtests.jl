using Base.Iterators
using Test

using Arbitrary



const alltypes = [Nothing, Bool, Char,
                  Int8, Int16, Int32, Int64, Int128,
                  UInt8, UInt16, UInt32, UInt64, UInt128,
                  Float16, Float32, Float64,
                  BigInt, BigFloat,
                  Rational{BigInt}]

for T in alltypes
    @testset "Basic functionality for type $T" begin
        # Generate arbitrary values
        arb = arbitrary(T)
        values = collect(take(arb, 100))
        # Generate some other arbitrary values
        arb2 = arbitrary(T)
        values2 = collect(take(arb2, 100))
        # Ensure they are different
        @test all(isequal.(values, values2)) == (T === Nothing)
        # Generate values from a known RNG
        arb3 = arbitrary(T, UInt(42))
        arb4 = arbitrary(T, UInt(42))
        @test all(isequal.(collect(take(arb3, 100)), collect(take(arb4, 100))))
    end
end

# Floating-point numbers do NOT satisfy the usual arithmetic laws
const arithmetic_types = [Int8, Int16, Int32, Int64, Int128,
                          UInt8, UInt16, UInt32, UInt64, UInt128,
                          # Float16, Float32, Float64,
                          BigInt, BigFloat,
                          Rational{BigInt}]
const division_types = [# Float16, Float32, Float64,
                        # BigFloat,
                        Rational{BigInt}]
for T in arithmetic_types
    @testset "Arithmetic identities for type $T" begin
        # Generate arbitrary values
        xs = collect(take(arbitrary(T), 100))
        ys = collect(take(arbitrary(T), 100))
        zs = collect(take(arbitrary(T), 100))
        ds = collect(take(Iterators.filter(x -> !isequal(x, T(0)),
                                           arbitrary(T)), 100))
        # Addition:
        # Commutativity
        @test all(isequal.(xs .+ ys, ys .+ xs))
        # Associativity
        @test all(isequal.((xs .+ ys) .+ zs, xs .+ (ys .+ zs)))
        # Neutral element
        @test all(isequal.(xs .+ T(0), xs))
        @test all(isequal.(T(0) .+ xs, xs))
        # Inverse
        @test all(isequal.(xs .+ (-xs), T(0)))
        @test all(isequal.(xs .- ys, xs .+ (-ys)))
        # Multiplication:
        # Commutativity
        @test all(isequal.(xs .* ys, ys .* xs))
        # Associativity
        @test all(isequal.((xs .* ys) .* zs, xs .* (ys .* zs)))
        # Neutral element
        @test all(isequal.(xs .* T(1), xs))
        @test all(isequal.(T(1) .* xs, xs))
        # Inverse
        if T in division_types
            @test all(isequal.(ds .* inv.(ds), T(1)))
            @test all(isequal.(xs ./ ds, xs .* inv.(ds)))
        end
    end
end
