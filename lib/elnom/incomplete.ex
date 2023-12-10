defmodule Elnom.Incomplete do
  @moduledoc """
  Error struct indicating more input is required by the parser.

  The `needed` field is an integer indicating the number of bytes needed to
  complete the current parsing operation.
  """

  defstruct [:needed]

  @doc "Create a new Incomplete struct."
  def new(needed) do
    %__MODULE__{needed: needed}
  end
end
