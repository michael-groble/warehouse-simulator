defmodule WarehouseSimulator.LineMember do
  @moduledoc """
  Line Members do all the work on a line.  They act as a chain, passing work orders (pick tickets) down the line, performing
  what work they can.
  """
  alias WarehouseSimulator.PickTicket

  @doc """
  Perform the work required, then pass down the line.

    * `receive_at` represents time in the simulation that the pick ticket arrives to the member
    * `pick_ticket` desired context
    * `current_contents` items picks that have already been added by previous members
  """
  @callback process_pick_ticket(
              pid,
              receive_at :: number,
              pick_ticket :: PickTicket,
              current_contents :: map
            ) :: nil

  @doc """
  Request the next pick ticket

    * `unblocked_at` represents time in the simulation that the member can process the requested ticket

    Returns: supplied pick ticket
  """
  @callback request_pick_ticket(
              pid,
              unblocked_at :: number
            ) :: nil

  @doc """
  Set the next worker on the chain.
  """
  @callback get_and_put_next_line_member(pid, next_in_line :: pid, module) :: pid | nil

  @doc """
  Set the previous worker on the chain.
  """
  @callback get_and_put_previous_line_member(pid, previous_in_line :: pid, module) :: pid | nil
  @doc """
  total number of seconds of simulation time elapsed for the member
  """
  @callback elapsed_time(pid) :: number

  @doc """
  Total number of seconds of simulation time spent idle
  """
  @callback idle_time(pid) :: number
end
