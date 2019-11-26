defmodule WarehouseSimulator.Picker do
  @moduledoc false
  @behaviour WarehouseSimulator.LineMember

  use Agent

  def start_link(parameters) do
    state = %{
      parameters: parameters,
      now: 0.0,
      blocked_until: 0.0,
      idle_duration: 0.0,
      next_in_line: nil
    }

    Agent.start_link(fn -> state end)
  end

  def get_and_put_next_line_member(picker, next_in_line) do
    Agent.get_and_update(picker, fn state ->
      # reset any block time from previous neighbor
      {state[:next_in_line], %{state | next_in_line: next_in_line, blocked_until: 0.0}}
    end)
  end

  def process_pick_ticket(picker, receive_at, pick_ticket) do
    Agent.get_and_update(
      picker,
      fn state ->
        duration = pick_duration(state[:parameters], pick_ticket)

        state
        |> wait_idle_until(receive_at)
        |> work_for_duration(duration)
        |> wait_until_unblocked
        |> pass_down_line(pick_ticket)
        |> now_and_state
      end,
      :infinity
    )
  end

  def elapsed_time(picker) do
    Agent.get(picker, & &1[:now])
  end

  def idle_time(picker) do
    Agent.get(picker, & &1[:idle_duration])
  end

  defp pass_down_line(state, pick_ticket) do
    next = state[:next_in_line]

    if state[:next_in_line] == nil do
      state
    else
      %{state | blocked_until: process_pick_ticket(next, state[:now], pick_ticket)}
    end
  end

  defp wait_idle_until(state, time) do
    duration = time - state[:now]

    if duration > 0 do
      %{state | now: time} |> Map.update!(:idle_duration, &(&1 + duration))
    else
      state
    end
  end

  defp wait_until_unblocked(state) do
    wait_idle_until(state, state[:blocked_until])
  end

  defp now_and_state(state) do
    {state[:now], state}
  end

  defp work_for_duration(state, duration) do
    Map.update!(state, :now, &(&1 + duration))
  end

  defp pick_duration(parameters, pick_ticket) do
    item_list = MapSet.to_list(parameters.pickable_items)
    picks = pick_ticket.item_picks |> Map.take(item_list)
    item_count = map_size(picks)
    pick_count = picks |> Map.values() |> Enum.sum()

    parameters.seconds_per_pick_ticket +
      item_count * parameters.seconds_per_item +
      pick_count * parameters.seconds_per_quantity
  end
end
