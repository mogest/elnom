defmodule Elnom.Strings.Complete do
  @moduledoc """
  Parsers recognising utf-8 strings.

  If you're working with binary (non-utf8) data, use `Elnom.Bytes.Complete` instead.
  """

  alias Elnom.Error

  @doc ~S"""
  Matches a string with escaped characters.

  The first argument matches the normal characters (it must not accept the control character)
  The second argument is the control character (like \\ in most languages)
  The third argument matches the escaped characters

      iex> esc = escaped(digit1(), "\\", one_of("rn;"))
      iex> esc.("123;")
      {:ok, ";", "123"}
      iex> esc.("123\\;456;")
      {:ok, ";", "123\\;456"}
  """
  def escaped(normal, <<control::utf8>>, escapable) do
    fn input ->
      escaped_internal(normal, control, escapable, input, "")
    end
  end

  defp escaped_internal(normal, control, escapable, input, accumulator, success \\ false)

  defp escaped_internal(
         normal,
         control,
         escapable,
         <<control::utf8, input::binary>>,
         accumulator,
         _success
       ) do
    case escapable.(input) do
      {:ok, input, escaped_output} ->
        escaped_internal(
          normal,
          control,
          escapable,
          input,
          <<accumulator::binary, control::utf8, escaped_output::binary>>,
          true
        )

      {:error, _} ->
        {:error, %Error{kind: :escaped, buffer: input}}
    end
  end

  defp escaped_internal(normal, control, escapable, input, accumulator, success) do
    case normal.(input) do
      {:ok, input, output} ->
        escaped_internal(normal, control, escapable, input, accumulator <> output, true)

      {:error, %Error{} = reason} ->
        if success do
          {:ok, input, accumulator}
        else
          {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc ~S"""
  Matches a byte string with escaped characters.

  * The first argument matches the normal characters (it must not match the control character)
  * The second argument is the control character (like \ in most languages)
  * The third argument matches the escaped characters and transforms them

  As an example, the chain `abc\tdef` could be `abc    def` (it also consumes the control character)

      iex> esc = escaped_transform(
      ...>   alpha1(),
      ...>   "\\",
      ...>   alt({
      ...>     value("\\", tag("\\")),
      ...>     value("\"", tag("\"")),
      ...>     value("\n", tag("n"))
      ...>   })
      ...> )
      iex> esc.("abc")
      {:ok, "", "abc"}
      iex> esc.("ab\\\"cd")
      {:ok, "", "ab\"cd"}
      iex> esc.("ab\\ncd")
      {:ok, "", "ab\ncd"}
  """
  def escaped_transform(normal, <<control::utf8>>, transform) do
    fn input ->
      escaped_transform_internal(normal, control, transform, input, "")
    end
  end

  defp escaped_transform_internal(
         normal,
         control,
         transform,
         input,
         accumulator,
         success \\ false
       )

  defp escaped_transform_internal(
         normal,
         control,
         transform,
         <<control::utf8, input::binary>>,
         accumulator,
         _success
       ) do
    case transform.(input) do
      {:ok, input, output} ->
        escaped_transform_internal(normal, control, transform, input, accumulator <> output, true)

      {:error, _} ->
        {:error, %Error{kind: :escaped, buffer: input}}
    end
  end

  defp escaped_transform_internal(normal, control, transform, input, accumulator, success) do
    case normal.(input) do
      {:ok, input, output} ->
        escaped_transform_internal(normal, control, transform, input, accumulator <> output, true)

      {:error, %Error{} = reason} ->
        if success do
          {:ok, input, accumulator}
        else
          {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Returns the longest substring of the matches the pattern.

  The parser will return the longest substring consisting of the characters in provided in the combinator’s argument.

  It will return an Error if the pattern wasn’t met.

      iex> hex = is_a("0123456789ABCDEF")
      iex> hex.("123 and voila")
      {:ok, " and voila", "123"}
      iex> hex.("DEADBEEF and others")
      {:ok, " and others", "DEADBEEF"}
      iex> hex.("D15EA5E")
      {:ok, "", "D15EA5E"}
      iex> hex.("other")
      {:error, %Error{kind: :is_a, buffer: "other"}}
      iex> hex.("")
      {:error, %Error{kind: :is_a, buffer: ""}}
  """
  def is_a(chars) do
    chars = String.to_charlist(chars) |> MapSet.new()
    take_while1(fn char -> char in chars end, :is_a)
  end

  @doc """
  Parse till certain characters are met.

  The parser will return the longest substring till one of the characters of the combinator’s argument are met.

  It doesn’t consume the matched character.

      iex> not_space = is_not(" \\t\\r\\n")
      iex> not_space.("Hello, World!")
      {:ok, " World!", "Hello,"}
      iex> not_space.("Sometimes\\t")
      {:ok, "\\t", "Sometimes"}
      iex> not_space.("Nospace")
      {:ok, "", "Nospace"}
      iex> not_space.(" hello")
      {:error, %Error{kind: :is_not, buffer: " hello"}}
      iex> not_space.("")
      {:error, %Error{kind: :is_not, buffer: ""}}
  """
  def is_not(chars) do
    chars = String.to_charlist(chars) |> MapSet.new()
    take_while1(fn char -> char not in chars end, :is_not)
  end

  @doc """
  Recognizes a pattern

  The input data will be compared to the tag combinator’s argument and will return the part of the input that matches the argument.

  It will return an Error if the input doesn’t match the pattern.

      iex> tag("hello").("hello there")
      {:ok, " there", "hello"}
      iex> tag("hello").("bye")
      {:error, %Error{kind: :tag, buffer: "bye"}}
      iex> tag("").("bye")
      {:ok, "bye", ""}
      iex> tag("💙").("💙💙")
      {:ok, "💙", "💙"}
  """
  def tag(tag) when is_binary(tag) do
    fn input ->
      n = byte_size(tag)

      case input do
        <<^tag::binary-size(n)>> <> input -> {:ok, input, tag}
        _ -> {:error, Error.new(:tag, input)}
      end
    end
  end

  @doc """
  Recognizes a case insensitive pattern.

  The input data will be compared to the tag combinator’s argument and will return the part of the input that matches the argument with no regard to case.

  It will return an Error if the input doesn’t match the pattern.

      iex> parser = tag_no_case("hello")
      iex> parser.("Hello, World!")
      {:ok, ", World!", "Hello"}
      iex> parser.("hello, World!")
      {:ok, ", World!", "hello"}
      iex> parser.("HeLlO, World!")
      {:ok, ", World!", "HeLlO"}
      iex> parser.("Something")
      {:error, %Error{kind: :tag, buffer: "Something"}}
      iex> parser.("")
      {:error, %Error{kind: :tag, buffer: ""}}
  """
  def tag_no_case(tag) when is_binary(tag) do
    tag = String.downcase(tag)
    n = byte_size(tag)

    fn input ->
      case input do
        <<partial::binary-size(n)>> <> rest ->
          if String.downcase(partial) == tag do
            {:ok, rest, partial}
          else
            {:error, Error.new(:tag, input)}
          end

        _ ->
          {:error, Error.new(:tag, input)}
      end
    end
  end

  @doc """
  Returns an input substring containing the first `count` utf-8 input characters.

  It will return Error if the input is shorter than the argument.

      iex> take6 = take(6)
      iex> take6.("1234567")
      {:ok, "7", "123456"}
      iex> take6.("things")
      {:ok, "", "things"}
      iex> take6.("short")
      {:error, %Error{kind: :eof, buffer: "short"}}
      iex> take6.("")
      {:error, %Error{kind: :eof, buffer: ""}}
      iex> take(1).("💙")
      {:ok, "", "💙"}
  """
  def take(count) do
    fn input ->
      if String.length(input) >= count do
        {match, rest} = String.split_at(input, count)
        {:ok, rest, match}
      else
        {:error, Error.new(:eof, input)}
      end
    end
  end

  @doc """
  Returns the longest input substring (if any) till a predicate is met.

  The parser will return the longest substring till the given predicate (a function that takes the input and returns a bool).

      iex> till_colon = take_till(fn char -> char == ?\\: end)
      iex> till_colon.("latin:123")
      {:ok, ":123", "latin"}
      iex> till_colon.(":empty matched")
      {:ok, ":empty matched", ""}
      iex> till_colon.("12345")
      {:ok, "", "12345"}
      iex> till_colon.("")
      {:ok, "", ""}
  """
  def take_till(predicate) do
    fn input ->
      {input, match} = take_till_internal(predicate, input)
      {:ok, input, match}
    end
  end

  @doc """
  Returns the longest input substring (at least 1) till a predicate is met.

  The parser will return the longest substring till the given predicate (a function that takes the input and returns a bool).

  It will return Error if the input is empty or the predicate matches the first input.

      iex> till_colon = take_till1(fn char -> char == ?\: end)
      iex> till_colon.("latin:123")
      {:ok, ":123", "latin"}
      iex> till_colon.(":empty matched")
      {:error, %Error{kind: :take_till1, buffer: ":empty matched"}}
      iex> till_colon.("12345")
      {:ok, "", "12345"}
      iex> till_colon.("")
      {:error, %Error{kind: :take_till1, buffer: ""}}
  """
  def take_till1(predicate) do
    fn
      <<char::utf8>> <> rest = input ->
        if predicate.(char) do
          {:error, Error.new(:take_till1, input)}
        else
          {input, more} = take_till_internal(predicate, rest)
          {:ok, input, <<char::utf8, more::binary>>}
        end

      "" ->
        {:error, Error.new(:take_till1, "")}
    end
  end

  defp take_till_internal(predicate, input) do
    case input do
      <<char::utf8>> <> rest ->
        if predicate.(char) do
          {input, ""}
        else
          {input, more} = take_till_internal(predicate, rest)
          {input, <<char::utf8, more::binary>>}
        end

      _ ->
        {input, ""}
    end
  end

  @doc """
  Returns the input substring up to the first occurrence of the pattern.

  It doesn’t consume the pattern. It will return Error if the pattern wasn’t met.

      iex> until_eof = take_until("eof")
      iex> until_eof.("hello, worldeof")
      {:ok, "eof", "hello, world"}
      iex> until_eof.("hello, world")
      {:error, %Error{kind: :take_until, buffer: "hello, world"}}
      iex> until_eof.("eof")
      {:ok, "eof", ""}
      iex> until_eof.("")
      {:error, %Error{kind: :take_until, buffer: ""}}
      iex> until_eof.("1eof2eof")
      {:ok, "eof2eof", "1"}
  """
  def take_until(pattern) do
    fn input ->
      case String.split(input, pattern, parts: 2) do
        [match, rest] -> {:ok, pattern <> rest, match}
        _ -> {:error, Error.new(:take_until, input)}
      end
    end
  end

  @doc """
  Returns the non empty input substring up to the first occurrence of the pattern.

  It doesn’t consume the pattern. It will return Error if the pattern wasn’t met.

      iex> until_eof = take_until1("eof")
      iex> until_eof.("hello, worldeof")
      {:ok, "eof", "hello, world"}
      iex> until_eof.("hello, world")
      {:error, %Error{kind: :take_until, buffer: "hello, world"}}
      iex> until_eof.("eof")
      {:error, %Error{kind: :take_until, buffer: "eof"}}
      iex> until_eof.("")
      {:error, %Error{kind: :take_until, buffer: ""}}
      iex> until_eof.("1eof2eof")
      {:ok, "eof2eof", "1"}
  """
  def take_until1(pattern) do
    fn input ->
      case String.split(input, pattern, parts: 2) do
        ["", _] -> {:error, Error.new(:take_until, input)}
        [match, rest] -> {:ok, pattern <> rest, match}
        _ -> {:error, Error.new(:take_until, input)}
      end
    end
  end

  @doc """
  Returns the longest input substring (if any) that matches the predicate.

  The parser will return the longest substring that matches the given predicate (a function that takes the input and returns a bool).

      iex> alpha = take_while(&is_alphabetic/1)
      iex> alpha.("latin123")
      {:ok, "123", "latin"}
      iex> alpha.("12345")
      {:ok, "12345", ""}
      iex> alpha.("latin")
      {:ok, "", "latin"}
      iex> alpha.("") == {:ok, "", ""}
  """
  def take_while(predicate) do
    fn input ->
      {input, data} = take_while_internal(predicate, input, :take_while)
      {:ok, input, data}
    end
  end

  @doc """
  Returns the longest (at least 1) input substring that matches the predicate.

  The parser will return the longest substring that matches the given predicate (a function that takes the input and returns a bool).

  It will return an Error if the pattern wasn’t met.

      iex> alpha = take_while1(&is_alphabetic/1)
      iex> alpha.("latin123")
      {:ok, "123", "latin"}
      iex> alpha.("12345")
      {:error, %Error{kind: :take_while1, buffer: "12345"}}
      iex> alpha.("latin")
      {:ok, "", "latin"}
      iex> alpha.("")
      {:error, %Error{kind: :take_while1, buffer: ""}}
  """
  def take_while1(predicate, kind \\ :take_while1) do
    fn input ->
      case take_while_internal(predicate, input, kind) do
        {input, ""} -> {:error, Error.new(kind, input)}
        {input, data} -> {:ok, input, data}
      end
    end
  end

  @doc """
  Returns the longest (min <= len <= max) input substring that matches the predicate.

  The parser will return the longest substring that matches the given predicate (a function that takes the input and returns a bool).

  It will return an Error if the pattern wasn’t met or is out of range.

      iex> short_alpha = take_while_m_n(3, 6, &is_alphabetic/1)
      iex> short_alpha.("latin123")
      {:ok, "123", "latin"}
      iex> short_alpha.("lengthy")
      {:ok, "y", "length"}
      iex> short_alpha.("latin")
      {:ok, "", "latin"}
      iex> short_alpha.("ed")
      {:error, %Error{kind: :take_while_m_n, buffer: "ed"}}
      iex> short_alpha.("12345")
      {:error, %Error{kind: :take_while_m_n, buffer: "12345"}}
  """
  def take_while_m_n(min, max, predicate) do
    fn input ->
      {new_input, data} =
        take_while_internal(predicate, input, max, :take_while_m_n)

      if String.length(data) < min do
        {:error, Error.new(:take_while_m_n, input)}
      else
        {:ok, new_input, data}
      end
    end
  end

  defp take_while_internal(predicate, input, max \\ :infinite, kind)

  defp take_while_internal(predicate, input, :infinite, kind) do
    case input do
      <<char::utf8>> <> rest ->
        if predicate.(char) do
          {input, more} = take_while_internal(predicate, rest, :infinite, kind)
          {input, <<char::utf8, more::binary>>}
        else
          {input, ""}
        end

      _ ->
        {input, ""}
    end
  end

  defp take_while_internal(_predicate, input, 0, _kind), do: {input, ""}

  defp take_while_internal(predicate, input, max, kind) do
    case input do
      <<char::utf8>> <> rest ->
        if predicate.(char) do
          {input, more} = take_while_internal(predicate, rest, max - 1, kind)
          {input, <<char::utf8, more::binary>>}
        else
          {input, ""}
        end

      _ ->
        {input, ""}
    end
  end
end
