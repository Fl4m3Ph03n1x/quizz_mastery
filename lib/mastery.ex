defmodule Mastery do
  @moduledoc """
  Public API of the mastery project. It is the outer API that connects to the
  all the internal APIs on the boundary level. Allows users to create and use
  quizes in a simple manner.
  """

  @type session :: {String.t, String.t}

  alias Mastery.Boundary.{QuizManager, QuizSession, QuizValidator,
    TemplateValidator, Validator}
  alias Mastery.Core.Quiz

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

  @spec take_quiz(String.t, String.t) :: session
  def take_quiz(title, email), do:
    with  %Quiz{} = quiz  <- QuizManager.lookup_quiz_by_title(title),
          {:ok, _}        <- QuizSession.take_quiz(quiz, email),
    do: {title, email}

  @spec select_question(session) :: String.t
  def select_question(session), do:
    QuizSession.select_question(session)

  @spec answer_question(session, String.t) :: :finished | {String.t, boolean}
  def answer_question(session, answer), do:
    QuizSession.answer_question(session, answer)

end
