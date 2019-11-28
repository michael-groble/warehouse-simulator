defmodule WarehouseSimulator.PickerTest do
  use ExUnit.Case, async: true
  alias WarehouseSimulator.Picker
  alias WarehouseSimulator.PickTicket
  alias WarehouseSimulator.Picker.Parameters

  doctest Picker

  setup do
    [
      pick_ticket: %PickTicket{item_picks: %{"A" => 1, "B" => 2}},
      station_parameters: %Parameters{
        pickable_items: %MapSet{},
        seconds_per_pick_ticket: 1.0,
        seconds_per_item: 1.0,
        seconds_per_quantity: 1.0
      }
    ]
  end

  describe "pick with no assigned stations" do
    setup :start_link

    test "it returns the base time", context do
      assert pick(context) == 1.0
    end
  end

  describe "pick with item A" do
    setup context do
      start_link(context, ["A"])
    end

    test "it returns base plus item plus quantity", context do
      assert pick(context) == 3.0
    end
  end

  describe "pick with items A and B" do
    setup context do
      start_link(context, ["A", "B"])
    end

    test "it returns base plus items plus quantities", context do
      assert pick(context) == 6.0
    end
  end

  describe "with downstream picker" do
    setup context do
      start_link(context, ["A"])
    end

    test "passes tickets along and accumulates time", context do
      [picker: other] = start_link(context, ["B"])
      Picker.get_and_put_next_line_member(context[:picker], other, Picker)
      t = pick(context, 0)
      t = pick(context, t)
      pick(context, t)
      # time      1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
      # picker 1: a a a|b b b -|c c c -|
      # picker 2: - - - a a a a|b b b b|c c c c
      assert Picker.elapsed_time(other) == 15.0
      assert Picker.idle_time(other) == 3.0
      assert Picker.elapsed_time(context[:picker]) == 11.0
      assert Picker.idle_time(context[:picker]) == 2.0
    end
  end

  defp pick(context, at \\ 0.0) do
    Picker.process_pick_ticket(context[:picker], at, context[:pick_ticket])
  end

  defp start_link(context, items \\ []) do
    params = %{context[:station_parameters] | pickable_items: items}
    {:ok, picker} = Picker.start_link(params)
    [picker: picker]
  end
end
