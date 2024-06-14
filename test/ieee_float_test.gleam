import gleam/bit_array
import gleam/list
import gleam/order
import ieee_float.{
  type IEEEFloat, finite, nan, negative_infinity, positive_infinity,
}
import startest
import startest/config.{Config}
import startest/expect
import startest/reporters/dot

pub fn main() {
  startest.run(Config(..startest.default_config(), reporters: [dot.new()]))
}

pub fn finite_test() {
  finite(1.0)
  |> ieee_float.is_finite
  |> expect.to_be_true
}

pub fn positive_infinity_test() {
  positive_infinity()
  |> ieee_float.is_finite
  |> expect.to_be_false

  positive_infinity()
  |> ieee_float.compare(finite(0.0))
  |> expect.to_equal(Ok(order.Gt))
}

pub fn negative_infinity_test() {
  negative_infinity()
  |> ieee_float.is_finite
  |> expect.to_be_false

  negative_infinity()
  |> ieee_float.compare(finite(0.0))
  |> expect.to_equal(Ok(order.Lt))
}

pub fn nan_test() {
  nan()
  |> ieee_float.is_nan
  |> expect.to_be_true
}

pub fn to_finite_test() {
  finite(1.0)
  |> ieee_float.to_finite
  |> expect.to_equal(Ok(1.0))

  positive_infinity()
  |> ieee_float.to_finite
  |> expect.to_equal(Error(Nil))

  negative_infinity()
  |> ieee_float.to_finite
  |> expect.to_equal(Error(Nil))

  nan()
  |> ieee_float.to_finite
  |> expect.to_equal(Error(Nil))
}

pub fn to_string_test() {
  finite(123.0)
  |> ieee_float.to_string
  |> expect.to_equal("123.0")

  finite(-8.1)
  |> ieee_float.to_string
  |> expect.to_equal("-8.1")

  positive_infinity()
  |> ieee_float.to_string
  |> expect.to_equal("Infinity")

  negative_infinity()
  |> ieee_float.to_string
  |> expect.to_equal("-Infinity")

  nan()
  |> ieee_float.to_string
  |> expect.to_equal("NaN")
}

pub fn parse_test() {
  "1.23"
  |> ieee_float.parse
  |> expect.to_equal(finite(1.23))

  "+1.23"
  |> ieee_float.parse
  |> expect.to_equal(finite(1.23))

  "-1.23"
  |> ieee_float.parse
  |> expect.to_equal(finite(-1.23))

  "5.0"
  |> ieee_float.parse
  |> expect.to_equal(finite(5.0))

  "0.123456789"
  |> ieee_float.parse
  |> expect.to_equal(finite(0.123456789))

  "Infinity"
  |> ieee_float.parse
  |> expect.to_equal(positive_infinity())

  "-Infinity"
  |> ieee_float.parse
  |> expect.to_equal(negative_infinity())

  ["", "NaN", "test", "1"]
  |> list.each(fn(s) {
    s
    |> ieee_float.parse
    |> ieee_float.is_nan
    |> expect.to_be_true
  })
}

pub fn fp32_bytes_serde_test() {
  [
    #([0x00, 0x00, 0x00, 0x00], finite(0.0)),
    #([0x3F, 0x80, 0x00, 0x00], finite(1.0)),
    #([0xBF, 0x80, 0x00, 0x00], finite(-1.0)),
    #([0x49, 0x74, 0x24, 0x00], finite(1_000_000.0)),
    #([0xC9, 0x74, 0x24, 0x00], finite(-1_000_000.0)),
    #([0x00, 0x10, 0x00, 0x00], finite(1.4693679385278594e-39)),
    #([0x7F, 0x80, 0x00, 0x00], positive_infinity()),
    #([0xFF, 0x80, 0x00, 0x00], negative_infinity()),
    #([0x7F, 0xC0, 0x00, 0x00], nan()),
  ]
  |> list.each(fn(x) {
    let #(bytes, expected_value) = x

    bytes
    |> text_ieee_bytes_serde(
      expected_value,
      ieee_float.from_bytes_32_be,
      ieee_float.to_bytes_32_be,
    )

    bytes
    |> list.reverse
    |> text_ieee_bytes_serde(
      expected_value,
      ieee_float.from_bytes_32_le,
      ieee_float.to_bytes_32_le,
    )
  })
}

