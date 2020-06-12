defmodule MehrSchulferien.Locations.Flag do
  @moduledoc """
  Module for handling federal state flags.
  """

  @flags __DIR__ |> Path.join("flags.txt") |> File.read!() |> String.split("\n", trim: true)
  @flag_map Enum.reduce(@flags, %{}, fn flag, acc ->
              [code, value] = String.split(flag, "::")
              Map.put(acc, code, value)
            end)

  def get_flag(code), do: @flag_map[code]
end
