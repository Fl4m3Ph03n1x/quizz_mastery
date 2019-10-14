defmodule Mastery.Core.Response do
  @moduledoc """
  A response to a question. Tracks the options the user selected, if it is right
  or wrong plus additional data for debbuging.
  """

  use TypedStruct

  alias Mastery.Core.Quiz

  typedstruct do
    field :quiz_title,    String.t
    field :template_name, atom
    field :to,            String.t
    field :email,         String.t
    field :answer,        String.t
    field :correct,       boolean
    field :timestamp,     DateTime.t
  end

  @spec new(Quiz.t, String.t, String.t) :: __MODULE__.t
  def new(quiz, email, answer) do
    question = quiz.current_question
    template = question.template

    %__MODULE__{
      quiz_title:     quiz.title,
      template_name:  template.name,
      to:             question.asked,
      email:          email,
      answer:         answer,
      correct:        template.checker.(question.substitutions, answer),
      timestamp:      DateTime.utc_now()
    }
  end
end
