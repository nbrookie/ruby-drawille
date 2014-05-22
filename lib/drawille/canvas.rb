# -*- encoding: utf-8 -*-

module Drawille

  class Canvas

    attr_reader :chars

    PIXEL_MAP = [[0x01, 0x08], 
      [0x02, 0x10], 
      [0x04, 0x20], 
      [0x40, 0x80]]

    BRAILLE_CHAR_OFFSET = 0x2800

    def initialize 
      clear
    end

    def paint &block
      Brush.new(self).instance_eval(&block)
      self
    end

    def clear
      @chars = Hash.new { |h,v| h[v] = Hash.new(0) }
    end

    def set x, y
      x, y, px, py = convert x, y
      @chars[py][px] |= PIXEL_MAP[y % 4][x % 2]
    end

    def unset x, y
      x, y, px, py = convert x, y
      @chars[py][px] &= ~PIXEL_MAP[y % 4][x % 2]
    end

    def get x, y
      x, y, px, py = convert x, y
      @chars[py][px] & PIXEL_MAP[y % 4][x % 2] != 0
    end

    def []= x, y, bool
      bool ? set(x, y) : unset(x, y)
    end

    alias_method :[], :get

    def toggle x, y
      x, y, px, py = convert x, y
      @chars[py][px] & PIXEL_MAP[y % 4][x % 2] == 0 ? set(x, y) : unset(x, y) 
    end

    def row y, options={}
      row   = @chars[y]
      min   = options[:min_x] || row.keys.min
      max   = options[:max_x] || row.keys.max

      (min..max).reduce("") { |memo, i| memo << to_braille(row[i] || 0) }
    end

    def rows options={}
      min   = options[:min_y] || @chars.keys.min
      max   = options[:max_y] || @chars.keys.max
      options[:min_x] ||= @chars.reduce([]) { |m,x| m << x.last.keys }.flatten.min
      options[:max_x] ||= @chars.reduce([]) { |m,x| m << x.last.keys }.flatten.max
      (min..max).map { |i| row i, options }
    end

    def frame options={}
      rows(options).join("\n")
    end

    def char x, y
      to_braille @chars[y][x]
    end

    private

    def convert x, y
      x = x.round
      y = y.round
      [x, y, (x / 2).floor, (y / 4).floor]
    end

    def to_braille x
      [BRAILLE_CHAR_OFFSET + x].pack("U*")
    end
  end
end
