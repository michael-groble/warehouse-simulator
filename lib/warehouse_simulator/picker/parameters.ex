defmodule WarehouseSimulator.Picker.Parameters do
  defstruct pickable_items: [],
            seconds_per_pick_ticket: 1.0,
            seconds_per_item: 1.0,
            seconds_per_quantity: 0.0
end
