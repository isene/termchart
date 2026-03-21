module Termchart
  # Braille line chart with Y-axis labels.
  # Uses BrailleCanvas for 2x4 sub-cell dot resolution.
  class Line
    attr_accessor :width, :height

    def initialize(width: 60, height: 20)
      @width  = width
      @height = height
      @series = []
    end

    # Add a data series (array of numeric values)
    def add(values, color: 82, label: nil)
      @series << { values: values.map(&:to_f), color: color, label: label }
    end

    def render
      return "" if @series.empty?
      effective_height = [@height, 3].max

      # Compute global min/max across all series
      all_vals = @series.flat_map { |s| s[:values] }
      data_min = all_vals.min
      data_max = all_vals.max
      data_range = data_max - data_min
      data_range = 1.0 if data_range.zero?

      # Reserve space for Y-axis labels (use widest of min/mid/max)
      mid = data_min + data_range / 2.0
      y_label_w = [Termchart.format_num(data_max), Termchart.format_num(data_min), Termchart.format_num(mid)].map(&:length).max + 1
      chart_w = @width - y_label_w
      chart_w = 10 if chart_w < 10
      chart_h = effective_height

      # Pixel dimensions (braille: 2 dots wide, 4 dots tall per cell)
      px_w = chart_w * 2
      px_h = chart_h * 4

      canvas = BrailleCanvas.new(chart_w, chart_h)

      @series.each do |series|
        vals = series[:values]
        n = vals.length
        next if n < 2

        # Map each value to pixel coordinates
        points = vals.each_with_index.map do |v, i|
          px = n == 1 ? 0 : (i.to_f / (n - 1) * (px_w - 1)).round
          py = ((data_max - v) / data_range * (px_h - 1)).round.clamp(0, px_h - 1)
          [px, py]
        end

        # Draw lines between consecutive points using Bresenham
        (0...points.length - 1).each do |i|
          x0, y0 = points[i]
          x1, y1 = points[i + 1]
          bresenham(x0, y0, x1, y1) do |px, py|
            canvas.set_dot(px, py, fg: series[:color])
          end
        end
      end

      chart_str = canvas.render

      # Add Y-axis labels
      lines = chart_str.split("\n")
      result = lines.each_with_index.map do |line, row|
        if row == 0
          label = Termchart.format_num(data_max).rjust(y_label_w - 1) + "┤"
        elsif row == chart_h - 1
          label = Termchart.format_num(data_min).rjust(y_label_w - 1) + "┤"
        elsif row == chart_h / 2
          mid = data_min + data_range / 2.0
          label = Termchart.format_num(mid).rjust(y_label_w - 1) + "┤"
        else
          label = " " * (y_label_w - 1) + "│"
        end
        label + line
      end

      # Legend line
      if @series.any? { |s| s[:label] }
        legend = @series.map do |s|
          name = s[:label] || "data"
          Termchart.colorize("━━", s[:color]) + " " + name
        end.join("  ")
        result << " " * y_label_w + legend
      end

      result.join("\n")
    end

    private

    def bresenham(x0, y0, x1, y1)
      dx = (x1 - x0).abs
      dy = -(y1 - y0).abs
      sx = x0 < x1 ? 1 : -1
      sy = y0 < y1 ? 1 : -1
      err = dx + dy
      loop do
        yield x0, y0
        break if x0 == x1 && y0 == y1
        e2 = 2 * err
        if e2 >= dy
          err += dy
          x0 += sx
        end
        if e2 <= dx
          err += dx
          y0 += sy
        end
      end
    end

  end
end
