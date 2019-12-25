defmodule WarehouseSimulator.Checker do
  @moduledoc """
  A Checker performs random quality checks on the current contents.

  Currently, there are no simulated "failures" in which the ticket needs to be sent back upstream or otherwise
  corrected.  All tickets are passed downstream after the check.
  """

  require WarehouseSimulator.LineMember
  alias WarehouseSimulator.LineMember
  use GenServer

  def start_link(parameters) do
    GenServer.start_link(__MODULE__, parameters)
  end

  def init(parameters) do
    state = %{
      parameters: parameters,
      line_member: %LineMember.State{}
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
    LineMember.process_pick_ticket(
      state[:line_member],
      receive_at,
      pick_ticket,
      current_contents,
      check_duration(state[:parameters], pick_ticket, current_contents)
    )
    |> LineMember.line_member_reply(state)
  end

  def handle_call({:get_and_put_next_line_member, next_in_line, module}, _from, state) do
    LineMember.get_and_put_next_line_member(state[:line_member], next_in_line, module)
    |> LineMember.line_member_reply(state)
  end

  def handle_call({:elapsed_time}, _from, state) do
    {:reply, state[:line_member].now, state}
  end

  def handle_call({:idle_time}, _from, state) do
    {:reply, state[:line_member].idle_duration, state}
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
end
