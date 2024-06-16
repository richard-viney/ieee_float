import gleam/erlang
import gleam/erlang/atom
import gleam/float
import gleam/int
import gleam/order.{type Order}
import gleam/result
import gleam/string

/// An IEEE 754 compliant floating point value that can be either a finite
/// number, positive infinity, negative infinity, or NaN (not a number).
///
/// On the JavaScript target, an `IEEEFloat` is a `number`.
///
pub opaque type IEEEFloat {
  Finite(value: Float)
  Infinite(sign: Sign)
  NaN
}

/// The sign of an infinite `IEEEFloat` value.
///
type Sign {
  Positive
  Negative
}

/// Creates a new `IEEEFloat` from a `Float`.
///
@external(javascript, "./ieee_float_js.mjs", "finite")
pub fn finite(f: Float) -> IEEEFloat {
  Finite(f)
}

/// Returns the positive infinity value.
///
@external(javascript, "./ieee_float_js.mjs", "positive_infinity")
pub fn positive_infinity() -> IEEEFloat {
  Infinite(Positive)
}

/// Returns the negative infinity value.
///
@external(javascript, "./ieee_float_js.mjs", "negative_infinity")
pub fn negative_infinity() -> IEEEFloat {
  Infinite(Negative)
}

/// Returns the `NaN` value.
///
@external(javascript, "./ieee_float_js.mjs", "nan")
pub fn nan() -> IEEEFloat {
  NaN
}

/// Returns whether an `IEEEFloat` is finite. If it isn't finite it is either
/// infinite or `NaN`.
///
@external(javascript, "./ieee_float_js.mjs", "is_finite")
pub fn is_finite(f: IEEEFloat) -> Bool {
  case f {
    Finite(_) -> True
    _ -> False
  }
}

/// Returns whether an `IEEEFloat` is `NaN`. If it isn't `NaN` it is either
/// finite or infinite.
///
@external(javascript, "./ieee_float_js.mjs", "is_nan")
pub fn is_nan(f: IEEEFloat) -> Bool {
  f == NaN
}

/// Converts an `IEEEFloat` to the native `Float` type. If the `IEEEFloat` is
/// infinite or `NaN` then `Error(Nil)` is returned.
///
@external(javascript, "./ieee_float_js.mjs", "to_finite")
pub fn to_finite(f: IEEEFloat) -> Result(Float, Nil) {
  case f {
    Finite(value) -> Ok(value)
    _ -> Error(Nil)
  }
}

/// Formats an `IEEEFloat` as a string.
///
@external(javascript, "./ieee_float_js.mjs", "to_string")
pub fn to_string(f: IEEEFloat) -> String {
  case f {
    Finite(f) -> float.to_string(f)
    Infinite(Positive) -> "Infinity"
    Infinite(Negative) -> "-Infinity"
    NaN -> "NaN"
  }
}

/// Parses a string to an `IEEEFloat`. If the string is not a valid float then
/// `NaN` is returned.
///
@external(javascript, "./ieee_float_js.mjs", "parse")
pub fn parse(s: String) -> IEEEFloat {
  case string.trim(s) {
    "Infinity" -> Infinite(Positive)
    "-Infinity" -> Infinite(Negative)
    s ->
      case float.parse(s) {
        Ok(f) -> Finite(f)
        _ -> NaN
      }
  }
}

/// Converts an `IEEEFloat` to bytes for a little endian 32-bit IEEE 754 float.
///
@external(javascript, "./ieee_float_js.mjs", "to_bytes_32_le")
pub fn to_bytes_32_le(f: IEEEFloat) -> BitArray {
  case f {
    Finite(f) -> <<f:32-float-little>>
    Infinite(Positive) -> <<0x7F800000:32-little>>
    Infinite(Negative) -> <<0xFF800000:32-little>>
    NaN -> <<0x7FC00000:32-little>>
  }
}

