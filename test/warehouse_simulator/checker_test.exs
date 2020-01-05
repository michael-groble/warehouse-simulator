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
      process(context, %{})
      assert Checker.elapsed_time(context[:checker]) == 1.0
      process(context, %{"A" => 1})
      assert Checker.elapsed_time(context[:checker]) == 4.0
      process(context, %{"A" => 1, "B" => 2})
      assert Checker.elapsed_time(context[:checker]) == 10.0
    end
  end

  describe "check probability" do
    setup context do
      start_link(context, 0.0)
    end

    test "it takes no time", context do
      process(context, %{"A" => 1})
      assert Checker.elapsed_time(context[:checker]) == 0.0
    end
  end

  defp process(context, contents) do
    Checker.request_pick_ticket(context[:checker], 0.0)
    Checker.process_pick_ticket(context[:checker], 0.0, context[:pick_ticket], contents)
  end

  defp start_link(context, probability \\ 1.0) do
    params = %{context[:parameters] | check_probability: probability}
    {:ok, checker} = Checker.start_link(params)
    [checker: checker]
  end
end
