defmodule WarehouseSimulator.LineMember do
  @callback process_pick_ticket(pid, receive_at :: number, WarehouseSimulator.PickTicket) ::
              completed_at :: number
  @callback get_and_put_next_line_member(pid, next_in_line :: pid) :: pid | nil
end
