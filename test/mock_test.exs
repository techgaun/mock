Code.require_file "test_helper.exs", __DIR__


defmodule MockTest do
  use ExUnit.Case, async: false
  import Mock

  setup_all do
    foo = "bar"
    {:ok, foo: foo}
  end

  defp test_fun do
    "string"
    |> String.reverse()
    |> String.reverse()
  end

  test "simple mock" do
    with_mock String,
        [reverse: fn(x) -> 2*x end] do
      assert String.reverse(3) == 6
    end
  end

  test "mock num_calls" do
    with_mock String,
        [reverse: fn(x) -> x end] do
      test_fun()
      assert called 2, String.reverse("string")
    end
  end

  test "multiple mocks" do
    with_mocks([
      {Map,
       [],
       [get: fn(%{}, "http://example.com") -> "<html></html>" end]},
      {String,
       [],
       [reverse: fn(x) -> 2*x end,
        length: fn(_x) -> :ok end]}
    ]) do
      assert Map.get(%{}, "http://example.com") == "<html></html>"
      assert String.reverse(3) == 6
      assert String.length(3) == :ok
    end
  end

  test "mock fuctions with different arity" do
    with_mock String,
      [slice: fn(string, _range)      -> string end,
       slice: fn(string, _range, _len) -> string end]
    do
      assert String.slice("test", 1..3) == "test"
      assert String.slice("test", 1, 3) == "test"
    end
  end

  test "mock returns the result" do
    result = with_mock String,
    [reverse: fn(x) -> 2*x end] do
      assert String.reverse(3) == 6
      String.reverse(3)
    end
    assert result == 6
  end

  test "called" do
    with_mock String,
       [reverse: fn(x) -> 2*x end,
        length: fn(_x) -> :ok end] do
      String.reverse 3
      assert :meck.called String, :reverse, [3]
      assert called String.reverse(3)
      refute called String.reverse(2)
      refute called String.length(3)
    end
  end

  test "assert_called" do
    with_mock String,
      [
        reverse: fn(x) -> 2*x end,
        length: fn(_x) -> :ok end,
        trim: fn x -> x end
      ] do
      try do
        "This should never be tested" = assert_called String.trim(:_)
      rescue
        error in [ExUnit.AssertionError] -> "Did not receive any call for Elixir.String" = error.message
      end

      String.reverse(3)
      assert_called(String.reverse(3))
      assert_called 1, String.reverse(3)

      try do
        "This should never be tested" = assert_called 1, String.reverse(6)
      rescue
        error in [ExUnit.AssertionError] ->
          """
          Expected 1 call(s) for Elixir.String.reverse(6). Got 0 calls
          Calls which were received:
          
          0. Elixir.String.reverse(3) (returned 6)\
          """ = error.message
      end

      try do
            "This should never be tested" = assert_called(String.reverse(2))
      rescue
        error in [ExUnit.AssertionError] ->
          """
          Expected call but did not receive it. Calls which were received:
          
          0. Elixir.String.reverse(3) (returned 6)\
          """ = error.message
      end
    end
  end

  test_with_mock "test_with_mock",
    String,
    [reverse: fn(_x) -> :ok end] do
    assert String.reverse 3
    assert called String.reverse(3)
    refute called String.reverse(4)
  end

  test_with_mock "test_with_mock with context", %{foo: foo}, String, [],
    [reverse: fn(_x) -> :ok end] do
    assert String.reverse 3
    assert foo == "bar"
    assert called String.reverse(3)
    refute called String.reverse(4)
  end

  test_with_mock "passthrough", Map, [:passthrough],
    [] do
    hd = Map.put(Map.new(), :a, 1)
    assert Map.get(hd, :a) == 1
    assert called Map.new()
    assert called Map.get(hd, :a)
    refute called Map.get(hd, :b)
  end

  test "restore after exception" do
    assert String.downcase("A") == "a"
    try do
      with_mock String,
          [downcase: fn(x) -> x end] do
        assert String.downcase("A") == "A"
        raise "some error"
      end
    rescue
      RuntimeError -> :ok
    end
    assert String.downcase("A") == "a"
  end

end
