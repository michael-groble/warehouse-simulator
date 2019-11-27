defmodule WarehouseSimulator.Picker do
  @moduledoc false

  use WarehouseSimulator.LineMember
  use Agent

  def start_link(parameters) do
    state = %{
      parameters: parameters,
      line_member: %WarehouseSimulator.LineMember.State{}
    }

    Agent.start_link(fn -> state end)
  end

  def process_pick_ticket(picker, receive_at, pick_ticket, current_contents \\ %{}) do
    Agent.get_and_update(
      picker,
      fn state ->
        {duration, contents} =
          pick_duration_and_contents(state[:parameters], pick_ticket, current_contents)

        process_pick_ticket_state(
          state[:line_member],
          receive_at,
          pick_ticket,
          contents,
          duration
        )
        |> now_and_state(state)
      end,
      :infinity
    )
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
