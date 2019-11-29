defmodule WarehouseSimulator.LineTest do
  use ExUnit.Case, async: true

  alias WarehouseSimulator.Line
  alias WarehouseSimulator.Picker
  alias WarehouseSimulator.Checker
  alias WarehouseSimulator.PickTicket

  doctest Line

  describe "options_from_file" do
    options = Line.options_from_file("test/fixtures/simple_line.json")
    {{module, [params]}, options} = List.pop_at(options, 0)
    assert module == Picker
    assert params.pickable_items == ["A", "B"]
    {{module, [params]}, options} = List.pop_at(options, 0)
    assert module == Picker
    assert params.pickable_items == ["C", "D"]
    {{module, [params]}, options} = List.pop_at(options, 0)
    assert module == Checker
    assert params.check_probability == 0.25
    assert params.seconds_per_pick_ticket == 2.0
    assert length(options) == 0
  end

  describe "process_pick_tickets" do
    # do the same thing as the Picker test "passes tickets along and accumulates time"
    members = [
      {Picker, %Picker.Parameters{pickable_items: ["A"], seconds_per_quantity: 1.0}},
      {Picker, %Picker.Parameters{pickable_items: ["B"], seconds_per_quantity: 1.0}}
    ]

    pick_tickets = for _ <- 1..3, do: %PickTicket{item_picks: %{"A" => 1, "B" => 2}}

    {:ok, line} = Line.start_link(members, :line)
    times = Line.process_pick_tickets(line, pick_tickets)
    assert times == [%{elapsed: 11.0, idle: 2.0}, %{elapsed: 15.0, idle: 3.0}]
  end
end
