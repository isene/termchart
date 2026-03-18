require_relative 'lib/termchart/version'

Gem::Specification.new do |s|
  s.name        = 'termchart'
  s.version     = Termchart::VERSION
  s.licenses    = ['Unlicense']
  s.summary     = "Terminal charts with Unicode and ANSI colors"
  s.description = "Render sparklines, line charts (braille), candlestick charts, and bar charts as plain strings with ANSI color codes. Zero dependencies, pure Ruby."
  s.authors     = ["Geir Isene"]
  s.email       = 'g@isene.com'
  s.files       = [
    "lib/termchart.rb",
    "lib/termchart/version.rb",
    "lib/termchart/canvas.rb",
    "lib/termchart/spark.rb",
    "lib/termchart/line.rb",
    "lib/termchart/candle.rb",
    "lib/termchart/bar.rb",
    "README.md"
  ]
  s.homepage    = 'https://github.com/isene/termchart'
  s.metadata    = { "source_code_uri" => "https://github.com/isene/termchart" }
  s.required_ruby_version = '>= 2.7.0'
end
