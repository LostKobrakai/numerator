defmodule Numerator.RangeToVisibleChunk do
  @moduledoc false
  @type max_chunk_size :: non_neg_integer()

  @spec to_visible_chunk(Range.t(), Numerator.page(), max_chunk_size) :: list(Numerator.page())
  def to_visible_chunk(range, current_page, max_chunk_size) do
    with chunk_size when chunk_size > 0 <- greatest_possible_chunk_size(range, max_chunk_size),
         chunks when chunks != [] <- Enum.chunk_every(range, chunk_size, 1, :discard) do
      middle = middle(chunk_size)

      sorted_chunks =
        Enum.sort_by(chunks, fn chunk ->
          index = Enum.find_index(chunk, fn x -> x == current_page end)

          cond do
            is_nil(index) -> :noindex
            index == middle -> 0
            index < middle -> middle - index
            index > middle -> index - middle + 1
          end
        end)

      List.first(sorted_chunks)
    else
      _ -> []
    end
  end

  @spec middle(pos_integer()) :: pos_integer()
  defp middle(i) when rem(i, 2) == 0 do
    div(i, 2) - 1
  end

  defp middle(i) when rem(i, 2) == 1 do
    div(i, 2)
  end

  @spec greatest_possible_chunk_size(Range.t(), non_neg_integer()) :: non_neg_integer()
  defp greatest_possible_chunk_size(range, max_chunk_size) do
    min(max_chunk_size, Enum.count(range))
  end
end
