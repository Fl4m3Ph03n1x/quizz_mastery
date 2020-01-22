defmodule Mastery.Boundary.Proctor do
  use GenServer

  require Logger

  alias Mastery.Boundary.{QuizManager, QuizSession}

  @type quiz_info :: %{
    fields: map, 
    templates: [keyword], 
    start_at: DateTime.t, 
    end_at: DateTime.t
  }

  ################
  # Public API   #
  ################
  
  @spec start_link(keyword) :: GenServer.on_start
  def start_link(options \\ []), do:
    GenServer.start_link(__MODULE__, [], options)
  
  @spec schedule_quiz(module, map, [keyword], DateTime.t, DateTime.t) :: :ok
  def schedule_quiz(proctor \\ __MODULE__, quiz, temps, start_at, end_at) do
    quiz = %{
      fields: quiz,
      templates: temps, 
      start_at: start_at,
      end_at: end_at
    }

    GenServer.call(proctor, {:schedule_quiz, quiz})
  end

  ##############
  # Callbacks  #
  ##############

  @impl GenServer
  def init(quizzes), do: {:ok, quizzes}

  @impl GenServer
  def handle_call({:schedule_quiz, quiz }, _from, quizzes) do
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
    remaining_quizzes = start_quizzes(quizzes, now)
    build_reply_with_timeout({:noreply}, remaining_quizzes, now)
  end

  @impl GenServer
  def handle_info({:end_quiz, title}, quizzes) do
    QuizManager.remove_quiz(title)

    title
    |> QuizSession.active_sessions_for()
    |> QuizSession.end_sessions()

    Logger.info("Stopped quiz #{title}.")
    handle_info(:timeout, quizzes)
  end

  #################
  # Aux functions #
  #################

  @spec build_reply_with_timeout(tuple, [quiz_info], DateTime.t) :: tuple
  defp build_reply_with_timeout(reply, quizzes, now), do:
    reply
    |> append_state(quizzes)
    |> maybe_append_timeout(quizzes, now)

  @spec append_state(tuple, [quiz_info]) :: tuple
  defp append_state(tuple, quizzes), do: Tuple.append(tuple, quizzes)

  @spec maybe_append_timeout(tuple, [quiz_info], DateTime.t) :: tuple
  defp maybe_append_timeout(tuple, [], _now), do: tuple
  
  defp maybe_append_timeout(tuple, quizzes, now) do
    timeout = 
      quizzes
      |> hd()
      |> Map.fetch!(:start_at)
      |> DateTime.diff(now, :millisecond) 

    Tuple.append(tuple, timeout)
  end
  
  @spec start_quizzes([quiz_info], DateTime.t) :: [quiz_info]
  defp start_quizzes(quizzes, now) do
    {ready, not_ready} = Enum.split_while(quizzes, fn quiz -> 
      date_time_less_than_or_equal?(quiz.start_at, now)
    end)

    Enum.each(ready, &start_quiz(&1, now))
    not_ready
  end

  @spec start_quiz(quiz_info, DateTime.t) :: reference
  defp start_quiz(quiz, now) do
    IO.puts("QUIZ_INFO NOT ATOM: #{inspect quiz}")
    Logger.info("starting quiz #{quiz.fields.title}...")
    QuizManager.build_quiz(quiz.fields)
    Enum.each(quiz.templates, &add_template(quiz, &1))
  
    timeout = 
      quiz.end_at
      |> DateTime.diff(now, :millisecond)
      |> time_to_finish()

    Process.send_after(self(), {:end_quiz, quiz.fields.title}, timeout)
  end

  @spec time_to_finish(integer) :: non_neg_integer
  defp time_to_finish(timediff) when timediff >= 0, do: timediff
  defp time_to_finish(_negative_timediff), do: 0

  @spec date_time_less_than_or_equal?(DateTime.t, DateTime.t) :: boolean
  defp date_time_less_than_or_equal?(a, b), do: 
    DateTime.compare(a, b) in ~w[lt eq]a
  
  @spec add_template(quiz_info, keyword) :: :ok
  defp add_template(quiz, template_fields), do:
    QuizManager.add_template(quiz.fields.title, template_fields)

end