/// Converts bytes for a little endian 32-bit IEEE 754 float to an `IEEEFloat`.
///
@external(javascript, "./ieee_float_js.mjs", "from_bytes_32_le")
pub fn from_bytes_32_le(bytes: BitArray) -> IEEEFloat {
  case bytes {
    <<value:32-float-little>> -> Finite(value)
    <<0x7F800000:32-little>> -> Infinite(Positive)
    <<0xFF800000:32-little>> -> Infinite(Negative)
    _ -> NaN
  }
}

/// Converts an `IEEEFloat` to bytes for a big endian 32-bit IEEE 754 float.
///
@external(javascript, "./ieee_float_js.mjs", "to_bytes_32_be")
pub fn to_bytes_32_be(f: IEEEFloat) -> BitArray {
  case f {
    Finite(f) -> <<f:32-float-big>>
    Infinite(Positive) -> <<0x7F800000:32-big>>
    Infinite(Negative) -> <<0xFF800000:32-big>>
    NaN -> <<0x7FC00000:32-big>>
  }
}

/// Converts bytes for a big endian 32-bit IEEE 754 float to an `IEEEFloat`.
///
@external(javascript, "./ieee_float_js.mjs", "from_bytes_32_be")
pub fn from_bytes_32_be(bytes: BitArray) -> IEEEFloat {
  case bytes {
    <<value:32-float-big>> -> Finite(value)
    <<0x7F800000:32-big>> -> Infinite(Positive)
    <<0xFF800000:32-big>> -> Infinite(Negative)
    _ -> NaN
  }
}

/// Converts an `IEEEFloat` to bytes for a little endian 64-bit IEEE 754 float.
///
@external(javascript, "./ieee_float_js.mjs", "to_bytes_64_le")
pub fn to_bytes_64_le(f: IEEEFloat) -> BitArray {
  case f {
    Finite(f) -> <<f:64-float-little>>
    Infinite(Positive) -> <<0x7FF0000000000000:64-little>>
    Infinite(Negative) -> <<0xFFF0000000000000:64-little>>
    NaN -> <<0x7FF8000000000000:64-little>>
  }
}

/// Converts bytes for a little endian 64-bit IEEE 754 float to an `IEEEFloat`.
///
@external(javascript, "./ieee_float_js.mjs", "from_bytes_64_le")
pub fn from_bytes_64_le(bytes: BitArray) -> IEEEFloat {
  case bytes {
    <<value:64-float-little>> -> Finite(value)
    <<0x7FF0000000000000:64-little>> -> Infinite(Positive)
    <<0xFFF0000000000000:64-little>> -> Infinite(Negative)
    _ -> NaN
  }
}

/// Converts an `IEEEFloat` to bytes for a big endian 64-bit IEEE 754 float.
///
@external(javascript, "./ieee_float_js.mjs", "to_bytes_64_be")
pub fn to_bytes_64_be(f: IEEEFloat) -> BitArray {
  case f {
    Finite(f) -> <<f:64-float-big>>
    Infinite(Positive) -> <<0x7FF0000000000000:64-big>>
    Infinite(Negative) -> <<0xFFF0000000000000:64-big>>
    NaN -> <<0x7FF8000000000000:64-big>>
  }
}

/// Converts bytes for a big endian 64-bit IEEE 754 float to an `IEEEFloat`.
///
@external(javascript, "./ieee_float_js.mjs", "from_bytes_64_be")
pub fn from_bytes_64_be(bytes: BitArray) -> IEEEFloat {
  case bytes {
    <<value:64-float-big>> -> Finite(value)
    <<0x7FF0000000000000:64-big>> -> Infinite(Positive)
    <<0xFFF0000000000000:64-big>> -> Infinite(Negative)
    _ -> NaN
  }
}

