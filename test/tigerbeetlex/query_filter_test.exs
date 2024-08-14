defmodule TigerBeetlex.QueryFilterTest do
  use ExUnit.Case

  alias TigerBeetlex.QueryFilter

  test "from_binary and to_batch_item round trip with minimal fields" do
    filter = %QueryFilter{}

    assert filter ==
             filter
             |> QueryFilter.to_batch_item()
             |> QueryFilter.from_binary()
  end

  test "from_binary and to_batch_item round trip with full fields" do
    filter = %QueryFilter{
      user_data_128: <<5678::128>>,
      user_data_64: <<1234::64>>,
      user_data_32: <<42::32>>,
      ledger: 42,
      code: 99,
      timestamp_min: 99,
      timestamp_max: 99,
      limit: 10,
      flags: %QueryFilter.Flags{reversed: true}
    }

    assert filter ==
             filter
             |> QueryFilter.to_batch_item()
             |> QueryFilter.from_binary()
  end

  test "to_batch_item/1 ignores server-controlled fields" do
    filter = %QueryFilter{
      user_data_128: <<5678::128>>,
      user_data_64: <<1234::64>>,
      user_data_32: <<42::32>>,
      ledger: 42,
      code: 99,
      timestamp_min: 99,
      timestamp_max: 99,
      limit: 10,
      flags: %QueryFilter.Flags{reversed: true}
    }

    assert %QueryFilter{} =
             filter
             |> QueryFilter.to_batch_item()
             |> QueryFilter.from_binary()
  end
end
