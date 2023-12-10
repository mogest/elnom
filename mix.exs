defmodule Elnom.MixProject do
  use Mix.Project

  def project do
    [
      app: :elnom,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/mogest/elnom",
      docs: [
        extras: ["README.md": [title: "elnom introduction"]]
      ]
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:ex_doc, "~> 0.30", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    An Elixir port of the Rust nom parser combinator framework.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/mogest/elnom"
      }
    ]
  end
end
