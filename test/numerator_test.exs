defmodule NumeratorTest do
  use ExUnit.Case
  use ExUnitProperties
  doctest Numerator

  describe "build/2" do
    test "it raises for invalid input" do
      assert_raise ArgumentError, "invalid input", fn ->
        Numerator.build(%{last: 5})
      end

      assert_raise ArgumentError, "invalid input", fn ->
        Numerator.build(-1)
      end

      assert_raise ArgumentError, "invalid input", fn ->
        Numerator.build(%{page: -1, last: 5})
      end

      assert_raise ArgumentError, "invalid input", fn ->
        Numerator.build(%{page: 2, size: 10, total: 9})
      end
    end

    test "it does not raise for valid inputs" do
      Numerator.build(5)
      Numerator.build(%{page: 2, last: 4})
      Numerator.build(%{page: 2, last: 2})
      Numerator.build(%{page: 2, size: 10, total: 15})
      Numerator.build(%{page_number: 2, total_pages: 2})
    end

    property "number input will only result in prev/next items" do
      check all num <- positive_integer(),
                # Prevent num == 1
                num = num + 1 do
        list = Numerator.build(num)
        assert [%{type: :prev} = prev, %{type: :next} = next] = list
        assert num - 1 == prev.page
        assert num + 1 == next.page
      end

      list = Numerator.build(1)
      assert [%{type: :next} = next] = list
      assert 2 == next.page
    end

    property "page/last input will only result in prev/next items with num_pages_shown: 0" do
      config = [num_pages_shown: 0]

      check all num <- positive_integer(),
                # Prevent num == 1
                num = num + 1,
                add_for_last <- positive_integer() do
        list = Numerator.build(%{page: num, last: num + add_for_last}, config)
        assert [%{type: :prev} = prev, %{type: :next} = next] = list
        assert num - 1 == prev.page
        assert num + 1 == next.page
      end

      check all num <- positive_integer() do
        list = Numerator.build(%{page: 1, last: 1 + num}, config)
        assert [%{type: :next} = next] = list
        assert 2 == next.page
      end

      check all num <- positive_integer(),
                num = num + 1 do
        list = Numerator.build(%{page: num, last: num}, config)
        assert [%{type: :prev} = prev] = list
        assert num - 1 == prev.page
      end

      list = Numerator.build(%{page: 1, last: 1}, config)
      assert [] = list
    end

    property "ellipsis is never shown between first_page and first number if there would only be only a single page hidden" do
      config = [show_first: true, show_prev: false, show_next: false]

      # [1, x, 3] size: 1, page: 3
      # [1, x, 3, 4] size: 2, page: 3
      # [1, x, 3, 4, 5] size: 3, page: 4
      # [1, x, 3, 4, 5, 6] size: 4, page: 4
      check all num <- positive_integer(),
                page = div(num + 1, 2) + 2,
                # Big enough to not hit the end
                last = page * 3 do
        list = Numerator.build(%{page: page, last: last}, [{:num_pages_shown, num} | config])
        assert [%{type: :page, page: 1}, %{type: :page, page: 2} | _] = list

        list = Numerator.build(%{page: page + 1, last: last}, [{:num_pages_shown, num} | config])
        assert [%{type: :page, page: 1}, %{type: :ellipsis}, %{page: 4} | _] = list
      end
    end

    property "ellipsis is never shown between first_page and first number if both are adjacent" do
      config = [show_first: true, show_prev: false, show_next: false]

      # [1, 2] size: 1, page: 2
      # [1, 2, 3] size: 2, page: 2
      # [1, 2, 3, 4] size: 3, page: 3
      # [1, 2, 3, 4, 5] size: 4, page: 3
      check all num <- positive_integer(),
                page = div(num + 1, 2) + 1,
                # Big enough to not hit the end
                last = page * 3 do
        list = Numerator.build(%{page: page, last: last}, [{:num_pages_shown, num} | config])
        assert [%{type: :page, page: 1}, %{page: 2} | _] = list
      end
    end

    property "first page is not added if already part of numbering" do
      config = [show_first: true, show_prev: false, show_next: false]

      # [1, 2] size: 2, page: 1
      # [1, 2, 3] size: 3, page: 2
      # [1, 2, 3, 4] size: 4, page: 2
      # [1, 2, 3, 4, 5] size: 5, page: 3
      # [1, 2, 3, 4, 5, 6] size: 6, page: 3
      check all num <- positive_integer(),
                # size one has no second page
                num = num + 1,
                page = div(num + 1, 2),
                # Big enough to not hit the end
                last = page * 3 do
        list = Numerator.build(%{page: page, last: last}, [{:num_pages_shown, num} | config])
        assert [%{page: 1}, %{page: 2} | _] = list
      end
    end

    property "ellipsis is never shown between last_page and last number if there would only be only a single page hidden" do
      config = [show_last: true, show_prev: false, show_next: false]

      check all num <- positive_integer(),
                last = num * 10,
                page = last - (div(num + 2, 2) + 1) do
        last_minus_one = last - 1
        last_minus_three = last - 3

        list = Numerator.build(%{page: page, last: last}, [{:num_pages_shown, num} | config])

        assert [%{type: :page, page: ^last}, %{type: :page, page: ^last_minus_one} | _] =
                 Enum.reverse(list)

        list =
          Numerator.build(%{page: page - 1, last: last}, [
            {:num_pages_shown, num} | config
          ])

        assert [%{type: :page, page: ^last}, %{type: :ellipsis}, %{page: ^last_minus_three} | _] =
                 Enum.reverse(list)
      end
    end

    property "ellipsis is never shown between last_page and last number if both are adjacent" do
      config = [show_last: true, show_prev: false, show_next: false]

      check all num <- positive_integer(),
                last = num * 10,
                page = last - div(num + 2, 2) do
        last_minus_one = last - 1

        list = Numerator.build(%{page: page, last: last}, [{:num_pages_shown, num} | config])

        assert [%{type: :page, page: ^last}, %{page: ^last_minus_one} | _] = Enum.reverse(list)
      end
    end

    property "last page is not added if already part of numbering" do
      config = [show_last: true, show_prev: false, show_next: false]

      check all num <- positive_integer(),
                # size one has no second page
                num = num + 1,
                last = num * 10,
                page = last - (div(num + 2, 2) - 1) do
        last_minus_one = last - 1

        list = Numerator.build(%{page: page, last: last}, [{:num_pages_shown, num} | config])

        assert [%{type: :page, page: ^last}, %{page: ^last_minus_one} | _] = Enum.reverse(list)
      end
    end
  end
end
