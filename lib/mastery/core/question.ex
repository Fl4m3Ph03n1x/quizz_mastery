defmodule Mastery.Core.Question do
  @moduledoc """
  Questions consist of the text the user was asked, the template used to create
  them and the substitutions used to build the template.
  """

  use TypedStruct

  alias Mastery.Core.Template

  typedstruct do
    field :asked,         String.t
    field :template,      Template.t
    field :substitutions,  [any]
  end

  @spec new(Template.t) :: __MODULE__.t
  def new(%Template{} = template) do
    template.generators
    |> Enum.map(&build_substitution/1)
    |> evaluate(template)
  end

  @spec evaluate([any], Template.t) :: __MODULE__.t
  defp evaluate(substitutions, template), do:
    %__MODULE__{
      asked: compile(template, substitutions),
      substitutions: substitutions,
      template: template
    }

  @spec compile(Template.t, [any]) :: any
  defp compile(template, substitutions) do
    template.compiled
    |> Code.eval_quoted([assigns: substitutions])
    |> elem(0)
  end

  @spec build_substitution({atom, [any] | (-> any)}) :: {atom, any}
  defp build_substitution({name, choices_or_gen}), do:
    {name, choose(choices_or_gen)}

  @spec choose([any] | (-> any)) :: any
  defp choose(choices) when is_list(choices), do: Enum.random(choices)
  defp choose(generator) when is_function(generator), do: generator.()

end
