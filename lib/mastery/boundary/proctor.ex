defmodule Mastery.Boundary.Proctor do
  use GenServer

  require Logger

  alias Mastery.Boundary.{QuizManager, QuizSession}

  # ########## #
  # Public API #
  # ########## #

  def start_link(options \\ []), do:
    GenServer.start_link(__MODULE__, [], options)

  def init(quizzes), do: {:ok, quizzes}
  
  @spec schedule_quizz(module, Quiz.t, Template.t, DateTime.t, DateTime.t) :: any
  def schedule_quizz(proctor \\ __MODULE__, quiz, temps, start_at, end_at) do
    quiz = %{
      fields: quiz,
      templates: temps, 
      start_at: start_at,
      end_at: end_at
    }

    GenServer.call(proctor, {:schedule_quizz, quizz})
  end 

  # ############## #
  # Implementation #
  # ############## #

  def handle_call({:schedule_quizz, quiz }, _from, quizzes) do
    now = DateTime.utc_now
    ordered_quizzes = 
      [quiz | quizzes]
      |> start_quizzes(now)
      |> Enum.sort(fn a, b -> 
        date_time_less_than_or_equal?(a.start_at, b.start_at)
      end)

    build_reply_with_timeout({:reply, :ok}, ordered_quizzes, now)
  end
  
  defp build_reply_with_timeout(reply, quizzes, now), do:
    reply
    |> append_state(quizzes)
    |> maybe_append_timeout(quizzes, now)

  defp append_state(tuple, quizzes), do: Tuple.append(tuple, quizzes)

  defp maybe_append_timeout(tuple, [], _now), do: tuple
  
  defp maybe_append_timeout(tuple, quizzes, now) do
    timeout = 
      quizzes
      |> hd()
      |> Map.fetch!(:start_at)
      |> DateTime.diff(now, :millisecond) 

    Tuple.append(tuple, timeout)
  end

  defp start_quizzes(quizzes, now) do
  
  end

end
