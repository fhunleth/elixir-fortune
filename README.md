# Fortune

[Fortune] file reader for Elixir.

This package provides the following features:

- `:fortune_compiler` Mix compiler that builds a [strfile]-format index file
  based on your text file that contains a collection of quotes separated by a
  `%` line
- Elixir functions that read a random fortune from compiled [strfile]s

[Fortune]: https://wiki.archlinux.org/title/Fortune
[fortune]: https://man.archlinux.org/man/fortune.6
[strfile]: https://man.archlinux.org/man/strfile.1

## Installation

Add `fortune` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:fortune, "~> 0.1"}
  ]
end
```

## Usage

`Fortune.random/1` picks one from a collection of quotes.

```elixir
iex> Fortune.random()
{:ok, "Elixir – where functional meets fun."}
```

By default, elixir-fortune will search for all available fortune files that
provided by your Elixir project and its dependencies.

## Configuration

elixir-fortune can be configured either:

- specifying settings in your `config/config.exs`; or
- passing `Fortune.random/1` options at runtime

See [online documentation](https://hexdocs.pm/fortune) for available options.

### compile-time configuration

Here are examples:

```elixir
# list absolute paths to `fortune` directories
config :fortune, paths: [Path.join(["some/location", "fortune"])]]

# list applications whose fortunes you want to opt in for
config :fortune, include: [:foo_app, :bar_app]

# list applications whose fortunes you want to opt out of
config :fortune, exclude: [:foo_app, :bar_app]
```

### runtime options

The same configuration options can be passed to `Fortune.random/1` at runtime.

```elixir
iex> Fortune.random(exclude: [:foo_app, :bar_app])
```

## How to add custom fortunes to your Elixir project

Here are the steps to take:

1. create a `fortune` directory in your Elixir project
1. create a fortune text file or more that have no extension in your `fortune` directory
1. append `:fortune_compiler` to default Mix compilers in your `mix.exs`
1. run `mix compile`

**fortune file format**

It is important that your fortune text files have no extension; otherwise,
currently elixir-fortune won't recognize them.

```bash
cd path/to/my/project
mkdir -p fortune
touch fortune/my-custom-quotes
```

**fortune content format**

In your fortune text file, your quotes should be separated by a `%` line. For
example:

```text
My first fortune
%
Another string or fortune
and this can be multiple lines too.
%
The last string
```

**setting up strfile compiler**

Append `:fortune_compiler` to ` Mix.compilers/1` in your `mix.exs` as follows:

```elixir
  def project do
    [
      ...
      compilers: Mix.compilers() ++ [:fortune_compiler],
      ...
    ]
  end
```

**compiling fortunes**

When you run `mix compile`, `:fortune_compiler` will scan all the `fortune`
directories in your project and its dependencies, then generate a `.dat` index
data file corresponding to each fortune text file.

```bash
mix deps.get
mix compile
```
