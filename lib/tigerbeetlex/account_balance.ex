defmodule TigerBeetlex.AccountBalance do
  @moduledoc """
  Account struct module.

  This module defines a struct that represents a TigerBeetle account-balance.

  See [TigerBeetle docs](https://docs.tigerbeetle.com/reference/account-balance) for the meaning of the
  fields.
  """

  use TypedStruct

  alias TigerBeetlex.AccountBalance
  alias TigerBeetlex.Types

  typedstruct do
    @typedoc "A struct representing a TigerBeetle account"

    field :debits_pending, non_neg_integer(), default: 0
    field :debits_posted, non_neg_integer(), default: 0
    field :credits_pending, non_neg_integer(), default: 0
    field :credits_posted, non_neg_integer(), default: 0
    field :timestamp, non_neg_integer(), default: 0
  end

  @doc """
  Converts the binary representation of an account (128 bytes) in a
  `%TigerBeetlex.AccountBalance{}` struct
  """
  @spec from_binary(bin :: Types.account_balance_binary()) :: t()
  def from_binary(<<_::binary-size(128)>> = bin) do
    <<debits_pending::unsigned-little-128, debits_posted::unsigned-little-128,
      credits_pending::unsigned-little-128, credits_posted::unsigned-little-128,
      timestamp::unsigned-little-64, _reserved::binary-size(56)>> = bin

    %AccountBalance{
      debits_pending: debits_pending,
      debits_posted: debits_posted,
      credits_pending: credits_pending,
      credits_posted: credits_posted,
      timestamp: timestamp
    }
  end

  @spec to_batch_item(balance :: t()) :: Types.account_balance_binary()
  def to_batch_item(%AccountBalance{} = balance) do
    %AccountBalance{
      debits_pending: debits_pending,
      debits_posted: debits_posted,
      credits_pending: credits_pending,
      credits_posted: credits_posted,
      timestamp: timestamp
    } = balance

    reserved = <<0::unit(8)-size(56)>>

    <<debits_pending::unsigned-little-128, debits_posted::unsigned-little-128,
      credits_pending::unsigned-little-128, credits_posted::unsigned-little-128,
      timestamp::unsigned-little-64,
      reserved::binary>>
  end
end