pub fn fp64_bytes_serde_test() {
  [
    #([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], finite(0.0)),
    #([0x3F, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], finite(1.0)),
    #([0xBF, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], finite(-1.0)),
    #([0x41, 0x2E, 0x84, 0x80, 0x00, 0x00, 0x00, 0x00], finite(1_000_000.0)),
    #([0xC1, 0x2E, 0x84, 0x80, 0x00, 0x00, 0x00, 0x00], finite(-1_000_000.0)),
    #(
      [0x7F, 0xEF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
      finite(1.7976931348623157e308),
    ),
    #([0x7F, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], positive_infinity()),
    #([0xFF, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], negative_infinity()),
    #([0x7F, 0xF8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], nan()),
  ]
  |> list.each(fn(x) {
    let #(bytes, expected_value) = x

    bytes
    |> text_ieee_bytes_serde(
      expected_value,
      ieee_float.from_bytes_64_be,
      ieee_float.to_bytes_64_be,
    )

    bytes
    |> list.reverse
    |> text_ieee_bytes_serde(
      expected_value,
      ieee_float.from_bytes_64_le,
      ieee_float.to_bytes_64_le,
    )
  })
}

fn text_ieee_bytes_serde(
  bytes: List(Int),
  expected_value: IEEEFloat,
  from_bytes: fn(BitArray) -> IEEEFloat,
  to_bytes: fn(IEEEFloat) -> BitArray,
) {
  let bits =
    bytes
    |> list.map(fn(x) { <<x>> })
    |> bit_array.concat

  let f = from_bytes(bits)

  case ieee_float.is_nan(expected_value) {
    True -> ieee_float.is_nan(f) |> expect.to_be_true
    False -> f |> expect.to_equal(expected_value)
  }

  expected_value
  |> to_bytes
  |> expect.to_equal(bits)

  Nil
}

pub fn absolute_value_test() {
  ieee_float.absolute_value(finite(-1.0))
  |> expect.to_equal(finite(1.0))

  ieee_float.absolute_value(finite(-20.6))
  |> expect.to_equal(finite(20.6))

  ieee_float.absolute_value(finite(0.0))
  |> expect.to_equal(finite(0.0))

  ieee_float.absolute_value(finite(1.0))
  |> expect.to_equal(finite(1.0))

  ieee_float.absolute_value(finite(25.2))
  |> expect.to_equal(finite(25.2))

  ieee_float.absolute_value(positive_infinity())
  |> expect.to_equal(positive_infinity())

  ieee_float.absolute_value(negative_infinity())
  |> expect.to_equal(positive_infinity())

  ieee_float.absolute_value(nan())
  |> ieee_float.is_nan
  |> expect.to_be_true
}

pub fn add_test() {
  finite(3.0)
  |> ieee_float.add(finite(2.0))
  |> expect.to_equal(finite(5.0))

  finite(1.7976931348623157e308)
  |> ieee_float.add(finite(1.7976931348623157e308))
  |> expect.to_equal(positive_infinity())

  finite(-1.7976931348623157e308)
  |> ieee_float.add(finite(1.7976931348623157e308))
  |> expect.to_equal(finite(0.0))

  finite(1.0)
  |> ieee_float.add(nan())
  |> ieee_float.is_nan
  |> expect.to_be_true

  finite(1.79e308)
  |> ieee_float.add(finite(1.79e308))
  |> expect.to_equal(positive_infinity())

  finite(-1.79e308)
  |> ieee_float.add(finite(-1.79e308))
  |> expect.to_equal(negative_infinity())

  nan()
  |> ieee_float.add(finite(1.0))
  |> ieee_float.is_nan
  |> expect.to_be_true

  positive_infinity()
  |> ieee_float.add(finite(-100.0))
  |> expect.to_equal(positive_infinity())

  negative_infinity()
  |> ieee_float.add(finite(100.0))
  |> expect.to_equal(negative_infinity())

  positive_infinity()
  |> ieee_float.add(positive_infinity())
  |> expect.to_equal(positive_infinity())

  negative_infinity()
  |> ieee_float.add(negative_infinity())
  |> expect.to_equal(negative_infinity())

  positive_infinity()
  |> ieee_float.add(negative_infinity())
  |> ieee_float.is_nan
  |> expect.to_be_true

  negative_infinity()
  |> ieee_float.add(positive_infinity())
  |> ieee_float.is_nan
  |> expect.to_be_true
}

