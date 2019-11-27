defmodule WarehouseSimulator.LineMember.State do
  defstruct now: 0.0,
            blocked_until: 0.0,
            idle_duration: 0.0,
            next_in_line: nil,
            next_module: nil
end