/// This helper function detects the `badarith` error that is raised by Erlang
/// when a floating point operation gives a result that is not allowed, such as
/// an infinity or a NaN.
///
/// `Error(Nil)` indicates that a `badarith` error occurred when executing the
/// passed function.
///
@external(javascript, "./ieee_float_js.mjs", "rescue_bad_arith")
fn rescue_bad_arith(do: fn() -> a) -> Result(a, Nil) {
  case erlang.rescue(do) {
    Ok(r) -> Ok(r)

    Error(erlang.Errored(reason)) ->
      case
        atom.from_dynamic(reason) |> result.map(atom.to_string)
        == Ok("badarith")
      {
        True -> Error(Nil)
        False ->
          panic as {
            "Unexpected error in float operation: " <> string.inspect(reason)
          }
      }

    Error(e) ->
      panic as { "Unexpected error in float operation: " <> string.inspect(e) }
  }
}

/// Returns the absolute value of an `IEEEFloat`.
///
@external(javascript, "./ieee_float_js.mjs", "absolute_value")
pub fn absolute_value(f: IEEEFloat) -> IEEEFloat {
  case f {
    Finite(f) -> f |> float.absolute_value |> Finite
    Infinite(_) -> Infinite(Positive)
    NaN -> NaN
  }
}

/// Adds two `IEEEFloat`s together.
///
@external(javascript, "./ieee_float_js.mjs", "add")
pub fn add(a: IEEEFloat, b: IEEEFloat) -> IEEEFloat {
  case a, b {
    Finite(a), Finite(b) ->
      case rescue_bad_arith(fn() { Finite(a +. b) }) {
        Ok(f) -> f
        Error(Nil) ->
          case a >=. 0.0, b >=. 0.0 {
            True, True -> Infinite(Positive)
            False, False -> Infinite(Negative)
            _, _ -> panic as "Unexpected error in ieee_float.add"
          }
      }

    Infinite(sign), Finite(_) -> Infinite(sign)
    Finite(_), Infinite(sign) -> Infinite(sign)

    Infinite(Positive), Infinite(Positive) -> Infinite(Positive)
    Infinite(Negative), Infinite(Negative) -> Infinite(Negative)
    Infinite(Positive), Infinite(Negative)
    | Infinite(Negative), Infinite(Positive)
    -> NaN

    NaN, _ | _, NaN -> NaN
  }
}

/// Rounds an `IEEEFloat` to the next highest whole number.
///
@external(javascript, "./ieee_float_js.mjs", "ceiling")
pub fn ceiling(f: IEEEFloat) -> IEEEFloat {
  case f {
    Finite(f) -> f |> float.ceiling |> Finite
    _ -> f
  }
}

/// Restricts an `IEEEFloat` between a lower and upper bound.
///
pub fn clamp(
  f: IEEEFloat,
  min min_bound: IEEEFloat,
  max max_bound: IEEEFloat,
) -> IEEEFloat {
  f
  |> min(max_bound)
  |> max(min_bound)
}

/// Compares two `IEEEFloats`, returning an `Order`: `Lt` for lower than, `Eq`
/// for equals, or `Gt` for greater than. If either value is `NaN` then
/// `Error(Nil)` is returned.
///
@external(javascript, "./ieee_float_js.mjs", "compare")
pub fn compare(a: IEEEFloat, with b: IEEEFloat) -> Result(Order, Nil) {
  case a, b {
    Finite(a), Finite(b) -> Ok(float.compare(a, b))

    Finite(_), Infinite(Positive) -> Ok(order.Lt)
    Infinite(Positive), Finite(_) -> Ok(order.Gt)
    Finite(_), Infinite(Negative) -> Ok(order.Gt)
    Infinite(Negative), Finite(_) -> Ok(order.Lt)

    Infinite(Negative), Infinite(Negative) -> Ok(order.Eq)
    Infinite(Negative), Infinite(Positive) -> Ok(order.Lt)
    Infinite(Positive), Infinite(Negative) -> Ok(order.Gt)
    Infinite(Positive), Infinite(Positive) -> Ok(order.Eq)

    NaN, _ | _, NaN -> Error(Nil)
  }
}

