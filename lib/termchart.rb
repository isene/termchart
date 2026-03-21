require_relative "termchart/version"
require_relative "termchart/canvas"
require_relative "termchart/spark"
require_relative "termchart/line"
require_relative "termchart/candle"
require_relative "termchart/bar"

module Termchart
  NAMED_COLORS = {
    red: 196, green: 82, blue: 33, yellow: 226, cyan: 51,
    magenta: 201, white: 255, gray: 245, orange: 208
  }.freeze

  # Shared colorize helper (ANSI escape wrapping).
  # Supports Integer (256-color), Symbol (named), and hex string.
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

  # Shared numeric formatter for axis labels.
  def self.format_num(v)
    if v.abs >= 1000
      "%.0f" % v
    elsif v.abs >= 100
      "%.1f" % v
    elsif v.abs >= 1
      "%.1f" % v
    else
      "%.2f" % v
    end
  end

  # Convenience: Termchart.spark([1,3,5,2,8], color: :green)
  def self.spark(values, color: nil)
    Spark.render(values, color: color)
  end
end
