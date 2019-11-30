defmodule WarehouseSimulator.LineMemberTest do
  use ExUnit.Case, async: true
  alias WarehouseSimulator.LineMember
  alias WarehouseSimulator.PickTicket

  doctest LineMember

  defmodule Member do
    require LineMember
    use Agent

    def start_link do
      Agent.start_link(fn -> %{line_member: %WarehouseSimulator.LineMember.State{}} end)
    end

    def process_pick_ticket(member, receive_at, pick_ticket, current_contents) do
      Agent.get_and_update(
        member,
        fn state ->
          LineMember.process_pick_ticket(
            state[:line_member],
            receive_at,
            pick_ticket,
            Map.merge(current_contents, %{"A" => 1}),
            1.0
          )
          |> LineMember.merge_line_member_state(state)
        end
      )
    end

    def get_and_put_next_line_member(checker, next_in_line, module) do
      Agent.get_and_update(checker, fn state ->
        LineMember.get_and_put_next_line_member(state[:line_member], next_in_line, module)
        |> LineMember.merge_line_member_state(state)
      end)
    end

    def elapsed_time(checker) do
      Agent.get(checker, & &1[:line_member].now)
    end

    def idle_time(checker) do
      Agent.get(checker, & &1[:line_member].idle_duration)
    end
  end

  defmodule CaptureMember do
    require LineMember
    use Agent

    def start_link do
      Agent.start_link(fn -> %{} end)
    end

    def process_pick_ticket(member, receive_at, pick_ticket, current_contents) do
      Agent.get_and_update(
        member,
        fn _ ->
          {receive_at,
           %{
             receive_at: receive_at,
             pick_ticket: pick_ticket,
             current_contents: current_contents
           }}
        end
      )
    end

    def get_and_put_next_line_member(checker, next_in_line, module) do
      Agent.get_and_update(checker, fn state ->
        LineMember.get_and_put_next_line_member(state[:line_member], next_in_line, module)
        |> LineMember.merge_line_member_state(state)
      end)
    end

    def elapsed_time(checker) do
      Agent.get(checker, & &1[:line_member].now)
    end

    def idle_time(checker) do
      Agent.get(checker, & &1[:line_member].idle_duration)
    end

    def state(member) do
      Agent.get(member, & &1)
    end
  end

  setup do
    [
      pick_ticket: %PickTicket{item_picks: %{"A" => 1, "B" => 2}}
    ]
  end

  describe "elapsed_time" do
    setup :start_link

    test "pick updates elapsed time with delays", context do
      assert Member.elapsed_time(context[:member]) == 0.0
      pick(context)
      assert Member.elapsed_time(context[:member]) == 1.0
      assert Member.idle_time(context[:member]) == 0.0
      pick(context, 2.0)
      # two seconds of work + 1 second of idle
      assert Member.elapsed_time(context[:member]) == 3.0
      assert Member.idle_time(context[:member]) == 1.0
    end
  end

  describe "with downstream picker" do
    setup :start_link

    test "it invokes next in line with valid time and current_contents", context do
      {:ok, other} = CaptureMember.start_link()
      Member.get_and_put_next_line_member(context[:member], other, CaptureMember)
      pick(context)
      received = CaptureMember.state(other)
      assert received[:receive_at] == 1.0
      assert received[:current_contents] == %{"A" => 1}
    end
  end

  defp pick(context, at \\ 0.0) do
    Member.process_pick_ticket(context[:member], at, context[:pick_ticket], %{})
  end

  defp start_link(_context) do
    {:ok, member} = Member.start_link()
    [member: member]
  end
end