/// Divides one `IEEEFloat` by another.
///
@external(javascript, "./ieee_float_js.mjs", "divide")
pub fn divide(a: IEEEFloat, b: IEEEFloat) -> IEEEFloat {
  case a, b {
    NaN, _ | _, NaN -> NaN

    Finite(0.0), Finite(0.0)
    | Finite(0.0), Finite(-0.0)
    | Finite(-0.0), Finite(0.0)
    | Finite(-0.0), Finite(-0.0)
    -> NaN

    Finite(a), Finite(0.0) ->
      case a <. 0.0 {
        True -> Infinite(Negative)
        False -> Infinite(Positive)
      }

    Finite(a), Finite(-0.0) ->
      case a <. 0.0 {
        True -> Infinite(Positive)
        False -> Infinite(Negative)
      }

    Finite(a), Finite(b) ->
      case rescue_bad_arith(fn() { Finite(a /. b) }) {
        Ok(f) -> f
        Error(Nil) ->
          case a >=. 0.0 == b >=. 0.0 {
            True -> Infinite(Positive)
            False -> Infinite(Negative)
          }
      }

    Finite(a), Infinite(Positive) ->
      case a >=. 0.0 {
        True -> Finite(0.0)
        False -> Finite(-0.0)
      }

    Finite(a), Infinite(Negative) ->
      case a >=. 0.0 {
        True -> Finite(-0.0)
        False -> Finite(0.0)
      }

    Infinite(Positive), Finite(b) ->
      case b >=. 0.0 {
        True -> Infinite(Positive)
        False -> Infinite(Negative)
      }

    Infinite(Negative), Finite(b) ->
      case b >=. 0.0 {
        True -> Infinite(Negative)
        False -> Infinite(Positive)
      }

    Infinite(_), Infinite(_) -> NaN
  }
}

/// Rounds an `IEEEFloat` to the next lowest whole number.
///
@external(javascript, "./ieee_float_js.mjs", "floor")
pub fn floor(f: IEEEFloat) -> IEEEFloat {
  case f {
    Finite(f) -> f |> float.floor |> Finite
    _ -> f
  }
}

/// Compares two `IEEEFloat`s, returning the larger of the two.
///
@external(javascript, "./ieee_float_js.mjs", "max")
pub fn max(a: IEEEFloat, b: IEEEFloat) -> IEEEFloat {
  case a, b {
    Finite(a), Finite(b) -> float.max(a, b) |> Finite
    Infinite(Positive), _ | _, Infinite(Positive) -> Infinite(Positive)
    Infinite(Negative), a | a, Infinite(Negative) -> a
    NaN, _ | _, NaN -> NaN
  }
}

/// Compares two `IEEEFloat`s, returning the smaller of the two.
///
@external(javascript, "./ieee_float_js.mjs", "min")
pub fn min(a: IEEEFloat, b: IEEEFloat) -> IEEEFloat {
  case a, b {
    Finite(a), Finite(b) -> float.min(a, b) |> Finite
    Infinite(Negative), _ | _, Infinite(Negative) -> Infinite(Negative)
    Infinite(Positive), a | a, Infinite(Positive) -> a
    NaN, _ | _, NaN -> NaN
  }
}

/// Multiplies two `IEEEFloat`s together.
///
@external(javascript, "./ieee_float_js.mjs", "multiply")
pub fn multiply(a: IEEEFloat, b: IEEEFloat) -> IEEEFloat {
  case a, b {
    NaN, _ | _, NaN -> NaN

    Finite(a), Finite(b) ->
      case rescue_bad_arith(fn() { Finite(a *. b) }) {
        Ok(f) -> f
        Error(Nil) ->
          case a >=. 0.0 == b >=. 0.0 {
            True -> Infinite(Positive)
            False -> Infinite(Negative)
          }
      }

    Infinite(Positive), Finite(f) | Finite(f), Infinite(Positive) ->
      case f >=. 0.0 {
        True -> Infinite(Positive)
        False -> Infinite(Negative)
      }

    Infinite(Negative), Finite(f) | Finite(f), Infinite(Negative) ->
      case f >=. 0.0 {
        True -> Infinite(Negative)
        False -> Infinite(Positive)
      }

    Infinite(a), Infinite(b) ->
      case a == b {
        True -> Infinite(Positive)
        False -> Infinite(Negative)
      }
  }
}

