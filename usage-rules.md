# TSL256X usage rules

Elixir/Nerves driver for the TSL2560/TSL2561 light-to-digital sensor family, communicating over I2C via `circuits_i2c`.

## Getting a sensor handle

Find the I2C bus name first (the sensor is not opened by module name, it's opened by bus string):

```elixir
Circuits.I2C.detect_devices()
# look for device id 0x29 (41) on one of the returned buses, e.g. "i2c-1"

{:ok, sensor} = TSL256X.start("i2c-1")
```

`TSL256X.start/2` returns `{:ok, %TSL256X{}}` or `{:error, reason}` — it fails if the bus can't be opened or the chip ID doesn't match a known TSL2560/2561 variant. Never construct `%TSL256X{}` by hand; always go through `start/2`.

All other functions take the `%TSL256X{}` struct returned by `start/2`, not the raw bus reference.

## Core API

- `TSL256X.lux/1` — reads both channels and returns the computed lux value as an integer, or `{:error, reason}` if a register read fails.
- `TSL256X.enable/1`, `TSL256X.disable/1`, `TSL256X.enabled?/1` — power state.
- `TSL256X.gain/1` (get) and `TSL256X.gain/2` (set) — `0` = 1x gain, `1` = 16x gain. Only these two values are valid.
- `TSL256X.integration_time/1` (get) and `TSL256X.integration_time/2` (set) — `0`..`3`. `0`/`1`/`2` are fixed nominal integration times (13.7ms/101ms/402ms); `3` means manual timing control (see the datasheet) and is not supported by `lux/1`, which only accepts `0`, `1`, or `2`.
- `TSL256X.stop/1` — disables the sensor and closes the I2C bus. Always call this when done with a sensor to release the bus reference.

## Gotchas

- `lux/1` will not return a lux value while `integration_time/1` is `3` (manual mode) — it pattern-matches on `0..2` and falls through to the raw `{:error, ...}`/timing tuple otherwise.
- The sensor's I2C address is fixed in hardware (`0x29`); there is no way to pass a custom address.
- This library targets Nerves/embedded targets with real I2C hardware — there is no mock/stub backend, so it cannot be exercised in plain `mix test` without actual hardware or a `Circuits.I2C` stub of your own.
