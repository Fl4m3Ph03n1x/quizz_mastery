defmodule MasteryPersistence do
  @moduledoc """
  Public API of the project.
  Allows Mastery to save responses into the DB and to get reports from finished
  quizes.
  """

  import Ecto.Query, only: [from: 2]

  alias MasteryPersistence.{Repo, Response}

  @type response :: %{
    quiz_title: String.t,
    template_name: String.t,
    to: String.t,
    email: String.t,
    correct: boolean,
    inserted_at: DateTime.t,
    updated_at: DateTime.t
  }

  @spec record_response(response, (any -> :ok)) :: any
  def record_response(response, in_transaction \\ fn _response -> :ok end) do
    {:ok, result} = Repo.transaction(fn ->
      %{
        quiz_title:     to_string(response.quiz_title),
        template_name:  to_string(response.template_name),
        to:             response.to,
        email:          response.email,
        answer:         response.answer,
        correct:        response.correct,
        inserted_at:    response.timestamp,
        updated_at:     response.timestamp
      }
      |> Response.record_changeset()
      |> Repo.insert!()

      in_transaction.(response)
    end)

    result
  end

  @spec report(String.t) :: map
  def report(quiz_title) do
    quiz_title = to_string(quiz_title)
    from(
      r in Response,
      select: {r.email, count(r.id)},
      where: r.quiz_title == ^quiz_title,
      group_by: [r.quiz_title, r.email]
    )
    |> Repo.all()
    |> Enum.into(Map.new())
  end

end
