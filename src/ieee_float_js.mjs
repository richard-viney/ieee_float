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

export function to_finite(f, fallback) {
  return Number.isFinite(f) ? f : fallback;
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

export function to_bytes_32_le(f) {
  const u8Array = new Uint8Array(4);

  const view = new DataView(u8Array.buffer);
  view.setFloat32(0, f, true);

  return new BitArray(u8Array);
}

export function from_bytes_32_le(f) {
  if (f.length !== 4) {
    return new Error(Nil);
  }

  const view = new DataView(f.buffer.buffer);

  return view.getFloat32(0, true);
}

export function to_bytes_32_be(f) {
  const u8Array = new Uint8Array(4);

  const view = new DataView(u8Array.buffer);
  view.setFloat32(0, f, false);

  return new BitArray(u8Array);
}

export function from_bytes_32_be(f) {
  if (f.length !== 4) {
    return new Error(Nil);
  }

  const view = new DataView(f.buffer.buffer);

  return view.getFloat32(0, false);
}

export function to_bytes_64_le(f) {
  const u8Array = new Uint8Array(8);

  const view = new DataView(u8Array.buffer);
  view.setFloat64(0, f, true);

  return new BitArray(u8Array);
}

export function from_bytes_64_le(f) {
  if (f.length !== 8) {
    return new Error(Nil);
  }

  const view = new DataView(f.buffer.buffer);

  return view.getFloat64(0, true);
}

export function to_bytes_64_be(f) {
  const u8Array = new Uint8Array(8);

  const view = new DataView(u8Array.buffer);
  view.setFloat64(0, f, false);

  return new BitArray(u8Array);
}

export function from_bytes_64_be(f) {
  if (f.length !== 8) {
    return new Error(Nil);
  }

  const view = new DataView(f.buffer.buffer);

  return view.getFloat64(0, false);
}

export function absolute_value(f) {
  return Math.abs(f);
}

export function add(a, b) {
  return a + b;
}

export function ceiling(a) {
  return Math.ceil(a);
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

export function floor(a) {
  return Math.floor(a);
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

export function negate(a) {
  return -a;
}

export function random() {
  return random_uniform();
}

export function round(a) {
  if (Number.isFinite(a)) {
    if (a >= 0) {
      return new Ok(Math.round(a));
    } else {
      return new Ok(-Math.round(-a));
    }
  } else {
    return new Error(Nil);
  }
}

export function subtract(a, b) {
  return a - b;
}

export function rescue_bad_arith() {}
