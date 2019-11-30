defmodule WarehouseSimulator.Picker do
  @moduledoc """
  A Picker is responsible for fulfilling a subset of possible items requested in the pick ticket.  They fulfill what they
  can and pass it down the line.
  """

  use WarehouseSimulator.LineMember
  use GenServer

  def start_link(parameters) do
    GenServer.start_link(__MODULE__, parameters)
  end

  def init(parameters) do
    state = %{
      parameters: Map.update!(parameters, :pickable_items, &Enum.uniq/1),
      line_member: %WarehouseSimulator.LineMember.State{}
    }

    {:ok, state}
  end

  def process_pick_ticket(picker, receive_at, pick_ticket, current_contents \\ %{}) do
    GenServer.call(picker, {:process_pick_ticket, receive_at, pick_ticket, current_contents})
  end

  def get_and_put_next_line_member(member, next_in_line, module) do
    GenServer.call(member, {:get_and_put_next_line_member, next_in_line, module})
  end

  def elapsed_time(member) do
    GenServer.call(member, {:elapsed_time})
  end

  def idle_time(member) do
    GenServer.call(member, {:idle_time})
  end

  def handle_call({:process_pick_ticket, receive_at, pick_ticket, current_contents}, _from, state) do
    {duration, contents} =
      pick_duration_and_contents(state[:parameters], pick_ticket, current_contents)

    process_pick_ticket_state(
      state[:line_member],
      receive_at,
      pick_ticket,
      contents,
      duration
    )
    |> reply(state)
  end

  def handle_call({:get_and_put_next_line_member, next_in_line, module}, _from, state) do
    get_and_put_next_line_member_state(state[:line_member], next_in_line, module)
    |> reply(state)
  end

  def handle_call({:elapsed_time}, _from, state) do
    {:reply, state[:line_member].now, state}
  end

  def handle_call({:idle_time}, _from, state) do
    {:reply, state[:line_member].idle_duration, state}
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

  defp reply({value, member_state}, state) do
    {:reply, value, %{state | line_member: member_state}}
  end
end
