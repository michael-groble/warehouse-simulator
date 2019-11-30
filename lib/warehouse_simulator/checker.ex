defmodule WarehouseSimulator.Checker do
  @moduledoc """
  A Checker performs random quality checks on the current contents.

  Currently, there are no simulated "failures" in which the ticket needs to be sent back upstream or otherwise
  corrected.  All tickets are passed downstream after the check.
  """

  use WarehouseSimulator.LineMember
  use Agent

  def start_link(parameters) do
    state = %{
      parameters: parameters,
      line_member: %WarehouseSimulator.LineMember.State{}
    }

    Agent.start_link(fn -> state end)
  end

  def get_and_put_next_line_member(checker, next_in_line, module) do
    Agent.get_and_update(checker, fn state ->
      get_and_put_next_line_member_state(state[:line_member], next_in_line, module)
      |> merge_line_member_state(state)
    end)
  end

  def process_pick_ticket(checker, receive_at, pick_ticket, current_contents \\ %{}) do
    Agent.get_and_update(
      checker,
      fn state ->
        process_pick_ticket_state(
          state[:line_member],
          receive_at,
          pick_ticket,
          current_contents,
          check_duration(state[:parameters], pick_ticket, current_contents)
        )
        |> merge_line_member_state(state)
      end,
      :infinity
    )
  end

  def elapsed_time(checker) do
    Agent.get(checker, & &1[:line_member].now)
  end

  def idle_time(checker) do
    Agent.get(checker, & &1[:line_member].idle_duration)
  end

  defp check_duration(parameters, _pick_ticket, contents) do
    if :rand.uniform() >= parameters.check_probability do
      0.0
    else
      item_count = map_size(contents)
      pick_count = contents |> Map.values() |> Enum.sum()

      parameters.seconds_per_pick_ticket +
        item_count * parameters.seconds_per_item +
        pick_count * parameters.seconds_per_quantity
    end
  end

  defp merge_line_member_state({value, member_state}, state) do
    {value, %{state | line_member: member_state}}
  end
end
