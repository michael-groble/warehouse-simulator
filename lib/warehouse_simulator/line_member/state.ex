defmodule WarehouseSimulator.LineMember.State do
  alias WarehouseSimulator.{LineMember, PickTicket}

  defstruct now: 0.0,
            blocked_until: 0.0,
            idle_duration: 0.0,
            previous_in_line: nil,
            previous_module: nil,
            next_in_line: nil,
            next_module: nil,
            wait_for: :request,
            queued: nil

  @doc """
  Performs the expected state update given how much work time is required and what the updated contents
  are to pass down the line.
  """
  @spec process_pick_ticket(
          %LineMember.State{},
          number,
          PickTicket,
          map,
          number
        ) :: %LineMember.State{}
  def process_pick_ticket(
        state,
        receive_at,
        pick_ticket,
        updated_contents,
        work_duration
      ) do
    state
    |> require_wait_state(:pick_ticket)
    |> wait_idle_until(receive_at)
    |> work_for_duration(work_duration)
    |> wait_until_unblocked
    |> pass_down_line(pick_ticket, updated_contents)
  end

  @spec request_pick_ticket(%LineMember.State{}, number) :: %LineMember.State{}
  def request_pick_ticket(
        state,
        unblocked_at
      ) do
    %{state | blocked_until: unblocked_at}
    |> require_wait_state(:request)
    |> wait_and_reply_if_queued
    |> forward_request
  end

  @doc """
  Updates the previous in line
  """
  @spec get_and_put_previous_line_member(%LineMember.State{}, pid, module) ::
          {{pid, module}, %LineMember.State{}}
  def get_and_put_previous_line_member(state, previous_in_line, module) do
    {{state.previous_in_line, state.previous_module},
     %{state | previous_in_line: previous_in_line, previous_module: module}}
  end

  @doc """
  Updates the next in line and clears old state
  """
  @spec get_and_put_next_line_member(%LineMember.State{}, pid, module) ::
          {{pid, module}, %LineMember.State{}}
  def get_and_put_next_line_member(state, next_in_line, module) do
    {{state.next_in_line, state.next_module},
     %{state | next_in_line: next_in_line, next_module: module, blocked_until: 0.0}}
  end

  def merge_line_member_state({value, member_state}, state, key \\ :line_member) do
    {value, Map.put(state, key, member_state)}
  end

  def line_member_reply(member_state, state, key \\ :line_member) do
    case member_state do
      {value, member} ->  {:reply, value, Map.put(state, key, member)}
      _ -> {:reply, nil, Map.put(state, key, member_state)}
    end

  end

  defp pass_down_line(state, pick_ticket, contents) do
    next = state.next_in_line

    if next != nil do
      state.next_module.process_pick_ticket(next, state.now, pick_ticket, contents)
    end
    %{state | wait_for: :request}
  end

  defp wait_and_reply_if_queued(state) do
    if state.queued == nil do
      state
    else
      {pick_ticket, updated_contents} = state.queued

      state
      |> wait_until_unblocked
      |> pass_down_line(pick_ticket, updated_contents)
    end
  end

  defp forward_request(state) do
    previous = state.previous_in_line

    if previous != nil do
      state.previous_module.request_pick_ticket(previous, state.now)
    end

    %{state | wait_for: :pick_ticket}
  end

  defp wait_idle_until(state, time) do
    duration = time - state.now

    if duration > 0 do
      %{state | now: time} |> Map.update!(:idle_duration, &(&1 + duration))
    else
      state
    end
  end

  defp wait_until_unblocked(state) do
    wait_idle_until(state, state.blocked_until)
  end

  defp work_for_duration(state, duration) do
    Map.update!(state, :now, &(&1 + duration))
  end

  defp require_wait_state(state, expected) do
    if state.wait_for != expected do
      raise "wait_for is #{state.wait_for} when #{expected} is required"
    end

    if expected == :pick_ticket && state.queued != nil do
      raise "wait_for is #{expected} but we already have a pick ticket queued"
    end

    state
  end
end
