import {
  float_to_string,
  parse_float,
  random_uniform,
} from "../gleam_stdlib/gleam_stdlib.mjs";
import { Eq, Gt, Lt } from "../gleam_stdlib/gleam/order.mjs";
import { BitArray, Ok, Error } from "../prelude.mjs";

const Nil = undefined;

export function finite(f) {
  return f;
}

export function positive_infinity() {
  return Infinity;
}

export function negative_infinity() {
  return -Infinity;
}

export function nan() {
  return NaN;
}

export function is_finite(f) {
  return Number.isFinite(f);
}

export function is_nan(f) {
  return Number.isNaN(f);
}

export function to_finite(f) {
  return Number.isFinite(f) ? new Ok(f) : new Error(Nil);
}

export function to_string(f) {
  if (Number.isFinite(f)) {
    return float_to_string(f);
  } else {
    return f.toString();
  }
}

export function parse(s) {
  s = s.trim();

  if (s === "Infinity") {
    return Infinity;
  } else if (s === "-Infinity") {
    return -Infinity;
  } else {
    const f = parse_float(s);

    if (f.isOk()) {
      return f[0];
    } else {
      return NaN;
    }
  }
}

function to_bytes_16(num, littleEndian) {
  const u8Array = new Uint8Array(2);

  if (isNaN(num)) {
    u8Array[1] = 0x7e;
  } else if (num === Infinity) {
    u8Array[1] = 0x7c;
  } else if (num === -Infinity) {
    u8Array[1] = 0xfc;
  } else if (num === 0) {
    // Both values are already zero
  } else {
    const sign = num < 0 ? 1 : 0;
    num = Math.abs(num);

    let exponent = Math.floor(Math.log2(num));
    let fraction = num / Math.pow(2, exponent) - 1;

    exponent += 15;

    if (exponent <= 0) {
      exponent = 0;
      fraction = num / Math.pow(2, -14);
    } else if (exponent >= 31) {
      exponent = 31;
      fraction = 0;
    }

    fraction = Math.round(fraction * 1024);

    u8Array[1] =
      (sign << 7) | ((exponent & 0x1f) << 2) | ((fraction >> 8) & 0x03);
    u8Array[0] = fraction & 0xff;
  }

  if (!littleEndian) {
    const a = u8Array[0];
    u8Array[0] = u8Array[1];
    u8Array[1] = a;
  }

  return new BitArray(u8Array);
}

function from_bytes_16(bitArray, littleEndian) {
  if (bitArray.length !== 2) {
    return NaN;
  }

  let intValue;
  if (littleEndian) {
    intValue = bitArray.buffer[0] + bitArray.buffer[1] * 256;
  } else {
    intValue = bitArray.buffer[0] * 256 + bitArray.buffer[1];
  }

  const sign = intValue >= 0x8000 ? -1 : 1;
  const exponent = (intValue & 0x7c00) >> 10;
  const fraction = intValue & 0x03ff;

  let value;
  if (exponent === 0) {
    value = 6.103515625e-5 * (fraction / 0x400);
  } else if (exponent === 0x1f) {
    value = fraction === 0 ? Infinity : NaN;
  } else {
    value = Math.pow(2, exponent - 15) * (1 + fraction / 0x400);
  }

  return sign * value;
}

function to_bytes_32(f, littleEndian) {
  const u8Array = new Uint8Array(4);

  const view = new DataView(u8Array.buffer);
  view.setFloat32(0, f, littleEndian);

  return new BitArray(u8Array);
}

function from_bytes_32(bitArray, littleEndian) {
  if (bitArray.length !== 4) {
    return NaN;
  }

  const view = new DataView(bitArray.buffer.buffer, bitArray.buffer.byteOffset);

  return view.getFloat32(0, littleEndian);
}

function to_bytes_64(f, littleEndian) {
  const u8Array = new Uint8Array(8);

  const view = new DataView(u8Array.buffer);
  view.setFloat64(0, f, littleEndian);

  return new BitArray(u8Array);
}

function from_bytes_64(bitArray, littleEndian) {
  if (bitArray.length !== 8) {
    return NaN;
  }

  const view = new DataView(bitArray.buffer.buffer, bitArray.buffer.byteOffset);

  return view.getFloat64(0, littleEndian);
}

export function to_bytes_16_le(f) {
  return to_bytes_16(f, true);
}

export function from_bytes_16_le(f) {
  return from_bytes_16(f, true);
}

export function to_bytes_16_be(f) {
  return to_bytes_16(f, false);
}

export function from_bytes_16_be(f) {
  return from_bytes_16(f, false);
}

export function to_bytes_32_le(f) {
  return to_bytes_32(f, true);
}

export function from_bytes_32_le(f) {
  return from_bytes_32(f, true);
}

export function to_bytes_32_be(f) {
  return to_bytes_32(f, false);
}

export function from_bytes_32_be(f) {
  return from_bytes_32(f, false);
}

export function to_bytes_64_le(f) {
  return to_bytes_64(f, true);
}

export function from_bytes_64_le(f) {
  return from_bytes_64(f, true);
}

export function to_bytes_64_be(f) {
  return to_bytes_64(f, false);
}

export function from_bytes_64_be(f) {
  return from_bytes_64(f, false);
}

export function absolute_value(f) {
  return Math.abs(f);
}

export function add(a, b) {
  return a + b;
}

export function ceiling(f) {
  return Math.ceil(f);
}

export function compare(a, b) {
  if (Number.isNaN(a) || Number.isNaN(b)) {
    return new Error(Nil);
  }

  if (a === b) {
    return new Ok(new Eq());
  } else if (a < b) {
    return new Ok(new Lt());
  } else {
    return new Ok(new Gt());
  }
}

export function divide(a, b) {
  return a / b;
}

export function floor(f) {
  return Math.floor(f);
}

export function max(a, b) {
  return Math.max(a, b);
}

export function min(a, b) {
  return Math.min(a, b);
}

export function multiply(a, b) {
  return a * b;
}

export function negate(f) {
  return -f;
}

export function power(base, exponent) {
  return base ** exponent;
}

export function random() {
  return random_uniform();
}

export function round(f) {
  if (!Number.isFinite(f)) {
    return new Error(Nil);
  }

  if (f >= 0) {
    return new Ok(Math.round(f));
  } else {
    return new Ok(-Math.round(-f));
  }
}

export function subtract(a, b) {
  return a - b;
}

export function square_root(f) {
  return Math.sqrt(f);
}

export function rescue_bad_arith() {}
