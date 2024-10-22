defmodule TSL256X.TPackage do
  import Bitwise

  @moduledoc """
  Calculation for T Package

  Coefficients
  ------------

  | Ch1/Ch0 | Lux/Ch0 |
  |---------|---------|
  |0.00 <= n <= 0.00| 0.0304−0.0272*(Ch1/Ch0)|
  |0.125 <= n <= 0.125| 0.0325−0.0440*(Ch1/Ch0)|
  |0.250 <= n <= 0.250| 0.0351−0.0544*(Ch1/Ch0)|
  |0.375 <= n <= 0.375| 0.0381−0.0624*(Ch1/Ch0)|
  |0.50 < n <= 0.50| 0.0224−0.031*(Ch1/Ch0)|
  |0.61 < n <= 0.61| 0.0128−0.0153*(Ch1/Ch0)|
  |0.80 < n <= 0.80| 0.00146−0.00112*(Ch1/Ch0)|
  |n > 1.30| 0|
  """

  # scale by 2^14
  @lux_scale 14
  # scale by 2^9
  @ratio_scale 9

  # Integration time scaling factors
  # scale channel values by 2^10
  @ch_scale 10
  # 322/11 * 2^CH_SCALE
  @ch_scale_tint0 0x7517
  # 322/81 * 2^CH_SCALE
  @ch_scale_tint1 0x0FE7

  # 0.125 * 2^RATIO_SCALE
  @k1t 0x0040
  # 0.0304 * 2^LUX_SCALE
  @b1t 0x01F2
  # 0.250 * 2^LUX_SCALE
  @m1t 0x01BE
  # 0.250 * 2^RATIO_SCALE
  @k2t 0x0080
  # 0.0325 * 2^LUX_SCALE
  @b2t 0x0214
  # 0.0440 * 2^LUX_SCALE
  @m2t 0x02D1
  # 0.375 * 2^RATIO_SCALE
  @k3t 0x00C0
  # 0.0351 * 2^LUX_SCALE
  @b3t 0x023F
  # 0.0544 * 2^LUX_SCALE
  @m3t 0x037B
  # 0.50 * 2^RATIO_SCALE
  @k4t 0x0100
  # 0.0381 * 2^LUX_SCALE
  @b4t 0x0270
  # 0.0624 * 2^LUX_SCALE
  @m4t 0x03FE
  # 0.61 * 2^RATIO_SCALE
  @k5t 0x0138
  # 0.0224 * 2^LUX_SCALE
  @b5t 0x016F
  # 0.0310 * 2^LUX_SCALE
  @m5t 0x01FC
  # 0.8 * 2^RATIO_SCALE
  @k6t 0x019A
  # 0.0128 * 2^LUX_SCALE
  @b6t 0x00D2
  # 0.0153 * 2^LUX_SCALE
  @m6t 0x00FB
  # 1.3 * 2^RATIO_SCALE
  @k7t 0x029A
  # 0.00146 * 2^LUX_SCALE
  @b7t 0x008
  # 0.00112 * 2^LUX_SCALE
  @m7t 0x0012
  # 1.3 * 2^RATIO_SCALE
  @k8t 0x029A
  # 0.000 * 2^LUX_SCALE
  @b8t 0x0000
  # 0.000 * 2^LUX_SCALE
  @m8t 0x0000

  @doc "Calculate the lux value"
  def calculate_lux(gain, int, ch0, ch1) do
    chScale =
      case int do
        0 -> @ch_scale_tint0
        1 -> @ch_scale_tint1
        _ -> bsl(1, @ch_scale)
      end

    # Scale 1X to 16X
    chScale = if gain == 1, do: chScale, else: bsl(chScale, 4)

    channel0 = (ch0 * chScale) |> bsr(@ch_scale)
    channel1 = (ch1 * chScale) |> bsr(@ch_scale)

    ratio1 =
      if channel0 != 0 do
        floor(bsl(channel1, @ratio_scale + 1) / channel0)
      else
        0
      end

    ratio = bsr(ratio1 + 1, 1)

    {b, m} =
      cond do
        0 <= ratio and ratio <= @k1t -> {@b1t, @m1t}
        ratio <= @k2t -> {@b2t, @m2t}
        ratio <= @k3t -> {@b3t, @m3t}
        ratio <= @k4t -> {@b4t, @m4t}
        ratio <= @k5t -> {@b5t, @m5t}
        ratio <= @k6t -> {@b6t, @m6t}
        ratio <= @k7t -> {@b7t, @m7t}
        ratio > @k8t -> {@b8t, @m8t}
      end

    temp = channel0 * b - channel1 * m
    temp = max(0, temp)
    temp = temp + bsl(1, @lux_scale - 1)
    bsr(temp, @lux_scale)
  end
end
