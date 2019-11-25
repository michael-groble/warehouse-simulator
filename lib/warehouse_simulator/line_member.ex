defmodule WarehouseSimulator.LineMember do
  @callback process_pick_ticket(pid, WarehouseSimulator.PickTicket) :: number
end
