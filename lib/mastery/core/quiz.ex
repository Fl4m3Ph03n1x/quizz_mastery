defmodule Mastery.Core.Quiz do
  @moduledoc """
  A quiz is a set of questions. The quizz will ask questions until the user
  achieves mastery in all categories.
  """

  use TypedStruct

  alias Mastery.Core.{Question, Response, Template}

  @type category      :: atom
  @type template_name :: atom

  typedstruct do
    field :title,             String.t
    field :current_question,  Question.t
    field :last_response,     Response.t
    field :mastery,           non_neg_integer,                    default: 3
    field :templates,         %{category: [Template.t]},          default: %{}
    field :used,              [Template.t],                       default: []
    field :mastered,          [Template.t],                       default: []
    field :record,            %{template_name: non_neg_integer},  default: %{}
  end

  ###############
  # Public API  #
  ###############

  @spec new(Enum.t) :: __MODULE__.t
  def new(fields), do: struct!(__MODULE__, fields)

  @spec add_template(__MODULE__.t, keyword) :: __MODULE__.t
  def add_template(quiz, fields) do
    template = Template.new(fields)

    templates =
      update_in(
        quiz.templates, [template.category], &add_to_list_or_nil(&1, template)
      )

      %__MODULE__{quiz | templates: templates}
  end

  @spec select_question(__MODULE__.t) :: nil | __MODULE__.t
  def select_question(%__MODULE__{templates: t}) when map_size(t) == 0, do: nil

  def select_question(quiz), do:
    quiz
    |> pick_current_question()
    |> move_template(:used)
    |> reset_template_cycle()

  @spec answer_question(__MODULE__.t, Response.t) :: __MODULE__.t
  def answer_question(quiz, %Response{correct: true} = response) do
    new_quiz =
      quiz
      |> inc_record()
      |> save_response(response)

    maybe_advance(new_quiz, mastered?(new_quiz))
  end

  def answer_question(quiz, %Response{correct: false} = response), do:
    quiz
    |> reset_record()
    |> save_response(response)

  ###############
  # Aux Functs  #
  ###############

  @spec add_to_list_or_nil(nil | [Template.t], Template.t) :: [Template.t]
  defp add_to_list_or_nil(nil, template), do: [template]
  defp add_to_list_or_nil(templates, template), do: [template | templates]

  @spec pick_current_question(__MODULE__.t) :: __MODULE__.t
  defp pick_current_question(quiz), do:
    Map.put(quiz, :current_question, select_a_random_question(quiz))

  @spec select_a_random_question(__MODULE__.t) :: Question.t
  defp select_a_random_question(quiz), do:
    quiz.templates
    |> Enum.random
    |> elem(1)
    |> Enum.random
    |> Question.new

  @spec move_template(__MODULE__.t, atom) :: __MODULE__.t
  defp move_template(quiz, field), do:
    quiz
    |> remove_template_from_category()
    |> add_template_to_field(field)

  @spec remove_template_from_category(__MODULE__.t) :: __MODULE__.t
  defp remove_template_from_category(quiz) do
    template = template(quiz)

    new_templates =
      quiz.templates
      |> templates_from_category(template.category)
      |> List.delete(template)
      |> update_templates_category(quiz.templates, template.category)

    Map.put(quiz, :templates, new_templates)
  end

  @spec templates_from_category(map, atom) :: [Template.t]
  defp templates_from_category(templates_by_category, category), do:
    Map.fetch!(templates_by_category, category)

  @spec update_templates_category([Template.t], map, atom) :: map
  defp update_templates_category([], templates, category), do:
    Map.delete(templates, category)

  defp update_templates_category(new_category_templates, templates, category), do:
    Map.put(templates, category, new_category_templates)

  @spec template(__MODULE__.t) :: Template.t
  defp template(quiz), do: quiz.current_question.template

  @spec add_template_to_field(__MODULE__.t, atom) :: __MODULE__.t
  defp add_template_to_field(quiz, field) do
    template = template(quiz)
    list = Map.get(quiz, field)

    Map.put(quiz, field, [template | list])
  end

  @spec reset_template_cycle(__MODULE__.t) :: __MODULE__.t
  defp reset_template_cycle(%{templates: templates, used: used} = quiz) when
  map_size(templates) == 0, do:
    %__MODULE__{
      quiz |
      templates: Enum.group_by(used, fn template -> template.category end),
      used: []
    }

  defp reset_template_cycle(quiz), do: quiz

  @spec save_response(__MODULE__.t, Response.t) :: __MODULE__.t
  defp save_response(quiz, response), do:
    Map.put(quiz, :last_response, response)

  @spec mastered?(__MODULE__.t) :: boolean
  defp mastered?(quiz) do
    score = Map.get(quiz.record, template(quiz).name, 0)
    score == quiz.mastery
  end

  @spec inc_record(__MODULE__.t) :: __MODULE__.t
  defp inc_record(%{current_question: question, record: record} = quiz) do
    new_record = Map.update(record, question.template.name, 1, &(&1 + 1))
    Map.put(quiz, :record, new_record)
  end

  @spec maybe_advance(__MODULE__.t, boolean) :: __MODULE__.t
  defp maybe_advance(quiz, false = _mastered), do: quiz
  defp maybe_advance(quiz, true = _mastered), do: advance(quiz)

  @spec advance(__MODULE__.t) :: __MODULE__.t
  defp advance(quiz), do:
    quiz
    |> move_template(:mastered)
    |> reset_record()
    |> reset_used()

  @spec reset_record(__MODULE__.t) :: __MODULE__.t
  defp reset_record(%{current_question: question} = quiz), do:
    Map.put(
      quiz,
      :record,
      Map.delete(quiz.record, question.template.name)
    )

  @spec reset_used(__MODULE__.t) :: __MODULE__.t
  defp reset_used(%{current_question: question} = quiz), do:
    Map.put(
      quiz,
      :used,
      List.delete(quiz.used, question.template)
    )

end
