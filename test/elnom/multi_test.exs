defmodule Elnom.MultiTest do
  use ExUnit.Case
  import Elnom.Character.Complete, only: [alpha0: 0, digit1: 0, integer: 0]
  import Elnom.Combinator
  import Elnom.Multi
  import Elnom.Number
  import Elnom.Strings.Complete

  alias Elnom.{Error, Incomplete}

  doctest Elnom.Multi
end
