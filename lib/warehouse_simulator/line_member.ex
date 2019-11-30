defmodule WarehouseSimulator.LineMember do
  @moduledoc """
  Line Members do all the work on a line.  They act as a chain, passing work orders (pick tickets) down the line, performing
  what work they can.
  """
  alias WarehouseSimulator.{LineMember, PickTicket}

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
              pick_ticket :: PickTicket,
              current_contents :: map
            ) ::
              completed_at :: number

  @doc """
  Set the next worker on the chain.
  """
  @callback get_and_put_next_line_member(pid, next_in_line :: pid, module) :: pid | nil

  @doc """
  total number of seconds of simulation time elapsed for the member
  """
  @callback elapsed_time(pid) :: number

  @doc """
  Total number of seconds of simulation time spent idle
  """
  @callback idle_time(pid) :: number

  @doc """
  Performs the expected state update given how much work time is required and what the updated contents
  are to pass down the line.
  """
  @spec process_pick_ticket(
          %LineMember.State{},
          number,
          PickTicket,
          map,
          number
        ) :: {number, %LineMember.State{}}
  def process_pick_ticket(
        state,
        receive_at,
        pick_ticket,
        updated_contents,
        work_duration
      ) do
    state
    |> wait_idle_until(receive_at)
    |> work_for_duration(work_duration)
    |> wait_until_unblocked
    |> pass_down_line(pick_ticket, updated_contents)
    |> now_and_state
  end

  @doc """
  Updates the next in line and clears old state
  """
  @spec get_and_put_next_line_member(%LineMember.State{}, pid, module) ::
          {{pid, module}, %LineMember.State{}}
  def get_and_put_next_line_member(state, next_in_line, module) do
    {{state.next_in_line, state.next_module},
     %{state | next_in_line: next_in_line, next_module: module, blocked_until: 0.0}}
  end

  defp pass_down_line(state, pick_ticket, contents) do
    next = state.next_in_line

    if next == nil do
      state
    else
      %{
        state
        | blocked_until:
            state.next_module.process_pick_ticket(next, state.now, pick_ticket, contents)
      }
    end
  end

  defp wait_idle_until(state, time) do
    duration = time - state.now

    if duration > 0 do
      %{state | now: time} |> Map.update!(:idle_duration, &(&1 + duration))
    else
      state
    end
  end

  defp wait_until_unblocked(state) do
    wait_idle_until(state, state.blocked_until)
  end

  defp now_and_state(state) do
    {state.now, state}
  end

  defp work_for_duration(state, duration) do
    Map.update!(state, :now, &(&1 + duration))
  end
end
