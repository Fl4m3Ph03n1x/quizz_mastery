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

  @spec answer_question(pname, String.t, function) :: :finished | {String.t, boolean}
  def answer_question(name, answer, persistence_fn), do:
    GenServer.call(via(name), {:answer_question, answer, persistence_fn})

  @spec active_sessions_for(String.t) :: [pname]
  def active_sessions_for(quiz_title), do:
    Mastery.Supervisor.QuizSession
    |> DynamicSupervisor.which_children()
    |> Enum.filter(&child_pid?/1)    
    |> Enum.flat_map(&active_sessions(&1, quiz_title))

  @spec end_sessions([pname]) :: :ok
  def end_sessions(pnames), do:
    Enum.each(pnames, fn name -> GenServer.stop(via(name)) end)

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

  def handle_call({:answer_question, answer, fun}, _from, {quiz, email}) do
    persistence_fn = fun || fn(response, f) -> f.(response) end
    response = Response.new(quiz, email, answer)
    
    persistence_fn.(response, fn r -> 
      quiz
      |> Quiz.answer_question(r)
      |> Quiz.select_question()
    end)
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

  @spec child_pid?(any) :: boolean
  defp child_pid?({:undefined, pid, :worker, [__MODULE__]}) when is_pid(pid), 
    do: true

  defp child_pid?(_child), do: false

  @spec active_sessions({:undefined, pid, :worker, [module]}, String.t) :: [pname]
  defp active_sessions({:undefined, pid, :worker, [__MODULE__]}, title), do:
    Mastery.Registry.QuizSession
    |> Registry.keys(pid)
    |> Enum.filter(fn {quiz_title, _email} -> quiz_title == title end)

end
