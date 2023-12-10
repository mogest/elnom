defmodule Elnom.Sequence do
  @moduledoc "Combinators applying parsers in sequence"

  @doc """
  Matches an object from the first parser and discards it, then gets an object from the second parser, and finally matches an object from the third parser and discards it.

        iex> parser = delimited(tag("("), tag("abc"), tag(")"))
        iex> parser.("(abc)")
        {:ok, "", "abc"}
        iex> parser.("(abc)def")
        {:ok, "def", "abc"}
        iex> parser.("")
        {:error, %Error{kind: :tag, buffer: ""}}
        iex> parser.("123")
        {:error, %Error{kind: :tag, buffer: "123"}}
  """
  def delimited(first, second, third) do
    fn str ->
      case first.(str) do
        {:ok, str, _} ->
          case second.(str) do
            {:ok, str, data} ->
              case third.(str) do
                {:ok, str, _} -> {:ok, str, data}
                {:error, reason} -> {:error, reason}
              end

            {:error, reason} ->
              {:error, reason}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Gets an object from the first parser, then gets another object from the second parser.

      iex> parser = pair(tag("abc"), tag("efg"))
      iex> parser.("abcefg")
      {:ok, "", {"abc", "efg"}}
      iex> parser.("abcefg123")
      {:ok, "123", {"abc", "efg"}}
      iex> parser.("")
      {:error, %Error{kind: :tag, buffer: ""}}
      iex> parser.("123")
      {:error, %Error{kind: :tag, buffer: "123"}}
  """
  def pair(first, second), do: tuple({first, second})

  @doc """
  Matches an object from the first parser and discards it, then gets an object from the second parser.

      iex> parser = preceded(tag("abc"), tag("efg"))
      iex> parser.("abcefg")
      {:ok, "", "efg"}
      iex> parser.("abcefghij")
      {:ok, "hij", "efg"}
      iex> parser.("")
      {:error, %Error{kind: :tag, buffer: ""}}
      iex> parser.("123")
      {:error, %Error{kind: :tag, buffer: "123"}}
  """
  def preceded(first, second) do
    fn str ->
      case first.(str) do
        {:ok, str, _} ->
          case second.(str) do
            {:ok, str, data} -> {:ok, str, data}
            {:error, reason} -> {:error, reason}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Gets an object from the first parser, then matches an object from the sep_parser and discards it, then gets another object from the second parser.

      iex> parser = separated_pair(tag("abc"), tag("|"), tag("efg"))
      iex> parser.("abc|efg")
      {:ok, "", {"abc", "efg"}}
      iex> parser.("abc|efg123")
      {:ok, "123", {"abc", "efg"}}
      iex> parser.("")
      {:error, %Error{kind: :tag, buffer: ""}}
      iex> parser.("123")
      {:error, %Error{kind: :tag, buffer: "123"}}
  """
  def separated_pair(first, sep, second) do
    pair(first, preceded(sep, second))
  end

  @doc """
  Gets an object from the first parser, then matches an object from the second parser and discards it.

      iex> parser = terminated(tag("abc"), tag("efg"))
      iex> parser.("abcefg")
      {:ok, "", "abc"}
      iex> parser.("abcefg123")
      {:ok, "123", "abc"}
      iex> parser.("")
      {:error, %Error{kind: :tag, buffer: ""}}
      iex> parser.("123")
      {:error, %Error{kind: :tag, buffer: "123"}}
  """
  def terminated(first, second) do
    fn str ->
      case first.(str) do
        {:ok, str, data} ->
          case second.(str) do
            {:ok, str, _} -> {:ok, str, data}
            {:error, reason} -> {:error, reason}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Applies a tuple of parsers one by one and returns their results as a tuple.

  Either a tuple or a list of parsers can be provided.

      iex> parser = tuple({alpha1(), digit1(), alpha1()})
      iex> parser.("abc123def")
      {:ok, "", {"abc", "123", "def"}}
      iex> parser.("123def")
      {:error, %Error{kind: :alpha, buffer: "123def"}}
  """
  def tuple(tuple) when is_tuple(tuple) do
    fn str ->
      case tuple(Tuple.to_list(tuple)).(str) do
        {:ok, str, data} -> {:ok, str, List.to_tuple(data)}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  def tuple(list) when is_list(list) do
    fn str ->
      Enum.reduce_while(list, {str, []}, fn parser, {str, data} ->
        case parser.(str) do
          {:ok, str, value} -> {:cont, {str, [value | data]}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
      |> case do
        {:error, reason} -> {:error, reason}
        {str, data} -> {:ok, str, Enum.reverse(data)}
      end
    end
  end
end
