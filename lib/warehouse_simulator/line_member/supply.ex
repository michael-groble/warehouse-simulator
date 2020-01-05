defmodule WarehouseSimulator.LineMember.Supply do
  defstruct provide_at: 0,
            pick_ticket: %{item_picks: %{}},
            current_contents: %{}
end
