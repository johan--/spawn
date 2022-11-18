defmodule ActivatorHTTP.MixProject do
  use Mix.Project

  @app :activator_http
  @version "local.dev"

  def project do
    [
      app: @app,
      version: @version,
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ActivatorHTTP.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:activator, path: "../activator"},
      {:spawn, path: "../../"},
      {:burrito, github: "burrito-elixir/burrito"}
      {:bandit, "~> 0.5"}
    ]
  end

  defp releases do
    [
      activator_http: [
        include_executables_for: [:unix],
        applications: [activator_http: :permanent],
        steps: [
          :assemble,
          &Burrito.wrap/1
        ],
        burrito: [
          targets: [
            linux: [os: :linux, cpu: :x86_64]
          ],
        ]
      ]
    ]
  end
end
