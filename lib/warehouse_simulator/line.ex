defmodule WarehouseSimulator.Line do
  @moduledoc """
  A Line is the fundamental simulation unit in the warehouse.  It consists of a sequence of line members along which
  pick tickets are passed.
  """

  alias WarehouseSimulator.Picker
  alias WarehouseSimulator.Checker

  @doc """
  Constructs a list of `{module, [args]}` tuples from the specified file that can then be passed to `@start_link/1`:

      members = Line.options_from_file("line.json")
      Line.start_link(members, line_name)
  """
  def options_from_file(filename) do
    ~w(members type parameters) |> Enum.each(&String.to_atom/1)

    with {:ok, body} <- File.read(filename),
         {:ok, json} <- Jason.decode(body, keys: :atoms!) do
      Enum.map(json[:members], fn member_spec ->
        module =
          case member_spec[:type] do
            "Picker" -> Picker
            "Checker" -> Checker
          end

        {module, [struct(Module.concat(module, Parameters), member_spec[:parameters])]}
      end)
    end
  end

  def start_link(members, name) do
    result = Supervisor.start_link(__MODULE__, members, name: name)

    with {:ok, pid} <- result do
      link_children(pid)
    end

    result
  end

  def process_pick_tickets(line, pick_tickets) do
    {member, module} = first_member(line)

    Enum.reduce(pick_tickets, 0, fn pick_ticket, time ->
      module.process_pick_ticket(member, time, pick_ticket, %{})
    end)

    times(line)
  end

  defp times(line) do
    ordered_members(line)
    |> Enum.map(fn {member, module} ->
      %{elapsed: module.elapsed_time(member), idle: module.idle_time(member)}
    end)
  end

  def init(members) do
    children =
      members
      |> Enum.with_index()
      |> Enum.map(fn {member, i} ->
        Supervisor.child_spec(member, id: i)
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp link_children(line) do
    ordered_members(line)
    |> List.foldr(nil, fn current, next ->
      with {pid, module} <- current,
           {next_pid, next_module} <- next do
        module.get_and_put_next_line_member(pid, next_pid, next_module)
      end

      current
    end)
  end

  # children ordered by `id` as `{pid, module}` tuples
  defp ordered_members(line) do
    Supervisor.which_children(line)
    |> Enum.sort_by(&child_id/1)
    |> Enum.map(&child_pid_and_module/1)
  end

  defp child_id(child) do
    with {id, _, _, _} <- child, do: id
  end

  defp child_pid_and_module(child) do
    with {_, pid, _, [module | _]} <- child, do: {pid, module}
  end

  defp first_member(line) do
    Supervisor.which_children(line)
    |> Enum.min_by(&child_id/1)
    |> child_pid_and_module
  end
end
