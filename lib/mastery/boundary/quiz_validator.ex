defmodule Mastery.Boundary.QuizValidator do
  @moduledoc """
  Contains functions that validate quizz data.
  """

  alias Mastery.Boundary.Validator

  @spec errors(any) :: :ok | Validator.errors
  def errors(fields) when is_map(fields), do:
    []
    |> Validator.require(fields, :title, &validate_title/1)
    |> Validator.optional(fields, :mastery, &validate_mastery/1)

  def errors(_fields), do: [{nil, "A map of fields is required"}]

  @spec validate_title(any) :: :ok | {:error, String.t}
  def validate_title(title) when is_binary(title), do:
    Validator.check(String.match?(title, ~r{\S}), {:error, "can't be blank"})

  def validate_title(_title), do: {:error, "must be a string"}

  @spec validate_mastery(any) :: :ok | {:error, String.t}
  def validate_mastery(mastery) when is_integer(mastery), do:
    Validator.check(mastery >= 1, {:error, "must be greater than zero"})

  def validate_mastery(_mastery), do: {:error, "must be an integer"}

end
