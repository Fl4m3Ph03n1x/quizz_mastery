defmodule Mastery do
  @moduledoc """
  Public API of the mastery project. It is the outer API that connects to the
  all the internal APIs on the boundary level. Allows users to create and use
  quizes in a simple manner.
  """

  alias Mastery.Boundary.{QuizManager, QuizSession, QuizValidator,
    TemplateValidator, Validator}
  alias Mastery.Core.Quiz

  @spec start_quiz_manager :: GenServer.on_start
  def start_quiz_manager, do:
    GenServer.start_link(QuizManager, %{}, name: QuizManager)

  @spec build_quiz(any) :: :ok | Validator.errors
  def build_quiz(fields), do:
    with  :ok <- QuizValidator.errors(fields),
          :ok <- QuizManager.build_quiz(fields),
    do: :ok

  @spec add_template(String.t, any) :: :ok | Validator.errors
  def add_template(title, fields), do:
    with  :ok <- TemplateValidator.errors(fields),
          :ok <- QuizManager.add_template(title, fields),
    do: :ok

  @spec take_quiz(String.t, String.t) :: pid
  def take_quiz(title, email), do:
    with  %Quiz{} = quiz  <- QuizManager.lookup_quiz_by_title(title),
          {:ok, session}  <- GenServer.start_link(QuizSession, {quiz, email}),
    do: session

  @spec select_question(pid) :: String.t
  def select_question(session), do:
    QuizSession.select_question(session)

  @spec answer_question(pid, String.t) :: :finished | {String.t, boolean}
  def answer_question(session, answer), do:
    QuizSession.answer_question(session, answer)

end
