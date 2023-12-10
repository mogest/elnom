defmodule Elnom.Character.Complete do
  @moduledoc "Parser functions recognizing specific characters"

  alias Elnom.Error

  @doc """
  Recognizes zero or more lowercase and uppercase ASCII alphabetic characters: a-z, A-Z

  Complete version: Will return the whole input if no terminating token is found (a non alphabetic character).

      iex> alpha0().("aB1c")
      {:ok, "1c", "aB"}
      iex> alpha0().("1c")
      {:ok, "1c", ""}
      iex> alpha0().("")
      {:ok, "", ""}
  """
  def alpha0, do: fn input -> alpha_internal(input) end

  @doc """
  Recognizes one or more lowercase and uppercase ASCII alphabetic characters: a-z, A-Z

  Complete version: Will return an error if there’s not enough input data, or the whole input if no terminating token is found (a non alphabetic character).

      iex> alpha1().("aB1c")
      {:ok, "1c", "aB"}
      iex> alpha1().("1c")
      {:error, %Error{kind: :alpha, buffer: "1c"}}
      iex> alpha1().("")
      {:error, %Error{kind: :alpha, buffer: ""}}
  """
  def alpha1 do
    fn input ->
      error_if_empty(alpha_internal(input), :alpha)
    end
  end

  defp alpha_internal(<<char::utf8, rest::binary>>) when char in ?a..?z or char in ?A..?Z do
    {:ok, rest, more} = alpha_internal(rest)
    {:ok, rest, <<char::utf8, more::binary>>}
  end

  defp alpha_internal(input), do: {:ok, input, ""}

  @doc """
  Recognizes zero or more ASCII numerical and alphabetic characters: 0-9, a-z, A-Z

  Complete version: Will return the whole input if no terminating token is found (a non alphanumerical character).

      iex> alphanumeric0().("21cZ%1")
      {:ok, "%1", "21cZ"}
      iex> alphanumeric0().("%1")
      {:ok, "%1", ""}
      iex> alphanumeric0().("")
      {:ok, "", ""}
  """
  def alphanumeric0, do: fn input -> alphanumeric_internal(input) end

  @doc """
  Recognizes one or more ASCII numerical and alphabetic characters: 0-9, a-z, A-Z

  Complete version: Will return an error if there’s not enough input data, or the whole input if no terminating token is found (a non alphanumerical character).

      iex> alphanumeric1().("21cZ%1")
      {:ok, "%1", "21cZ"}
      iex> alphanumeric1().("%1")
      {:error, %Error{kind: :alphanumeric, buffer: "%1"}}
      iex> alphanumeric1().("")
      {:error, %Error{kind: :alphanumeric, buffer: ""}}
  """
  def alphanumeric1 do
    fn input ->
      error_if_empty(alphanumeric_internal(input), :alphanumeric)
    end
  end

  defp alphanumeric_internal(<<char::utf8, rest::binary>>)
       when char in ?a..?z or char in ?A..?Z or char in ?0..?9 do
    {:ok, rest, more} = alphanumeric_internal(rest)
    {:ok, rest, <<char::utf8, more::binary>>}
  end

  defp alphanumeric_internal(input), do: {:ok, input, ""}

  @doc """
  Matches one utf-8 character.

  Complete version: Will return an error if there’s not enough input data.

      iex> anychar().("abc")
      {:ok, "bc", "a"}
      iex> anychar().("")
      {:error, %Error{kind: :anychar, buffer: ""}}
  """
  def anychar do
    fn
      <<char::utf8>> <> rest -> {:ok, rest, <<char::utf8>>}
      "" -> {:error, Error.new(:anychar, "")}
    end
  end

  @doc """
  Recognizes one utf-8 character.

  Complete version: Will return an error if there’s not enough input data.

      iex> char("h").("hello")
      {:ok, "ello", "h"}
      iex> char("e").("hello")
      {:error, %Error{kind: :char, buffer: "hello"}}
  """
  def char(<<char::utf8>>) do
    fn
      <<^char::utf8>> <> input -> {:ok, input, <<char::utf8>>}
      input -> {:error, Error.new(:char, input)}
    end
  end

  @doc ~S"""
  Recognizes the string “\r\n”.

  Complete version: Will return an error if there’s not enough input data.

      iex> crlf().("\r\nc")
      {:ok, "c", "\r\n"}
      iex> crlf().("ab\r\nc")
      {:error, %Error{kind: :crlf, buffer: "ab\r\nc"}}
      iex> crlf().("")
      {:error, %Error{kind: :crlf, buffer: ""}}
  """
  def crlf do
    fn
      <<?\r::utf8, ?\n::utf8>> <> input -> {:ok, input, <<?\r::utf8, ?\n::utf8>>}
      input -> {:error, Error.new(:crlf, input)}
    end
  end

  @doc """
  Recognizes zero or more ASCII numerical characters: 0-9

  Complete version: Will return an error if there’s not enough input data, or the whole input if no terminating token is found (a non digit character).

      iex> digit0().("21c")
      {:ok, "c", "21"}
      iex> digit0().("21")
      {:ok, "", "21"}
      iex> digit0().("a21c")
      {:ok, "a21c", ""}
      iex> digit0().("")
      {:ok, "", ""}
  """
  def digit0, do: fn input -> digit_internal(input) end

  @doc """
  Recognizes one or more ASCII numerical characters: 0-9

  Complete version: Will return an error if there’s not enough input data, or the whole input if no terminating token is found (a non digit character).

      iex> digit1().("213c")
      {:ok, "c", "213"}
      iex> digit1().("c1")
      {:error, %Error{kind: :digit, buffer: "c1"}}
      iex> digit1().("")
      {:error, %Error{kind: :digit, buffer: ""}}

  You can use this function in combination with `Elnom.Combinator.map/2` to parse an integer:

      iex> parser = map(digit1(), &String.to_integer/1)
      iex> parser.("123abc")
      {:ok, "abc", 123}
  """
  def digit1 do
    fn input ->
      error_if_empty(digit_internal(input), :digit)
    end
  end

  defp digit_internal(<<char::utf8, rest::binary>>) when char in ?0..?9 do
    {:ok, rest, more} = digit_internal(rest)
    {:ok, rest, <<char::utf8, more::binary>>}
  end

  defp digit_internal(input), do: {:ok, input, ""}

  @doc """
  Recognizes zero or more ASCII hexadecimal numerical characters: 0-9, A-F, a-f

  Complete version: Will return the whole input if no terminating token is found (a non hexadecimal digit character).

      iex> hex_digit0().("21cZ")
      {:ok, "Z", "21c"}
      iex> hex_digit0().("%1")
      {:ok, "%1", ""}
      iex> hex_digit0().("")
      {:ok, "", ""}
  """
  def hex_digit0, do: fn input -> hex_digit_internal(input) end

  @doc """
  Recognizes one or more ASCII hexadecimal numerical characters: 0-9, A-F, a-f

  Complete version: Will return an error if there’s not enough input data, or the whole input if no terminating token is found (a non hexadecimal digit character).

      iex> hex_digit1().("21cZ")
      {:ok, "Z", "21c"}
      iex> hex_digit1().("%1")
      {:error, %Error{kind: :hex_digit, buffer: "%1"}}
      iex> hex_digit1().("")
      {:error, %Error{kind: :hex_digit, buffer: ""}}
  """
  def hex_digit1 do
    fn input ->
      error_if_empty(hex_digit_internal(input), :hex_digit)
    end
  end

  defp hex_digit_internal(<<char::utf8, rest::binary>>)
       when char in ?a..?f or char in ?A..?F or char in ?0..?9 do
    {:ok, rest, more} = hex_digit_internal(rest)
    {:ok, rest, <<char::utf8, more::binary>>}
  end

  defp hex_digit_internal(input), do: {:ok, input, ""}

  @doc """
  Parses a number in text form to an integer.

  This function does not exist in Rust's nom library because it uses u8(), i8, u16(), etc. to convert to integers.  Elixir doesn't have these types, so this single function can translate a string to an integer of any size.

  Complete version: Will return an error if there’s not enough input data, or the whole input if no terminating token is found (a non digit character).

      iex> integer().("123abc")
      {:ok, "abc", 123}
      iex> integer().("abc")
      {:error, %Error{kind: :digit, buffer: "abc"}}
      iex> integer().("")
      {:error, %Error{kind: :digit, buffer: ""}}
  """
  def integer do
    fn input ->
      case digit1().(input) do
        {:ok, input, digits} ->
          {:ok, input, String.to_integer(digits)}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc "See `integer/0`"
  def i8, do: integer()
  @doc "See `integer/0`"
  def i16, do: integer()
  @doc "See `integer/0`"
  def i32, do: integer()
  @doc "See `integer/0`"
  def i64, do: integer()
  @doc "See `integer/0`"
  def i128, do: integer()

  @doc ~S"""
  Recognizes an end of line (both ‘\n’ and ‘\r\n’).

  Complete version: Will return an error if there’s not enough input data.

      iex> line_ending().("\r\nc")
      {:ok, "c", "\r\n"}
      iex> line_ending().("ab\r\nc")
      {:error, %Error{kind: :cr_lf, buffer: "ab\r\nc"}}
      iex> line_ending().("")
      {:error, %Error{kind: :cr_lf, buffer: ""}}
  """
  def line_ending do
    fn
      <<?\r::utf8, ?\n::utf8>> <> input -> {:ok, input, <<?\r::utf8, ?\n::utf8>>}
      <<?\n::utf8>> <> input -> {:ok, input, <<?\n::utf8>>}
      input -> {:error, Error.new(:cr_lf, input)}
    end
  end

  @doc ~S"""
  Recognizes zero or more spaces, tabs, carriage returns and line feeds.

  Complete version: will return the whole input if no terminating token is found (a non space character).

      iex> multispace0().(" \t\n\r21c")
      {:ok, "21c", " \t\n\r"}
      iex> multispace0().("Z21c")
      {:ok, "Z21c", ""}
      iex> multispace0().("")
      {:ok, "", ""}
  """
  def multispace0, do: fn input -> multispace_internal(input) end

  @doc ~S"""
    Recognizes one or more spaces, tabs, carriage returns and line feeds.

  Complete version: will return an error if there’s not enough input data, or the whole input if no terminating token is found (a non space character).

      iex> multispace1().(" \t\n\r21c")
      {:ok, "21c", " \t\n\r"}
      iex> multispace1().("Z21c")
      {:error, %Error{kind: :multispace, buffer: "Z21c"}}
      iex> multispace1().("")
      {:error, %Error{kind: :multispace, buffer: ""}}
  """
  def multispace1 do
    fn input ->
      error_if_empty(multispace_internal(input), :multispace)
    end
  end

  defp multispace_internal(<<char::utf8, rest::binary>>)
       when char in [?\s, ?\t, ?\r, ?\n] do
    {:ok, rest, more} = multispace_internal(rest)
    {:ok, rest, <<char::utf8, more::binary>>}
  end

  defp multispace_internal(input), do: {:ok, input, ""}

  @doc ~S"""
  Matches a newline character ‘\n’.

  Complete version: Will return an error if there’s not enough input data.

      iex> newline().("\nc")
      {:ok, "c", "\n"}
      iex> newline().("\r\nc")
      {:error, %Error{kind: :newline, buffer: "\r\nc"}}
      iex> newline().("")
      {:error, %Error{kind: :newline, buffer: ""}}
  """
  def newline do
    fn
      <<?\n::utf8>> <> input -> {:ok, input, <<?\n::utf8>>}
      input -> {:error, Error.new(:newline, input)}
    end
  end

  @doc """
  Recognizes a character that is not in the provided characters.

  Complete version: Will return an error if there’s not enough input data.

      iex> none_of("abc").("z")
      {:ok, "", "z"}
      iex> none_of("ab").("a")
      {:error, %Error{kind: :none_of, buffer: "a"}}
      iex> none_of("a").("")
      {:error, %Error{kind: :none_of, buffer: ""}}
  """
  def none_of(chars) do
    chars = String.to_charlist(chars) |> MapSet.new()

    fn str ->
      case str do
        <<char::utf8>> <> rest ->
          if char not in chars do
            {:ok, rest, <<char::utf8>>}
          else
            {:error, Error.new(:none_of, str)}
          end

        _ ->
          {:error, Error.new(:none_of, str)}
      end
    end
  end

  @doc ~S"""
  Recognizes a string of any char except ‘\r\n’ or ‘\n’.

  Complete version: Will return an error if there’s not enough input data.

      iex> not_line_ending().("ab\r\nc")
      {:ok, "\r\nc", "ab"}
      iex> not_line_ending().("ab\nc")
      {:ok, "\nc", "ab"}
      iex> not_line_ending().("abc")
      {:ok, "", "abc"}
      iex> not_line_ending().("")
      {:ok, "", ""}
      iex> not_line_ending().("a\rb\nc")
      {:error, %Error{kind: :tag, buffer: "a\rb\nc"}}
  """
  def not_line_ending do
    fn input ->
      case String.split(input, ~r(\r|\n), parts: 2, include_captures: true) do
        [line, "\n", rest] -> {:ok, "\n" <> rest, line}
        [line, "\r", "\n" <> rest] -> {:ok, "\r\n" <> rest, line}
        [_, "\r", _] -> {:error, Error.new(:tag, input)}
        [line] -> {:ok, "", line}
      end
    end
  end

  @doc """
  Recognizes zero or more octal characters: 0-7

  Complete version: Will return the whole input if no terminating token is found (a non octal digit character).

      iex> oct_digit0().("21cZ")
      {:ok, "cZ", "21"}
      iex> oct_digit0().("%1")
      {:ok, "%1", ""}
      iex> oct_digit0().("")
      {:ok, "", ""}
  """
  def oct_digit0, do: fn input -> oct_digit_internal(input) end

  @doc """
  Recognizes one or more octal characters: 0-7

  Complete version: Will return an error if there’s not enough input data, or the whole input if no terminating token is found (a non octal digit character).

      iex> oct_digit1().("218cZ")
      {:ok, "8cZ", "21"}
      iex> oct_digit1().("%1")
      {:error, %Error{kind: :oct_digit, buffer: "%1"}}
      iex> oct_digit1().("")
      {:error, %Error{kind: :oct_digit, buffer: ""}}
  """
  def oct_digit1 do
    fn input ->
      error_if_empty(oct_digit_internal(input), :oct_digit)
    end
  end

  defp oct_digit_internal(<<char::utf8, rest::binary>>) when char in ?0..?7 do
    {:ok, rest, more} = oct_digit_internal(rest)
    {:ok, rest, <<char::utf8, more::binary>>}
  end

  defp oct_digit_internal(input), do: {:ok, input, ""}

  @doc """
  Recognizes one of the provided utf-8 characters.

  Complete version: Will return an error if there’s not enough input data.

      iex> one_of("abc").("b")
      {:ok, "", "b"}
      iex> one_of("a").("bc")
      {:error, %Error{kind: :one_of, buffer: "bc"}}
      iex> one_of("a").("")
      {:error, %Error{kind: :one_of, buffer: ""}}
  """
  def one_of(chars) do
    chars = String.to_charlist(chars) |> MapSet.new()

    fn str ->
      case str do
        <<char::utf8>> <> rest ->
          if char in chars do
            {:ok, rest, <<char::utf8>>}
          else
            {:error, Error.new(:one_of, str)}
          end

        _ ->
          {:error, Error.new(:one_of, str)}
      end
    end
  end

  @doc """
  Recognizes one utf-8 character and checks that it satisfies a predicate

  Complete version: Will return an error if there’s not enough input data.

      iex> parser = satisfy(&(&1 == ?a || &1 == ?b))
      iex> parser.("abc")
      {:ok, "bc", "a"}
      iex> parser.("cd")
      {:error, %Error{kind: :satisfy, buffer: "cd"}}
      iex> parser.("")
      {:error, %Error{kind: :satisfy, buffer: ""}}
  """
  def satisfy(predicate) do
    fn
      <<char::utf8>> <> rest = input ->
        if predicate.(char) do
          {:ok, rest, <<char::utf8>>}
        else
          {:error, Error.new(:satisfy, input)}
        end

      input ->
        {:error, Error.new(:satisfy, input)}
    end
  end

  @doc ~S"""
  Recognizes zero or more spaces and tabs.

  Complete version: Will return the whole input if no terminating token is found (a non space character).

      iex> space0().(" \t21c")
      {:ok, "21c", " \t"}
      iex> space0().("Z21c")
      {:ok, "Z21c", ""}
      iex> space0().("")
      {:ok, "", ""}
  """
  def space0, do: fn input -> space_internal(input) end

  @doc ~S"""
  Recognizes one or more spaces and tabs.

  Complete version: Will return an error if there’s not enough input data, or the whole input if no terminating token is found (a non space character).

      iex> space1().(" \t21c")
      {:ok, "21c", " \t"}
      iex> space1().("Z21c")
      {:error, %Error{kind: :space, buffer: "Z21c"}}
      iex> space1().("")
      {:error, %Error{kind: :space, buffer: ""}}
  """
  def space1 do
    fn input ->
      error_if_empty(space_internal(input), :space)
    end
  end

  defp space_internal(<<char::utf8, rest::binary>>) when char in [?\s, ?\t] do
    {:ok, rest, more} = space_internal(rest)
    {:ok, rest, <<char::utf8, more::binary>>}
  end

  defp space_internal(input), do: {:ok, input, ""}

  @doc ~S"""
  Matches a tab character ‘\t’.

  Complete version: Will return an error if there’s not enough input data.

      iex> tab().("\tc")
      {:ok, "c", "\t"}
      iex> tab().("\r\nc")
      {:error, %Error{kind: :char, buffer: "\r\nc"}}
      iex> tab().("")
      {:error, %Error{kind: :char, buffer: ""}}
  """
  def tab, do: char("\t")

  @doc "See `integer/0`"
  def u8, do: integer()
  @doc "See `integer/0`"
  def u16, do: integer()
  @doc "See `integer/0`"
  def u32, do: integer()
  @doc "See `integer/0`"
  def u64, do: integer()
  @doc "See `integer/0`"
  def u128, do: integer()

  defp error_if_empty({:ok, input, ""}, kind) do
    {:error, Error.new(kind, input)}
  end

  defp error_if_empty(other, _kind), do: other
end