pub fn ceiling_test() {
  finite(8.1)
  |> ieee_float.ceiling
  |> expect.to_equal(finite(9.0))

  finite(-8.1)
  |> ieee_float.ceiling
  |> expect.to_equal(finite(-8.0))

  finite(-8.0)
  |> ieee_float.ceiling
  |> expect.to_equal(finite(-8.0))

  nan()
  |> ieee_float.ceiling
  |> ieee_float.is_nan
  |> expect.to_be_true

  positive_infinity()
  |> ieee_float.ceiling
  |> expect.to_equal(positive_infinity())

  negative_infinity()
  |> ieee_float.ceiling
  |> expect.to_equal(negative_infinity())
}

pub fn clamp_test() {
  ieee_float.clamp(finite(1.4), min: finite(1.3), max: finite(1.5))
  |> expect.to_equal(finite(1.4))

  ieee_float.clamp(finite(1.2), min: finite(1.3), max: finite(1.5))
  |> expect.to_equal(finite(1.3))

  ieee_float.clamp(finite(1.6), min: finite(1.3), max: finite(1.5))
  |> expect.to_equal(finite(1.5))

  ieee_float.clamp(
    finite(1.6),
    min: positive_infinity(),
    max: positive_infinity(),
  )
  |> expect.to_equal(positive_infinity())

  ieee_float.clamp(
    finite(1.6),
    min: negative_infinity(),
    max: negative_infinity(),
  )
  |> expect.to_equal(negative_infinity())

  ieee_float.clamp(nan(), min: finite(0.0), max: finite(0.0))
  |> ieee_float.is_nan
  |> expect.to_be_true

  ieee_float.clamp(finite(0.0), min: nan(), max: finite(100.0))
  |> ieee_float.is_nan
  |> expect.to_be_true
}

pub fn compare_test() {
  ieee_float.compare(finite(1.0), finite(1.0))
  |> expect.to_equal(Ok(order.Eq))

  ieee_float.compare(finite(1.0), finite(2.0))
  |> expect.to_equal(Ok(order.Lt))

  ieee_float.compare(finite(2.0), finite(1.0))
  |> expect.to_equal(Ok(order.Gt))

  ieee_float.compare(finite(0.0), positive_infinity())
  |> expect.to_equal(Ok(order.Lt))

  ieee_float.compare(positive_infinity(), finite(0.0))
  |> expect.to_equal(Ok(order.Gt))

  ieee_float.compare(finite(0.0), negative_infinity())
  |> expect.to_equal(Ok(order.Gt))

  ieee_float.compare(negative_infinity(), finite(0.0))
  |> expect.to_equal(Ok(order.Lt))

  ieee_float.compare(negative_infinity(), negative_infinity())
  |> expect.to_equal(Ok(order.Eq))

  ieee_float.compare(negative_infinity(), positive_infinity())
  |> expect.to_equal(Ok(order.Lt))

  ieee_float.compare(positive_infinity(), negative_infinity())
  |> expect.to_equal(Ok(order.Gt))

  ieee_float.compare(positive_infinity(), positive_infinity())
  |> expect.to_equal(Ok(order.Eq))

  ieee_float.compare(finite(0.0), nan())
  |> expect.to_equal(Error(Nil))

  ieee_float.compare(nan(), finite(0.0))
  |> expect.to_equal(Error(Nil))
}

