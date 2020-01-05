defmodule WarehouseSimulator.LineMember.StateTest do
  use ExUnit.Case, async: true
  alias WarehouseSimulator.LineMember.State
  alias WarehouseSimulator.PickTicket

  doctest State

  defmodule CaptureMember do
    use Agent

    def start_link do
      Agent.start_link(fn -> %{} end)
    end

    def process_pick_ticket(member, receive_at, pick_ticket, current_contents) do
      Agent.get_and_update(
        member,
        fn _ ->
          {nil,
           %{
             receive_at: receive_at,
             pick_ticket: pick_ticket,
             current_contents: current_contents
           }}
        end
      )
    end

    def request_pick_ticket(member, unblocked_at) do
      Agent.get_and_update(
        member,
        fn _ ->
          {nil,
           %{
             unblocked_at: unblocked_at
           }}
        end
      )
    end

    def state(member) do
      Agent.get(member, & &1)
    end
  end

  setup do
    [
      pick_ticket: %PickTicket{item_picks: %{"A" => 1}},
      contents: %{"A" => 1}
    ]
  end

  describe "request pick ticket" do
    setup :start_link

    test "it updates blocked_until and forwards request", context do
      state =
        context[:state]
        |> State.request_pick_ticket(1.0)

      assert state.blocked_until == 1.0
      assert CaptureMember.state(context[:previous]) == %{unblocked_at: 0.0}
      assert CaptureMember.state(context[:next]) == %{}
    end

    test "doesn't blow up with no adjacent members", context do
      %{context[:state] | previous_in_line: nil, next_in_line: nil}
      |> State.request_pick_ticket(1.0)

      assert CaptureMember.state(context[:previous]) == %{}
      assert CaptureMember.state(context[:next]) == %{}
    end

    test "replies with pick ticket when queued", context do
      %{context[:state] | queued: {context[:pick_ticket], context[:contents]}}
      |> State.request_pick_ticket(1.0)

      assert CaptureMember.state(context[:previous]) == %{unblocked_at: 1.0}

      assert CaptureMember.state(context[:next]) == %{
               receive_at: 1.0,
               pick_ticket: context[:pick_ticket],
               current_contents: context[:contents]
             }
    end
  end

  describe "process pick ticket" do
    setup :start_link

    test "it updates state", context do
      state =
        %{context[:state] | wait_for: :pick_ticket}
        |> State.process_pick_ticket(
          1.0,
          context[:pick_ticket],
          context[:contents],
          1.0
        )

      assert state.now == 2.0
      assert CaptureMember.state(context[:previous]) == %{}

      assert CaptureMember.state(context[:next]) == %{
               receive_at: 2.0,
               pick_ticket: context[:pick_ticket],
               current_contents: context[:contents]
             }
    end

    test "raises error when already queued", context do
      assert_raise RuntimeError, "wait_for is pick_ticket but we already have a pick ticket queued", fn ->
        %{context[:state] | wait_for: :pick_ticket, queued: {context[:pick_ticket], context[:contents]}}
        |> State.process_pick_ticket(
          1.0,
          context[:pick_ticket],
          context[:contents],
          1.0
        )
      end
    end

    test "raises error when waiting for request", context do
      assert_raise RuntimeError, "wait_for is request when pick_ticket is required", fn ->
        context[:state]
        |> State.process_pick_ticket(
             1.0,
             context[:pick_ticket],
             context[:contents],
             1.0
           )
      end
    end
  end

  defp start_link(_context) do
    {:ok, next} = CaptureMember.start_link()
    {:ok, previous} = CaptureMember.start_link()

    state = %State{
      previous_in_line: previous,
      previous_module: CaptureMember,
      next_in_line: next,
      next_module: CaptureMember
    }

    [state: state, next: next, previous: previous]
  end
end
