import gleam/bit_array
import gleam/list
import gleam/order
import gleeunit
import gleeunit/should
import ieee_float.{
  type IEEEFloat, finite, nan, negative_infinity, positive_infinity,
}

pub fn main() {
  gleeunit.main()
}

pub fn finite_test() {
  finite(1.0)
  |> ieee_float.is_finite
  |> should.be_true
}

pub fn positive_infinity_test() {
  positive_infinity()
  |> ieee_float.is_finite
  |> should.be_false

  positive_infinity()
  |> ieee_float.compare(finite(0.0))
  |> should.equal(Ok(order.Gt))
}

pub fn negative_infinity_test() {
  negative_infinity()
  |> ieee_float.is_finite
  |> should.be_false

  negative_infinity()
  |> ieee_float.compare(finite(0.0))
  |> should.equal(Ok(order.Lt))
}

pub fn nan_test() {
  nan()
  |> ieee_float.is_nan
  |> should.be_true
}

pub fn to_finite_test() {
  finite(1.0)
  |> ieee_float.to_finite
  |> should.equal(Ok(1.0))

  positive_infinity()
  |> ieee_float.to_finite
  |> should.equal(Error(Nil))

  negative_infinity()
  |> ieee_float.to_finite
  |> should.equal(Error(Nil))

  nan()
  |> ieee_float.to_finite
  |> should.equal(Error(Nil))
}

pub fn to_string_test() {
  finite(123.0)
  |> ieee_float.to_string
  |> should.equal("123.0")

  finite(-8.1)
  |> ieee_float.to_string
  |> should.equal("-8.1")

  positive_infinity()
  |> ieee_float.to_string
  |> should.equal("Infinity")

  negative_infinity()
  |> ieee_float.to_string
  |> should.equal("-Infinity")

  nan()
  |> ieee_float.to_string
  |> should.equal("NaN")
}

pub fn parse_test() {
  let test_parse = build_test_function1(ieee_float.parse)

  test_parse("1.23", finite(1.23))
  test_parse("+1.23", finite(1.23))
  test_parse("-1.23", finite(-1.23))
  test_parse("5.0", finite(5.0))
  test_parse("0.123456789", finite(0.123456789))
  test_parse("Infinity", positive_infinity())
  test_parse("-Infinity", negative_infinity())
  test_parse("", nan())
  test_parse("NaN", nan())
  test_parse("test", nan())
  test_parse("1", nan())
}

pub fn fp16_bytes_serde_test() {
  [
    #([0x00, 0x00], finite(0.0)),
    #([0x3C, 0x00], finite(1.0)),
    #([0xBC, 0x00], finite(-1.0)),
    #([0x3C, 0xF0], finite(1.234375)),
    #([0xFB, 0xFF], finite(-65_504.0)),
    #([0x80, 0xFF], finite(-0.00001519918441772461)),
    #([0x7C, 0x00], positive_infinity()),
    #([0xFC, 0x00], negative_infinity()),
    #([0x7E, 0x00], nan()),
  ]
  |> test_ieee_bytes_serde(
    ieee_float.from_bytes_16_be,
    ieee_float.to_bytes_16_be,
    ieee_float.from_bytes_16_le,
    ieee_float.to_bytes_16_le,
  )

  // Check overly large values round to infinity
  finite(1_000_000.0)
  |> ieee_float.to_bytes_16_be
  |> should.equal(<<0x7C, 0x00>>)

  finite(-1_000_000.0)
  |> ieee_float.to_bytes_16_be
  |> should.equal(<<0xFC, 0x00>>)
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
  |> test_ieee_bytes_serde(
    ieee_float.from_bytes_32_be,
    ieee_float.to_bytes_32_be,
    ieee_float.from_bytes_32_le,
    ieee_float.to_bytes_32_le,
  )

  // Check overly large values round to infinity
  finite(1.7e308)
  |> ieee_float.to_bytes_32_be
  |> should.equal(<<0x7F, 0x80, 0x00, 0x00>>)

  finite(-1.7e308)
  |> ieee_float.to_bytes_32_be
  |> should.equal(<<0xFF, 0x80, 0x00, 0x00>>)
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
  |> test_ieee_bytes_serde(
    ieee_float.from_bytes_64_be,
    ieee_float.to_bytes_64_be,
    ieee_float.from_bytes_64_le,
    ieee_float.to_bytes_64_le,
  )
}

