defmodule Elnom.Number do
  @moduledoc "Parsers recognizing numbers in binary and numeric-string formats"

  import Elnom.Character, only: [is_hex_digit: 1]
  import Elnom.Combinator, only: [map: 2, recognize: 1]
  import Elnom.Strings.Complete, only: [take_while_m_n: 3]

  alias Elnom.Error

  @doc """
  Recognizes an unsigned 1 byte integer.

      iex> u8().(<<0, 3, "abcefg">>)
      {:ok, <<3, "abcefg">>, 0}

      iex> u8().("")
      {:error, %Elnom.Error{buffer: "", kind: :eof}}
  """
  def u8() do
    fn
      <<byte::8, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes an unsigned 2 byte integer in big endian format.

      iex> be_u16().(<<1, 3, "abcefg">>)
      {:ok, "abcefg", 0x0103}

      iex> be_u16().(<<0>>)
      {:error, %Elnom.Error{buffer: <<0>>, kind: :eof}}
  """
  def be_u16() do
    fn
      <<byte::16-big, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes an unsigned 3 byte integer in big endian format.

      iex> be_u24().(<<1, 3, 5, "abcefg">>)
      {:ok, "abcefg", 0x010305}

      iex> be_u24().(<<0, 1>>)
      {:error, %Elnom.Error{buffer: <<0, 1>>, kind: :eof}}
  """
  def be_u24() do
    fn
      <<byte::24-big, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes an unsigned 4 byte integer in big endian format.

      iex> be_u32().(<<1, 3, 5, 7, "abcefg">>)
      {:ok, "abcefg", 0x01030507}

      iex> be_u32().(<<0, 1, 2>>)
      {:error, %Elnom.Error{buffer: <<0, 1, 2>>, kind: :eof}}
  """
  def be_u32() do
    fn
      <<byte::32-big, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes an unsigned 8 byte integer in big endian format.

      iex> be_u64().(<<1, 3, 5, 7, 9, 11, 13, 15, "abcefg">>)
      {:ok, "abcefg", 0x01030507090b0d0f}

      iex> be_u64().(<<0, 1, 2, 3, 4, 5, 6>>)
      {:error, %Elnom.Error{buffer: <<0, 1, 2, 3, 4, 5, 6>>, kind: :eof}}
  """
  def be_u64() do
    fn
      <<byte::64-big, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes an unsigned 16 byte integer in big endian format.

      iex> be_u128().(<<1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, "abcefg">>)
      {:ok, "abcefg", 0x01030507090b0d0f11131517191b1d1f}

      iex> be_u128().(<<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14>>)
      {:error, %Elnom.Error{buffer: <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14>>, kind: :eof}}
  """
  def be_u128() do
    fn
      <<byte::128-big, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes an unsigned 2 byte integer in little endian format.

      iex> le_u16().(<<1, 3, "abcefg">>)
      {:ok, "abcefg", 0x0301}

      iex> le_u16().(<<0>>)
      {:error, %Elnom.Error{buffer: <<0>>, kind: :eof}}
  """
  def le_u16() do
    fn
      <<byte::16-little, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes an unsigned 3 byte integer in little endian format.

      iex> le_u24().(<<1, 3, 5, "abcefg">>)
      {:ok, "abcefg", 0x050301}

      iex> le_u24().(<<0, 1>>)
      {:error, %Elnom.Error{buffer: <<0, 1>>, kind: :eof}}
  """
  def le_u24() do
    fn
      <<byte::24-little, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes an unsigned 4 byte integer in little endian format.

      iex> le_u32().(<<1, 3, 5, 7, "abcefg">>)
      {:ok, "abcefg", 0x07050301}

      iex> le_u32().(<<0, 1, 2>>)
      {:error, %Elnom.Error{buffer: <<0, 1, 2>>, kind: :eof}}
  """
  def le_u32() do
    fn
      <<byte::32-little, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes an unsigned 8 byte integer in little endian format.

      iex> le_u64().(<<1, 3, 5, 7, 9, 11, 13, 15, "abcefg">>)
      {:ok, "abcefg", 0x0f0d0b0907050301}

      iex> le_u64().(<<0, 1, 2, 3, 4, 5, 6>>)
      {:error, %Elnom.Error{buffer: <<0, 1, 2, 3, 4, 5, 6>>, kind: :eof}}
  """
  def le_u64() do
    fn
      <<byte::64-little, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes an unsigned 16 byte integer in little endian format.

      iex> le_u128().(<<1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, "abcefg">>)
      {:ok, "abcefg", 0x1f1d1b19171513110f0d0b0907050301}

      iex> le_u128().(<<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14>>)
      {:error, %Elnom.Error{buffer: <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14>>, kind: :eof}}
  """
  def le_u128() do
    fn
      <<byte::128-little, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes a signed 1 byte integer.

      iex> i8().(<<0, 3, "abcefg">>)
      {:ok, <<3, "abcefg">>, 0}

      iex> i8().(<<255, 3, "abcefg">>)
      {:ok, <<3, "abcefg">>, -1}

      iex> i8().("")
      {:error, %Elnom.Error{buffer: "", kind: :eof}}
  """
  def i8() do
    fn
      <<byte::8-signed, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes an signed 2 byte integer in big endian format.

      iex> be_i16().(<<1, 3, "abcefg">>)
      {:ok, "abcefg", 0x0103}

      iex> be_i16().(<<0>>)
      {:error, %Elnom.Error{buffer: <<0>>, kind: :eof}}
  """
  def be_i16() do
    fn
      <<byte::16-big-signed, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes an signed 3 byte integer in big endian format.

      iex> be_i24().(<<1, 3, 5, "abcefg">>)
      {:ok, "abcefg", 0x010305}

      iex> be_i24().(<<0, 1>>)
      {:error, %Elnom.Error{buffer: <<0, 1>>, kind: :eof}}
  """
  def be_i24() do
    fn
      <<byte::24-big-signed, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes an signed 4 byte integer in big endian format.

      iex> be_i32().(<<1, 3, 5, 7, "abcefg">>)
      {:ok, "abcefg", 0x01030507}

      iex> be_i32().(<<0, 1, 2>>)
      {:error, %Elnom.Error{buffer: <<0, 1, 2>>, kind: :eof}}
  """
  def be_i32() do
    fn
      <<byte::32-big-signed, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes an signed 8 byte integer in big endian format.

      iex> be_i64().(<<1, 3, 5, 7, 9, 11, 13, 15, "abcefg">>)
      {:ok, "abcefg", 0x01030507090b0d0f}

      iex> be_i64().(<<0, 1, 2, 3, 4, 5, 6>>)
      {:error, %Elnom.Error{buffer: <<0, 1, 2, 3, 4, 5, 6>>, kind: :eof}}
  """
  def be_i64() do
    fn
      <<byte::64-big-signed, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes an signed 16 byte integer in big endian format.

      iex> be_i128().(<<1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, "abcefg">>)
      {:ok, "abcefg", 0x01030507090b0d0f11131517191b1d1f}

      iex> be_i128().(<<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14>>)
      {:error, %Elnom.Error{buffer: <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14>>, kind: :eof}}
  """
  def be_i128() do
    fn
      <<byte::128-big-signed, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes an signed 2 byte integer in little endian format.

      iex> le_i16().(<<1, 3, "abcefg">>)
      {:ok, "abcefg", 0x0301}

      iex> le_i16().(<<0>>)
      {:error, %Elnom.Error{buffer: <<0>>, kind: :eof}}
  """
  def le_i16() do
    fn
      <<byte::16-little-signed, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes an signed 3 byte integer in little endian format.

      iex> le_i24().(<<1, 3, 5, "abcefg">>)
      {:ok, "abcefg", 0x050301}

      iex> le_i24().(<<0, 1>>)
      {:error, %Elnom.Error{buffer: <<0, 1>>, kind: :eof}}
  """
  def le_i24() do
    fn
      <<byte::24-little-signed, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes an signed 4 byte integer in little endian format.

      iex> le_i32().(<<1, 3, 5, 7, "abcefg">>)
      {:ok, "abcefg", 0x07050301}

      iex> le_i32().(<<0, 1, 2>>)
      {:error, %Elnom.Error{buffer: <<0, 1, 2>>, kind: :eof}}
  """
  def le_i32() do
    fn
      <<byte::32-little-signed, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes an signed 8 byte integer in little endian format.

      iex> le_i64().(<<1, 3, 5, 7, 9, 11, 13, 15, "abcefg">>)
      {:ok, "abcefg", 0x0f0d0b0907050301}

      iex> le_i64().(<<0, 1, 2, 3, 4, 5, 6>>)
      {:error, %Elnom.Error{buffer: <<0, 1, 2, 3, 4, 5, 6>>, kind: :eof}}
  """
  def le_i64() do
    fn
      <<byte::64-little-signed, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes an signed 16 byte integer in little endian format.

      iex> le_i128().(<<1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, "abcefg">>)
      {:ok, "abcefg", 0x1f1d1b19171513110f0d0b0907050301}

      iex> le_i128().(<<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14>>)
      {:error, %Elnom.Error{buffer: <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14>>, kind: :eof}}
  """
  def le_i128() do
    fn
      <<byte::128-little-signed, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes a big endian 4 bytes floating point number.

      iex> be_f32().(<<0x41, 0x48, 0x00, 0x00>>)
      {:ok, "", 12.5}

      iex> be_f32().("abc")
      {:error, %Elnom.Error{buffer: "abc", kind: :eof}}
  """
  def be_f32() do
    fn
      <<byte::32-big-float, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes a big endian 8 bytes floating point number.

      iex> be_f64().(<<0x40, 0x29, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>)
      {:ok, "", 12.5}

      iex> be_f64().("abcdefg")
      {:error, %Elnom.Error{buffer: "abcdefg", kind: :eof}}
  """
  def be_f64() do
    fn
      <<byte::64-big-float, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes a little endian 4 bytes floating point number.

      iex> le_f32().(<<0x00, 0x00, 0x48, 0x41>>)
      {:ok, "", 12.5}

      iex> le_f32().("abc")
      {:error, %Elnom.Error{buffer: "abc", kind: :eof}}
  """
  def le_f32() do
    fn
      <<byte::32-little-float, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes a little endian 8 bytes floating point number.

      iex> le_f64().(<<0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x29, 0x40>>)
      {:ok, "", 12.5}

      iex> le_f64().("abcdefg")
      {:error, %Elnom.Error{buffer: "abcdefg", kind: :eof}}
  """
  def le_f64() do
    fn
      <<byte::64-little-float, rest::binary>> -> {:ok, rest, byte}
      str -> {:error, Error.new(:eof, str)}
    end
  end

  @doc """
  Recognizes floating point number in text format and returns a float.

      iex> float().("11e-1")
      {:ok, "", 1.1}

      iex> float().("123E-02")
      {:ok, "", 1.23}

      iex> float().("123K-01")
      {:ok, "K-01", 123.0}

      iex> float().("abc")
      {:error, %Elnom.Error{buffer: "abc", kind: :float}}
  """
  def double() do
    fn str ->
      case Float.parse(str) do
        {float, str} -> {:ok, str, float}
        _ -> {:error, Error.new(:float, str)}
      end
    end
  end

  @doc """
  Parses a hex-encoded integer.

      iex> hex_u32().("01AE")
      {:ok, "", 0x01AE}

      iex> hex_u32().("abc")
      {:ok, "", 0x0ABC}

      iex> hex_u32().("012345678")
      {:ok, "8", 0x01234567}

      iex> hex_u32().("ggg")
      {:error, %Elnom.Error{buffer: "ggg", kind: :take_while_m_n}}
  """
  def hex_u32() do
    map(take_while_m_n(1, 8, &is_hex_digit/1), &String.to_integer(&1, 16))
  end

  @doc """
  Recognizes floating point number in a byte string and returns the corresponding string.

      iex> recognize_float().("11e-1")
      {:ok, "", "11e-1"}

      iex> recognize_float().("123E-02")
      {:ok, "", "123E-02"}

      iex> recognize_float().("123K-01")
      {:ok, "K-01", "123"}

      iex> recognize_float().("abc")
      {:error, %Elnom.Error{buffer: "abc", kind: :float}}
  """
  def recognize_float() do
    recognize(float())
  end

  @doc """
  Elixir does not have a float type, so this function aliases to double/0.
  """
  def float(), do: double()

  @doc "Parse a i16 integer as big endian if the argument is `:big` and little endian if `:little`."
  def i16(:big), do: be_i16()
  def i16(:little), do: le_i16()

  @doc "Parse a i24 integer as big endian if the argument is `:big` and little endian if `:little`."
  def i24(:big), do: be_i24()
  def i24(:little), do: le_i24()

  @doc "Parse a i32 integer as big endian if the argument is `:big` and little endian if `:little`."
  def i32(:big), do: be_i32()
  def i32(:little), do: le_i32()

  @doc "Parse a i64 integer as big endian if the argument is `:big` and little endian if `:little`."
  def i64(:big), do: be_i64()
  def i64(:little), do: le_i64()

  @doc "Parse a i128 integer as big endian if the argument is `:big` and little endian if `:little`."
  def i128(:big), do: be_i128()
  def i128(:little), do: le_i128()

  @doc "Parse a u16 integer as big endian if the argument is `:big` and little endian if `:little`."
  def u16(:big), do: be_u16()
  def u16(:little), do: le_u16()

  @doc "Parse a u24 integer as big endian if the argument is `:big` and little endian if `:little`."
  def u24(:big), do: be_u24()
  def u24(:little), do: le_u24()

  @doc "Parse a u32 integer as big endian if the argument is `:big` and little endian if `:little`."
  def u32(:big), do: be_u32()
  def u32(:little), do: le_u32()

  @doc "Parse a u64 integer as big endian if the argument is `:big` and little endian if `:little`."
  def u64(:big), do: be_u64()
  def u64(:little), do: le_u64()

  @doc "Parse a u128 integer as big endian if the argument is `:big` and little endian if `:little`."
  def u128(:big), do: be_u128()
  def u128(:little), do: le_u128()

  @doc "Parse a 32-bit float as big endian if the argument is `:big` and little endian if `:little`."
  def f32(:big), do: be_f32()
  def f32(:little), do: le_f32()

  @doc "Parse a 64-bit double as big endian if the argument is `:big` and little endian if `:little`."
  def f64(:big), do: be_f64()
  def f64(:little), do: le_f64()
end
