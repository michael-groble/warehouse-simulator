defmodule WarehouseSimulator.Line do
  @moduledoc """
  A Line is the fundamental simulation unit in the warehouse.  It consists of a sequence of line members along which
  pick tickets are passed.
  """

  alias WarehouseSimulator.Picker
  alias WarehouseSimulator.Checker

  def options_from_file(filename) do
    ~w(members type parameters) |> Enum.each(&String.to_atom/1)

    with {:ok, body} <- File.read(filename),
         {:ok, json} <- Jason.decode(body, keys: :atoms!) do
      json[:members]
      |> Enum.with_index()
      |> Enum.map(fn {member_spec, i} ->
        module =
          case member_spec[:type] do
            "Picker" -> Picker
            "Checker" -> Checker
          end

        %{
          id: i,
          start:
            {module, :start_link,
             [struct(Module.concat(module, Parameters), member_spec[:parameters])]}
        }
      end)
    end
  end
end
