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
      color ? Termchart.colorize(line, color) : line
    end
  end
end
