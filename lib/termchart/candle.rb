module Termchart
  # OHLC candlestick chart.
  # Uses │ for wicks, █/▌ for bodies. Green (82) up, red (196) down.
  # Y-axis labels on left.
  class Candle
    UP_COLOR   = 82   # green
    DOWN_COLOR = 196  # red

    attr_accessor :width, :height

    def initialize(width: 60, height: 20)
      @width  = width
      @height = height
      @data   = []
    end

    # Add OHLC data: array of hashes with keys :o, :h, :l, :c
    def add(ohlc_data)
      ohlc_data.each do |d|
        @data << {
          o: d[:o].to_f, h: d[:h].to_f,
          l: d[:l].to_f, c: d[:c].to_f
        }
      end
    end

    def render
      return "" if @data.empty?

      data_min = @data.map { |d| d[:l] }.min
      data_max = @data.map { |d| d[:h] }.max
      data_range = data_max - data_min
      data_range = 1.0 if data_range.zero?

      # Y-axis label width
      y_label_w = [format_num(data_max).length, format_num(data_min).length].max + 1
      chart_w = @width - y_label_w
      chart_w = 10 if chart_w < 10
      chart_h = @height

      # Decide how many candles to show (1 char width each, with gaps)
      max_candles = chart_w / 2  # each candle takes 1 col + 1 gap
      visible = @data.last(max_candles)

      # Map price to row (0 = top = data_max, chart_h-1 = bottom = data_min)
      price_to_row = ->(price) {
        ((data_max - price) / data_range * (chart_h - 1)).round.clamp(0, chart_h - 1)
      }

      # Build grid
      canvas = Canvas.new(chart_w, chart_h)

      visible.each_with_index do |d, i|
        col = i * 2  # 1 col candle, 1 col gap
        next if col >= chart_w

        up = d[:c] >= d[:o]
        color = up ? UP_COLOR : DOWN_COLOR

        high_row = price_to_row.call(d[:h])
        low_row  = price_to_row.call(d[:l])
        body_top = price_to_row.call([d[:o], d[:c]].max)
        body_bot = price_to_row.call([d[:o], d[:c]].min)

        # Draw wick above body
        (high_row...body_top).each do |row|
          canvas.set(col, row, "│", fg: color)
        end

        # Draw body
        if body_top == body_bot
          # Doji: single line
          canvas.set(col, body_top, "─", fg: color)
        else
          (body_top..body_bot).each do |row|
            canvas.set(col, row, "█", fg: color)
          end
        end

        # Draw wick below body
        ((body_bot + 1)..low_row).each do |row|
          canvas.set(col, row, "│", fg: color)
        end
      end

      chart_str = canvas.render
      lines = chart_str.split("\n")

      # Add Y-axis labels
      result = lines.each_with_index.map do |line, row|
        if row == 0
          label = format_num(data_max).rjust(y_label_w - 1) + "┤"
        elsif row == chart_h - 1
          label = format_num(data_min).rjust(y_label_w - 1) + "┤"
        elsif row == chart_h / 2
          mid = data_min + data_range / 2.0
          label = format_num(mid).rjust(y_label_w - 1) + "┤"
        elsif row == chart_h / 4
          q1 = data_max - data_range / 4.0
          label = format_num(q1).rjust(y_label_w - 1) + "┤"
        elsif row == chart_h * 3 / 4
          q3 = data_min + data_range / 4.0
          label = format_num(q3).rjust(y_label_w - 1) + "┤"
        else
          label = " " * (y_label_w - 1) + "│"
        end
        label + line
      end

      result.join("\n")
    end

    private

    def format_num(v)
      if v.abs >= 1000
        "%.0f" % v
      elsif v.abs >= 100
        "%.1f" % v
      else
        "%.2f" % v
      end
    end
  end
end
