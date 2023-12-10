defmodule Elnom.Error do
  @moduledoc """
  Error struct indicating a recoverable error has occurred during parsing.

  The `kind` field is an atom indicating the kind of error that occurred.

  The `buffer` field holds the input buffer at the time the error occurred.
  """
  defstruct [:kind, :buffer]

  @doc "Create a new Error struct."
  def new(kind, buffer) do
    %__MODULE__{kind: kind, buffer: buffer}
  end

  @doc """
  Dumps the parser output to the console if the parser returns an error.

  `context` is any value (usually a string) that will be printed before the
  error message.
  """
  def dbg_dmp(parser, context) do
    fn input ->
      case parser.(input) do
        {:ok, input, output} ->
          {:ok, input, output}

        {:error, error} ->
          IO.puts("#{inspect(context)}: #{inspect(error)}")
          {:error, error}
      end
    end
  end
end
