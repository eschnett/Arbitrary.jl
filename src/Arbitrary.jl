module Arbitrary

using Base.Iterators
using Random

using IterTools

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



# Create an iterator from a pure function that takes an iterator as argument
mutable struct Iter
    iter
    havestate::Bool
    state
    Iter(iter) = new(iter, false, nothing)
end
function next(iter::Iter)
    if !iter.havestate
        res, state = iterate(iter.iter)
    else
        res, state = iterate(iter.iter, iter.state)
    end
    iter.havestate = true
    iter.state = state
    res
end

struct Gen2{T}
    fun::Function
    iter::Iter
end

Base.IteratorEltype(::Type{Gen2{T}}) where {T} = Base.HasEltype()
Base.IteratorSize(::Type{Gen2{T}}) where {T} = Base.IsInfinite()
Base.eltype(::Type{Gen2{T}}) where {T} = T
Base.iterate(gen::Gen2{T}, state::Nothing = nothing) where {T} =
    gen.fun(gen.iter), nothing



# Internal state for arbitrary iterators
struct ArbState
    rng::AbstractRNG
end

# Provide a default state
arbitrary(::Type{T}) where {T} = arbitrary(T, ArbState(MersenneTwister()))
arbitrary(::Type{T}, seed::UInt) where {T} =
    arbitrary(T, ArbState(MersenneTwister(seed)))



# Produce arbitrary values based on an RNG
random_arbitrary(::Type{T}, ast::ArbState) where {T} =
    Gen{T}(() -> rand(ast.rng, T))



# Methods for particular types
arbitrary(::Type{Nothing}, ast::ArbState) = repeated(nothing)

arbitrary(::Type{Bool}, ast::ArbState) = random_arbitrary(Bool, ast)

arbitrary(::Type{Char}, ast::ArbState) =
    flatten([Char['a', 'b', 'c', 'A', 'B', 'C', '0', '1', '2',
                  '\'', '"', '`', '\\', '/',
                  ' ', '\t', '\r', '\n',
                  '\0'],
             random_arbitrary(Char, ast)])

arbitrary(::Type{S}, ast::ArbState) where {S<:Signed} =
    flatten([S[0, 1, 2, 3, -1, -2, 10, 100, -10,
               typemax(S), typemax(S)-1, typemin(S), typemin(S)+1],
             random_arbitrary(S, ast)])

arbitrary(::Type{U}, ast::ArbState) where {U<:Unsigned} =
    flatten([U[0, 1, 2, 3, 10, 100, typemax(U), typemax(U)-1],
             random_arbitrary(U, ast)])

const Floating = Union{Float16, Float32, Float64}
arbitrary(::Type{F}, ast::ArbState) where {F<:Floating} =
    flatten([F[0, 1, 2, 3, -1, -2, 10, 100, -10,
               1//2, 1//3, -1//2, 1//10, 1//100, -1//10,
               F(-0.0), F(Inf), F(-Inf), eps(F), 1+eps(F), 1-eps(F),
               F(NaN)],
             random_arbitrary(F, ast)])

arbitrary(::Type{BigInt}, ast::ArbState) =
    flatten([BigInt[0, 1, 2, 3, -1, -2, 10, 100, -10,
                    big(10)^10, big(10)^100, -big(10)^10],
             imap(big, random_arbitrary(Int, ast))])

arbitrary(::Type{BigFloat}, ast::ArbState) =
    flatten([BigFloat[0, 1, 2, 3, -1, -2, 10, 100, -10,
                      1//2, 1//3, -1//2, 1//10, 1//100, -1//10,
                      big(10)^10, big(10)^100, big(10)^1000, -big(10)^10,
                      big(10)^-10, big(10)^-100, big(10)^-1000, -big(10)^-10],
             imap(big, random_arbitrary(Float64, ast))])

const BigRational = Rational{BigInt}
function mkrat(iter::Iter)::BigRational
    enum = big(next(iter))
    denom = big(0)
    while denom == 0
        denom = big(next(iter))
    end
    BigRational(enum, denom)
end
arbitrary(::Type{BigRational}, ast::ArbState) =
    flatten([BigRational[0, 1, 2, 3, -1, -2, 10, 100, -10,
                         1//2, 1//3, -1//2, 1//10, 1//100, -1//10,
                         big(10)^10, big(10)^100, -big(10)^10,
                         1//big(10)^10, 1//big(10)^100, -1//big(10)^10],
             Gen2{BigRational}(mkrat, Iter(random_arbitrary(Int, ast)))])

end
