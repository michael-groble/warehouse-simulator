defmodule WarehouseSimulator.PickerTest do
  use ExUnit.Case, async: true

  doctest WarehouseSimulator.Picker

  setup do
    [
      pick_ticket: %WarehouseSimulator.PickTicket{item_picks: %{"A" => 1, "B" => 2}},
      station_parameters: %WarehouseSimulator.StationParameters{
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
      add_items(context, ["A"])
    end

    setup :start_link

    test "it returns base plus item plus quantity", context do
      assert pick(context) == 3.0
    end
  end

  describe "pick with items A and B" do
    setup context do
      add_items(context, ["A", "B"])
    end

    setup :start_link

    test "it returns base plus items plus quantities", context do
      assert pick(context) == 6.0
    end
  end

  describe "elapsed_time" do
    setup :start_link

    test "pick updates elapsed time", context do
      assert WarehouseSimulator.Picker.elapsed_time(context[:picker]) == 0.0
      pick(context)
      assert WarehouseSimulator.Picker.elapsed_time(context[:picker]) == 1.0
    end
  end

  defp pick(context) do
    WarehouseSimulator.Picker.pick(context[:picker], context[:pick_ticket])
  end

  defp start_link(context) do
    {:ok, picker} = WarehouseSimulator.Picker.start_link(context[:station_parameters])
    [picker: picker]
  end

  defp add_items(context, items) do
    params = context[:station_parameters]
    params = %{params | pickable_items: MapSet.union(params.pickable_items, MapSet.new(items))}
    [station_parameters: params]
  end
end
