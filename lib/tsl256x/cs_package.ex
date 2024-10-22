defmodule TSL256X.CSPackage do
  import Bitwise

  @moduledoc """
  Calculation for CS Package

  Coefficients
  ------------

  | Ch1/Ch0 | Lux/Ch0 |
  |---------|---------|
  | 0 <= n <= 0.13| 0.0315−0.0262*(Ch1/Ch0) |
  | 0.13 <= n <= 0.26| 0.0337−0.0430*(Ch1/Ch0)|
  | 0.26 <= n <= 0.39| 0.0363−0.0529*(Ch1/Ch0)|
  | 0.39 <= n <= 0.52| 0.0392−0.0605*(Ch1/Ch0)|
  | 0.52 < n <= 0.65| 0.0229−0.0291*(Ch1/Ch0)|
  | 0.65 < n <= 0.80| 0.00157−0.00180*(Ch1/Ch0)|
  | 0.80 < n <= 1.30| 0.00338−0.00260*(Ch1/Ch0)|
  | n > 1.30| 0|
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

  # 0.130 * 2^RATIO_SCALE
  @k1c 0x0043
  # 0.0315 * 2^LUX_SCALE
  @b1c 0x0204
  # 0.262 * 2^LUX_SCALE
  @m1c 0x01AD
  # 0.260 * 2^RATIO_SCALE
  @k2c 0x0085
  # 0.0337 * 2^LUX_SCALE
  @b2c 0x0228
  # 0.0430 * 2^LUX_SCALE
  @m2c 0x02C1
  # 0.390 * 2^RATIO_SCALE
  @k3c 0x00C8
  # 0.0363 * 2^LUX_SCALE
  @b3c 0x0253
  # 0.0529 * 2^LUX_SCALE
  @m3c 0x0363
  # 0.520 * 2^RATIO_SCALE
  @k4c 0x010A
  # 0.0392 * 2^LUX_SCALE
  @b4c 0x0282
  # 0.0605 * 2^LUX_SCALE
  @m4c 0x03DF
  # 0.65 * 2^RATIO_SCALE
  @k5c 0x014D
  # 0.0229 * 2^LUX_SCALE
  @b5c 0x0177
  # 0.0291 * 2^LUX_SCALE
  @m5c 0x01DD
  # 0.8 * 2^RATIO_SCALE
  @k6c 0x019A
  # 0.0157 * 2^LUX_SCALE
  @b6c 0x0101
  # 0.0180 * 2^LUX_SCALE
  @m6c 0x0127
  # 1.3 * 2^RATIO_SCALE
  @k7c 0x029A
  # 0.00338 * 2^LUX_SCALE
  @b7c 0x0037
  # 0.00260 * 2^LUX_SCALE
  @m7c 0x002B
  # 1.3 * 2^RATIO_SCALE
  @k8c 0x029A
  # 0.000 * 2^LUX_SCALE
  @b8c 0x0000
  # 0.000 * 2^LUX_SCALE
  @m8c 0x0000

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
        0 <= ratio and ratio <= @k1c -> {@b1c, @m1c}
        ratio <= @k2c -> {@b2c, @m2c}
        ratio <= @k3c -> {@b3c, @m3c}
        ratio <= @k4c -> {@b4c, @m4c}
        ratio <= @k5c -> {@b5c, @m5c}
        ratio <= @k6c -> {@b6c, @m6c}
        ratio <= @k7c -> {@b7c, @m7c}
        ratio > @k8c -> {@b8c, @m8c}
      end

    temp = channel0 * b - channel1 * m
    temp = max(0, temp)
    temp = temp + bsl(1, @lux_scale - 1)
    bsr(temp, @lux_scale)
  end
end
