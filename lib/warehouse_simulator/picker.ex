defmodule WarehouseSimulator.Picker do
  @moduledoc false
  @behaviour WarehouseSimulator.LineMember

  use Agent

  def start_link(parameters) do
    state = %{
      parameters: parameters,
      line_member: %WarehouseSimulator.LineMember.State{}
    }

    Agent.start_link(fn -> state end)
  end

  def get_and_put_next_line_member(picker, next_in_line, module) do
    Agent.get_and_update(picker, fn state ->
      # reset any block time from previous neighbor
      {state[:line_member].next_in_line,
       Map.update!(
         state,
         :line_member,
         &%{&1 | next_in_line: next_in_line, next_module: module, blocked_until: 0.0}
       )}
    end)
  end

  def process_pick_ticket(picker, receive_at, pick_ticket, current_contents \\ %{}) do
    Agent.get_and_update(
      picker,
      fn state ->
        {duration, contents} =
          pick_duration_and_contents(state[:parameters], pick_ticket, current_contents)

          state[:line_member]
          |> wait_idle_until(receive_at)
          |> work_for_duration(duration)
          |> wait_until_unblocked
          |> pass_down_line(pick_ticket, contents)
          |> now_and_state(state)
      end,
      :infinity
    )
  end

  def elapsed_time(picker) do
    Agent.get(picker, & &1[:line_member].now)
  end

  def idle_time(picker) do
    Agent.get(picker, & &1[:line_member].idle_duration)
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

  defp now_and_state(member_state, state) do
    {member_state.now, %{state | line_member: member_state}}
  end

  defp work_for_duration(state, duration) do
    Map.update!(state, :now, &(&1 + duration))
  end

  defp pick_duration_and_contents(parameters, pick_ticket, current_contents) do
    item_list = MapSet.to_list(parameters.pickable_items)
    picks = pick_ticket.item_picks |> Map.take(item_list)
    item_count = map_size(picks)
    pick_count = picks |> Map.values() |> Enum.sum()

    duration =
      parameters.seconds_per_pick_ticket +
        item_count * parameters.seconds_per_item +
        pick_count * parameters.seconds_per_quantity

    {duration, Map.merge(current_contents, picks)}
  end
end
