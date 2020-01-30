defmodule Mastery.Boundary.QuizManager do
  @moduledoc """
  Manages Quizz Sessions from players.
  """

  use GenServer

  alias Mastery.Core.Quiz

  @type quizzes :: %{String.t => Quiz.t}

  ##############
  # Public API #
  ##############

  @spec start_link(keyword) :: GenServer.on_start
  def start_link(options \\ []), do:
    GenServer.start_link(__MODULE__, %{}, options)

  @spec build_quiz(module, Enum.t) :: :ok
  def build_quiz(manager \\ __MODULE__, quiz_fields), do:
    GenServer.call(manager, {:build_quiz, quiz_fields})

  @spec add_template(module, String.t, keyword) :: :ok
  def add_template(manager \\ __MODULE__, quiz_title, template_fields), do:
    GenServer.call(manager, {:add_template, quiz_title, template_fields})

  @spec lookup_quiz_by_title(module, String.t) :: Quiz.t
  def lookup_quiz_by_title(manager \\ __MODULE__, quiz_title), do:
    GenServer.call(manager, {:lookup_quiz_by_title, quiz_title})

  @spec remove_quiz(module, String.t) :: Quiz.t
  def remove_quiz(manager \\ __MODULE__, quiz_title), do:
    GenServer.call(manager, {:remove_quiz, quiz_title})

  ############################
  # Callback implementations #
  ############################

  @impl GenServer
  @spec init(any) :: {:stop, String.t} | {:ok, quizzes}
  def init(quizzes) when is_map(quizzes), do: {:ok, quizzes}
  def init(_quizzes), do: {:stop, "quizzes must be a map"}

  @impl GenServer
  def handle_call({:build_quiz, quiz_fields}, _from, quizzes) do
    quiz = Quiz.new(quiz_fields)

    # Using a title as UUID is a trade off in the name of simplicity
    # https://elixirforum.com/t/designing-elixir-systems-with-otp-pragprog/21626/25?u=fl4m3ph03n1x
    new_quizzes = Map.put(quizzes, quiz.title, quiz)
    {:reply, :ok, new_quizzes}
  end

  def handle_call(
    {:add_template, quiz_title, template_fields}, _from, quizzes
  ) do
    new_quizzes = Map.update!(
      quizzes,
      quiz_title,
      fn quiz -> Quiz.add_template(quiz, template_fields) end
    )
    {:reply, :ok, new_quizzes}
  end

  def handle_call({:lookup_quiz_by_title, quiz_title}, _from, quizzes), do:
    {:reply, quizzes[quiz_title], quizzes}

  def handle_call({:remove_quiz, quiz_title}, _from, quizzes) do
    new_quizzes = Map.delete(quizzes, quiz_title)
    {:reply, :ok, new_quizzes}  
  end

end
