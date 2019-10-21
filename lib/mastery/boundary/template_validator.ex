defmodule Mastery.Boundary.TemplateValidator do
  alias Mastery.Boundary.Validator

  @spec errors(any) :: [{atom | nil, String.t}]
  def errors(fields) when is_list(fields) do
    fields = Map.new(fields)
    []
    |> Validator.require(fields, :name, &validate_name/1)
    |> Validator.require(fields, :category, &validate_name/1)
    |> Validator.optional(fields, :instructions, &validate_instructions/1)
    |> Validator.require(fields, :raw, &validate_raw/1)
    |> Validator.require(fields, :generators, &validate_generators/1)
    |> Validator.require(fields, :checker, &validate_checker/1)
  end

  def errors(_fields), do: [{nil, "A keyword list of fields is required"}]

  @spec validate_name(any) :: :ok | {:error, String.t}
  defp validate_name(name) when is_atom(name), do: :ok
  defp validate_name(_name), do: {:error, "must be an atom"}

  @spec validate_instructions(any) :: :ok | {:error, String.t}
  defp validate_instructions(instructions) when is_binary(instructions), do: :ok
  defp validate_instructions(_instructions), do: {:error, "must be a binary"}

  @spec validate_raw(any) :: :ok | {:error, String.t}
  defp validate_raw(raw) when is_binary(raw), do:
    Validator.check(String.match?(raw, ~r{\S}), {:error, "can't be blank"})

  defp validate_raw(_raw), do: {:error, "must be a string"}

  @spec validate_generators(any) ::
    :ok
    | {:errors, [{:error, String.t}]}
    | {:error, String.t}
  defp validate_generators(generators) when is_map(generators) do
    generators
    |> Enum.map(&validate_generator/1)
    |> Enum.reject(&(&1 == :ok))
    |> case do
      [] -> :ok
      errors -> {:errors, errors}
    end
  end

  defp validate_generators(_generators), do: {:error, "must be a map"}

  @spec validate_generator({any, any}) :: :ok | {:error, String.t}
  defp validate_generator({name, generator}) when is_atom(name) and is_list(generator), do:
    Validator.check(generator != [], {:error, "can't be empty"})

  defp validate_generator({name, generator}) when is_atom(name) and is_function(generator, 0), do:
    :ok

  defp validate_generator(_generate), do:
    {:error, "must be a string to list or function pair"}

  @spec validate_checker(any) :: :ok | {:error, String.t}
  defp validate_checker(checker) when is_function(checker, 2), do: :ok
  defp validate_checker(_checker), do: {:error, "must be an arity 2 function"}

end
