# Gleam IEEE Float

This Gleam library provides an `IEEEFloat` type that is compliant with the IEEE
754 standard for floating point arithmetic.

[![Package Version](https://img.shields.io/hexpm/v/ieee_float)](https://hex.pm/packages/ieee_float)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/ieee_float/)
![Erlang Compatible](https://img.shields.io/badge/target-erlang-a90432)
![JavaScript Compatible](https://img.shields.io/badge/target-javascript-f3e155)

## Background

Erlang's native float data type does not support infinity and NaN values. This
library fills that gap when such values need to be able to be represented and
worked with.

On the JavaScript target, an `IEEEFloat` is simply a `number` because JavaScript
natively implements the IEEE 754 standard.

## Usage

Add this library to your project:

```sh
gleam add ieee_float
```

API documentation can be found at <https://hexdocs.pm/ieee_float/>.

The following code demonstrates commonly used functionality of this library.

```gleam
import ieee_float.{finite}

pub fn main() {
  // Create finite values
  let zero = finite(0.0)
  let one = finite(1.0)
  let two = finite(2.0)
  let three = finite(3.0)

  // Create infinity and NaN values
  let positive_inf = ieee_float.positive_infinity()
  let negative_inf = ieee_float.negative_infinity()
  let nan = ieee_float.nan()

  // Check whether a value is finite or NaN
  let assert False = ieee_float.is_finite(positive_inf)
  let assert True = ieee_float.is_nan(nan)

  // Convert to a finite value of type `Float`. If the IEEE float is not
  // finite then an error is returned.
  let assert Ok(1.0) = ieee_float.to_finite(one)
  let assert Error(Nil) = ieee_float.to_finite(positive_inf)

  // Convert a value to raw bytes
  let assert <<0x3F, 0x80, 0x00, 0x00>> = ieee_float.to_bytes_32_be(one)

  // Create a value from raw bytes
  let assert True =
    ieee_float.from_bytes_32_be(<<0x3F, 0x80, 0x00, 0x00>>) == one

  // Perform math operations
  let assert True = ieee_float.add(two, three) == finite(5.0)
  let assert True = ieee_float.divide(one, two) == finite(0.5)
  let assert True = ieee_float.multiply(two, three) == finite(6.0)
  let assert True = ieee_float.subtract(three, one) == finite(2.0)

  // Perform math operations not supported by Erlang floats
  let assert True = ieee_float.add(one, positive_inf) == positive_inf
  let assert True =
    ieee_float.add(positive_inf, negative_inf) |> ieee_float.is_nan

  let assert True = ieee_float.multiply(positive_inf, two) == positive_inf
  let assert True =
    ieee_float.multiply(negative_inf, positive_inf) == negative_inf

  let assert True = ieee_float.divide(two, zero) == positive_inf
  let assert True =
    ieee_float.divide(positive_inf, positive_inf) |> ieee_float.is_nan
}
```

### Erlang Version

Use Erlang 27 or later for the best IEEE 754 compliance. Earlier Erlang versions
will work for the vast majority of use cases, but operations involving or
returning negative zero may return non-compliant results.

## License

This library is published under the MIT license, a copy of which is included.
