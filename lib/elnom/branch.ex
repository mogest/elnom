defmodule Elnom.Branch do
  @moduledoc """
  Choice combinators.
  """

  alias Elnom.{Error, Failure}

  @doc """
  Tests a list of parsers one by one until one succeeds.

  It takes as argument a tuple or list of parsers.

      iex> parser = alt({alpha1(), digit1()})
      iex> parser.("abc")
      {:ok, "", "abc"}
      iex> parser.("123456")
      {:ok, "", "123456"}
      iex> parser.("abc123")
      {:ok, "123", "abc"}
      iex> parser.(" ")
      {:error, %Error{kind: :digit, buffer: " "}}
  """
  def alt(tuple) when is_tuple(tuple) do
    alt(Tuple.to_list(tuple))
  end

  def alt(list) when is_list(list) do
    fn str -> alt_internal(str, list) end
  end

  defp alt_internal(str, []) do
    {:error, Error.new(:alt, str)}
  end

  defp alt_internal(str, [head | rest]) do
    case head.(str) do
      {:ok, str, data} ->
        {:ok, str, data}

      {:error, %Failure{} = reason} ->
        {:error, reason}

      {:error, reason} ->
        case rest do
          [] -> {:error, reason}
          _ -> alt_internal(str, rest)
        end
    end
  end

  @doc """
  Applies a list of parsers in any order.

  Permutation will succeed if all of the child parsers succeeded. It takes as argument a tuple of parsers, and returns a tuple of the parser results.

      iex> parser = permutation({alpha1(), digit1()})
      iex> parser.("abc123")
      {:ok, "", {"abc", "123"}}
      iex> parser.("123abc")
      {:ok, "", {"abc", "123"}}
      iex> parser.("abc;")
      {:error, %Error{kind: :digit, buffer: ";"}}

  The parsers are applied greedily: if there are multiple unapplied parsers that could parse the next slice of input, the first one is used.

      iex> parser = permutation({anychar(), char("a")})
      iex> parser.("ba")
      {:ok, "", {"b", "a"}}
      iex> parser.("ab")
      {:error, %Error{kind: :char, buffer: "b"}}
  """
  def permutation(parsers) when is_tuple(parsers) do
    fn str ->
      list =
        parsers
        |> Tuple.to_list()
        |> Enum.map(&{&1, nil})

      permutation_internal(str, list)
      |> case do
        {:ok, str, data} -> {:ok, str, List.to_tuple(data)}
        error -> error
      end
    end
  end

  def permutation(parsers) when is_list(parsers) do
    fn str ->
      permutation_internal(str, Enum.map(parsers, &{&1, nil}))
    end
  end

  defp permutation_internal(str, list) do
    case permutation_pass(str, list) do
      {:error, reason} ->
        {:error, reason}

      {str, list, _, nil} ->
        {:ok, str, Enum.map(list, fn {_, data} -> data end)}

      {str, list, true, _} ->
        permutation_internal(str, list)

      {_, _, _, last_error} ->
        {:error, last_error}
    end
  end

  defp permutation_pass(str, input, output \\ [], progression \\ false, last_error \\ nil)

  defp permutation_pass(str, [], output, progression, last_error) do
    {str, Enum.reverse(output), progression, last_error}
  end

  defp permutation_pass(str, [{parser, nil} | rest], output, progression, last_error) do
    case parser.(str) do
      {:ok, str, data} ->
        permutation_pass(str, rest, [{parser, data} | output], true, last_error)

      {:error, %Failure{} = reason} ->
        {:error, reason}

      {:error, reason} ->
        permutation_pass(str, rest, [{parser, nil} | output], progression, reason)
    end
  end

  defp permutation_pass(str, [head | rest], output, progression, last_error) do
    permutation_pass(str, rest, [head | output], progression, last_error)
  end
end
