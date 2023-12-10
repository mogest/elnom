defmodule Elnom.Failure do
  @moduledoc """
  Error struct indicating a unrecoverable error has occurred during parsing.

  The `kind` field is an atom indicating the kind of error that occurred.

  The `buffer` field holds the input buffer at the time the error occurred.
  """
  defstruct [:kind, :buffer]

  @doc "Construct a Failure struct from an Error struct."
  def new(error) do
    %__MODULE__{kind: error.kind, buffer: error.buffer}
  end

  @doc "Construct a new Failure struct."
  def new(kind, buffer) do
    %__MODULE__{kind: kind, buffer: buffer}
  end
end