pub fn divide_test() {
  finite(6.0)
  |> ieee_float.divide(finite(3.0))
  |> expect.to_equal(finite(2.0))

  finite(0.0)
  |> ieee_float.divide(finite(0.0))
  |> ieee_float.is_nan
  |> expect.to_be_true

  finite(0.0)
  |> ieee_float.divide(finite(-0.0))
  |> ieee_float.is_nan
  |> expect.to_be_true

  finite(-0.0)
  |> ieee_float.divide(finite(0.0))
  |> ieee_float.is_nan
  |> expect.to_be_true

  finite(-0.0)
  |> ieee_float.divide(finite(-0.0))
  |> ieee_float.is_nan
  |> expect.to_be_true

  finite(100.0)
  |> ieee_float.divide(finite(0.0))
  |> expect.to_equal(positive_infinity())

  finite(100.0)
  |> ieee_float.divide(finite(-0.0))
  |> expect.to_equal(negative_infinity())

  finite(-100.0)
  |> ieee_float.divide(finite(0.0))
  |> expect.to_equal(negative_infinity())

  finite(-100.0)
  |> ieee_float.divide(finite(-0.0))
  |> expect.to_equal(positive_infinity())

  finite(10.0)
  |> ieee_float.divide(finite(1.7e-308))
  |> expect.to_equal(positive_infinity())

  finite(10.0)
  |> ieee_float.divide(finite(-1.7e-308))
  |> expect.to_equal(negative_infinity())

  finite(-10.0)
  |> ieee_float.divide(finite(1.7e-308))
  |> expect.to_equal(negative_infinity())

  finite(-10.0)
  |> ieee_float.divide(finite(-1.7e-308))
  |> expect.to_equal(positive_infinity())

  finite(100.0)
  |> ieee_float.divide(positive_infinity())
  |> expect.to_equal(finite(0.0))

  finite(100.0)
  |> ieee_float.divide(negative_infinity())
  |> expect.to_equal(finite(-0.0))

  finite(-100.0)
  |> ieee_float.divide(positive_infinity())
  |> expect.to_equal(finite(-0.0))

  finite(-100.0)
  |> ieee_float.divide(negative_infinity())
  |> expect.to_equal(finite(0.0))

  positive_infinity()
  |> ieee_float.divide(finite(100.0))
  |> expect.to_equal(positive_infinity())

  positive_infinity()
  |> ieee_float.divide(finite(-100.0))
  |> expect.to_equal(negative_infinity())

  negative_infinity()
  |> ieee_float.divide(finite(100.0))
  |> expect.to_equal(negative_infinity())

  negative_infinity()
  |> ieee_float.divide(finite(-100.0))
  |> expect.to_equal(positive_infinity())

  positive_infinity()
  |> ieee_float.divide(positive_infinity())
  |> ieee_float.is_nan
  |> expect.to_be_true

  positive_infinity()
  |> ieee_float.divide(negative_infinity())
  |> ieee_float.is_nan
  |> expect.to_be_true

  negative_infinity()
  |> ieee_float.divide(positive_infinity())
  |> ieee_float.is_nan
  |> expect.to_be_true

  negative_infinity()
  |> ieee_float.divide(negative_infinity())
  |> ieee_float.is_nan
  |> expect.to_be_true
}

pub fn floor_test() {
  finite(8.1)
  |> ieee_float.floor
  |> expect.to_equal(finite(8.0))

  finite(-8.1)
  |> ieee_float.floor
  |> expect.to_equal(finite(-9.0))

  finite(-8.0)
  |> ieee_float.floor
  |> expect.to_equal(finite(-8.0))

  positive_infinity()
  |> ieee_float.floor
  |> expect.to_equal(positive_infinity())

  negative_infinity()
  |> ieee_float.floor
  |> expect.to_equal(negative_infinity())

  nan()
  |> ieee_float.floor
  |> ieee_float.is_nan
  |> expect.to_be_true
}

pub fn max_test() {
  finite(2.0)
  |> ieee_float.max(finite(5.0))
  |> expect.to_equal(finite(5.0))

  finite(2.0)
  |> ieee_float.max(positive_infinity())
  |> expect.to_equal(positive_infinity())

  finite(100.0)
  |> ieee_float.max(negative_infinity())
  |> expect.to_equal(finite(100.0))

  nan()
  |> ieee_float.max(finite(100.0))
  |> ieee_float.is_nan
  |> expect.to_be_true
}

pub fn min_test() {
  finite(2.0)
  |> ieee_float.min(finite(5.0))
  |> expect.to_equal(finite(2.0))

  finite(2.0)
  |> ieee_float.min(positive_infinity())
  |> expect.to_equal(finite(2.0))

  finite(100.0)
  |> ieee_float.min(negative_infinity())
  |> expect.to_equal(negative_infinity())

  nan()
  |> ieee_float.min(finite(100.0))
  |> ieee_float.is_nan
  |> expect.to_be_true
}

