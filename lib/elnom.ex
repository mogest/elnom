defmodule Elnom do
  @moduledoc """
  Convenience module for importing all of elnom's functionality at once.

  Elnom has a lot of modules to mirror nom's module structure.  It's often easier just to
  import everything at once, although entirely optional to do so.

  You can choose to import either the string or bytes parsers, but not both.  If you're using
  strings, you should use type `:string`.

      use Elnom, type: :string

  If you're only handling byte data, and no unicode characters, you should use type `:bytes`.

      use Elnom, type: :bytes
  """

  defmacro __using__(opts) do
    module =
      case Keyword.get(opts, :type) do
        :bytes -> Elnom.Bytes.Complete
        :string -> Elnom.Strings.Complete
        _ -> raise "When using Elnom, you must specify opts of [type: :string] or [type: :bytes]"
      end

    quote do
      import unquote(module)
      import Elnom.Multi
      import Elnom.Branch
      import Elnom.Number
      import Elnom.Sequence
      import Elnom.Character
      import Elnom.Character.Complete
      import Elnom.Combinator
    end
  end
end
