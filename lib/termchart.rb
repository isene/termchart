require_relative "termchart/version"
require_relative "termchart/canvas"
require_relative "termchart/spark"
require_relative "termchart/line"
require_relative "termchart/candle"
require_relative "termchart/bar"

module Termchart
  # Convenience: Termchart.spark([1,3,5,2,8], color: :green)
  def self.spark(values, color: nil)
    Spark.render(values, color: color)
  end
end