/// Returns the negative of an `IEEEFloat`.
///
@external(javascript, "./ieee_float_js.mjs", "negate")
pub fn negate(f: IEEEFloat) -> IEEEFloat {
  case f {
    Finite(f) -> f |> float.negate |> Finite
    Infinite(Positive) -> Infinite(Negative)
    Infinite(Negative) -> Infinite(Positive)
    NaN -> NaN
  }
}

/// Returns the results of the base being raised to the power of the exponent.
///
@external(javascript, "./ieee_float_js.mjs", "power")
pub fn power(f: IEEEFloat, exp: IEEEFloat) -> IEEEFloat {
  case f, exp {
    Finite(f), Finite(exp) ->
      case rescue_bad_arith(fn() { float.power(f, exp) }) {
        Ok(f) ->
          f
          |> result.map(Finite)
          |> result.unwrap(NaN)

        Error(Nil) -> Infinite(Positive)
      }

    NaN, _ | _, NaN -> NaN

    // An infinity to the power of zero is one
    Infinite(_), Finite(0.0) | Infinite(_), Finite(-0.0) -> Finite(1.0)

    // 1 and -1 to the power of an infinity is NaN
    Finite(1.0), Infinite(_) | Finite(-1.0), Infinite(_) -> NaN

    // Powers involving two infinities
    Infinite(Positive), Infinite(Positive) -> Infinite(Positive)
    Infinite(Positive), Infinite(Negative) -> Finite(0.0)
    Infinite(Negative), Infinite(Positive) -> Infinite(Positive)
    Infinite(Negative), Infinite(Negative) -> Finite(0.0)

    // Cases of a positive infinity and a finite
    Infinite(Positive), Finite(f) if f <. 0.0 -> Finite(0.0)
    Finite(0.0), Infinite(Positive) | Finite(-0.0), Infinite(Positive) ->
      Finite(0.0)
    Finite(_), Infinite(Positive) | Infinite(Positive), Finite(_) ->
      Infinite(Positive)

    // Cases of a finite raised to negative infinity
    Finite(f), Infinite(Negative) ->
      case f >. 1.0 || f <. -1.0 {
        True -> Finite(0.0)
        False -> Infinite(Positive)
      }

    // Case of negative infinity raised to a finite. Whole odd numbers need to
    // be handled explicitly.
    Infinite(Negative), Finite(f) ->
      case int.to_float(float.round(f)) == f && int.is_odd(float.truncate(f)) {
        True ->
          case f <. 0.0 {
            True -> Finite(-0.0)
            False -> Infinite(Negative)
          }

        False ->
          case f <. 0.0 {
            True -> Finite(0.0)
            False -> Infinite(Positive)
          }
      }
  }
}

/// Generates a random `IEEEFloat` between zero (inclusive) and one (exclusive).
///
/// On the Erlang target this updates the random state in the process
/// dictionary. See <https://www.erlang.org/doc/man/rand.html#uniform-0>.
///
@external(javascript, "./ieee_float_js.mjs", "random")
pub fn random() -> IEEEFloat {
  Finite(float.random())
}

/// Rounds an `IEEEFloat` to the nearest whole number as an `Int`. If the input
/// value is not finite then `Error(Nil)` is returned.
///
@external(javascript, "./ieee_float_js.mjs", "round")
pub fn round(f: IEEEFloat) -> Result(Int, Nil) {
  case f {
    Finite(f) -> f |> float.round |> Ok
    _ -> Error(Nil)
  }
}

/// Subtracts one `IEEEFloat` from another.
///
@external(javascript, "./ieee_float_js.mjs", "subtract")
pub fn subtract(a: IEEEFloat, b: IEEEFloat) -> IEEEFloat {
  add(a, negate(b))
}
