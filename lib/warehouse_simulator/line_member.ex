defmodule WarehouseSimulator.LineMember do
  @callback process_pick_ticket(pid, receive_at :: number, WarehouseSimulator.PickTicket) ::
              completed_at :: number
end
