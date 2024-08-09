defmodule TigerBeetlex.QueryFilterBatch do
  @moduledoc """
  ID Batch creation and manipulation.

  This module collects functions to interact with an id batch. An ID Batch represents a list of
  IDs (with a maximum capacity) that will be used to submit a Lookup Accounts or Lookup Transfers
  operation on TigerBeetle.

  The ID Batch should be treated as an opaque and underneath it is implemented with a mutable NIF
  resource. It is safe to modify an ID Batch from multiple processes concurrently.
  """

  use TypedStruct

  typedstruct do
    field :ref, reference(), enforce: true
  end

  alias TigerBeetlex.BatchFullError
  alias TigerBeetlex.InvalidBatchError
  alias TigerBeetlex.NifAdapter
  alias TigerBeetlex.OutOfBoundsError
  alias TigerBeetlex.OutOfMemoryError
  alias TigerBeetlex.QueryFilter
  alias TigerBeetlex.QueryFilterBatch
  alias TigerBeetlex.Types

  @doc """
  Creates a new id batch with the specified capacity.

  The capacity is the maximum number of IDs that can be added to the batch.
  """
  @spec new(capacity :: non_neg_integer()) ::
  {:ok, t()} | {:error, Types.create_batch_error()}
  def new(capacity) when is_integer(capacity) and capacity > 0 do
    with {:ok, ref} <- NifAdapter.create_query_batch(capacity) do
      {:ok, %QueryFilterBatch{ref: ref}}
    end
  end

  @doc """
  Creates a new id batch with the specified capacity, raising in case of an error.

  The capacity is the maximum number of IDs that can be added to the batch.
  """
  @spec new!(capacity :: non_neg_integer()) :: t()
  def new!(capacity) when is_integer(capacity) and capacity > 0 do
    case new(capacity) do
      {:ok, batch} -> batch
      {:error, :out_of_memory} -> raise OutOfMemoryError
    end
  end

  @doc """
  Appends an ID to the batch.
  """
  @spec append(batch :: t(), transfer :: TigerBeetlex.QueryFilter.t()) ::
          {:ok, t()} | {:error, Types.append_error()}
  def append(%QueryFilterBatch{} = batch, %QueryFilter{} = transfer) do
    %QueryFilterBatch{ref: ref} = batch

    transfer_binary = QueryFilter.to_batch_item(transfer)

    with :ok <- NifAdapter.append_query(ref, transfer_binary) do
      {:ok, batch}
    end
  end

  @doc """
  Appends an ID to the batch, raising in case of an error.
  """
  @spec append!(batch :: t(), transfer :: TigerBeetlex.QueryFilter.t()) :: t()
  def append!(%QueryFilterBatch{} = batch, %QueryFilter{} = transfer) do
    case append(batch, transfer) do
      {:ok, batch} -> batch
      {:error, :invalid_batch} -> raise InvalidBatchError
      {:error, :batch_full} -> raise BatchFullError
    end
  end

  @spec fetch(batch :: t(), idx :: non_neg_integer()) ::
          {:ok, TigerBeetlex.QueryFilter.t()} | {:error, Types.fetch_error()}
  def fetch(%QueryFilterBatch{} = batch, idx) when is_number(idx) and idx >= 0 do
    with {:ok, transfer_binary} <- NifAdapter.fetch_query(batch.ref, idx) do
      {:ok, QueryFilter.from_binary(transfer_binary)}
    end
  end

  def fetch(%QueryFilterBatch{} = batch, idx) when is_number(idx) and idx >= 0 do
    with {:ok, transfer_binary} <- NifAdapter.fetch_query(batch.ref, idx) do
      {:ok, QueryFilter.from_binary(transfer_binary)}
    end
  end

  @spec replace(batch :: t(), idx :: non_neg_integer(), transfer :: TigerBeetlex.QueryFilter.t()) ::
          {:ok, t()} | {:error, Types.replace_error()}
  def replace(%QueryFilterBatch{} = batch, idx, %QueryFilter{} = filter)
      when is_number(idx) and idx >= 0 do
    filter_binary = QueryFilter.to_batch_item(filter)

    with :ok <- NifAdapter.replace_query(batch.ref, idx, filter_binary) do
      {:ok, batch}
    end
  end

  @spec replace!(batch :: t(), idx :: non_neg_integer(), transfer :: TigerBeetlex.QueryFilter.t()) ::
          t()
  def replace!(%QueryFilterBatch{} = batch, idx, %QueryFilter{} = transfer)
      when is_number(idx) and idx >= 0 do
    case replace(batch, idx, transfer) do
      {:ok, batch} -> batch
      {:error, :invalid_batch} -> raise InvalidBatchError
      {:error, :out_of_bounds} -> raise OutOfBoundsError
    end
  end
end
