defmodule WarehouseSimulator.Checker.Parameters do
  defstruct check_probability: 1.0,
            seconds_per_pick_ticket: 1.0,
            seconds_per_item: 1.0,
            seconds_per_quantity: 0.0
end
