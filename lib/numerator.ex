defmodule Numerator do
  @moduledoc """
  Documentation for Numerator.
  """
  @type page :: pos_integer()
  @typep t :: %__MODULE__{
           page: page,
           first_page: page,
           last_page: page | :undefined,
           show_prev: boolean,
           show_next: boolean,
           show_first: boolean,
           show_last: boolean,
           num_pages_shown: non_neg_integer()
         }

  @type page_element :: %{
          type: :prev | :next | :page | :current,
          page: page
        }
  @type ellipsis_element :: %{type: :ellipsis}
  @type element :: page_element | ellipsis_element

  defstruct page: 1,
            first_page: 1,
            last_page: :undefined,
            show_prev: true,
            show_next: true,
            show_first: false,
            show_last: false,
            num_pages_shown: 5

  @doc """
  Hello world.

  ## Examples

      iex> Numerator.build(2)
      [
        %{type: :prev, page: 1},
        %{type: :next, page: 3}
      ]

      iex> Numerator.build(%{page: 2, last: 6})
      [
        %{type: :prev, page: 1},
        %{type: :page, page: 1},
        %{type: :current, page: 2},
        %{type: :page, page: 3},
        %{type: :page, page: 4},
        %{type: :page, page: 5},
        %{type: :page, page: 6},
        %{type: :next, page: 3}
      ]

      iex> Numerator.build(%{page: 2, last: 7})
      [
        %{type: :prev, page: 1},
        %{type: :page, page: 1},
        %{type: :current, page: 2},
        %{type: :page, page: 3},
        %{type: :page, page: 4},
        %{type: :page, page: 5},
        %{type: :ellipsis},
        %{type: :next, page: 3}
      ]

      iex> Numerator.build(%{page: 2, last: 7}, show_last: true)
      [
        %{type: :prev, page: 1},
        %{type: :page, page: 1},
        %{type: :current, page: 2},
        %{type: :page, page: 3},
        %{type: :page, page: 4},
        %{type: :page, page: 5},
        %{type: :page, page: 6},
        %{type: :page, page: 7},
        %{type: :next, page: 3}
      ]

      iex> Numerator.build(%{page: 2, last: 9}, show_last: true)
      [
        %{type: :prev, page: 1},
        %{type: :page, page: 1},
        %{type: :current, page: 2},
        %{type: :page, page: 3},
        %{type: :page, page: 4},
        %{type: :page, page: 5},
        %{type: :ellipsis},
        %{type: :page, page: 9},
        %{type: :next, page: 3}
      ]

  """
  @spec build(term, keyword) :: [element]
  def build(data, opts \\ []) when is_list(opts) do
    data = prepare_data(data)

    if data == :invalid do
      raise ArgumentError, "invalid input"
    end

    config =
      __MODULE__
      |> struct(from_opts(opts))
      |> struct(data)

    [
      build_prev(config),
      build_inbetween(config),
      build_next(config)
    ]
    |> List.flatten()
  end

  @spec from_opts(keyword) :: keyword
  def from_opts(opts) do
    Keyword.take(opts, [:show_prev, :show_next, :show_first, :show_last, :num_pages_shown])
  end

  @spec prepare_data(term) :: map | :invalid
  defp prepare_data(page) when is_integer(page) and page >= 1 do
    %{
      page: page,
      first_page: 1,
      show_first: false,
      show_last: false,
      num_pages_shown: 0
    }
  end

  defp prepare_data(%{page: page, last: last})
       when is_integer(page) and page >= 1 and is_integer(last) and last >= 1 and last >= page do
    %{
      page: page,
      first_page: 1,
      last_page: last
    }
  end

  defp prepare_data(%{page: page, size: size, total: total}) do
    prepare_data(%{page: page, last: div(total, size) + 1})
  end

  # Scrivener support
  defp prepare_data(%{page_number: page, total_pages: total_pages}) do
    prepare_data(%{page: page, last: total_pages})
  end

  defp prepare_data(_), do: :invalid

  @spec build_prev(t) :: list(element)
  defp build_prev(%{show_prev: false}), do: []
  defp build_prev(%{page: p, first_page: p}), do: []

  defp build_prev(%{page: p, first_page: f}) when p > f do
    [%{type: :prev, page: p - 1}]
  end

  @spec build_next(t) :: list(element)
  defp build_next(%{show_next: false}), do: []
  defp build_next(%{page: p, last_page: p}), do: []

  defp build_next(%{page: p, last_page: f}) when f == :undefined or p < f do
    [%{type: :next, page: p + 1}]
  end

  @spec build_inbetween(t) :: list(element)
  defp build_inbetween(%{num_pages_shown: 0}), do: []

  defp build_inbetween(config) do
    range = config.first_page..config.last_page
    chunks = Enum.chunk_every(range, config.num_pages_shown, 1, :discard)
    do_build_inbetween(chunks, config)
  end

  @spec do_build_inbetween(list(list(page)), t) :: list(element)
  defp do_build_inbetween([], _config), do: []

  defp do_build_inbetween(chunks, config) do
    middle = middle(config.num_pages_shown)

    sorted_chunks =
      Enum.sort_by(chunks, fn chunk ->
        index = Enum.find_index(chunk, fn x -> x == config.page end)

        cond do
          is_nil(index) -> :noindex
          index == middle -> 0
          index < middle -> middle - index
          index > middle -> index - middle + 1
        end
      end)

    sorted_chunks
    |> List.first()
    |> Enum.map(&to_pages(&1, config))
    |> add_first(config)
    |> add_last(config)
  end

  @spec middle(pos_integer()) :: pos_integer()
  defp middle(i) when rem(i, 2) == 0 do
    div(i, 2) - 1
  end

  defp middle(i) when rem(i, 2) == 1 do
    div(i, 2)
  end

  @spec to_pages(pos_integer(), t) :: page_element
  defp to_pages(page, %{page: page}) do
    %{type: :current, page: page}
  end

  defp to_pages(num, _) do
    %{type: :page, page: num}
  end

  @spec add_first(list(page_element), t) :: list(element)
  defp add_first([%{page: first_numbered} | _] = middle, %{first_page: first})
       when first == first_numbered do
    middle
  end

  defp add_first([%{page: first_numbered} | _] = middle, %{first_page: first})
       when first + 1 == first_numbered do
    [%{type: :page, page: first} | middle]
  end

  defp add_first([%{page: first_numbered} | _] = middle, %{first_page: first, show_first: true})
       when first + 2 == first_numbered do
    [%{type: :page, page: first}, %{type: :page, page: first + 1} | middle]
  end

  defp add_first(middle, %{first_page: first, show_first: true}) do
    [%{type: :page, page: first}, %{type: :ellipsis} | middle]
  end

  defp add_first(middle, %{show_first: false}) do
    [%{type: :ellipsis} | middle]
  end

  @spec add_last(list(page_element), t) :: list(element)
  defp add_last(middle, config) do
    add_last(List.last(middle), middle, config)
  end

  @spec add_last(page_element, list(page_element), t) :: list(element)
  defp add_last(%{page: last_numbered}, middle, %{last_page: last})
       when last == last_numbered do
    middle
  end

  defp add_last(%{page: last_numbered}, middle, %{last_page: last})
       when last - 1 == last_numbered do
    middle ++ [%{type: :page, page: last}]
  end

  defp add_last(%{page: last_numbered}, middle, %{last_page: last, show_last: true})
       when last - 2 == last_numbered do
    middle ++ [%{type: :page, page: last - 1}, %{type: :page, page: last}]
  end

  defp add_last(_, middle, %{last_page: last, show_last: true}) do
    middle ++ [%{type: :ellipsis}, %{type: :page, page: last}]
  end

  defp add_last(_, middle, %{show_last: false}) do
    middle ++ [%{type: :ellipsis}]
  end
end
