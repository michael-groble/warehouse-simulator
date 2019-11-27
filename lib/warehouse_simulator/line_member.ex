defmodule WarehouseSimulator.LineMember do
  @moduledoc """
  Line Members do all the work on a line.  They act as a chain, passing work orders (pick tickets) down the line, performing
  what work they can.
  """

  @doc """
  Perform the work required, then pass down the line.

    * `receive_at` represents time in the simulation that the pick ticket arrives to the member
    * `pick_ticket` desired context
    * `current_contents` items picks that have already been added by previous members

    Returns: simulation time when ready to accept the next work item
  """
  @callback process_pick_ticket(
              pid,
              receive_at :: number,
              pick_ticket :: WarehouseSimulator.PickTicket,
              current_contents :: map
            ) ::
              completed_at :: number

  @doc """
  Set the next worker on the chain.
  """
  @callback get_and_put_next_line_member(pid, next_in_line :: pid, module) :: pid | nil
end
