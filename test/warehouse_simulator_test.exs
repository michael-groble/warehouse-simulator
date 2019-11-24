defmodule WarehouseSimulatorTest do
  use ExUnit.Case
  doctest WarehouseSimulator

  test "greets the world" do
    assert WarehouseSimulator.hello() == :world
  end
end
