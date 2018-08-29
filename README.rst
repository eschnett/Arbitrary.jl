Arbitrary
=========

Generate arbitrary sequences for testing.

|Build Status (Travis)|
|Build Status (Appveyor)|
|Coverage Status (Coveralls)|

.. |Build Status (Travis)| image:: https://travis-ci.org/eschnett/Arbitrary.jl.svg?branch=master
   :target: https://travis-ci.org/eschnett/Arbitrary.jl
.. |Build status (Appveyor)| image:: https://ci.appveyor.com/api/projects/status/r0ryqdjn2rmhv29w?svg=true
   :target: https://ci.appveyor.com/project/eschnett/arbitrary-jl
.. |Coverage Status (Coveralls)| image:: https://coveralls.io/repos/github/eschnett/Arbitrary.jl/badge.svg?branch=master
   :target: https://coveralls.io/github/eschnett/Arbitrary.jl?branch=master

Introduction
------------

The Arbitrary package allows testing properties that must hold for
data types. For example, the `BigInt` implementation needs to ensure
that addition and multiplication are commutative and associative, that
`0` and `1` are the additive and multiplicative identity, etc. In an
ideal world, we would want the compiler to prove that these properties
hold (or at least to verify a human-written proof). In the real world,
we can test these properties hold for "arbitrary" `BigInt` numbers.

The basic API consists of the function `arbitrary(::Type{T})`, which
returns an iterator that produces values of type `T`. The iterator
will first produce "simple" or "special" values (such as 0 or 1), and
will then go on to produce more "difficult" values via a random number
generator. I expect that testing properties with e.g. 100 such
arbitrary values make for good property tests.

Example:
::
   import Arbitrary
   import Test

   # Generate arbitrary values
   xs = collect(take(arbitrary(BigInt), 100))
   ys = collect(take(arbitrary(BigInt), 100))
   zs = collect(take(arbitrary(BigInt), 100))

   # Test commutativity
   @test all(xs .+ ys .== ys .+ xs)
   # Test associativity
   @test all((xs .+ ys) .+ zs .== xs .+ (ys .+ zs))

Why not just random values?
---------------------------

This package takes its motivation from Haskell's
`Test.QuickCheck.Arbitrary` type class
<http://hackage.haskell.org/package/QuickCheck-2.11.3/docs/Test-QuickCheck-Arbitrary.html>.

Arbitrary values are quite similar to random values. The main
difference is that one has (better) control over the the probability
with which certain values are produced. This ensures that corner cases
receive proper testing. For example, the default random number
generator for `Int` values creates numbers with a uniform
distribution, and it is thus very unlikely to obtain small integers
(e.g. from 1 to 10).

Defining `arbitrary` for your own type
--------------------------------------

The `Arbitrary` package contains methods for various built-in types.
To extend this for your own type, you need to provide a respective
method for the `arbitrary` function.

Example:
::
   import Random
   import Arbitrary

   # Define your own type
   struct Point{T}
       x::T
       y::T
   end

   # Define an arbitrary method
   Arbitrary.arbitrary(::Type{Point{T}}, ast::ArbState) where {T <: Number} =
       flatten([Point{T}[Point(T(0), T(0)),
                         Point(T(0), T(1)),
                         Point(T(1), T(0)),
                         Point(T(-1), T(-1))],
                ...
