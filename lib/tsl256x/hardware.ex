defmodule TSL256X.Hardware do
  @moduledoc false
  alias Circuits.I2C
  import Bitwise

  @default_addr 0x29
  @command_bit 0x80
  @word_bit 0x20

  @control_poweron 0x03
  @control_poweroff 0x00

  @register_control 0x00
  @register_timing 0x01
  @register_th_low 0x02
  @register_th_high 0x04
  @register_int_ctrl 0x06
  @register_id 0x0A
  @register_chan0_low 0x0C
  @register_chan1_low 0x0E

  @spec chip_id(I2C.Bus.t()) ::
          {:ok, :TSL2560CS | :TSL2561CS | :TSL2560T | :TSL2561T | :unknown, byte()}
          | {:error, any()}
  def chip_id(bus_ref) do
    case read_register(bus_ref, @register_id) do
      {:ok, <<dev_id>>} ->
        partno =
          bsr(dev_id, 4)
          |> band(0x0F)
          |> case do
            0 -> :TSL2560CS
            1 -> :TSL2561CS
            4 -> :TSL2560T
            5 -> :TSL2561T
            _ -> :unknown
          end

        revno = band(dev_id, 0x0F)
        {:ok, partno, revno}

      error ->
        error
    end
  end

  def enabled?(bus_ref) do
    case I2C.write_read(bus_ref, @default_addr, <<0x80>>, 1) do
      {:ok, <<val>>} ->
        band(val, 0x03) != 0
    end
  end

  def enable(bus_ref) do
    write_control_register(bus_ref, @control_poweron)
  end

  def disable(bus_ref) do
    write_control_register(bus_ref, @control_poweroff)
  end

  def broadband(bus_ref) do
    read_register(bus_ref, @register_chan0_low, 2)
  end

  def infrared(bus_ref) do
    read_register(bus_ref, @register_chan1_low, 2)
  end

  @spec gain(I2C.Bus.t()) :: 0 | 1
  def gain(bus_ref) do
    with {:ok, <<value>>} <- read_register(bus_ref, @register_timing) do
      bsr(value, 4)
      |> band(0x01)
    end
  end

  @spec gain(I2C.Bus.t(), 0 | 1) :: :ok | {:error, any()}
  def gain(bus_ref, value) do
    with {:ok, <<current>>} <- read_register(bus_ref, @register_timing) do
      new_gain = value |> band(0x01) |> bsl(4)

      I2C.write(
        bus_ref,
        @default_addr,
        <<register(@register_timing), band(current, 0xEF) |> bor(new_gain)>>
      )
    end
  end

  @spec integration_time(I2C.Bus.t()) :: 0 | 1 | 2 | 3 | {:error, any()}
  def integration_time(bus_ref) do
    with {:ok, <<value>>} <- read_register(bus_ref, @register_timing) do
      band(value, 0x03)
    end
  end

  def integration_time(bus_ref, value) do
    with {:ok, <<current>>} <- read_register(bus_ref, @register_timing) do
      new_time = band(value, 0x03)

      I2C.write(
        bus_ref,
        @default_addr,
        <<register(@register_timing), band(current, 0xFC) |> bor(new_time)>>
      )
    end
  end

  def threshold_low(bus_ref) do
    read_register(bus_ref, <<register(@register_th_low)>>, 2)
  end

  def threshold_low(bus_ref, value) do
    byte1 = band(value, 0xFF)
    byte2 = value |> bsr(8) |> band(0xFF)
    I2C.write(bus_ref, @default_addr, <<register(@register_th_low, 2), byte1, byte2>>)
  end

  def threshold_high(bus_ref) do
    read_register(bus_ref, <<register(@register_th_high)>>, 2)
  end

  def threshold_high(bus_ref, value) do
    byte1 = band(value, 0xFF)
    byte2 = value |> bsr(8) |> band(0xFF)
    I2C.write(bus_ref, @default_addr, <<register(@register_th_high, 2), byte1, byte2>>)
  end

  def cycles(bus_ref) do
    with {:ok, <<value>>} <- read_register(bus_ref, @register_int_ctrl) do
      value |> band(0x0F)
    end
  end

  def cycles(bus_ref, value) do
    with {:ok, <<current>>} <- read_register(bus_ref, @register_int_ctrl) do
      new_cycle = current |> bor(band(value, 0x0F))
      I2C.write(bus_ref, @default_addr, <<register(@register_int_ctrl), new_cycle>>)
    end
  end

  def interrupt_mode(bus_ref) do
    with {:ok, <<value>>} <- read_register(bus_ref, @register_int_ctrl) do
      value
      |> bsr(4)
      |> band(0x03)
      |> case do
        0 -> :disabled
        1 -> :level
        2 -> :smb_alert
        3 -> :test_mode
      end
    end
  end

  def interrupt_mode(bus_ref, value) when value in [:disabled, :level, :smb_alert, :test_mode] do
    with {:ok, <<current>>} <- read_register(bus_ref, @register_int_ctrl) do
      value =
        case value do
          :disabled -> 0
          :level -> 1
          :smb_alert -> 2
          :test_mode -> 3
        end
        |> bsl(4)

      I2C.write(
        bus_ref,
        @default_addr,
        <<register(@register_int_ctrl), current |> band(0x0F) |> bor(value)>>
      )
    end
  end

  def clear_interrupt(bus_ref) do
    I2C.write(bus_ref, @default_addr, <<0xC0>>)
  end

  def read_register(bus_ref, register, count \\ 1)

  def read_register(bus_ref, register, count) when count in [1, 2] do
    I2C.write_read(bus_ref, @default_addr, <<register(register, count)>>, count)
  end

  def read_register(_, _, count) do
    {:error, "Count #{count} should be either 1 or 2"}
  end

  def write_control_register(bus_ref, register) do
    I2C.write!(bus_ref, @default_addr, <<register(@register_control), register>>)
  end

  defp register(register, count \\ 1)
  defp register(register, 1), do: @command_bit ||| register
  defp register(register, 2), do: @command_bit ||| @word_bit ||| register
end
