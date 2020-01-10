defmodule Mastery.Boundary.Proctor do
  use GenServer

  require Logger

  alias Mastery.Boundary.{QuizManager, QuizSession}

  ################
  # Public API   #
  ################

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

  def start_quiz(quiz, now) do
    Logger.info("starting quiz #{quiz.fields.title}...")
    QuizManager.build_quiz(quiz.fields)
    Enum.each(quiz.templates, &add_template(quiz, &1))

    timeout = DateTime.diff(quiz.end_at, now, :millisecond)
    Process.send_after(self(), {:end_quiz, quiz.fields.title}, timeout)
  end

  ###################
  # Implementation  #
  ###################

  @impl GenServer
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

  @impl GenServer
  def handle_info(:timeout, quizzes) do
    now = DateTime.utc_now()
    reamaining_quizzes = start_quizzes(quizzes, now)
    build_reply_with_timeout({:noreply}, remaining_quizzes, now)
  end

  @impl GenServer
  def handle_info({:end_quiz, title}, quizzes) do
    QuizManager.remove_quiz(title)

    title
    |> QuizSession.active_sessions_s_for()
    |> QuizSession.end_sessions()

    Logger.info("Stopped quiz #{title}.")
    handle_info(:timeout, quizzes)
  end

  #################
  # Aux functions #
  #################

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
  
  @spec start_quizzes([Quiz.t], DateTime.t) :: [Quiz.t]
  defp start_quizzes(quizzes, now) do
    {ready, not_ready} = Enum.split_while(quizzes, fn quiz -> 
      date_time_less_than_or_equal?(quiz.start_at, now)
    end)

    Enum.each(ready, fn quiz -> start_quiz(quiz, now) end)
    not_ready
  end

  @spec date_time_less_than_or_equal?(DateTime.t, DateTime.t) :: boolean
  defp date_time_less_than_or_equal?(a, b), do: 
    DateTime.compare(a, b) in ~w[lt eq]a

end
