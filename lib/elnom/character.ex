defmodule Elnom.Character do
  @moduledoc "Character-specific parsers and combinators"

  @doc "Matches characters a..z, A..Z"
  def is_alphabetic(char), do: char in ?a..?z or char in ?A..?Z

  @doc "Matches characters a..z, A..Z, 0..9"
  def is_alphanumeric(char), do: char in ?a..?z or char in ?A..?Z or char in ?0..?9

  @doc "Matches characters 0..9"
  def is_digit(char), do: char in ?0..?9

  @doc "Matches characters 0..9, a..f, A..F"
  def is_hex_digit(char), do: char in ?0..?9 or char in ?a..?f or char in ?A..?F

  @doc "Matches characters 0..7"
  def is_oct_digit(char), do: char in ?0..?7

  @doc "Matches characters 0..1"
  def is_bin_digit(char), do: char == ?0 or char == ?1

  @doc "Matches space and tab characters"
  def is_space(char), do: char == ?\s or char == ?\t

  @doc "Matches the newline character"
  def is_newline(char), do: char == ?\n
end
