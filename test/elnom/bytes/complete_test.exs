defmodule Elnom.Bytes.CompleteTest do
  use ExUnit.Case
  import Elnom.Branch
  import Elnom.Combinator
  import Elnom.Character.Complete
  import Elnom.Bytes.Complete

  alias Elnom.Error

  doctest Elnom.Bytes.Complete
end
