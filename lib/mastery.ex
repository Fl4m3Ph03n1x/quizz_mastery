defmodule Mastery do
  @moduledoc """
  Public API of the mastery project. It is the outer API that connects to the
  all the internal APIs on the boundary level. Allows users to create and use
  quizes in a simple manner.
  """

  @type session :: {String.t, String.t}

  alias Mastery.Boundary.{Proctor, QuizManager, QuizSession, QuizValidator,
    TemplateValidator, Validator}
  alias Mastery.Core.{Quiz, Template}

  @persistence_fn Application.get_env(:mastery, :persistence_fn)

  ##############
  # Public API #
  ##############

  @spec schedule_quiz(Quiz.t, [Template.t], DateTime.t, DateTime.t, pid | nil) :: :ok | any
  def schedule_quiz(quiz, templates, start_at, end_at, notify_pid \\ nil) do
    with  :ok  <- QuizValidator.errors(quiz),
          true <- Enum.all?(templates, &(:ok == TemplateValidator.errors(&1))),
          :ok  <- Proctor.schedule_quiz(quiz, templates, start_at, end_at, notify_pid),
         do: :ok
  end

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

  @spec answer_question(session, String.t, function) :: :finished | {String.t, boolean}
  def answer_question(session, answer, persistence_fn \\ @persistence_fn), do:
    QuizSession.answer_question(session, answer, persistence_fn)

end
