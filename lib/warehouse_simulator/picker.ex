defmodule WarehouseSimulator.Picker do
  @moduledoc """
  A Picker is responsible for fulfilling a subset of possible items requested in the pick ticket.  They fulfill what they
  can and pass it down the line.
  """

  use WarehouseSimulator.GenServerLineMember

  def start_link(parameters) do
    GenServer.start_link(__MODULE__, parameters)
  end

  def init(parameters) do
    state = %{
      parameters: Map.update!(parameters, :pickable_items, &Enum.uniq/1),
      line_member: %LineMember.State{}
    }

    {:ok, state}
  end

  def handle_call({:process_pick_ticket, receive_at, pick_ticket, current_contents}, _from, state) do
    {duration, contents} =
      pick_duration_and_contents(state[:parameters], pick_ticket, current_contents)

    LineMember.State.process_pick_ticket(
      state[:line_member],
      receive_at,
      pick_ticket,
      contents,
      duration
    )
    |> LineMember.State.line_member_reply(state)
  end

  defp pick_duration_and_contents(parameters, pick_ticket, current_contents) do
    picks = pick_ticket.item_picks |> Map.take(parameters.pickable_items)
    item_count = map_size(picks)
    pick_count = picks |> Map.values() |> Enum.sum()

    duration =
      parameters.seconds_per_pick_ticket +
        item_count * parameters.seconds_per_item +
        pick_count * parameters.seconds_per_quantity

    {duration, Map.merge(current_contents, picks)}
  end
end
