require 'math'

class AppleCatcher < Game
  Context = Struct.new(:display, :keyboard)

  class Actor
    def initialize(c)
      @alive = true
      @image = nil
      @x = @y = 0
    end
    attr_accessor :alive

    def act(c); end

    def render(c)
      c.display.image(@image, V[@x, @y])
    end
  end

  class Player < Actor
    def initialize(c)
      super
      @image = Image["images/noschar.png"]
      @x = 240
      @y = 400 - 32
      @anim = 0
    end
    attr_reader :x, :y

    def act(c)
      if c.keyboard.pressing?(:left)
        @x -= 8
        @x = -16 if @x < -16
      end
      if c.keyboard.pressing?(:right)
        @x += 8
        @x = 640-16 if @x > 640-16
      end
      @anim = (@anim+1) % 40
    end

    def render(c)
      c.display.image_cropped(@image, V[@x, @y],
                              V[(@anim/10).floor*32, 0], V[32, 32])
    end
  end

  class Item < Actor
    def initialize(c)
      super
      @image = self.class.image
      @x = rand(c.display.width - @image.width)
      @v = rand(9)+4
    end

    def act(c)
      @y += @v
      @alive = false if @y > c.display.height
    end
  end

  class Apple < Item
    def self.image; @image ||= Image["images/apple.png"]; end

    def hit?(player)
      xdiff = (@x+38) - (player.x+16)
      ydiff = (@y+48) - (player.y+16)
      distance = Math.sqrt(xdiff**2 + ydiff**2)

      distance < (40+16)
    end
  end

  class Bomb < Item
    def self.image; @image ||= Image["images/bomb.png"]; end

    def hit?(player)
      xdiff = (@x+36) - (player.x+16)
      ydiff = (@y+54) - (player.y+16)
      distance = Math.sqrt(xdiff**2 + ydiff**2)

      distance < (34+8)
    end
  end

  def setup
    @context = Context.new(display, keyboard)
    @player = Player.new(@context)
    @actors = [@player]
    display.size = V[640, 480]
  end

  def update(elapsed)
    # Create new items if needed
    while @actors.length < 6
      @actors.push([Apple, Bomb].sample.new(@context))
    end

    # Call #act
    @actors.each do |x|
      x.act(@context)
      if x.is_a?(Item)
        if x.hit?(@player)
          x.alive = false
        end
      end
    end
    @actors.delete_if{|x| not x.alive}

    # Update display
    display.clear
    display.fill_color = C[128, 255, 255]
    display.fill_rectangle(V[0, 0], display.size)
    display.fill_color = C[0, 128, 0]
    display.fill_rectangle(V[0, 400], V[640,180])
    @actors.each{|x| x.render(@context)}
  end
end
