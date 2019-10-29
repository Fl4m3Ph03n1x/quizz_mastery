defmodule Mastery.Boundary.Validator do

  @type error     :: {atom, String.t}
  @type errors    :: keyword(String.t)
  @type validator :: (any -> :ok | {:error, String.t} | {:errors, [String.t]})
  @type fields    :: %{optional(atom) => any}

  @spec require(errors, fields, atom, validator) :: :ok | errors
  def require(errors, fields, field_name, validator) do
    present = Map.has_key?(fields, field_name)
    check_required_field(present, fields, errors, field_name, validator)
  end

  @spec optional(errors, fields, atom, validator) :: :ok | errors
  def optional(errors, fields, field_name, validator) do
    if Map.has_key?(fields, field_name) do
      require(errors, fields, field_name, validator)
    else
      errors
    end
  end

  @spec check(boolean, error) :: :ok | error
  def check(true = _valid, _message), do: :ok
  def check(false = _valid, message), do: message

  @spec check_required_field(boolean, fields, errors, atom, validator) ::
    :ok | errors
  defp check_required_field(true = _present, fields, errors, field_name, validator), do:
    fields
    |> Map.fetch!(field_name)
    |> validator.()
    |> check_field(errors, field_name)

  defp check_required_field(false = _present, _fields, errors, field_name, _validator), do:
    errors ++ [{field_name, "is required"}]

  @spec check_field(
    :ok | {:error, String.t} | {:errors, [String.t]},
    errors,
    atom
  ) :: :ok | errors
  defp check_field(:ok = _valid, _errors, _field_name), do: :ok

  defp check_field({:error, message}, errors, field_name), do:
    errors ++ [{field_name, message}]

  defp check_field({:errors, messages}, errors, field_name), do:
    errors ++ Enum.map(messages, &{field_name, &1})

end
