module Termchart
  # Character grid where each cell has a character, fg color, and bg color.
  # render() converts to an ANSI-colored string (rows joined by \n).
  class Canvas
    attr_reader :width, :height

    def initialize(width, height)
      @width  = width
      @height = height
      @cells  = Array.new(height) { Array.new(width) { [" ", nil, nil] } }
    end

    # Set a cell: char, optional fg/bg (256-color int or hex string)
    def set(x, y, char, fg: nil, bg: nil)
      return unless x >= 0 && x < @width && y >= 0 && y < @height
      @cells[y][x] = [char, fg, bg]
    end

    def get(x, y)
      return nil unless x >= 0 && x < @width && y >= 0 && y < @height
      @cells[y][x]
    end

    def render
      @cells.map { |row| render_row(row) }.join("\n")
    end

    private

    def render_row(row)
      out = +""
      prev_fg = prev_bg = nil
      row.each do |char, fg, bg|
        if fg != prev_fg || bg != prev_bg
          out << "\e[0m" if prev_fg || prev_bg
          codes = []
          codes << fg_code(fg) if fg
          codes << bg_code(bg) if bg
          out << "\e[#{codes.join(';')}m" unless codes.empty?
          prev_fg = fg
          prev_bg = bg
        end
        out << char
      end
      out << "\e[0m" if prev_fg || prev_bg
      out
    end

    def fg_code(color)
      case color
      when Integer then "38;5;#{color}"
      when /\A#?([0-9a-fA-F]{6})\z/
        r, g, b = [$1].pack("H*").unpack("CCC")
        "38;2;#{r};#{g};#{b}"
      else "38;5;#{color}"
      end
    end

    def bg_code(color)
      case color
      when Integer then "48;5;#{color}"
      when /\A#?([0-9a-fA-F]{6})\z/
        r, g, b = [$1].pack("H*").unpack("CCC")
        "48;2;#{r};#{g};#{b}"
      else "48;5;#{color}"
      end
    end
  end

  # Braille canvas: each terminal cell maps to a 2x4 dot grid.
  # Pixel resolution = width*2 x height*4.
  # Uses Unicode braille patterns U+2800..U+28FF.
  class BrailleCanvas < Canvas
    # Braille dot offsets: dot(px % 2, py % 4) maps to a bit
    #   col0  col1
    #   0x01  0x08   row0
    #   0x02  0x10   row1
    #   0x04  0x20   row2
    #   0x40  0x80   row3
    DOT_MAP = [
      [0x01, 0x08],
      [0x02, 0x10],
      [0x04, 0x20],
      [0x40, 0x80],
    ].freeze

    def initialize(width, height)
      super
      @dots = Array.new(height) { Array.new(width, 0) }
    end

    # Set a sub-cell dot. px range: 0..width*2-1, py range: 0..height*4-1
    def set_dot(px, py, fg: nil)
      cx = px / 2
      cy = py / 4
      return unless cx >= 0 && cx < @width && cy >= 0 && cy < @height
      dx = px % 2
      dy = py % 4
      @dots[cy][cx] |= DOT_MAP[dy][dx]
      # Store fg color on the cell
      cell = get(cx, cy)
      if cell
        set(cx, cy, cell[0], fg: fg || cell[1], bg: cell[2])
      end
    end

    def render
      # Convert dot patterns to braille characters, then render as Canvas
      @height.times do |cy|
        @width.times do |cx|
          pattern = @dots[cy][cx]
          char = (0x2800 + pattern).chr(Encoding::UTF_8)
          cell = get(cx, cy)
          set(cx, cy, char, fg: cell ? cell[1] : nil, bg: cell ? cell[2] : nil)
        end
      end
      super
    end
  end
end
