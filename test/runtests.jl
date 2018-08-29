using Base.Iterators
using Test

using Arbitrary



const alltypes = [Nothing, Bool, Char,
                  Int8, Int16, Int32, Int64, Int128,
                  UInt8, UInt16, UInt32, UInt64, UInt128,
                  Float16, Float32, Float64,
                  BigInt, BigFloat,
                  Rational{BigInt},
                  Tuple{}]
hasonevalue(T) = T in [Nothing, Tuple{}]

const Array0{T} = Array{T, 0}
const Array1{T} = Array{T, 1}
const Array2{T} = Array{T, 2}
const allcontainers = [nothing, Ref, Tuple, Array0, Array1, Array2]
hasfixedshape(C) = C in [nothing, Ref, Tuple, Array0]

myequal(x::T, y::T) where {T} = isequal(x, y)
myequal(x::Ref{T}, y::Ref{T}) where {T} = isequal(x[], y[])

for C in allcontainers
    for E in alltypes
        T = C === nothing ? E : C{E}
        @testset "Basic functionality for type $T" begin
            # Generate arbitrary values
            arb = arbitrary(T)
            values = collect(take(arb, 100))
            # Generate some other arbitrary values
            arb2 = arbitrary(T)
            values2 = collect(take(arb2, 100))
            # Ensure they are different
            @test all(myequal.(values, values2)) ==
                (hasonevalue(E) && hasfixedshape(C))
            # Generate values from a known RNG
            arb3 = arbitrary(T, UInt(42))
            arb4 = arbitrary(T, UInt(42))
            @test all(myequal.(collect(take(arb3, 100)),
                               collect(take(arb4, 100))))
        end
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
