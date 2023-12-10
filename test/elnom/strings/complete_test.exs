defmodule Elnom.Strings.CompleteTest do
  use ExUnit.Case
  import Elnom.Branch
  import Elnom.Combinator
  import Elnom.Character
  import Elnom.Character.Complete
  import Elnom.Strings.Complete

  alias Elnom.Error

  doctest Elnom.Strings.Complete
end
