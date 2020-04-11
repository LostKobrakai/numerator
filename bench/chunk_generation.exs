Benchee.run(%{
  "Small number of pages" => fn ->
    Numerator.RangeToVisibleChunk.to_visible_chunk(1..100, 53, 5)
  end,
  "Large number of pages" => fn ->
    Numerator.RangeToVisibleChunk.to_visible_chunk(1..100_000, 53, 5)
  end
})
