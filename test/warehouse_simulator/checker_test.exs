defmodule WarehouseSimulator.CheckerTest do
  use ExUnit.Case, async: true
  alias WarehouseSimulator.Checker
  alias WarehouseSimulator.PickTicket
  alias WarehouseSimulator.Checker.Parameters

  doctest Checker

  setup do
    [
      pick_ticket: %PickTicket{item_picks: %{"A" => 1, "B" => 2}},
      parameters: %Parameters{
        check_probability: 1.0,
        seconds_per_pick_ticket: 1.0,
        seconds_per_item: 1.0,
        seconds_per_quantity: 1.0
      }
    ]
  end

  describe "process time" do
    setup :start_link

    test "it returns times based on content", context do
      assert process(context, %{}) == 1.0
      assert process(context, %{"A" => 1}) == 4.0
      assert process(context, %{"A" => 1, "B" => 2}) == 10.0
    end
  end

  describe "check probability" do
    setup context do
      start_link(context, 0.0)
    end

    test "it takes no time", context do
      assert process(context, %{"A" => 1}) == 0.0
    end
  end

  defp process(context, contents) do
    Checker.process_pick_ticket(context[:checker], 0.0, context[:pick_ticket], contents)
  end

  defp start_link(context, probability \\ 1.0) do
    params = %{context[:parameters] | check_probability: probability}
    {:ok, checker} = Checker.start_link(params)
    [checker: checker]
  end
end
