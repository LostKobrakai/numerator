# Numerator
[![Build Status](https://travis-ci.org/madeitGmbH/numerator.svg?branch=master)](https://travis-ci.org/madeitGmbH/numerator)
[![Coverage Status](https://coveralls.io/repos/github/madeitGmbH/numerator/badge.svg?branch=master)](https://coveralls.io/github/madeitGmbH/numerator?branch=master)

Numerator does calculate paginations without creating any markup. Building markup based on the returned list of elements is up to the user.

## Usage

```elixir
iex(1)> Numerator.build(%{page: 6, last: 17}, show_first: true, show_last: true)
[
  %{page: 5, type: :prev},
  %{page: 1, type: :page},
  %{type: :ellipsis},
  %{page: 4, type: :page},
  %{page: 5, type: :page},
  %{page: 6, type: :current},
  %{page: 7, type: :page},
  %{page: 8, type: :page},
  %{type: :ellipsis},
  %{page: 17, type: :page},
  %{page: 7, type: :next}
]
```

### Options

* `:show_prev`: Include a prev. page element. Default `true`
* `:show_next`: Include a next page element. Default `true`
* `:prev_next_unavailable_mode`: `:remove` or `:disable` unavailable prev. or next page elements. Default `:remove`
* `:show_first`: Always show first page. Default `false`
* `:show_last`: Always show last page. Default `false`
* `:num_pages_shown`: How many numbers for pages to be shown at least. Default `5`

### Bootstrap

Example implementation using the Twitter Bootstrap UI framework.

```eex
<ul class="pagination">
	<%= for element <- pagination_data do %>
		<%= case element do %>
			<% %{type: :ellipsis} -> %>
				<li class="page-item disabled"><span class="page-link">…</span></li>
			<% %{type: :current, page: page} -> %>
				<li class="page-item active" aria-current="page">
					<span class="page-link"><%= page %><span class="sr-only">(current)</span></span>
				</li>
			<% %{type: :page, page: page} -> %>
				<li class="page-item">
					<%= link page, to: Routes.index_path(@conn, :index, %{page: page}) %>
				</li>
			<% %{type: :prev, page: :disabled} -> %>
				<li class="page-item disabled"><span class="page-link"><%= dgettext("pagination", "Prev. Page") %></span></li>
			<% %{type: :prev, page: page} -> %>
				<li class="page-item">
					<%= link dgettext("pagination", "Prev. Page"), to: Routes.index_path(@conn, :index, %{page: page}) %>
				</li>
			<% %{type: :next, page: :disabled} -> %>
				<li class="page-item disabled"><span class="page-link"><%= dgettext("pagination", "Next Page") %></span></li>
			<% %{type: :next, page: page} -> %>
				<li class="page-item">
					<%= link dgettext("pagination", "Next Page"), to: Routes.index_path(@conn, :index, %{page: page}) %>
				</li>
	<% end %>
</ul>
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `numerator` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:numerator, "~> 0.2.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/numerator](https://hexdocs.pm/numerator).

