defmodule TigerBeetlex.AccountFilter do
  @moduledoc """
  AccountFilter struct module.

  This module defines a struct that represents a TigerBeetle AccountFilter.

  See [TigerBeetle docs](https://docs.tigerbeetle.com/reference/account-filter) for the meaning of the
  fields.
  """

  use TypedStruct

  alias TigerBeetlex.AccountFilter
  alias TigerBeetlex.AccountFilter.Flags
  alias TigerBeetlex.Types

  typedstruct do
    @typedoc "A struct representing a TigerBeetle AccountFilter"

    field :account_id, Types.id_128()
    field :timestamp_min, non_neg_integer(), default: 0
    field :timestamp_max, non_neg_integer(), default: 0
    field :limit, non_neg_integer(), default: 8190
    field :flags, Flags.t(), default: %Flags{}
  end

  @doc """
  Converts the binary representation of an AccountFilter (64 bytes) in a
  `%TigerBeetlex.AccountFilter{}` struct
  """
  @spec from_binary(bin :: Types.account_filter_binary()) :: t()
  def from_binary(<<_::binary-size(64)>> = bin) do
    <<account_id::binary-size(16),
      timestamp_min::unsigned-little-64,
      timestamp_max::unsigned-little-64,
      limit::unsigned-little-32,
      flags::unsigned-little-32,
      _reserved::binary-size(24)>> = bin

    %AccountFilter{
      account_id: account_id,
      timestamp_min: timestamp_min,
      timestamp_max: timestamp_max,
      limit: limit,
      flags: Flags.from_u32!(flags)
    }
  end

  @doc """
  Converts a `%TigerBeetlex.AccountFilter{}` to its binary representation (64 bytes
  binary) in a `%TigerBeetlex.AccountFilterBatch{}`.
  """
  @spec to_batch_item(account_filter :: t()) :: Types.account_filter_binary()
  def to_batch_item(%AccountFilter{} = account_filter) do
    %AccountFilter{
      account_id: account_id,
      timestamp_min: timestamp_min,
      timestamp_max: timestamp_max,
      limit: limit,
      flags: flags
    } = account_filter

    reserved = <<0::unit(8)-size(24)>>

    flags_u32 =
      (flags || %Flags{})
      |> Flags.to_u32!()

    <<account_id::binary-size(16), timestamp_min::unsigned-little-64,
      timestamp_max::unsigned-little-64, limit::unsigned-little-32, flags_u32::unsigned-little-32,
      reserved::binary>>
  end
end
