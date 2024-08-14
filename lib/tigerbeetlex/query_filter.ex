defmodule TigerBeetlex.QueryFilter do
  @moduledoc """
  QueryFilter struct module.

  This module defines a struct that represents a TigerBeetle QueryFilter.

  See [TigerBeetle docs](https://docs.tigerbeetle.com/reference/query-filter) for the meaning of the
  fields.
  """

  use TypedStruct

  alias TigerBeetlex.QueryFilter
  alias TigerBeetlex.QueryFilter.Flags
  alias TigerBeetlex.Types

  typedstruct do
    @typedoc "A struct representing a TigerBeetle QueryFilter"

    field :user_data_128, Types.user_data_128()
    field :user_data_64, Types.user_data_64()
    field :user_data_32, Types.user_data_32()
    field :ledger, non_neg_integer(), default: 0
    field :code, non_neg_integer(), default: 0
    field :timestamp_min, non_neg_integer(), default: 0
    field :timestamp_max, non_neg_integer(), default: 0
    field :limit, non_neg_integer(), default: 10
    field :flags, Flags.t(), default: %Flags{}
  end

  @doc """
  Converts the binary representation of an QueryFilter (64 bytes) in a
  `%TigerBeetlex.QueryFilter{}` struct
  """
  @spec from_binary(bin :: Types.query_filter_binary()) :: t()
  def from_binary(<<_::binary-size(64)>> = bin) do
    <<user_data_128::binary-size(16),
      user_data_64::binary-size(8),
      user_data_32::binary-size(4),
      ledger::unsigned-little-32,
      code::unsigned-little-16,
      _reserved::binary-size(6),
      timestamp_min::unsigned-little-64,
      timestamp_max::unsigned-little-64,
      limit::unsigned-little-32,
      flags::unsigned-little-32>> = bin

    %QueryFilter{
      user_data_128: nilify_user_data_128_default(user_data_128),
      user_data_64: nilify_user_data_64_default(user_data_64),
      user_data_32: nilify_user_data_32_default(user_data_32),
      ledger: ledger,
      code: code,
      timestamp_min: timestamp_min,
      timestamp_max: timestamp_max,
      limit: limit,
      flags: Flags.from_u32!(flags)
    }
  end

  defp nilify_user_data_128_default(<<0::unit(8)-size(16)>>), do: nil
  defp nilify_user_data_128_default(value), do: value

  defp nilify_user_data_64_default(<<0::unit(8)-size(8)>>), do: nil
  defp nilify_user_data_64_default(value), do: value

  defp nilify_user_data_32_default(<<0::unit(8)-size(4)>>), do: nil
  defp nilify_user_data_32_default(value), do: value

  @doc """
  Converts a `%TigerBeetlex.QueryFilter{}` to its binary representation (64 bytes
  binary) in a `%TigerBeetlex.QueryFilterBatch{}`.
  """
  @spec to_batch_item(query_filter :: t()) :: Types.query_filter_binary()
  def to_batch_item(%QueryFilter{} = query_filter) do
    %QueryFilter{
      user_data_128: user_data_128,
      user_data_64: user_data_64,
      user_data_32: user_data_32,
      ledger: ledger,
      code: code,
      timestamp_min: timestamp_min,
      timestamp_max: timestamp_max,
      limit: limit,
      flags: flags
    } = query_filter

    reserved = <<0::unit(8)-size(6)>>

    flags_u32 =
      (flags || %Flags{})
      |> Flags.to_u32!()

    <<user_data_128_default(user_data_128)::binary-size(16),
      user_data_64_default(user_data_64)::binary-size(8),
      user_data_32_default(user_data_32)::binary-size(4), ledger::unsigned-little-32,
      code::unsigned-little-16, reserved::binary, timestamp_min::unsigned-little-64,
      timestamp_max::unsigned-little-64, limit::unsigned-little-32,
      flags_u32::unsigned-little-32>>
  end

  defp user_data_128_default(nil), do: <<0::unit(8)-size(16)>>
  defp user_data_128_default(value), do: value

  defp user_data_64_default(nil), do: <<0::unit(8)-size(8)>>
  defp user_data_64_default(value), do: value

  defp user_data_32_default(nil), do: <<0::unit(8)-size(4)>>
  defp user_data_32_default(value), do: value
end
