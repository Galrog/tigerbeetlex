defmodule TigerBeetlex.QueryFilter.Flags do
  @moduledoc """
  .QueryFilter Flags.

  This module defines a struct that represents the flags for a TigerBeetle query filter. Flags are all
  false by default.

  See [TigerBeetle docs](https://docs.tigerbeetle.com/reference/query-filter#flags) for the meaning
  of the flags.
  """

  use TypedStruct

  alias TigerBeetlex.QueryFilter.Flags

  typedstruct do
    @typedoc "A struct representing TigerBeetle query filter flags"

    field :reversed, boolean(), default: false
  end

  @doc """
  Converts the integer representation of flags (32 bit unsigned int) in a
  `%TigerBeetlex.QueryFilter.Flags{}` struct
  """
  @spec from_u32!(n :: non_neg_integer()) :: t()
  def from_u32!(n) when n >= 0 and n < 4_294_967_295 do
    # We use big endian for the source number so we can just follow the (reverse) order of
    # the struct for the fields without manually swapping bytes
    <<_padding::31, reversed::1>> = <<n::unsigned-big-32>>

    %Flags{
      reversed: reversed == 1,
    }
  end

  @doc """
  Converts a `%TigerBeetlex.QueryFilter.Flags{}` struct to its integer representation (32 bit unsigned
  int)
  """
  @spec to_u32!(flags :: t()) :: non_neg_integer()
  def to_u32!(%Flags{} = flags) do
    %Flags{
      reversed: reversed,
    } = flags

    # We use big endian for the destination number so we can just follow the (reverse) order of
    # the struct for the fields without manually swapping bytes
    <<n::unsigned-big-32>> = <<_padding = 0::31, bool_to_u1(reversed)::1>>
    n
  end

  @spec bool_to_u1(b :: boolean()) :: 0 | 1
  defp bool_to_u1(false), do: 0
  defp bool_to_u1(true), do: 1
end