pub fn multiply_test() {
  finite(2.0)
  |> ieee_float.multiply(finite(3.0))
  |> expect.to_equal(finite(6.0))

  finite(1.4e308)
  |> ieee_float.multiply(finite(1.4e308))
  |> expect.to_equal(positive_infinity())

  finite(-1.4e308)
  |> ieee_float.multiply(finite(1.4e308))
  |> expect.to_equal(negative_infinity())

  finite(-1.4e308)
  |> ieee_float.multiply(finite(-1.4e308))
  |> expect.to_equal(positive_infinity())

  finite(2.0)
  |> ieee_float.multiply(positive_infinity())
  |> expect.to_equal(positive_infinity())

  finite(-2.0)
  |> ieee_float.multiply(positive_infinity())
  |> expect.to_equal(negative_infinity())

  finite(2.0)
  |> ieee_float.multiply(negative_infinity())
  |> expect.to_equal(negative_infinity())

  finite(-2.0)
  |> ieee_float.multiply(positive_infinity())
  |> expect.to_equal(negative_infinity())

  positive_infinity()
  |> ieee_float.multiply(positive_infinity())
  |> expect.to_equal(positive_infinity())

  negative_infinity()
  |> ieee_float.multiply(negative_infinity())
  |> expect.to_equal(positive_infinity())

  positive_infinity()
  |> ieee_float.multiply(negative_infinity())
  |> expect.to_equal(negative_infinity())
}

pub fn negate_test() {
  ieee_float.negate(finite(-1.0))
  |> expect.to_equal(finite(1.0))

  ieee_float.negate(finite(2.0))
  |> expect.to_equal(finite(-2.0))

  ieee_float.negate(finite(0.0))
  |> ieee_float.negate
  |> expect.to_equal(finite(0.0))

  positive_infinity()
  |> ieee_float.negate
  |> expect.to_equal(negative_infinity())

  negative_infinity()
  |> ieee_float.negate
  |> expect.to_equal(positive_infinity())

  nan()
  |> ieee_float.negate
  |> ieee_float.is_nan
  |> expect.to_be_true
}

pub fn random_test() {
  let i = ieee_float.random()

  i
  |> ieee_float.compare(finite(1.0))
  |> expect.to_equal(Ok(order.Lt))

  i
  |> ieee_float.add(finite(2.23e-308))
  |> ieee_float.compare(finite(0.0))
  |> expect.to_equal(Ok(order.Gt))
}

pub fn round_test() {
  finite(8.1)
  |> ieee_float.round
  |> expect.to_equal(Ok(8))

  finite(8.4)
  |> ieee_float.round
  |> expect.to_equal(Ok(8))

  finite(8.499)
  |> ieee_float.round
  |> expect.to_equal(Ok(8))

  finite(8.5)
  |> ieee_float.round
  |> expect.to_equal(Ok(9))

  finite(-8.1)
  |> ieee_float.round
  |> expect.to_equal(Ok(-8))

  finite(-7.5)
  |> ieee_float.round
  |> expect.to_equal(Ok(-8))

  [positive_infinity(), negative_infinity(), nan()]
  |> list.each(fn(f) {
    f
    |> ieee_float.round
    |> expect.to_equal(Error(Nil))
  })
}

pub fn subtract_test() {
  finite(3.0)
  |> ieee_float.subtract(finite(2.0))
  |> expect.to_equal(finite(1.0))

  finite(-1.7976931348623157e308)
  |> ieee_float.subtract(finite(1.7976931348623157e308))
  |> expect.to_equal(negative_infinity())

  finite(1.7976931348623157e308)
  |> ieee_float.subtract(finite(1.7976931348623157e308))
  |> expect.to_equal(finite(0.0))

  finite(1.0)
  |> ieee_float.subtract(nan())
  |> ieee_float.is_nan
  |> expect.to_be_true

  finite(-1.79e308)
  |> ieee_float.subtract(finite(1.79e308))
  |> expect.to_equal(negative_infinity())

  finite(1.79e308)
  |> ieee_float.subtract(finite(-1.79e308))
  |> expect.to_equal(positive_infinity())

  nan()
  |> ieee_float.subtract(finite(1.0))
  |> ieee_float.is_nan
  |> expect.to_be_true

  positive_infinity()
  |> ieee_float.subtract(finite(-100.0))
  |> expect.to_equal(positive_infinity())

  negative_infinity()
  |> ieee_float.subtract(finite(100.0))
  |> expect.to_equal(negative_infinity())

  positive_infinity()
  |> ieee_float.subtract(negative_infinity())
  |> expect.to_equal(positive_infinity())

  negative_infinity()
  |> ieee_float.subtract(positive_infinity())
  |> expect.to_equal(negative_infinity())

  positive_infinity()
  |> ieee_float.subtract(positive_infinity())
  |> ieee_float.is_nan
  |> expect.to_be_true

  negative_infinity()
  |> ieee_float.subtract(negative_infinity())
  |> ieee_float.is_nan
  |> expect.to_be_true
}
