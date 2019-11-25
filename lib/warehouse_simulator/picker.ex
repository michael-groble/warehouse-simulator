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
        params = state[:station_parameters]
        picks = Map.take(pick_ticket.item_picks, MapSet.to_list(params.pickable_items))
        item_count = map_size(picks)
        pick_count = Enum.sum(Map.values(picks))

        pick_time =
          params.seconds_per_pick_ticket +
            item_count * params.seconds_per_item +
            pick_count * params.seconds_per_quantity

        new_state = Map.update!(state, :elapsed_time, fn time -> time + pick_time end)

        {pick_time, new_state}
      end,
      :infinity
    )
  end

  def elapsed_time(picker) do
    Agent.get(picker, fn state -> state[:elapsed_time] end)
  end
end
