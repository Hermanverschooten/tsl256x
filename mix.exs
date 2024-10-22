defmodule TSL256X.MIXPROJECT do
  use Mix.Project

  @version "0.1.0"
  @description "Driver for TSL256x family of Light-to-digital convertors"
  @source_url "https://github.com/Hermanverschooten/tsl256x"

  def project do
    [
      app: :tsl256x,
      version: @version,
      description: @description,
      source_url: @source_url,
      package: package(),
      docs: docs(),
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: %{
        docs: :docs,
        "hex.publish": :docs,
        "hex.build": :docs
      }
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    %{
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "LICENSE",
        "CHANGELOG.md"
      ],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    }
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.22", only: :docs, runtime: false},
      {:circuits_i2c, "~> 2.0.6"}
    ]
  end

  defp docs do
    [
      assets: %{"assets" => "assets"},
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
