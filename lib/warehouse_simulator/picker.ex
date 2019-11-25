defmodule WarehouseSimulator.Picker do
  @moduledoc false

  use Agent

  def start_link(station_parameters) do
    state = %{
      station_parameters: station_parameters,
      elapsed_time: 0.0
    }

    Agent.start_link(fn -> state end)
  end

  def pick(picker, pick_ticket) do
    Agent.get_and_update(
      picker,
      fn state ->
        duration = pick_duration(state[:station_parameters], pick_ticket)
        new_state = Map.update!(state, :elapsed_time, &(&1 + duration))

        {duration, new_state}
      end,
      :infinity
    )
  end

  def elapsed_time(picker) do
    Agent.get(picker, & &1[:elapsed_time])
  end

  defp pick_duration(station_parameters, pick_ticket) do
    item_list = MapSet.to_list(station_parameters.pickable_items)
    picks = pick_ticket.item_picks |> Map.take(item_list)
    item_count = map_size(picks)
    pick_count = picks |> Map.values() |> Enum.sum()

    station_parameters.seconds_per_pick_ticket +
      item_count * station_parameters.seconds_per_item +
      pick_count * station_parameters.seconds_per_quantity
  end
end
