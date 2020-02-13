defmodule MasteryPersistenceTest do
  use ExUnit.Case

  alias MasteryPersistenceTest.{Response, Repo}

  #########
  # Setup #
  #########

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    response = %{
      quiz_title: :simple_addition,
      template_name: :single_digit_addition,
      to: "3 + 4",
      email: "student@example.com",
      answer: "7",
      correct: true,
      timestamp: DateTime.utc_now()
    }

    {:ok, %{response: response}}
  end

  #########
  # Tests #
  #########

  test "responses are recorded", %{response: response} do
    assert Repo.aggregate(Response, :count, :id) == 0
    assert :ok = MasteryPersistence.record_response(response)
    assert Repo.all(Response) |> Enum.map(fn r -> r.email end) == 
      [response.email]
  end

end
