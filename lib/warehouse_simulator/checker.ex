defmodule WarehouseSimulator.Checker do
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
        process_pick_ticket_state(
          state[:line_member],
          receive_at,
          pick_ticket,
          current_contents,
          check_duration(state[:parameters], pick_ticket, current_contents)
        )
        |> now_and_state(state)
      end,
      :infinity
    )
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
