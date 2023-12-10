defmodule Elnom.CombinatorTest do
  use ExUnit.Case
  import Elnom.Branch
  import Elnom.Character.Complete, only: [alpha1: 0, char: 1, digit1: 0, one_of: 1]
  import Elnom.Combinator
  import Elnom.Multi
  import Elnom.Number
  import Elnom.Sequence
  import Elnom.Strings.Complete

  alias Elnom.{Error, Failure}

  doctest Elnom.Combinator
end
