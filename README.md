# Fortune

[![Hex version](https://img.shields.io/hexpm/v/fortune.svg "Hex version")](https://hex.pm/packages/fortune)
[![API docs](https://img.shields.io/hexpm/v/fortune.svg?label=hexdocs "API docs")](https://hexdocs.pm/fortune/)
[![CircleCI](https://circleci.com/gh/fhunleth/elixir-fortune.svg?style=svg)](https://circleci.com/gh/fhunleth/elixir-fortune)
[![REUSE status](https://api.reuse.software/badge/github.com/fhunleth/elixir-fortune)](https://api.reuse.software/info/github.com/fhunleth/elixir-fortune)

Get a fortune!

Fortune reads a string, usually a random one, from one or more fortune files.
Fortune files contain a list of strings and an associated index for for quick
retrieval of a randomly chosen string. This implementation provides an Elixir
take on the ubiquitous [Unix fortune](https://en.wikipedia.org/wiki/Fortune_(Unix))
implementation. It is compatible with Unix fortune and can read most Unix
fortune files.

```elixir
iex> Fortune.random()
{:ok, "Harness the power of the BEAM, one Elixir potion at a time."}
```

No fortunes are provided, though. You'll need to add your own, add Elixir
libraries to your mix dependencies that have fortunes, or configure Fortune to
use your system ones.

Here's an example on Mac when you've installed `fortune` via Homebrew:

```elixir
Fortune.random(include_system_fortunes?: true)
```

Fortunes provided by Elixir libraries are stored in that library's
`priv/fortune` directory when using this library's `fortune` compiler. Fortune
scans for these paths by default.

## Installation

Add `fortune` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:fortune, "~> 0.1"}
  ]
end
```

Note that Fortune does NOT provide any fortunes itself.

## Configuration

The defaults should be good for most users. If not, see `fortune_options/0` to adjust fortune search paths and more. These can be passed to `Fortune.random/1` or added to your `config.exs` for use as new defaults:

```elixir
# Completely override fortune search paths
config :fortune, paths: [Path.join(["some/location", "fortune"])]]

# Only include fortunes from a couple applications
config :fortune, included_applications: [:funny_app, :helpful_app]

# Remove fortunes from a list of applications
config :fortune, excluded_applications: [:bad_app]
```

## Adding fortunes to your Elixir project

Any project can supply fortunes (or tips, since that's the likely use case).

Here are the steps:

1. Create a `fortune` directory in your Elixir project
1. Create one or more fortune-formatted files in the `fortune` directory
1. Add the `:fortune_compiler` to the compilers list in your `mix.exs`
1. Run `mix compile`

### Fortune files

Fortune files are text files with quotes separated by `%` lines. Filenames can
be anything but must not have an extension.

It's easies to see by example:

```sh
cd path/to/my/project
mkdir -p fortune
touch fortune/my-fortunes
```

Then open `my-fortunes` in a text editor:

```text
My first fortune
%
Another string or fortune
and this can be multiple lines too.
%
The last string
```

### Compiling fortune files

Fortune files need to be indexed for use by `fortune`. The `:fortune_compiler`
knows how to do this, so add it to your `mix.exs`:

```elixir
  def project do
    [
      ...
      compilers: Mix.compilers() ++ [:fortune_compiler],
      ...
    ]
  end
```

If you don't like putting your fortunes in the `fortune` directory, use the
`:fortunec_paths` option.

Finally, run:

```sh
mix deps.get
mix compile
```

Then to see the result of your work, run:

```sh
iex -S mix

Interactive Elixir - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> Fortune.random()
{:ok, "My first fortune"}
```
