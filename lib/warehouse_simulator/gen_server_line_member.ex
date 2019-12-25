defmodule WarehouseSimulator.GenServerLineMember do
  defmacro __using__(_) do

    quote do
      alias WarehouseSimulator.LineMember
      @behaviour LineMember
      use GenServer

      def process_pick_ticket(member, receive_at, pick_ticket, current_contents \\ %{}) do
        GenServer.call(member, {:process_pick_ticket, receive_at, pick_ticket, current_contents})
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
    end
  end
end
