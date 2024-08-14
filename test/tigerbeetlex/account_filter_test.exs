defmodule TigerBeetlex.AccountFilterTest do
  use ExUnit.Case

  alias TigerBeetlex.AccountFilter

  test "from_binary and to_batch_item round trip with minimal fields" do
    filter = %AccountFilter{
      account_id: <<5678::128>>
    }

    assert filter ==
             filter
             |> AccountFilter.to_batch_item()
             |> AccountFilter.from_binary()
  end

  test "from_binary and to_batch_item round trip with full fields" do
    filter = %AccountFilter{
      account_id: <<5678::128>>,
      timestamp_min: 99,
      timestamp_max: 99,
      limit: 8190,
      flags: %AccountFilter.Flags{reversed: true}
    }

    assert filter ==
             filter
             |> AccountFilter.to_batch_item()
             |> AccountFilter.from_binary()
  end

  test "to_batch_item/1 ignores server-controlled fields" do
    filter = %AccountFilter{
      account_id: <<5678::128>>,
      timestamp_min: 99,
      timestamp_max: 99,
      flags: %AccountFilter.Flags{reversed: true, credits: true, debits: true}
    }

    assert %AccountFilter{} =
             filter
             |> AccountFilter.to_batch_item()
             |> AccountFilter.from_binary()
  end
end
