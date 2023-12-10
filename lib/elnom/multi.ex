defmodule Elnom.Multi do
  @moduledoc "Combinators applying their child parser multiple times"

  import Elnom.Combinator
  alias Elnom.{Error, Failure, Incomplete}

  @doc """
  Runs the embedded parser `count` times, gathering the results into a list

      iex> parser = count(tag("abc"), 2)
      iex> parser.("abcabc")
      {:ok, "", ["abc", "abc"]}
      iex> parser.("abc123")
      {:error, %Error{kind: :tag, buffer: "123"}}
      iex> parser.("123123")
      {:error, %Error{kind: :tag, buffer: "123123"}}
      iex> parser.("")
      {:error, %Error{kind: :tag, buffer: ""}}
      iex> parser.("abcabcabc")
      {:ok, "abc", ["abc", "abc"]}
  """
  def count(parser, count) do
    fn input -> count_internal(parser, count, input, []) end
  end

  defp count_internal(_parser, 0, input, output), do: {:ok, input, Enum.reverse(output)}

  defp count_internal(parser, count, input, output) do
    case parser.(input) do
      {:ok, input, data} ->
        count_internal(parser, count - 1, input, [data | output])

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Repeats the embedded parser, calling `fun` to gather the results.

  This stops on Error. To instead chain an error up, see cut/1.

  Warning: the `element` and `accumulator` arguments passed to the `fun` are swapped relative to the Rust library so that they are idiomatic with Enum.reduce/2.

      iex> parser = fold_many0(tag("abc"), fn -> [] end, fn x, acc -> [[x] | acc] end)
      iex> parser.("abcabc")
      {:ok, "", [["abc"], ["abc"]]}
      iex> parser.("abc123")
      {:ok, "123", [["abc"]]}
      iex> parser.("123123")
      {:ok, "123123", []}
      iex> parser.("")
      {:ok, "", []}
  """
  def fold_many0(parser, init, fun) do
    fn input -> fold_many_internal(parser, initialize(init), nil, fun, input) end
  end

  @doc """
  Repeats the embedded parser, calling `fun` to gather the results.

  This stops on Error if there is at least one result. To instead chain an error up, see cut/1.

  Warning: the `element` and `accumulator` arguments passed to the `fun` are swapped relative to the Rust library so that they are idiomatic with Enum.reduce/2.

      iex> parser = fold_many1(tag("abc"), fn -> [] end, fn x, acc -> [[x] | acc] end)
      iex> parser.("abcabc")
      {:ok, "", [["abc"], ["abc"]]}
      iex> parser.("abc123")
      {:ok, "123", [["abc"]]}
      iex> parser.("123123")
      {:error, %Error{kind: :many1, buffer: "123123"}}
      iex> parser.("")
      {:error, %Error{kind: :many1, buffer: ""}}
  """
  def fold_many1(parser, init, fun) do
    fn input ->
      case parser.(input) do
        {:ok, input, data} ->
          fold_many_internal(parser, fun.(data, initialize(init)), nil, fun, input)

        {:error, _} ->
          {:error, Error.new(:many1, input)}
      end
    end
  end

  @doc """
  Repeats the embedded parser m..=n times, calling g to gather the results

  This stops before n when the parser returns Err::Error. To instead chain an error up, see cut.

  Warning: the `element` and `accumulator` arguments passed to the `fun` are swapped relative to the Rust library so that they are idiomatic with Enum.reduce/2.

      iex> parser = fold_many_m_n(0, 2, tag("abc"), fn -> [] end, fn x, acc -> [[x] | acc] end)
      iex> parser.("abcabc")
      {:ok, "", [["abc"], ["abc"]]}
      iex> parser.("abc123")
      {:ok, "123", [["abc"]]}
      iex> parser.("123123")
      {:ok, "123123", []}
      iex> parser.("")
      {:ok, "", []}
      iex> parser.("abcabcabc")
      {:ok, "abc", [["abc"], ["abc"]]}

      iex> parser = fold_many_m_n(2, 2, tag("abc"), fn -> [] end, fn x, acc -> [[x] | acc] end)
      iex> parser.("abcabc")
      {:ok, "", [["abc"], ["abc"]]}
      iex> parser.("abc")
      {:error, %Error{kind: :many_m_n, buffer: ""}}
      iex> parser.("")
      {:error, %Error{kind: :many_m_n, buffer: ""}}
  """
  def fold_many_m_n(min, max, parser, init, fun) do
    fn input ->
      case fold_many_internal(parser, initialize(init), max, fun, input) do
        {:ok, input, data} ->
          if length(data) < min do
            {:error, Error.new(:many_m_n, input)}
          else
            {:ok, input, data}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp initialize(init) when is_function(init), do: init.()
  defp initialize(init), do: init

  defp fold_many_internal(_, accumulator, 0, _, input) do
    {:ok, input, accumulator}
  end

  defp fold_many_internal(parser, accumulator, max, fun, input) do
    case parser.(input) do
      {:ok, input, ""} ->
        # Prevent an infinite loop
        {:error, Error.new(:fold_many, input)}

      {:ok, input, data} ->
        max = max && max - 1
        fold_many_internal(parser, fun.(data, accumulator), max, fun, input)

      {:error, %Failure{} = reason} ->
        {:error, reason}

      {:error, _} ->
        {:ok, input, accumulator}
    end
  end

  @doc """
  Gets a number from the first parser, then applies the second parser that many times.

      iex> parser = length_count(u8(), tag("abc"))
      iex> parser.(<<2, "abcabcabc">>)
      {:ok, "abc", ["abc", "abc"]}
      iex> parser.(<<3, "123123123">>)
      {:error, %Error{kind: :tag, buffer: "123123123"}}

      iex> length_count(integer(), tag("abc")).("2abcabcabc")
      {:ok, "abc", ["abc", "abc"]}
  """
  def length_count(length_parser, data_parser) do
    fn input ->
      case length_parser.(input) do
        {:ok, input, length} when is_integer(length) ->
          count(data_parser, length).(input)

        {:ok, _, _} ->
          {:error, Error.new(:length_count, input)}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Gets a number from the parser and returns a substring of the input of that size in utf-8 characters or bytes, depending on the `size` argument. If the parser returns Incomplete, length_data will return an error.

      iex> parser = length_data(be_u16(), :utf8)
      iex> parser.(<<0, 3, "ab💙efg">>)
      {:ok, "efg", "ab💙"}
      iex> parser.(<<0, 3, "a">>)
      {:error, %Incomplete{needed: 2}}

      iex> parser = length_data(be_u16(), :byte)
      iex> parser.(<<0, 3, "ab💙efg">>)
      {:ok, <<0x9f, 0x92, 0x99, "efg">>, <<"ab", 0xf0>>}
      iex> parser.(<<0, 3, "a">>)
      {:error, %Incomplete{needed: 2}}
  """
  def length_data(length_parser, _size = :utf8) do
    fn input ->
      case length_parser.(input) do
        {:ok, input, length} when is_integer(length) ->
          remaining = String.length(input) - length

          if remaining >= 0 do
            {match, rest} = String.split_at(input, length)
            {:ok, rest, match}
          else
            {:error, Incomplete.new(-remaining)}
          end

        {:ok, _, _} ->
          {:error, Error.new(:length_data, input)}

        {:error, %Incomplete{}} ->
          {:error, Error.new(:length_data, input)}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  def length_data(length_parser, _size = :byte) do
    fn input ->
      case length_parser.(input) do
        {:ok, input, length} when is_integer(length) ->
          case input do
            <<match::binary-size(length), rest::binary>> ->
              {:ok, rest, match}

            _ ->
              {:error, Incomplete.new(length - byte_size(input))}
          end

        {:ok, _, _} ->
          {:error, Error.new(:length_data, input)}

        {:error, %Incomplete{}} ->
          {:error, Error.new(:length_data, input)}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Gets a number from the first parser, takes a substring of the input of that size in utf-8 characters or bytes (depending on the `size` argument), then applies the second parser on that substring. If the second parser returns Incomplete, length_value will return an error.

      iex> parser = length_value(be_u16(), tag("ab💙"), :utf8)
      iex> parser.(<<0, 3, "ab💙efg">>)
      {:ok, "efg", "ab💙"}
      iex> parser.(<<0, 3, "123123">>)
      {:error, %Error{kind: :tag, buffer: "123"}}
      iex> parser.(<<0, 3, "a">>)
      {:error, %Incomplete{needed: 2}}

      iex> parser = length_value(be_u16(), tag("abc"), :byte)
      iex> parser.(<<0, 3, "abcefg">>)
      {:ok, "efg", "abc"}
  """
  def length_value(length_parser, data_parser, size) do
    fn input ->
      case length_data(length_parser, size).(input) do
        {:ok, input, output} ->
          case data_parser.(output) do
            {:ok, _, output} -> {:ok, input, output}
            {:error, reason} -> {:error, reason}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Repeats the embedded parser, gathering the results in a list.

  This stops on Error and returns the results that were accumulated. To instead chain an error up, see cut/1.

      iex> parser = many0(tag("abc"))
      iex> parser.("abcabc")
      {:ok, "", ["abc", "abc"]}
      iex> parser.("abc123")
      {:ok, "123", ["abc"]}
      iex> parser.("123123")
      {:ok, "123123", []}
      iex> parser.("")
      {:ok, "", []}
      iex> parser.("abcabcabcxabc")
      {:ok, "xabc", ["abc", "abc", "abc"]}

      iex> many0(alpha0()).("")
      {:error, %Error{kind: :many, buffer: ""}}
  """
  def many0(parser) do
    fn input ->
      case many0_internal(parser, input, []) do
        {:ok, input, output, _} -> {:ok, input, output}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Repeats the embedded parser, counting the results

  This stops on Error. To instead chain an error up, see cut/1.

      iex> parser = many0_count(tag("abc"))
      iex> parser.("abcabc")
      {:ok, "", 2}
      iex> parser.("abc123")
      {:ok, "123", 1}
      iex> parser.("123123")
      {:ok, "123123", 0}
      iex> parser.("")
      {:ok, "", 0}
      iex> parser.("abcabcabcxabc")
      {:ok, "xabc", 3}
  """
  def many0_count(parser) do
    fn input ->
      case many0_internal(parser, input, []) do
        {:ok, input, output, _} -> {:ok, input, length(output)}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Runs the embedded parser, gathering the results in a Vec.

  This stops on Error if there is at least one result, and returns the results that were accumulated. To instead chain an error up, see cut/1.

      iex> parser = many1(tag("abc"))
      iex> parser.("abcabc")
      {:ok, "", ["abc", "abc"]}
      iex> parser.("abc123")
      {:ok, "123", ["abc"]}
      iex> parser.("123123")
      {:error, %Error{kind: :tag, buffer: "123123"}}
      iex> parser.("")
      {:error, %Error{kind: :tag, buffer: ""}}
  """
  def many1(parser) do
    fn input ->
      case many0_internal(parser, input, []) do
        {:ok, _input, [], reason} -> {:error, reason}
        {:ok, input, output, _reason} -> {:ok, input, output}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Runs the embedded parser, counting the results.

  This stops on Error if there is at least one result. To instead chain an error up, see cut/1.

      iex> parser = many1_count(tag("abc"))
      iex> parser.("abcabc")
      {:ok, "", 2}
      iex> parser.("abc123")
      {:ok, "123", 1}
      iex> parser.("123123")
      {:error, %Error{kind: :tag, buffer: "123123"}}
      iex> parser.("")
      {:error, %Error{kind: :tag, buffer: ""}}
  """
  def many1_count(parser) do
    fn input ->
      case many0_internal(parser, input, []) do
        {:ok, _input, [], reason} -> {:error, reason}
        {:ok, input, output, _reason} -> {:ok, input, length(output)}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Repeats the embedded parser m..n times

  This stops before n when the parser returns Error and returns the results that were accumulated. To instead chain an error up, see cut/1.

      iex> parser = many_m_n(0, 2, tag("abc"))
      iex> parser.("abcabc")
      {:ok, "", ["abc", "abc"]}
      iex> parser.("abc123")
      {:ok, "123", ["abc"]}
      iex> parser.("123123")
      {:ok, "123123", []}
      iex> parser.("")
      {:ok, "", []}
      iex> parser.("abcabcabc")
      {:ok, "abc", ["abc", "abc"]}

      iex> parser = many_m_n(2, 2, tag("abc"))
      iex> parser.("abcabc")
      {:ok, "", ["abc", "abc"]}
      iex> parser.("abc")
      {:error, %Error{kind: :many_m_n, buffer: ""}}
      iex> parser.("")
      {:error, %Error{kind: :many_m_n, buffer: ""}}
  """
  def many_m_n(min, max, parser) do
    fn input ->
      case many_internal(parser, input, max, []) do
        {:ok, input, output, _} ->
          if length(output) < min do
            {:error, Error.new(:many_m_n, input)}
          else
            {:ok, input, output}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp many0_internal(parser, input, output) do
    case parser.(input) do
      {:ok, input, ""} ->
        # Prevent an infinite loop
        {:error, Error.new(:many, input)}

      {:ok, input, data} ->
        many0_internal(parser, input, [data | output])

      {:error, %Failure{} = reason} ->
        {:error, reason}

      {:error, reason} ->
        {:ok, input, Enum.reverse(output), reason}
    end
  end

  defp many_internal(_parser, input, 0, output), do: {:ok, input, Enum.reverse(output), nil}

  defp many_internal(parser, input, max, output) do
    case parser.(input) do
      {:ok, input, ""} ->
        # Prevent an infinite loop
        {:error, Error.new(:many, input)}

      {:ok, input, data} ->
        many_internal(parser, input, max - 1, [data | output])

      {:error, %Failure{} = reason} ->
        {:error, reason}

      {:error, reason} ->
        {:ok, input, Enum.reverse(output), reason}
    end
  end

  @doc """
  Applies the parser `parser` until the parser `until` produces a result.

  Returns a tuple of the results of `parser` in a list and the result of `until`.

  `parser` keeps going so long as `until` produces Error. To instead chain an error up, see cut/1.

      iex> parser = many_till(tag("abc"), tag("end"))
      iex> parser.("abcabcend")
      {:ok, "", {["abc", "abc"], "end"}}
      iex> parser.("abc123end")
      {:error, %Error{kind: :tag, buffer: "123end"}}
      iex> parser.("123123end")
      {:error, %Error{kind: :tag, buffer: "123123end"}}
      iex> parser.("")
      {:error, %Error{kind: :tag, buffer: ""}}
      iex> parser.("abcendefg")
      {:ok, "efg", {["abc"], "end"}}
      iex> parser.("endabc")
      {:ok, "abc", {[], "end"}}
  """
  def many_till(parser, until) do
    fn input ->
      many_till_internal(parser, until, input, [])
    end
  end

  defp many_till_internal(parser, until, input, output) do
    case until.(input) do
      {:ok, input, data} ->
        {:ok, input, {Enum.reverse(output), data}}

      {:error, %Failure{} = reason} ->
        {:error, reason}

      {:error, _} ->
        case parser.(input) do
          {:ok, input, data} ->
            many_till_internal(parser, until, input, [data | output])

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc """
  Alternates between two parsers to produce a list of elements.

  This stops when either parser returns Error and returns the results that were accumulated. To instead chain an error up, see cut/1.

      iex> parser = separated_list0(tag("|"), tag("abc"))
      iex> parser.("abc|abc|abc")
      {:ok, "", ["abc", "abc", "abc"]}
      iex> parser.("abc123abc")
      {:ok, "123abc", ["abc"]}
      iex> parser.("abc|def")
      {:ok, "|def", ["abc"]}
      iex> parser.("")
      {:ok, "", []}
      iex> parser.("def|abc")
      {:ok, "def|abc", []}

      iex> parser = separated_list0(map(digit1(), &String.to_integer/1), tag("abc"))
      iex> parser.("abc23abc")
      {:ok, "", ["abc", "abc"]}
  """
  def separated_list0(separator, parser) do
    fn input ->
      case parser.(input) do
        {:ok, input, output} ->
          separated_list_internal(recognize(separator), parser, input, [output])

        {:error, %Failure{} = reason} ->
          {:error, reason}

        {:error, _} ->
          {:ok, input, []}
      end
    end
  end

  @doc """
  Alternates between two parsers to produce a list of elements until Error.

  Fails if the element parser does not produce at least one element.

  This stops when either parser returns Error and returns the results that were accumulated. To instead chain an error up, see cut/1.

      iex> parser = separated_list1(tag("|"), tag("abc"))
      iex> parser.("abc|abc|abc")
      {:ok, "", ["abc", "abc", "abc"]}
      iex> parser.("abc123abc")
      {:ok, "123abc", ["abc"]}
      iex> parser.("abc|def")
      {:ok, "|def", ["abc"]}
      iex> parser.("")
      {:error, %Error{kind: :tag, buffer: ""}}
      iex> parser.("def|abc")
      {:error, %Error{kind: :tag, buffer: "def|abc"}}
  """
  def separated_list1(separator, parser) do
    fn input ->
      case parser.(input) do
        {:ok, input, output} ->
          separated_list_internal(recognize(separator), parser, input, [output])

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp separated_list_internal(separator, parser, input, output) do
    case separator.(input) do
      {:ok, sep_input, _} ->
        case parser.(sep_input) do
          {:ok, input, data} ->
            separated_list_internal(separator, parser, input, [data | output])

          {:error, %Failure{} = reason} ->
            {:error, reason}

          {:error, _} ->
            {:ok, input, Enum.reverse(output)}
        end

      {:error, %Failure{} = reason} ->
        {:error, reason}

      {:error, _} ->
        {:ok, input, Enum.reverse(output)}
    end
  end
end
