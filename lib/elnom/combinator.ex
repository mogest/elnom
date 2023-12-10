defmodule Elnom.Combinator do
  @moduledoc "General purpose combinators"

  alias Elnom.{Error, Failure, Incomplete}

  @doc """
  Succeeds if all the input has been consumed by its child parser.

      iex> parser = all_consuming(tag("abc"))
      iex> parser.("abc")
      {:ok, "", "abc"}
      iex> parser.("abc123")
      {:error, %Error{kind: :all_consuming, buffer: "123"}}
      iex> parser.("ab")
      {:error, %Error{kind: :tag, buffer: "ab"}}
  """
  def all_consuming(parser) do
    fn str ->
      case parser.(str) do
        {:ok, "", data} -> {:ok, "", data}
        {:ok, str, _} -> {:error, Error.new(:all_consuming, str)}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Transforms an Incomplete error into an Error.

      iex> parser = complete(length_data(u8(), :byte))
      iex> parser.(<<5, "abcdefg">>)
      {:ok, "fg", "abcde"}
      iex> parser.(<<5, "abc">>)
      {:error, %Error{kind: :complete, buffer: <<5, "abc">>}}
  """
  def complete(parser) do
    fn input ->
      case parser.(input) do
        {:ok, input, data} ->
          {:ok, input, data}

        {:error, %Incomplete{}} ->
          {:error, %Error{kind: :complete, buffer: input}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Calls the parser if the condition is met.

      iex> parser = fn b -> cond(b, alpha1()) end
      iex> parser.(true).("abcd;")
      {:ok, ";", "abcd"}
      iex> parser.(false).("abcd;")
      {:ok, "abcd;", nil}
      iex> parser.(true).("123;")
      {:error, %Error{kind: :alpha, buffer: "123;"}}
      iex> parser.(false).("123;")
      {:ok, "123;", nil}
  """
  def cond(condition, parser) do
    fn str ->
      if condition do
        parser.(str)
      else
        {:ok, str, nil}
      end
    end
  end

  @doc """
  If the child parser was successful, return the consumed input with the output as a tuple. Functions similarly to recognize/1 except it returns the parser output as well.

  This can be useful especially in cases where the output is not the same type as the input, or the input is a user defined type.

  Returned tuple is of the format {consumed input, produced output}.

      iex> parser = consumed(value(true, tag("abc")))
      iex> parser.("abcdef")
      {:ok, "def", {"abc", true}}
  """
  def consumed(parser) do
    fn input ->
      case parser.(input) do
        {:ok, new_input, output} ->
          consumed_input = String.slice(input, 0, String.length(input) - String.length(new_input))
          {:ok, new_input, {consumed_input, output}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Transforms an Error (recoverable) to Failure (unrecoverable)

  This commits the parse result, preventing alternative branch paths like with Elnom.Branch.alt/1.

  Without cut/1:
      iex> parser = alt({preceded(one_of("+-"), digit1()), rest()})
      iex> parser.("+10 ab")
      {:ok, " ab", "10"}
      iex> parser.("ab")
      {:ok, "", "ab"}
      iex> parser.("+")
      {:ok, "", "+"}

  With cut/1:
      iex> parser = alt({preceded(one_of("+-"), cut(digit1())), rest()})
      iex> parser.("+10 ab")
      {:ok, " ab", "10"}
      iex> parser.("ab")
      {:ok, "", "ab"}
      iex> parser.("+")
      {:error, %Failure{kind: :digit, buffer: ""}}
  """
  def cut(parser) do
    fn str ->
      case parser.(str) do
        {:ok, str, data} -> {:ok, str, data}
        {:error, %Error{} = error} -> {:error, Failure.new(error)}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Returns its input if it is at the end of input data.

  When we're at the end of the data, this combinator will succeed.

      iex> eof().("abc")
      {:error, %Error{kind: :eof, buffer: "abc"}}
      iex> eof().("")
      {:ok, "", ""}
  """
  def eof do
    fn
      "" -> {:ok, "", ""}
      input -> {:error, %Error{kind: :eof, buffer: input}}
    end
  end

  @doc """
  A parser which always fails.

      iex> fail().("abc")
      {:error, %Error{kind: :fail, buffer: "abc"}}
  """
  def fail do
    fn input -> {:error, %Error{kind: :fail, buffer: input}} end
  end

  @doc """
  Creates a new parser from the output of the first parser, then apply that parser over the rest of the input.

      iex> parser = flat_map(u8(), &take/1)
      iex> parser.(<<2, 0, 1, 2>>)
      {:ok, <<2>>, <<0, 1>>}
      iex> parser.(<<4, 0, 1, 2>>)
      {:error, %Error{kind: :eof, buffer: <<0, 1, 2>>}}
  """
  def flat_map(parser, fun) do
    fn str ->
      case parser.(str) do
        {:ok, str, data} -> fun.(data).(str)
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Maps a function on the result of a parser.

      iex> parser = map(digit1(), &String.length/1)
      iex> parser.("123456")
      {:ok, "", 6}
      iex> parser.("abc")
      {:error, %Error{kind: :digit, buffer: "abc"}}
  """
  def map(parser, fun) do
    fn str ->
      case parser.(str) do
        {:ok, str, data} -> {:ok, str, fun.(data)}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Applies a parser over the result of another one.

      iex> parser = map_parser(take(5), digit1())
      iex> parser.("123456")
      {:ok, "6", "12345"}
      iex> parser.("123ab6")
      {:ok, "6", "123"}
      iex> parser.("123")
      {:error, %Error{kind: :eof, buffer: "123"}}
      iex> parser.("abcdef")
      {:error, %Error{kind: :digit, buffer: "abcde"}}
  """
  def map_parser(parser, applied_parser) do
    fn input ->
      case parser.(input) do
        {:ok, input, output} ->
          case applied_parser.(output) do
            {:ok, _, output} -> {:ok, input, output}
            {:error, reason} -> {:error, reason}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Applies a function successfully when returning {:ok, data} or unsuccesfully when returning anything else on the result of a parser.

      iex> to_integer = fn str ->
      ...>   case Integer.parse(str) do
      ...>     {int, ""} -> {:ok, int}
      ...>     _ -> :error
      ...>   end
      ...> end
      iex> parser = map_res(take(3), to_integer)
      iex> parser.("123abc")
      {:ok, "abc", 123}
      iex> parser.("abc")
      :error
  """
  def map_res(parser, fun) do
    fn str ->
      case parser.(str) do
        {:ok, str, data} ->
          case fun.(data) do
            {:ok, data} -> {:ok, str, data}
            other -> other
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Succeeds if the child parser returns an error.

  Because Elixir has a reserved `not` function, this combinator is named `not_`.

      iex> parser = not_(alpha1())
      iex> parser.("123")
      {:ok, "123", nil}
      iex> parser.("abc")
      {:error, %Error{kind: :not, buffer: "abc"}}
  """
  def not_(parser) do
    fn input ->
      case parser.(input) do
        {:ok, _, _} -> {:error, Error.new(:not, input)}
        {:error, %Error{}} -> {:ok, input, nil}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Optional parser, will return nil on Error.

  To chain an error up, see cut/1.

      iex> parser = opt(alpha1())
      iex> parser.("abc")
      {:ok, "", "abc"}
      iex> parser.("123")
      {:ok, "123", nil}
  """
  def opt(parser) do
    fn input ->
      case parser.(input) do
        {:ok, input, data} -> {:ok, input, data}
        {:error, %Error{}} -> {:ok, input, nil}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Tries to apply its parser without consuming the input.

      iex> parser = peek(alpha1())
      iex> parser.("abcd;")
      {:ok, "abcd;", "abcd"}
      iex> parser.("123;")
      {:error, %Error{kind: :alpha, buffer: "123;"}}
  """
  def peek(parser) do
    fn input ->
      case parser.(input) do
        {:ok, _, output} -> {:ok, input, output}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  If the child parser was successful, return the consumed input as produced value.

      iex> parser = recognize(separated_pair(alpha1(), char(","), alpha1()))
      iex> parser.("abcd,efgh")
      {:ok, "", "abcd,efgh"}
      iex> parser.("abcd;")
      {:error, %Error{kind: :char, buffer: ";"}}
  """
  def recognize(parser) do
    fn input ->
      case parser.(input) do
        {:ok, new_input, _} ->
          consumed_input = String.slice(input, 0, String.length(input) - String.length(new_input))
          {:ok, new_input, consumed_input}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Return the remaining input.

      iex> parser = rest()
      iex> parser.("abc")
      {:ok, "", "abc"}
      iex> parser.("")
      {:ok, "", ""}
  """
  def rest do
    fn input -> {:ok, "", input} end
  end

  @doc """
  Return the length of the remaining input.

      iex> parser = rest_len()
      iex> parser.("abc")
      {:ok, "", 3}
      iex> parser.("")
      {:ok, "", 0}
  """
  def rest_len do
    fn input -> {:ok, "", String.length(input)} end
  end

  @doc """
  A parser which always succeeds with given value without consuming any input.

      iex> parser = success(10)
      iex> parser.("abc")
      {:ok, "abc", 10}

      iex> sign = alt({value(-1, char("-")), value(1, char("+")), success(1)})
      iex> sign.("+10")
      {:ok, "10", 1}
      iex> sign.("-10")
      {:ok, "10", -1}
      iex> sign.("10")
      {:ok, "10", 1}
  """
  def success(value) do
    fn input -> {:ok, input, value} end
  end

  @doc """
  Returns the provided value if the child parser succeeds.

      iex> parser = value(1234, tag("abc"))
      iex> parser.("abc")
      {:ok, "", 1234}
      iex> parser.("123")
      {:error, %Error{kind: :tag, buffer: "123"}}
  """
  def value(value, parser) do
    fn input ->
      case parser.(input) do
        {:ok, input, _} -> {:ok, input, value}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Returns the result of the child parser if it satisfies a verification function.

  The verification function takes as argument a reference to the output of the parser.

      iex> parser = verify(alpha1(), &String.length(&1) == 4)
      iex> parser.("abcd")
      {:ok, "", "abcd"}
      iex> parser.("abcde")
      {:error, %Error{kind: :verify, buffer: "abcde"}}
      iex> parser.("123abcd;")
      {:error, %Error{kind: :alpha, buffer: "123abcd;"}}
  """
  def verify(parser, fun) do
    fn input ->
      case parser.(input) do
        {:ok, new_input, data} ->
          if fun.(data) do
            {:ok, new_input, data}
          else
            {:error, Error.new(:verify, input)}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end
end
