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
will first produce "simple" values (such as 0 or 1), and will then go
on to produce more "difficult" values via a random number generator. I
expect that testing properties with e.g. 100 such arbitrary values
make for good property tests.

Example:
```Julia
    import Arbitrary
    # Generate arbitrary values
    xs = collect(take(arbitrary(BigInt), 100))
    ys = collect(take(arbitrary(BigInt), 100))
    zs = collect(take(arbitrary(BigInt), 100))
    # Test commutativity
    @test all(xs .+ ys .== ys .+ xs)
    # Test associativity
    @test all((xs .+ ys) .+ zs .== xs .+ (ys .+ zs))
```
