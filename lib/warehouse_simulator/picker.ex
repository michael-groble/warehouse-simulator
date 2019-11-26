defmodule WarehouseSimulator.Picker do
  @moduledoc false
  @behaviour WarehouseSimulator.LineMember

  use Agent

  def start_link(parameters) do
    state = %{
      parameters: parameters,
      now: 0.0,
      idle_duration: 0.0
    }

    Agent.start_link(fn -> state end)
  end

  def process_pick_ticket(picker, receive_at, pick_ticket) do
    Agent.get_and_update(
      picker,
      fn state ->
        duration = pick_duration(state[:parameters], pick_ticket)
        new_state = state |> wait_idle_until(receive_at) |> work_for_duration(duration)

        {duration, new_state}
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

  defp wait_idle_until(state, time) do
    duration = time - state[:now]

    if duration > 0 do
      %{state | now: time} |> Map.update!(:idle_duration, &(&1 + duration))
    else
      state
    end
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
