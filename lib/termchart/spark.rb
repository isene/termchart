module Termchart
  # Sparkline: maps values to 8 eighth-block characters ▁▂▃▄▅▆▇█
  # Returns a single-line string (with optional ANSI color).
  module Spark
    TICKS = %w[▁ ▂ ▃ ▄ ▅ ▆ ▇ █].freeze

    def self.render(values, color: nil)
      return "" if values.nil? || values.empty?
      values = values.map(&:to_f)
      min = values.min
      max = values.max
      range = max - min
      chars = values.map do |v|
        idx = range.zero? ? 3 : ((v - min) / range * 7).round.clamp(0, 7)
        TICKS[idx]
      end
      line = chars.join
      color ? colorize(line, color) : line
    end

    private

    def self.colorize(str, color)
      code = case color
             when Integer then "38;5;#{color}"
             when Symbol  then "38;5;#{NAMED_COLORS[color] || 7}"
             when /\A#?([0-9a-fA-F]{6})\z/
               r, g, b = [$1].pack("H*").unpack("CCC")
               "38;2;#{r};#{g};#{b}"
             else "38;5;#{color}"
             end
      "\e[#{code}m#{str}\e[0m"
    end

    NAMED_COLORS = {
      red: 196, green: 82, blue: 33, yellow: 226, cyan: 51,
      magenta: 201, white: 255, gray: 245, orange: 208
    }.freeze
  end
end
