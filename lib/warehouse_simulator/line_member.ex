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

  @doc """
  total number of seconds of simulation time elapsed for the member
  """
  @callback elapsed_time(pid) :: number

  @doc """
  Total number of seconds of simulation time spent idle
  """
  @callback idle_time(pid) :: number

  @doc """
  Default implementation to manipulate `WarehouseSimulator.LineMember.State`

  provides `process_pick_ticket_state` and `now_and_state` that will do the expected state update given how much
  work time is required and what the updated contents are to pass down the line.  For example:

      def process_pick_ticket(member, receive_at, pick_ticket, current_contents) do
        Agent.get_and_update(
          member,
          fn state ->
            {duration, contents} =
              pick_duration_and_contents(state, pick_ticket, current_contents)

            process_pick_ticket_state(
              state[:line_member],
              receive_at,
              pick_ticket,
              contents,
              duration
            )
            |> now_and_state(state)
          end
        )
      end
  """
  defmacro __using__(_) do
    quote do
      @behaviour WarehouseSimulator.LineMember

      @spec process_pick_ticket_state(
              %WarehouseSimulator.LineMember.State{},
              number,
              WarehouseSimulator.PickTicket,
              map,
              number
            ) :: {number, %WarehouseSimulator.LineMember.State{}}
      defp process_pick_ticket_state(
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

      defp get_and_put_next_line_member_state(state, next_in_line, module) do
        {state.next_in_line,
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
  end
end
