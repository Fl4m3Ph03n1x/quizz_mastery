defmodule Mastery.Boundary.QuizSession do
  @moduledoc """
  Holds and manages the state of a quizz session. When a player starts a quizz,
  the player's progress is saved into the state this process is managing.
  """

  use GenServer

  alias Mastery.Core.{Quiz, Response}

  @type state :: {Quiz.t, String.t}
  @type pname :: {String.t, String.t} #Process name to use with via tuples

  @spec child_spec(state) :: map
  def child_spec({quiz, email}), do:
    %{
      id:       {__MODULE__, {quiz.title, email}},
      start:    {__MODULE__, :start_link, [{quiz, email}]},
      restart:  :temporary
    }

  ##############
  # Public API #
  ##############

  @spec start_link(state) :: GenServer.on_start
  def start_link({quiz, email}), do:
    GenServer.start_link(
      __MODULE__,
      {quiz, email},
      name: via({quiz.title, email})
    )

  @spec take_quiz(Quiz.t, String.t) :: DynamicSupervisor.on_start_child
  def take_quiz(quiz, email), do:
    DynamicSupervisor.start_child(
      Mastery.Supervisor.QuizSession,
      {__MODULE__, {quiz, email}}
    )

  @spec select_question(pname) :: String.t
  def select_question(name), do:
    GenServer.call(via(name), :select_question)

  @spec answer_question(pname, String.t) :: :finished | {String.t, boolean}
  def answer_question(name, answer), do:
    GenServer.call(via(name), {:answer_question, answer})

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

  ##############
  # Aux functs #
  ##############

  @spec via({String.t, String.t}) :: {:via, module, {module, pname}}
  defp via({_title, _email} = name), do:
    {
      :via,
      Registry,
      {Mastery.Registry.QuizSession, name}
    }

end
