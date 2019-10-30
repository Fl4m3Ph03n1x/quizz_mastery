defmodule Mastery.Boundary.QuizSession do

  use GenServer

  alias Mastery.Core.{Quiz, Response}

  @type state :: {Quiz.t, String.t}

  ##############
  # Public API #
  ##############

  @spec select_question(pid) :: String.t
  def select_question(session), do:
    GenServer.call(session, :select_question)

  @spec answer_question(pid, String.t) :: :finished | {String.t, boolean}
  def answer_question(session, answer), do:
    GenServer.call(session, {:answer_question, answer})

  ############################
  # Callback implementations #
  ############################

  @impl GenServer
  @spec init(state) :: {:ok, state}
  def init({quiz, email}), do: {:ok, {quiz, email}}

  @impl GenServer
  def handle_call(:select_question, _from, {quiz, email}) do
    quiz = Quiz.select_question(quiz)
    {:reply, quiz.current_question.asked, {quiz, email}}
  end

  def handle_call({:answer_question, answer}, _from, {quiz, email}) do
    quiz
    |> Quiz.answer_question(Response.new(quiz, email, answer))
    |> Quiz.select_question()
    |> maybe_finish(email)
  end

  @spec maybe_finish(Quiz.t | nil, String.t) ::
    {:stop, :normal, :finished, nil}
    | {:reply, {String.t, boolean}, state}
  defp maybe_finish(nil, _email), do: {:stop, :normal, :finished, nil}

  defp maybe_finish(quiz, email), do:
    {
      :reply,
      {quiz.current_question.asked, quiz.last_response.correct},
      {quiz, email}
    }

end
