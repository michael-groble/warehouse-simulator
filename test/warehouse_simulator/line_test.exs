defmodule WarehouseSimulator.LineTest do
  use ExUnit.Case, async: true

  alias WarehouseSimulator.Line
  alias WarehouseSimulator.Picker
  alias WarehouseSimulator.Checker

  doctest Line

  describe "options_from_file" do
    options = Line.options_from_file("test/fixtures/simple_line.json")
    {%{id: id, start: {module, _init, [params | _]}}, options} = List.pop_at(options, 0)
    assert id == 0
    assert module == Picker
    assert params.pickable_items == ["A", "B"]
    {%{id: id, start: {module, _init, [params | _]}}, options} = List.pop_at(options, 0)
    assert id == 1
    assert module == Picker
    assert params.pickable_items == ["C", "D"]
    {%{id: id, start: {module, _init, [params | _]}}, options} = List.pop_at(options, 0)
    assert id == 2
    assert module == Checker
    assert params.check_probability == 0.25
    assert params.seconds_per_pick_ticket == 2.0
    assert length(options) == 0
  end
end
