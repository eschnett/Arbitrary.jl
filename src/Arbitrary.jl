module Arbitrary

using Base.Iterators
using Random

export arbitrary



# Create an iterator from a stateful function
struct Gen{T}
    fun::Function
end

Base.IteratorEltype(::Type{Gen{T}}) where {T} = Base.HasEltype()
Base.IteratorSize(::Type{Gen{T}}) where {T} = Base.IsInfinite()
Base.eltype(::Type{Gen{T}}) where {T} = T
Base.iterate(gen::Gen{T}, state::Nothing = nothing) where {T} =
    (gen.fun()::T, nothing)



arbitrary(::Type{Nothing}, rng::AbstractRNG = MersenneTwister()) =
    repeated(nothing)

arbitrary(::Type{Bool}, rng::AbstractRNG = MersenneTwister()) =
    Gen{Bool}(() -> rand(rng, Bool))

arbitrary(::Type{Char}, rng::AbstractRNG = MersenneTwister()) =
    flatten([Char['a', 'b', 'c', 'A', 'B', 'C', '0', '1', '2',
                  '\'', '"', '`', '\\', '/',
                  ' ', '\t', '\r', '\n',
                  '\0'],
             Gen{Char}(() -> rand(rng, Char))])

arbitrary(::Type{S}, rng::AbstractRNG = MersenneTwister()) where {S<:Signed} =
    flatten([S[0, 1, 2, 3, -1, -2, 10, 100, -10,
               typemax(S), typemax(S)-1, typemin(S), typemin(S)+1],
             Gen{S}(() -> rand(rng, S))])

arbitrary(::Type{U}, rng::AbstractRNG = MersenneTwister()) where {U<:Unsigned} =
    flatten([U[0, 1, 2, 3, 10, 100, typemax(U), typemax(U)-1],
             Gen{U}(() -> rand(rng, U))])

const Floating = Union{Float16, Float32, Float64}
arbitrary(::Type{F}, rng::AbstractRNG = MersenneTwister()) where {F<:Floating} =
    flatten([F[0, 1, 2, 3, -1, -2, 10, 100, -10,
               1//2, 1//3, -1//2, 1//10, 1//100, -1//10,
               F(-0.0), F(Inf), F(-Inf), eps(F), 1+eps(F), 1-eps(F),
               F(NaN)],
             Gen{F}(() -> rand(rng, F))])

arbitrary(::Type{BigInt}, rng::AbstractRNG = MersenneTwister()) =
    flatten([BigInt[0, 1, 2, 3, -1, -2, 10, 100, -10,
                    big(10)^10, big(10)^100, -big(10)^10],
             Gen{BigInt}(() -> big(rand(rng, Int)))])

arbitrary(::Type{BigFloat}, rng::AbstractRNG = MersenneTwister()) =
    flatten([BigFloat[0, 1, 2, 3, -1, -2, 10, 100, -10,
                      1//2, 1//3, -1//2, 1//10, 1//100, -1//10,
                      big(10)^10, big(10)^100, -big(10)^10,
                      big(10)^-10, big(10)^-100, -big(10)^-10],
             Gen{BigFloat}(() -> big(rand(rng, Float64)))])

const BigRational = Rational{BigInt}
function rand1(rng, ::Type{BigRational})
    enum = big(rand(rng, Int))
    denom = big(0)
    while denom == 0
        denom = big(rand(rng, Int))
    end
    BigRational(enum, denom)
end
arbitrary(::Type{BigRational}, rng::AbstractRNG = MersenneTwister()) =
    flatten([BigRational[0, 1, 2, 3, -1, -2, 10, 100, -10,
                         1//2, 1//3, -1//2, 1//10, 1//100, -1//10,
                         big(10)^10, big(10)^100, -big(10)^10,
                         1//big(10)^10, 1//big(10)^100, -1//big(10)^10],
             Gen{BigRational}(() -> rand1(rng, BigRational))])

end
