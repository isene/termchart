module Termchart
  # Horizontal and vertical bar charts.
  # Horizontal uses ▏▎▍▌▋▊▉█ eighths for sub-cell width.
  # Vertical uses ▁▂▃▄▅▆▇█ eighths for sub-cell height.
  class Bar
    H_BLOCKS = [" ", "▏", "▎", "▍", "▌", "▋", "▊", "▉", "█"].freeze
    V_BLOCKS = [" ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"].freeze

    attr_accessor :width, :orientation

    def initialize(width: 40, height: nil, orientation: :horizontal)
      @width       = width
      @height      = height  # only used for vertical
      @orientation = orientation
      @items       = []
    end

    def add(label, value, color: nil)
      @items << { label: label.to_s, value: value.to_f, color: color }
    end

    def render
      return "" if @items.empty?
      @orientation == :horizontal ? render_horizontal : render_vertical
    end

    private

    def render_horizontal
      max_val = @items.map { |i| i[:value] }.max
      max_val = 1.0 if max_val.zero?
      label_w = @items.map { |i| i[:label].length }.max
      val_w   = @items.map { |i| format_val(i[:value]).length }.max
      bar_w   = @width - label_w - val_w - 4  # " │" + " " + value
      bar_w   = 10 if bar_w < 10

      lines = @items.map do |item|
        frac   = item[:value] / max_val * bar_w
        full   = frac.floor
        eighth = ((frac - full) * 8).round.clamp(0, 8)
        bar    = "█" * full
        bar   += H_BLOCKS[eighth] if eighth > 0 && full < bar_w
        pad    = bar_w - visible_len(bar)
        pad    = 0 if pad < 0
        bar_str = bar + " " * pad
        bar_str = colorize(bar_str, item[:color]) if item[:color]
        lbl = item[:label].ljust(label_w)
        val = format_val(item[:value]).rjust(val_w)
        "#{lbl} │#{bar_str} #{val}"
      end
      lines.join("\n")
    end

    def render_vertical
      max_val = @items.map { |i| i[:value] }.max
      max_val = 1.0 if max_val.zero?
      h = @height || 15
      col_w = [@items.map { |i| i[:label].length }.max, 3].max
      cols = @items.map do |item|
        frac   = item[:value] / max_val * h
        full   = frac.floor
        eighth = ((frac - full) * 8).round.clamp(0, 8)
        column = []
        h.times do |row|
          row_from_bottom = h - 1 - row
          if row_from_bottom < full
            column << "█" * col_w
          elsif row_from_bottom == full && eighth > 0
            column << (V_BLOCKS[eighth] * col_w)
          else
            column << " " * col_w
          end
        end
        column
      end

      lines = []
      h.times do |row|
        parts = cols.each_with_index.map do |col, i|
          cell = col[row]
          @items[i][:color] ? colorize(cell, @items[i][:color]) : cell
        end
        lines << parts.join(" ")
      end
      # Labels below
      labels = @items.map { |i| i[:label].center(col_w) }.join(" ")
      lines << labels
      lines.join("\n")
    end

    def format_val(v)
      v == v.to_i.to_f ? v.to_i.to_s : ("%.2f" % v)
    end

    def visible_len(str)
      str.gsub(/\e\[[0-9;]*m/, "").length
    end

    def colorize(str, color)
      code = case color
             when Integer then "38;5;#{color}"
             when /\A#?([0-9a-fA-F]{6})\z/
               r, g, b = [$1].pack("H*").unpack("CCC")
               "38;2;#{r};#{g};#{b}"
             else "38;5;#{color}"
             end
      "\e[#{code}m#{str}\e[0m"
    end
  end
end
