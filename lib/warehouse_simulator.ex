defmodule WarehouseSimulator do
  @moduledoc """
  Documentation for WarehouseSimulator.
  """

  use Application
  require Logger
  alias WarehouseSimulator.Line

  def start(_type, _args) do
    {:ok, self()}
  end

  defmodule CLI do
    def main(args) do
      {[], [line_member_file, pick_ticket_file], []} = OptionParser.parse(args, strict: [])
      pick_tickets = File.stream!(pick_ticket_file) |> Stream.map(&line_to_picks/1)

      pickers = Line.options_from_file(line_member_file)
      {:ok, line} = Line.start_link(pickers, :line)

      times = Line.process_pick_tickets(line, pick_tickets)
      max_time = times |> Enum.map(&Map.get(&1, :elapsed)) |> Enum.max()

      IO.puts("Elapsed: #{max_time}")
      IO.puts("Idle times:")

      times
      |> Enum.each(fn times ->
        idle = times[:idle]
        percent_idle = Float.round(100.0 * idle / max_time)
        IO.puts("#{idle} (#{percent_idle}%)")
      end)
    end

    defp line_to_picks(line) do
      line
      |> String.trim()
      |> String.split("\t")
      |> Enum.map(&String.split(&1, ":"))
      |> Enum.map(fn [a, b] ->
        {count, ""} = Integer.parse(b)
        {a, count}
      end)
      |> Map.new()
      |> (&%WarehouseSimulator.PickTicket{item_picks: &1}).()
    end
  end
end
