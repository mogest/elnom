# elnom, an Elixir port of the Rust nom parser

[nom](https://github.com/rust-bakery/nom/tree/main) is a fantastic parser combinator for Rust.  `elnom` is an
Elixir port, trying to stay as true as possible to nom's design.

The function calls are almost identical, so the [nom
documentation](https://github.com/rust-bakery/nom/tree/main#documentation) is an excellent place to start to learn
about how to use elnom, or look at the [elnom documentation](https://hexdocs.pm/elnom).

## Example

```elixir
defmodule Color do
  use Elnom, type: :string

  defstruct [:red, :green, :blue]

  def new_from_string(string) do
    case hex_color().(string) do
      {:ok, "", color} -> {:ok, color}
      {:error, reason} -> {:error, reason}
    end
  end

  defp hex_color do
    map(
      all_consuming(
        preceded(tag("#"), count(hex_primary(), 3)),
      )
      fn [r, g, b] -> %Color{red: r, green: g, blue: b} end
    )
  end

  defp hex_primary do
    map(
      take_while_m_n(2, 2, &is_hex_digit/1),
      fn hex -> String.to_integer(hex, 16) end
    )
  end
end

Color.new_from_string("#2F14DF") #=> {:ok, %Color{red: 47, green: 20, blue: 223}}
```

## Installation

Add `elnom` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elnom, "~> 0.1.0"}
  ]
end
```

## Using it

Add `use Elnom, type: :string` or `use Elnom, type: :byte` to your module, depending on whether you are parsing
utf-8 strings or raw binary data.  This imports all of the elnom modules straight into your module, ready for use.
Alternatively you can import just the functions you need, or even call the functions directly.

All parser functions return a function, and you can call that function with your input string/binary to get it
started.

Successful parses return `{:ok, remaining_buffer, output}`, and failed parses return `{:error, %{}}` where the
map is one of `Elnom.Error` (recoverable error), `Elnom.Failure` (unrecoverable error), or `Elnom.Incomplete`
(more data required.)

```elixir
alpha1().("hello world") #=> {:ok, " world", "hello"}

digit1().("not a number") #=> {:error, %Elnom.Error{kind: :digit, buffer: "not a number"}}
```

Parser functions are composable, so you build up your parser before executing it.

```elixir
separated_list1(is_a(" -"), digit1()).("555 555-1212") #=> {:ok, "", ["555", "555", "1212"]}
```

Keep adding functions.  There are a couple dozen to learn, and you can easily make your own.

```elixir
all_consuming(                                  # ensure all the input text is matched
    tuple({                                     # match on these one after the other
        delimited(                              # match the start & end characters and throw them away
            char("("),                          # (start character) 
            take_while_m_n(3, 3, &is_digit/1),  # take exactly 3 digits
            tag(") ")                           # (end characters)
        ),
        terminated(                             # match the end characters and throw them away
            take_while_m_n(3, 3, &is_digit/1),  # take exactly 3 digits
            one_of("- ")                        # (end characters, either a "-" or a " ")
        ),
        take_while_m_n(4, 4, &is_digit/1),      # take exactly 4 digits
    })
).("(555) 555-1212")
#=> {:ok, "", ["555", "555", "1212"]}
```

By default, most parser functions return strings.  With `map/1` though you can map them into your own data format.

```elixir
map(
    separated_list1(
        char(" "),
        tuple({
            terminated(
                map(
                    digit1(),
                    &String.to_integer/1
                ),
                char(":")
            ),
            take_till(&is_space/1)
        })
    ),
    &Map.new/1
).("1:foxes 4:banana 10:pumpkin")
#=> {:ok, "", %{1 => "foxes", 4 => "banana", 10 => "pumpkin"}}
```

## Differences with nom

### Strings vs bitstrings

Because Elixir's bitstrings and strings are the same type, you'll need to select the right module to use.

You most likely want to use `Elnom.Strings.Complete` which has exactly the same functions but works with strings
and handles utf-8 characters. `Elnom.Bytes.Complete` is only for use when using bitstreams and will not handle
utf-8 characters.  

### No streaming support

nom has support for streamed matching.  elnom does not support this (yet).
