require "minitest/autorun"
require_relative "../lib/termchart"

class TestSpark < Minitest::Test
  def test_empty_array_returns_empty_string
    assert_equal "", Termchart::Spark.render([])
  end

  def test_nil_returns_empty_string
    assert_equal "", Termchart::Spark.render(nil)
  end

  def test_normal_values_produce_braille_output
    result = Termchart::Spark.render([1, 3, 5, 2, 8])
    refute_empty result
    assert_equal 5, result.length
  end

  def test_single_value_works
    result = Termchart::Spark.render([42])
    refute_empty result
    assert_equal 1, result.length
  end

  def test_color_wraps_in_ansi
    result = Termchart::Spark.render([1, 2, 3], color: :green)
    assert_match(/\e\[/, result)
    assert_match(/\e\[0m\z/, result)
  end
end

class TestLine < Minitest::Test
  def test_empty_series_returns_empty_string
    chart = Termchart::Line.new
    assert_equal "", chart.render
  end

  def test_height_clamping_to_minimum_3
    chart = Termchart::Line.new(width: 30, height: 1)
    chart.add([1, 5, 3, 7, 2])
    result = chart.render
    # Should render without error; canvas height will be 3
    lines = result.split("\n")
    assert lines.length >= 3
  end

  def test_basic_render_produces_output
    chart = Termchart::Line.new(width: 40, height: 10)
    chart.add([10, 20, 15, 25, 30])
    result = chart.render
    refute_empty result
  end
end

class TestCandle < Minitest::Test
  def test_invalid_ohlc_raises_argument_error
    chart = Termchart::Candle.new
    assert_raises(ArgumentError) do
      chart.add([{ o: 10, h: 5, l: 8, c: 9 }])  # high < low
    end
  end

  def test_valid_ohlc_does_not_raise
    chart = Termchart::Candle.new
    chart.add([{ o: 10, h: 15, l: 8, c: 12 }])
    # Should not raise
  end

  def test_height_clamping
    chart = Termchart::Candle.new(width: 30, height: 1)
    chart.add([{ o: 10, h: 15, l: 8, c: 12 }])
    result = chart.render
    lines = result.split("\n")
    assert lines.length >= 3
  end

  def test_empty_data_returns_empty_string
    chart = Termchart::Candle.new
    assert_equal "", chart.render
  end
end

class TestBar < Minitest::Test
  def test_negative_values_raise_argument_error
    chart = Termchart::Bar.new
    chart.add("item", -5)
    assert_raises(ArgumentError) do
      chart.render
    end
  end

  def test_positive_values_render_fine
    chart = Termchart::Bar.new(width: 40)
    chart.add("Apples", 10)
    chart.add("Bananas", 20)
    result = chart.render
    refute_empty result
    assert_match(/Apples/, result)
    assert_match(/Bananas/, result)
  end

  def test_empty_items_returns_empty_string
    chart = Termchart::Bar.new
    assert_equal "", chart.render
  end
end

class TestCanvas < Minitest::Test
  def test_set_get_within_bounds
    canvas = Termchart::Canvas.new(10, 5)
    canvas.set(3, 2, "X", fg: 196)
    cell = canvas.get(3, 2)
    assert_equal "X", cell[0]
    assert_equal 196, cell[1]
  end

  def test_out_of_bounds_set_is_ignored
    canvas = Termchart::Canvas.new(10, 5)
    canvas.set(-1, 0, "X")
    canvas.set(10, 0, "X")
    canvas.set(0, -1, "X")
    canvas.set(0, 5, "X")
    # None of these should raise; get returns nil for out of bounds
    assert_nil canvas.get(-1, 0)
    assert_nil canvas.get(10, 0)
  end

  def test_default_cell_is_space
    canvas = Termchart::Canvas.new(5, 5)
    cell = canvas.get(0, 0)
    assert_equal " ", cell[0]
    assert_nil cell[1]
    assert_nil cell[2]
  end
end

class TestSharedHelpers < Minitest::Test
  def test_colorize_with_integer
    result = Termchart.colorize("hi", 196)
    assert_equal "\e[38;5;196mhi\e[0m", result
  end

  def test_colorize_with_symbol
    result = Termchart.colorize("hi", :red)
    assert_equal "\e[38;5;196mhi\e[0m", result
  end

  def test_colorize_with_hex
    result = Termchart.colorize("hi", "#ff0000")
    assert_match(/\e\[38;2;\d+;\d+;\d+mhi\e\[0m/, result)
  end

  def test_format_num_large
    assert_equal "1500", Termchart.format_num(1500.0)
  end

  def test_format_num_medium
    assert_equal "50.0", Termchart.format_num(50.0)
  end

  def test_format_num_small
    assert_equal "0.42", Termchart.format_num(0.42)
  end
end
