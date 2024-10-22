# TSL256X

This is a Circuits-based Elixir driver for the TSL256X family of Light-to-digital convertors.
It uses i2C for communication.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `tsl256x` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tsl256x, "~> 0.1.0"}
  ]
end
```

## Getting started

If you have I2C hooked up on your device, typically under Nerves:

```elixir
iex> Circuits.I2C.detect_devices() # Use to find the right bus, eg "i2c-1"
# there will be a lot of output, but one of the busses - usualy "i2c-1" will
# contain the id 41, the default id this library uses.
iex> {:ok, sensor} = TSL256X.start("i2c-1")
{:ok, %TSL256X{...}}
iex> TSL256X.lux(sensor)
2851
```
