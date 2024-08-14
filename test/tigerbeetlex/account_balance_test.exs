defmodule TigerBeetlex.AccountBalanceTest do
  use ExUnit.Case

  alias TigerBeetlex.AccountBalance

  test "from_binary and to_batch_item round trip with minimal fields" do
    balance = %AccountBalance{
      debits_pending: 11,
      debits_posted: 22,
      credits_pending: 33,
      credits_posted: 44,
      timestamp: 99,
    }

    assert balance ==
      balance
      |> AccountBalance.to_batch_item()
      |> AccountBalance.from_binary()
  end

  test "from_binary and to_batch_item round trip with full fields" do
    balance = %AccountBalance{
      debits_pending: 11,
      debits_posted: 22,
      credits_pending: 33,
      credits_posted: 44,
      timestamp: 99,
    }

    assert balance ==
             balance
             |> AccountBalance.to_batch_item()
             |> AccountBalance.from_binary()
  end
end
