defmodule Mastery.Boundary.Proctor do
  use GenServer

  require Logger

  alias Mastery.Boundary.{QuizManager, QuizSession}

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, [], options)
  end

  def init(quizzes), do: {:ok, quizzes}

  def schedule_quizz(proctor \\ __MODULE__, quiz, temps, start_at, end_at) do
    quiz = %{
      fields: quiz,
      templates: temps, 
      start_at: start_at,
      end_at: end_at
    }
    GenServer.call(proctor, {:schedule_quizz, quizz})
  end 
end
