defmodule TSL256X do
  @moduledoc """
  Documentation for `TSL256x family of Ligh to digital convertors`.

  This module supports TSL2560 and 2561 in both T and SC packages.

  To start add the module to your mix.exs

  """

  defstruct bus_ref: nil, type: :unknown, rev: 0
  @type t :: %__MODULE__{}

  alias Circuits.I2C
  alias TSL256X.Hardware

  @doc """
  Start the sensor and return a struct for future calls.

  ## Examples
  ```elixir
  iex> TSL256X.start("i2c-1", 4)
  {:ok, %TSL256X{}}
  ```
  """

  @spec start(String.t(), integer()) :: {:ok, t()} | {:error, any()}
  def start(i2c_bus, retries \\ 1) do
    with {:ok, bus_ref} <- I2C.open(i2c_bus, retries: retries),
         :ok <- Hardware.enable(bus_ref),
         {:ok, type, rev} <- Hardware.chip_id(bus_ref) do
      if type != :unknown do
        {:ok, %__MODULE__{bus_ref: bus_ref, type: type, rev: rev}}
      else
        I2C.close(bus_ref)
        {:error, :unknown_device}
      end
    end
  end

  @doc """
  Stop the light sensor and closes the I2C bus.


  ## Examples
  ```elixir
  iex> TSL256X.stop(sensor)
  :ok
  ```
  """
  @spec stop(t()) :: :ok
  def stop(%__MODULE__{bus_ref: bus_ref} = _sensor) do
    :ok = disable(bus_ref)
    I2C.close(bus_ref)
  end

  @doc "Checks to see if the sensor is currently enabled."
  @spec enabled?(t()) :: true | false | {:error, any()}
  def enabled?(%__MODULE__{bus_ref: bus_ref} = _sensor), do: Hardware.enabled?(bus_ref)

  @doc "Enable the sensor"
  @spec enable(t()) :: :ok | {:error, any()}
  def enable(%__MODULE__{bus_ref: bus_ref} = _sensor), do: Hardware.enable(bus_ref)

  @doc "Disable the sensor"
  @spec disable(t()) :: :ok | {:error, any()}
  def disable(%__MODULE__{bus_ref: bus_ref} = _sensor), do: Hardware.disable(bus_ref)

  @doc """
  Gets the current `gain` setting from the sensor:

  * 0 - 1X
  * 1 - 16X

  """
  @spec gain(t()) :: 0 | 1
  def gain(%__MODULE__{bus_ref: bus_ref} = _sensor), do: Hardware.gain(bus_ref)

  @doc """
  Sets the current `gain` setting for the sensor:

  * 0 - 1X
  * 1 - 16X

  """
  @spec gain(t(), 0 | 1) :: :ok | {:error, any()}
  def gain(%__MODULE__{bus_ref: bus_ref} = _sensor, value) when value in [0, 1],
    do: Hardware.gain(bus_ref, value)

  @doc """
  Gets the current `integration time` from the sensors.

  | value | scale | nominal integration time|
  |-----:|------:|:-----------------------:|
  |0 | 0.034 | 13.7 ms|
  |1 | 0.252 | 101 ms|
  |2 | 1 | 402 ms|
  |3 | -- | N/A|

  When the value is set to 3, manual timing control is used, check the [datasheet](assets/datasheet.pdf) for more information.
  """
  @spec integration_time(t()) :: 0 | 1 | 2 | 3 | {:error, any()}
  def integration_time(%__MODULE__{bus_ref: bus_ref} = _sensor),
    do: Hardware.integration_time(bus_ref)

  @doc """
  Set the `integration time`, check `integration_time/1` for the possible values.
  """
  @spec integration_time(t(), 0..3) :: :ok | {:error, any()}
  def integration_time(%__MODULE__{bus_ref: bus_ref} = _sensor, value) when value in 0..3,
    do: Hardware.integration_time(bus_ref, value)

  @doc """
  Calculate the current light strength in lux.

  ## Example
  ```elixir
     iex> TSL256X.lux(sensor)
     2851
  ```
  """

  def lux(%__MODULE__{} = sensor) do
    with {:ok, <<ch0::16>>} <- Hardware.broadband(sensor.bus_ref),
         {:ok, <<ch1::16>>} <- Hardware.infrared(sensor.bus_ref),
         integ_time when integ_time in [0, 1, 2] <- integration_time(sensor),
         gain when is_integer(gain) <- gain(sensor) do
      func =
        case sensor.type do
          :TSL2560CS -> TSL256X.CSPackage
          :TSL2561CS -> TSL256X.CSPackage
          :TSL2561T -> TSL256X.TPackage
          :TSL2560T -> TSL256X.TPackage
        end

      apply(func, :calculate_lux, [gain, integ_time, ch0, ch1])
    end
  end
end
