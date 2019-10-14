defmodule Mastery.Core.Template do
  @moduledoc """
  Templates represent a group of questions on a quizz and have all the
  functionality necessary to generate the questions based on the given
  generators and check the responses as well.
  """

  use TypedStruct

  @type substitution :: atom

  typedstruct do
    field :name,          atom
    field :category,      atom
    field :instructions,  String.t
    field :raw,           String.t
    field :compiled,      Macro.t
    field :generators,    %{substitution: [any] | (-> any)}
    field :checker,       ([any], String.t -> boolean)
  end

  @spec new(keyword) :: __MODULE__.t
  def new(fields) do
    raw = Keyword.fetch!(fields, :raw)

    struct!(
      __MODULE__,
      Keyword.put(fields, :compiled, EEx.compile_string(raw))
    )
  end
end
