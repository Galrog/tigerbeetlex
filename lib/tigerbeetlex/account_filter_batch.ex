defmodule TigerBeetlex.AccountFilterBatch do
  @moduledoc """
  AccountFilter Batch creation and manipulation.

  This module collects functions to interact with an account batch. An AccountFilter Batch represents a
  list of AccountFilters (with a maximum capacity) that will be used to submit a Create AccountFilters
  operation on TigerBeetle.

  The AccountFilter Batch should be treated as an opaque and underneath it is implemented with a
  mutable NIF resource. It is safe to modify an AccountFilter Batch from multiple processes concurrently.
  """

  use TypedStruct

  typedstruct do
    field :ref, reference(), enforce: true
  end

  alias TigerBeetlex.AccountFilter
  alias TigerBeetlex.AccountFilterBatch
  alias TigerBeetlex.BatchFullError
  alias TigerBeetlex.InvalidBatchError
  alias TigerBeetlex.NifAdapter
  alias TigerBeetlex.OutOfBoundsError
  alias TigerBeetlex.OutOfMemoryError
  alias TigerBeetlex.Types

  @doc """
  Creates a new account batch with the specified capacity.

  The capacity is the maximum number of accounts that can be added to the batch.
  """
  @spec new(capacity :: non_neg_integer()) ::
  {:ok, t()} | {:error, Types.create_batch_error()}
  def new(capacity) when is_integer(capacity) and capacity > 0 do
    with {:ok, ref} <- NifAdapter.create_account_filter_batch(capacity) do
      {:ok, %AccountFilterBatch{ref: ref}}
    end
  end

  @doc """
  Creates a new account batch with the specified capacity, rasing in case of an error.

  The capacity is the maximum number of accounts that can be added to the batch.
  """
  @spec new!(capacity :: non_neg_integer()) :: t()
  def new!(capacity) when is_integer(capacity) and capacity > 0 do
    case new(capacity) do
      {:ok, batch} -> batch
      {:error, :out_of_memory} -> raise OutOfMemoryError
    end
  end

  @doc """
  Appends an account to the batch.

  The `%AccountFilter{}` struct must contain at least `:id`, `:ledger` and `:code`, and may also contain
  `:user_data` and `:flags`. All other fields are ignored since they are server-controlled fields.
  """
  @spec append(batch :: t(), filter :: TigerBeetlex.AccountFilter.t()) ::
          {:ok, t()} | {:error, Types.append_error()}
  def append(%AccountFilterBatch{} = batch, %AccountFilter{} = filter) do
    %AccountFilterBatch{ref: ref} = batch

    account_binary = AccountFilter.to_batch_item(filter)

    with :ok <- NifAdapter.append_account_filter(ref, account_binary) do
      {:ok, batch}
    end
  end

  @doc """
  Appends an account to the batch, raising in case of an error.

  See `append/2` for the supported fields in the `%AccountFilter{}` struct.
  """
  @spec append!(batch :: t(), account :: TigerBeetlex.AccountFilter.t()) :: t()
  def append!(%AccountFilterBatch{} = batch, %AccountFilter{} = account) do
    case append(batch, account) do
      {:ok, batch} -> batch
      {:error, :invalid_batch} -> raise InvalidBatchError
      {:error, :batch_full} -> raise BatchFullError
    end
  end

  @doc """
  Fetches an `%AccountFilter{}` from the batch, given its index.
  """
  @spec fetch(batch :: t(), idx :: non_neg_integer()) ::
          {:ok, TigerBeetlex.AccountFilter.t()} | {:error, Types.fetch_error()}
  def fetch(%AccountFilterBatch{} = batch, idx) when is_number(idx) and idx >= 0 do
    with {:ok, account_binary} <- NifAdapter.fetch_account_filter(batch.ref, idx) do
      {:ok, AccountFilter.from_binary(account_binary)}
    end
  end

  @doc """
  Fetches an `%AccountFilter{}` from the batch, given its index. Raises in case of an error.
  """
  @spec fetch!(batch :: t(), idx :: non_neg_integer()) :: TigerBeetlex.AccountFilter.t()
  def fetch!(%AccountFilterBatch{} = batch, idx) when is_number(idx) and idx >= 0 do
    case fetch(batch, idx) do
      {:ok, account} -> account
      {:error, :invalid_batch} -> raise InvalidBatchError
      {:error, :out_of_bounds} -> raise OutOfBoundsError
    end
  end

  @doc """
  Replaces the `%AccountFilter{}` at index `idx` in the batch.
  """
  @spec replace(batch :: t(), idx :: non_neg_integer(), account :: TigerBeetlex.AccountFilter.t()) ::
          {:ok, t()} | {:error, Types.replace_error()}
  def replace(%AccountFilterBatch{} = batch, idx, %AccountFilter{} = account)
      when is_number(idx) and idx >= 0 do
    account_binary = AccountFilter.to_batch_item(account)

    with :ok <- NifAdapter.replace_account_filter(batch.ref, idx, account_binary) do
      {:ok, batch}
    end
  end

  @doc """
  Replaces the ID at index `idx` in the batch. Raises in case of an error.
  """
  @spec replace!(batch :: t(), idx :: non_neg_integer(), account :: TigerBeetlex.AccountFilter.t()) ::
          t()
  def replace!(%AccountFilterBatch{} = batch, idx, %AccountFilter{} = account)
      when is_number(idx) and idx >= 0 do
    case replace(batch, idx, account) do
      {:ok, batch} -> batch
      {:error, :invalid_batch} -> raise InvalidBatchError
      {:error, :out_of_bounds} -> raise OutOfBoundsError
    end
  end
end