fn test_ieee_bytes_serde(
  cases: List(#(List(Int), IEEEFloat)),
  from_bytes_be: fn(BitArray) -> IEEEFloat,
  to_bytes_be: fn(IEEEFloat) -> BitArray,
  from_bytes_le: fn(BitArray) -> IEEEFloat,
  to_bytes_le: fn(IEEEFloat) -> BitArray,
) {
  let test_serde = fn(bytes, expected_value, from_bytes, to_bytes) {
    let bytes =
      bytes
      |> list.map(fn(x) { <<x>> })
      |> bit_array.concat

    let f = from_bytes(bytes)

    case ieee_float.is_nan(expected_value) {
      True -> ieee_float.is_nan(f) |> should.be_true
      False -> f |> should.equal(expected_value)
    }

    expected_value
    |> to_bytes
    |> should.equal(bytes)
  }

  list.each(cases, fn(x) {
    let #(bytes, expected_value) = x

    bytes
    |> test_serde(expected_value, from_bytes_be, to_bytes_be)

    bytes
    |> list.reverse
    |> test_serde(expected_value, from_bytes_le, to_bytes_le)
  })

  <<0>>
  |> from_bytes_be
  |> ieee_float.is_nan
  |> should.be_true

  <<0>>
  |> from_bytes_le
  |> ieee_float.is_nan
  |> should.be_true

  Nil
}

pub fn absolute_value_test() {
  let test_absolute_value = build_test_function1(ieee_float.absolute_value)

  test_absolute_value(finite(-1.0), finite(1.0))
  test_absolute_value(finite(-20.6), finite(20.6))
  test_absolute_value(finite(0.0), finite(0.0))
  test_absolute_value(finite(1.0), finite(1.0))
  test_absolute_value(finite(25.2), finite(25.2))
  test_absolute_value(positive_infinity(), positive_infinity())
  test_absolute_value(negative_infinity(), positive_infinity())
  test_absolute_value(nan(), nan())
}

pub fn add_test() {
  let test_add = build_test_function2(ieee_float.add)

  test_add(finite(3.0), finite(2.0), finite(5.0))
  test_add(finite(1.79769313e308), finite(1.79769313e308), positive_infinity())
  test_add(finite(-1.797693134862e308), finite(1.797693134862e308), finite(0.0))
  test_add(finite(1.0), nan(), nan())
  test_add(finite(1.79e308), finite(1.79e308), positive_infinity())
  test_add(finite(-1.79e308), finite(-1.79e308), negative_infinity())
  test_add(nan(), finite(1.0), nan())
  test_add(positive_infinity(), finite(-100.0), positive_infinity())
  test_add(negative_infinity(), finite(100.0), negative_infinity())
  test_add(positive_infinity(), positive_infinity(), positive_infinity())
  test_add(negative_infinity(), negative_infinity(), negative_infinity())
  test_add(positive_infinity(), negative_infinity(), nan())
  test_add(negative_infinity(), positive_infinity(), nan())
}

pub fn ceiling_test() {
  let test_ceiling = build_test_function1(ieee_float.ceiling)

  test_ceiling(finite(8.1), finite(9.0))
  test_ceiling(finite(-8.1), finite(-8.0))
  test_ceiling(finite(-8.0), finite(-8.0))
  test_ceiling(nan(), nan())
  test_ceiling(positive_infinity(), positive_infinity())
  test_ceiling(negative_infinity(), negative_infinity())
}

pub fn clamp_test() {
  let test_clamp = build_test_function3(ieee_float.clamp)

  test_clamp(finite(1.4), finite(1.3), finite(1.5), finite(1.4))
  test_clamp(finite(1.2), finite(1.3), finite(1.5), finite(1.3))
  test_clamp(finite(1.6), finite(1.3), finite(1.5), finite(1.5))
  test_clamp(
    finite(1.6),
    positive_infinity(),
    positive_infinity(),
    positive_infinity(),
  )
  test_clamp(
    finite(1.6),
    negative_infinity(),
    negative_infinity(),
    negative_infinity(),
  )
  test_clamp(nan(), finite(0.0), finite(0.0), nan())
  test_clamp(finite(0.0), nan(), finite(100.0), nan())
}

pub fn compare_test() {
  ieee_float.compare(finite(1.0), finite(1.0))
  |> should.equal(Ok(order.Eq))

  ieee_float.compare(finite(1.0), finite(2.0))
  |> should.equal(Ok(order.Lt))

  ieee_float.compare(finite(2.0), finite(1.0))
  |> should.equal(Ok(order.Gt))

  ieee_float.compare(finite(0.0), positive_infinity())
  |> should.equal(Ok(order.Lt))

  ieee_float.compare(positive_infinity(), finite(0.0))
  |> should.equal(Ok(order.Gt))

  ieee_float.compare(finite(0.0), negative_infinity())
  |> should.equal(Ok(order.Gt))

  ieee_float.compare(negative_infinity(), finite(0.0))
  |> should.equal(Ok(order.Lt))

  ieee_float.compare(negative_infinity(), negative_infinity())
  |> should.equal(Ok(order.Eq))

  ieee_float.compare(negative_infinity(), positive_infinity())
  |> should.equal(Ok(order.Lt))

  ieee_float.compare(positive_infinity(), negative_infinity())
  |> should.equal(Ok(order.Gt))

  ieee_float.compare(positive_infinity(), positive_infinity())
  |> should.equal(Ok(order.Eq))

  ieee_float.compare(finite(0.0), nan())
  |> should.equal(Error(Nil))

  ieee_float.compare(nan(), finite(0.0))
  |> should.equal(Error(Nil))
}

pub fn divide_test() {
  let test_divide = build_test_function2(ieee_float.divide)

  test_divide(finite(6.0), finite(3.0), finite(2.0))
  test_divide(finite(0.0), finite(0.0), nan())
  test_divide(finite(0.0), finite(-0.0), nan())
  test_divide(finite(-0.0), finite(0.0), nan())
  test_divide(finite(-0.0), finite(-0.0), nan())
  test_divide(finite(100.0), finite(0.0), positive_infinity())
  test_divide(finite(100.0), finite(-0.0), negative_infinity())
  test_divide(finite(-100.0), finite(0.0), negative_infinity())
  test_divide(finite(-100.0), finite(-0.0), positive_infinity())
  test_divide(finite(10.0), finite(1.7e-308), positive_infinity())
  test_divide(finite(10.0), finite(-1.7e-308), negative_infinity())
  test_divide(finite(-10.0), finite(1.7e-308), negative_infinity())
  test_divide(finite(-10.0), finite(-1.7e-308), positive_infinity())
  test_divide(finite(100.0), positive_infinity(), finite(0.0))
  test_divide(finite(100.0), negative_infinity(), finite(-0.0))
  test_divide(finite(-100.0), positive_infinity(), finite(-0.0))
  test_divide(finite(-100.0), negative_infinity(), finite(0.0))
  test_divide(positive_infinity(), finite(100.0), positive_infinity())
  test_divide(positive_infinity(), finite(-100.0), negative_infinity())
  test_divide(negative_infinity(), finite(100.0), negative_infinity())
  test_divide(negative_infinity(), finite(-100.0), positive_infinity())
  test_divide(positive_infinity(), positive_infinity(), nan())
  test_divide(positive_infinity(), negative_infinity(), nan())
  test_divide(negative_infinity(), positive_infinity(), nan())
  test_divide(negative_infinity(), negative_infinity(), nan())
}

pub fn floor_test() {
  let test_floor = build_test_function1(ieee_float.floor)

  test_floor(finite(8.1), finite(8.0))
  test_floor(finite(-8.1), finite(-9.0))
  test_floor(finite(-8.0), finite(-8.0))
  test_floor(positive_infinity(), positive_infinity())
  test_floor(negative_infinity(), negative_infinity())
  test_floor(nan(), nan())
}

pub fn max_test() {
  let test_max = build_test_function2(ieee_float.max)

  test_max(finite(2.0), finite(5.0), finite(5.0))
  test_max(finite(2.0), positive_infinity(), positive_infinity())
  test_max(finite(100.0), negative_infinity(), finite(100.0))
  test_max(nan(), finite(100.0), nan())
  test_max(finite(100.0), nan(), nan())
  test_max(nan(), nan(), nan())
}

pub fn min_test() {
  let test_min = build_test_function2(ieee_float.min)

  test_min(finite(2.0), finite(5.0), finite(2.0))
  test_min(finite(2.0), positive_infinity(), finite(2.0))
  test_min(finite(100.0), negative_infinity(), negative_infinity())
  test_min(finite(100.0), nan(), nan())
  test_min(nan(), finite(100.0), nan())
  test_min(nan(), nan(), nan())
}

pub fn multiply_test() {
  let test_multiply = build_test_function2(ieee_float.multiply)

  test_multiply(finite(2.0), finite(3.0), finite(6.0))
  test_multiply(finite(1.4e308), finite(1.4e308), positive_infinity())
  test_multiply(finite(-1.4e308), finite(1.4e308), negative_infinity())
  test_multiply(finite(-1.4e308), finite(-1.4e308), positive_infinity())
  test_multiply(finite(2.0), positive_infinity(), positive_infinity())
  test_multiply(finite(-2.0), positive_infinity(), negative_infinity())
  test_multiply(finite(2.0), negative_infinity(), negative_infinity())
  test_multiply(finite(-2.0), positive_infinity(), negative_infinity())
  test_multiply(positive_infinity(), positive_infinity(), positive_infinity())
  test_multiply(negative_infinity(), negative_infinity(), positive_infinity())
  test_multiply(positive_infinity(), negative_infinity(), negative_infinity())
}

pub fn negate_test() {
  let test_negate = build_test_function1(ieee_float.negate)

  test_negate(finite(-1.0), finite(1.0))
  test_negate(finite(2.0), finite(-2.0))
  test_negate(finite(0.0), finite(-0.0))
  test_negate(finite(-0.0), finite(0.0))
  test_negate(positive_infinity(), negative_infinity())
  test_negate(negative_infinity(), positive_infinity())
  test_negate(nan(), nan())
}

pub fn power_test() {
  let test_power = build_test_function2(ieee_float.power)

  // Finite values
  test_power(finite(6.0), finite(3.0), finite(216.0))
  test_power(finite(0.0), finite(0.0), finite(1.0))
  test_power(finite(100.0), finite(0.0), finite(1.0))
  test_power(finite(-100.0), finite(0.0), finite(1.0))
  test_power(finite(100.0), finite(-1.0), finite(0.01))
  test_power(finite(-100.0), finite(1.5), nan())
  test_power(finite(1.7e308), finite(10.0), positive_infinity())

  // Infinities to the power of zero
  test_power(positive_infinity(), finite(0.0), finite(1.0))
  test_power(positive_infinity(), finite(-0.0), finite(1.0))
  test_power(negative_infinity(), finite(0.0), finite(1.0))
  test_power(negative_infinity(), finite(-0.0), finite(1.0))

  // Two infinites
  test_power(positive_infinity(), positive_infinity(), positive_infinity())
  test_power(positive_infinity(), negative_infinity(), finite(0.0))
  test_power(negative_infinity(), positive_infinity(), positive_infinity())
  test_power(negative_infinity(), negative_infinity(), finite(0.0))

  // One input is positive infinity
  test_power(finite(100.0), positive_infinity(), positive_infinity())
  test_power(finite(-100.0), positive_infinity(), positive_infinity())
  test_power(finite(0.0), positive_infinity(), finite(0.0))
  test_power(finite(-0.0), positive_infinity(), finite(0.0))
  test_power(finite(-1.0), positive_infinity(), nan())
  test_power(finite(1.0), positive_infinity(), nan())
  test_power(finite(-1.0), positive_infinity(), nan())
  test_power(positive_infinity(), finite(0.1), positive_infinity())
  test_power(positive_infinity(), finite(-1.0), finite(0.0))
  test_power(positive_infinity(), finite(-2.0), finite(0.0))

  // One input is negative infinity
  test_power(finite(100.0), negative_infinity(), finite(0.0))
  test_power(finite(-100.0), negative_infinity(), finite(0.0))
  test_power(finite(0.0), negative_infinity(), positive_infinity())
  test_power(finite(-0.0), negative_infinity(), positive_infinity())
  test_power(finite(1.0), negative_infinity(), nan())
  test_power(finite(-1.0), negative_infinity(), nan())
  test_power(finite(0.5), negative_infinity(), positive_infinity())
  test_power(finite(-0.5), negative_infinity(), positive_infinity())
  test_power(finite(1.5), negative_infinity(), finite(0.0))
  test_power(finite(-1.5), negative_infinity(), finite(0.0))
  test_power(negative_infinity(), finite(2.0), positive_infinity())
  test_power(negative_infinity(), finite(3.0), negative_infinity())
  test_power(negative_infinity(), finite(-2.0), finite(0.0))
  test_power(negative_infinity(), finite(-3.0), finite(-0.0))

  // NaN
  test_power(nan(), finite(10.0), nan())
  test_power(finite(10.0), nan(), nan())
  test_power(nan(), nan(), nan())
}

pub fn random_test() {
  let i = ieee_float.random()

  i
  |> ieee_float.compare(finite(1.0))
  |> should.equal(Ok(order.Lt))

  i
  |> ieee_float.add(finite(2.23e-308))
  |> ieee_float.compare(finite(0.0))
  |> should.equal(Ok(order.Gt))
}

pub fn round_test() {
  finite(8.1)
  |> ieee_float.round
  |> should.equal(Ok(8))

  finite(8.4)
  |> ieee_float.round
  |> should.equal(Ok(8))

  finite(8.499)
  |> ieee_float.round
  |> should.equal(Ok(8))

  finite(8.5)
  |> ieee_float.round
  |> should.equal(Ok(9))

  finite(-8.1)
  |> ieee_float.round
  |> should.equal(Ok(-8))

  finite(-7.5)
  |> ieee_float.round
  |> should.equal(Ok(-8))

  [positive_infinity(), negative_infinity(), nan()]
  |> list.each(fn(f) {
    f
    |> ieee_float.round
    |> should.equal(Error(Nil))
  })
}

pub fn square_root_test() {
  let test_square_root = build_test_function1(ieee_float.square_root)

  test_square_root(finite(0.0), finite(0.0))
  test_square_root(finite(1.0), finite(1.0))
  test_square_root(finite(16.0), finite(4.0))
  test_square_root(finite(-1.0), nan())
  test_square_root(positive_infinity(), positive_infinity())
  test_square_root(negative_infinity(), positive_infinity())
  test_square_root(nan(), nan())
}

pub fn subtract_test() {
  let test_subtract = build_test_function2(ieee_float.subtract)

  test_subtract(finite(3.0), finite(2.0), finite(1.0))
  test_subtract(
    finite(-1.7976931348623157e308),
    finite(1.7976931348623157e308),
    negative_infinity(),
  )
  test_subtract(
    finite(1.7976931348623157e308),
    finite(1.7976931348623157e308),
    finite(0.0),
  )
  test_subtract(finite(1.0), nan(), nan())
  test_subtract(finite(-1.79e308), finite(1.79e308), negative_infinity())
  test_subtract(finite(1.79e308), finite(-1.79e308), positive_infinity())
  test_subtract(nan(), finite(1.0), nan())
  test_subtract(positive_infinity(), finite(-100.0), positive_infinity())
  test_subtract(negative_infinity(), finite(100.0), negative_infinity())
  test_subtract(positive_infinity(), negative_infinity(), positive_infinity())
  test_subtract(negative_infinity(), positive_infinity(), negative_infinity())
  test_subtract(positive_infinity(), positive_infinity(), nan())
  test_subtract(negative_infinity(), negative_infinity(), nan())
}

fn build_test_function1(f: fn(a) -> IEEEFloat) {
  fn(a, expected_value) { f(a) |> check_expected_value(expected_value) }
}

fn build_test_function2(f: fn(a, b) -> IEEEFloat) {
  fn(a, b, expected_value) { f(a, b) |> check_expected_value(expected_value) }
}

fn build_test_function3(f: fn(a, b, c) -> IEEEFloat) {
  fn(a, b, c, expected_value) {
    f(a, b, c) |> check_expected_value(expected_value)
  }
}

fn check_expected_value(value: IEEEFloat, expected_value: IEEEFloat) {
  case ieee_float.is_nan(value) {
    True -> ieee_float.is_nan(value) |> should.be_true
    False -> value |> should.equal(expected_value)
  }
}
