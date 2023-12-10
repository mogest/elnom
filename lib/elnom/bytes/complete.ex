defmodule Elnom.Bytes.Complete do
  @moduledoc """
  Parsers recognising byte streams.  Only for use with bitstrings, use `Elnom.Strings.Complete` for strings.
  """

  alias Elnom.Error

  @doc """
  Matches a bitstring with escaped bytes.

  Warning: This function is for use with bitstrings only.  For strings, use
  `Elnom.Strings.Complete.escaped/3`.

  The first argument matches the normal bytes (it must not accept the control byte)
  The second argument is the control byte
  The third argument matches the escaped bytes

      iex> esc = escaped(is_a(<<1, 2, 3>>), <<0>>, one_of(<<4, 5>>))
      iex> esc.(<<2, 2, 1, 5>>)
      {:ok, <<5>>, <<2, 2, 1>>}
      iex> esc.(<<2, 2, 0, 4, 1, 5>>)
      {:ok, <<5>>, <<2, 2, 0, 4, 1>>}
  """
  def escaped(normal, <<control>>, escapable) do
    fn input ->
      escaped_internal(normal, control, escapable, input, "")
    end
  end

  defp escaped_internal(normal, control, escapable, input, accumulator, success \\ false)

  defp escaped_internal(
         normal,
         control,
         escapable,
         <<control, input::binary>>,
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
          <<accumulator::binary, control, escaped_output::binary>>,
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

  @doc """
  Matches a bitstring with escaped bytes.

  Warning: This function is for use with bitstrings only.  For strings, use
  `Elnom.Strings.Complete.escaped_transform/3`.

  * The first argument matches the normal bytes (it must not match the control byte)
  * The second argument is the control byte
  * The third argument matches the escaped bytes and transforms them

  Example:

      iex> esc = escaped_transform(
      ...>   is_a(<<1, 2, 3>>),
      ...>   <<0>>,
      ...>   alt({
      ...>     value(<<44>>, tag(<<4>>)),
      ...>     value(<<55>>, tag(<<5>>)),
      ...>     value(<<66>>, tag(<<6>>))
      ...>   })
      ...> )
      iex> esc.(<<2, 2, 1>>)
      {:ok, <<>>, <<2, 2, 1>>}
      iex> esc.(<<2, 2, 1, 0, 4, 0, 5, 1, 5>>)
      {:ok, <<5>>, <<2, 2, 1, 44, 55, 1>>}
  """
  def escaped_transform(normal, <<control>>, transform) do
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
         <<control, input::binary>>,
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
  Returns the longest match of the matches the pattern.

  Warning: This function is for use with bitstrings only.  For strings, use
  `Elnom.Strings.Complete.is_a/1`.

  The parser will return the longest match consisting of the bytes in provided in the combinator’s argument.

  It will return an Error if the pattern wasn’t met.

      iex> hex = is_a(<<244, 13, 15>>)
      iex> hex.(<<13, 13, 244, 14, 15>>)
      {:ok, <<14, 15>>, <<13, 13, 244>>}
      iex> hex.(<<6>>)
      {:error, %Error{kind: :is_a, buffer: <<6>>}}
      iex> hex.(<<>>)
      {:error, %Error{kind: :is_a, buffer: <<>>}}
  """
  def is_a(bytes) do
    list = :binary.bin_to_list(bytes) |> MapSet.new()
    take_while1(fn byte -> byte in list end, :is_a)
  end

  @doc """
  Parse till certain characters are met.

  Warning: This function is for use with bitstrings only.  For strings, use
  `Elnom.Strings.Complete.is_not/1`.

  The parser will return the longest match till one of the characters of the combinator’s argument are met.

  It doesn’t consume the matched character.

      iex> parser = is_not(<<1, 220>>)
      iex> parser.(<<3, 4, 5, 1, 7>>)
      {:ok, <<1, 7>>, <<3, 4, 5>>}
      iex> parser.(<<3, 4, 5>>)
      {:ok, <<>>, <<3, 4, 5>>}
      iex> parser.(<<220, 4>>)
      {:error, %Error{kind: :is_not, buffer: <<220, 4>>}}
      iex> parser.("")
      {:error, %Error{kind: :is_not, buffer: ""}}
  """
  def is_not(bytes) do
    list = :binary.bin_to_list(bytes) |> MapSet.new()
    take_while1(fn byte -> byte not in list end, :is_not)
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
  defdelegate tag(tag), to: Elnom.Strings.Complete

  @doc """
  Returns an input substring containing the first `count` input bytes.

  Warning: This function is for use with bitstrings only.  For strings, use
  `Elnom.Strings.Complete.take/1`.

  It will return Error if the input is shorter than the argument.

      iex> take(1).("💙")
      {:ok, <<0x9f, 0x92, 0x99>>, <<0xf0>>}

      iex> take6 = take(6)
      iex> take6.(<<1, 2, 3, 4, 5, 6, 7>>)
      {:ok, <<7>>, <<1, 2, 3, 4, 5, 6>>}
      iex> take6.(<<1, 2, 3, 4, 5, 6>>)
      {:ok, <<>>, <<1, 2, 3, 4, 5, 6>>}
      iex> take6.(<<1, 2, 3>>)
      {:error, %Error{kind: :eof, buffer: <<1, 2, 3>>}}
      iex> take6.(<<>>)
      {:error, %Error{kind: :eof, buffer: <<>>}}
  """
  def take(count) do
    fn
      <<output::binary-size(count)>> <> rest ->
        {:ok, rest, output}

      input ->
        {:error, Error.new(:eof, input)}
    end
  end

  @doc """
  Returns the longest matching input (if any) till a predicate is met.

  Warning: This function is for use with bitstrings only.  For strings, use
  `Elnom.Strings.Complete.take_till/1`.

  The parser will return the longest match till the given predicate (a function that takes the input and returns a bool).

      iex> till_colon = take_till(fn byte -> byte > 200 end)
      iex> till_colon.(<<4, 99, 180, 215, 5>>)
      {:ok, <<215, 5>>, <<4, 99, 180>>}
      iex> till_colon.(<<215, 5>>)
      {:ok, <<215, 5>>, <<>>}
      iex> till_colon.(<<4, 99>>)
      {:ok, <<>>, <<4, 99>>}
      iex> till_colon.(<<>>)
      {:ok, <<>>, <<>>}
  """
  def take_till(predicate) do
    fn input ->
      {input, match} = take_till_internal(predicate, input)
      {:ok, input, match}
    end
  end

  @doc """
  Returns the longest matching input (at least 1) till a predicate is met.

  Warning: This function is for use with bitstrings only.  For strings, use
  `Elnom.Strings.Complete.take_till1/1`.

  The parser will return the longest match till the given predicate (a function that takes the input and returns a bool).

  It will return Error if the input is empty or the predicate matches the first input.

      iex> till_colon = take_till1(fn byte -> byte > 200 end)
      iex> till_colon.(<<4, 99, 180, 215, 5>>)
      {:ok, <<215, 5>>, <<4, 99, 180>>}
      iex> till_colon.(<<215, 5>>)
      {:error, %Error{kind: :take_till1, buffer: <<215, 5>>}}
      iex> till_colon.(<<4, 99>>)
      {:ok, <<>>, <<4, 99>>}
      iex> till_colon.(<<>>)
      {:error, %Error{kind: :take_till1, buffer: <<>>}}
  """
  def take_till1(predicate) do
    fn
      <<byte>> <> rest = input ->
        if predicate.(byte) do
          {:error, Error.new(:take_till1, input)}
        else
          {input, more} = take_till_internal(predicate, rest)
          {:ok, input, <<byte, more::binary>>}
        end

      "" ->
        {:error, Error.new(:take_till1, "")}
    end
  end

  defp take_till_internal(predicate, input) do
    case input do
      <<byte>> <> rest ->
        if predicate.(byte) do
          {input, ""}
        else
          {input, more} = take_till_internal(predicate, rest)
          {input, <<byte, more::binary>>}
        end

      _ ->
        {input, ""}
    end
  end

  @doc """
  Returns the input up to the first occurrence of the pattern.

  Warning: This function is for use with bitstrings only.  For strings, use
  `Elnom.Strings.Complete.take_until/1`.

  It doesn’t consume the pattern. It will return Error if the pattern wasn’t met.

      iex> until_eof = take_until(<<255, 0, 255>>)
      iex> until_eof.(<<30, 108, 255, 34, 255, 0, 255, 7>>)
      {:ok, <<255, 0, 255, 7>>, <<30, 108, 255, 34>>}
      iex> until_eof.(<<30, 108, 255, 0>>)
      {:error, %Error{kind: :take_until, buffer: <<30, 108, 255, 0>>}}
      iex> until_eof.(<<255, 0, 255>>)
      {:ok, <<255, 0, 255>>, <<>>}
      iex> until_eof.(<<>>)
      {:error, %Error{kind: :take_until, buffer: <<>>}}
  """
  def take_until(pattern) do
    fn input ->
      case :binary.split(input, pattern) do
        [match, rest] -> {:ok, pattern <> rest, match}
        _ -> {:error, Error.new(:take_until, input)}
      end
    end
  end

  @doc """
  Returns the non empty input up to the first occurrence of the pattern.

  Warning: This function is for use with bitstrings only.  For strings, use
  `Elnom.Strings.Complete.take_until1/1`.

  It doesn’t consume the pattern. It will return Error if the pattern wasn’t met.

      iex> until_eof = take_until1(<<255, 0, 255>>)
      iex> until_eof.(<<30, 108, 255, 34, 255, 0, 255, 7>>)
      {:ok, <<255, 0, 255, 7>>, <<30, 108, 255, 34>>}
      iex> until_eof.(<<30, 108, 255, 0>>)
      {:error, %Error{kind: :take_until, buffer: <<30, 108, 255, 0>>}}
      iex> until_eof.(<<255, 0, 255>>)
      {:error, %Error{kind: :take_until, buffer: <<255, 0, 255>>}}
      iex> until_eof.(<<>>)
      {:error, %Error{kind: :take_until, buffer: <<>>}}
  """
  def take_until1(pattern) do
    fn input ->
      case :binary.split(input, pattern) do
        [<<>>, _] -> {:error, Error.new(:take_until, input)}
        [match, rest] -> {:ok, pattern <> rest, match}
        _ -> {:error, Error.new(:take_until, input)}
      end
    end
  end

  @doc """
  Returns the longest input match (if any) that matches the predicate.

  Warning: This function is for use with bitstrings only.  For strings, use
  `Elnom.Strings.Complete.take_while/1`.

  The parser will return the longest match that matches the given predicate (a function that takes the input and returns a bool).

      iex> high = take_while(fn byte -> byte >= 200 end)
      iex> high.(<<200, 201, 205, 7, 210>>)
      {:ok, <<7, 210>>, <<200, 201, 205>>}
      iex> high.(<<5, 6, 255>>)
      {:ok, <<5, 6, 255>>, <<>>}
      iex> high.(<<210, 210, 210>>)
      {:ok, <<>>, <<210, 210, 210>>}
      iex> high.(<<>>)
      {:ok, <<>>, <<>>}
  """
  def take_while(predicate) do
    fn input ->
      {input, data} = take_while_internal(predicate, input, :take_while)
      {:ok, input, data}
    end
  end

  @doc """
  Returns the longest (at least 1) input match that matches the predicate.

  Warning: This function is for use with bitstrings only.  For strings, use
  `Elnom.Strings.Complete.take_while1/1`.

  The parser will return the longest match that matches the given predicate (a function that takes the input and returns a bool).

  It will return an Error if the pattern wasn’t met.

      iex> high = take_while1(fn byte -> byte >= 200 end)
      iex> high.(<<200, 201, 205, 7, 210>>)
      {:ok, <<7, 210>>, <<200, 201, 205>>}
      iex> high.(<<5, 6, 255>>)
      {:error, %Error{kind: :take_while1, buffer: <<5, 6, 255>>}}
      iex> high.(<<210, 210, 210>>)
      {:ok, <<>>, <<210, 210, 210>>}
      iex> high.(<<>>)
      {:error, %Error{kind: :take_while1, buffer: <<>>}}
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
  Returns the longest (min <= len <= max) input match that matches the predicate.

  Warning: This function is for use with bitstrings only.  For strings, use
  `Elnom.Strings.Complete.take_while_m_n/3`.

  The parser will return the longest match that matches the given predicate (a function that takes the input and returns a bool).

  It will return an Error if the pattern wasn’t met or is out of range.

      iex> short_alpha = take_while_m_n(3, 6, fn byte -> byte >= 200 end)
      iex> short_alpha.(<<205, 210, 215, 220, 225, 80, 90>>)
      {:ok, <<80, 90>>, <<205, 210, 215, 220, 225>>}
      iex> short_alpha.(<<200, 205, 210, 215, 220, 225, 230, 235>>)
      {:ok, <<230, 235>>, <<200, 205, 210, 215, 220, 225>>}
      iex> short_alpha.(<<220, 200, 220, 200, 205>>)
      {:ok, <<>>, <<220, 200, 220, 200, 205>>}
      iex> short_alpha.(<<220, 200>>)
      {:error, %Error{kind: :take_while_m_n, buffer: <<220, 200>>}}
      iex> short_alpha.(<<5, 6, 7>>)
      {:error, %Error{kind: :take_while_m_n, buffer: <<5, 6, 7>>}}
  """
  def take_while_m_n(min, max, predicate) do
    fn input ->
      case take_while_internal(predicate, input, max, :take_while_m_n) do
        {input, <<_::binary-size(min)>> <> _ = output} ->
          {:ok, input, output}

        _ ->
          {:error, Error.new(:take_while_m_n, input)}
      end
    end
  end

  defp take_while_internal(predicate, input, max \\ nil, kind)
  defp take_while_internal(_predicate, input, 0, _kind), do: {input, ""}

  defp take_while_internal(predicate, input, max, kind) do
    case input do
      <<byte>> <> rest ->
        if predicate.(byte) do
          max = max && max - 1
          {input, more} = take_while_internal(predicate, rest, max, kind)
          {input, <<byte, more::binary>>}
        else
          {input, ""}
        end

      _ ->
        {input, ""}
    end
  end
end
