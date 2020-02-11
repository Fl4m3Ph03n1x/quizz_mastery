defmodule MasteryTest do
  use ExUnit.Case, async: false
  use QuizBuilders

  alias MasteryPersistence.Repo
  alias Mastery.Examples.Math
  alias Mastery.Boundary.QuizSession
  alias MasteryPersistence.Response

  defp enable_persistence() do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  defp response_count() do
    Repo.aggregate(Response, :count, :id)
  end

  defp start_quiz(fields) do
    now = DateTime.utc_now()
    ending = DateTime.add(now, 6)

    Mastery.schedule_quiz(Math.quiz_fields(), fields, now, ending)
  end

  defp take_quiz(email) do
    Mastery.take_quiz(Math.quiz.title, email)
  end

  defp select_question(session) do
    assert Mastery.select_question(session) == "1 + 2"
  end

  defp give_wrong_answer(session) do
    Mastery.answer_question(session, "wrong", &MasteryPersistence.record_response/2)
  end

  defp give_right_answer(session) do
    Mastery.answer_question(session, "3", &MasteryPersistence.record_response/2)
  end
end
