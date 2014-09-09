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
    def self.hit_sound; @sound ||= Sound["sounds/get.wav"]; end

    def hit?(player)
      xdiff = (@x+38) - (player.x+16)
      ydiff = (@y+48) - (player.y+16)
      distance = Math.sqrt(xdiff**2 + ydiff**2)

      distance < (40+16)
    end
  end

  class Bomb < Item
    def self.image; @image ||= Image["images/bomb.png"]; end
    def self.hit_sound; @sound ||= Sound["sounds/bom08.wav"]; end

    def hit?(player)
      xdiff = (@x+36) - (player.x+16)
      ydiff = (@y+54) - (player.y+16)
      distance = Math.sqrt(xdiff**2 + ydiff**2)

      distance < (34+8)
    end
  end

  # Game main -----------------------------------------------

  def setup
    @context = Context.new(display, keyboard)
    display.size = V[640, 480]
    @high_score = 0
    @play_sound = false

    reset_game
  end

  def reset_game
    @player = Player.new(@context)
    @actors = [@player]
    @score = 0
    @state = :playing
  end

  def update(elapsed)
    # Create new items if needed
    while @actors.length < 6
      @actors.push([Apple, Bomb].sample.new(@context))
    end

    # System keys
    if keyboard.pressed?(:enter)
      reset_game
    end
    if keyboard.pressed?(:s)
      @play_sound = !@play_sound
    end

    # Call #act
    @actors.each do |x|
      x.act(@context)

      if x.is_a?(Item) && @state == :playing
        if x.hit?(@player)
          x.alive = false
          x.class.hit_sound.play if @play_sound
          case x
          when Apple
            @score += 1
          when Bomb
            @state = :gameover
            @player.alive = false
            @high_score = [@high_score, @score].max
          end
        end
      end
    end
    @actors.delete_if{|x| not x.alive}

    # Render background
    display.clear
    display.fill_color = C[128, 255, 255]
    display.fill_rectangle(V[0, 0], display.size)
    display.fill_color = C[0, 128, 0]
    display.fill_rectangle(V[0, 400], V[640,180])

    # Render characters
    @actors.each{|x| x.render(@context)}

    # Render texts
    display.fill_color = C[0, 0, 0]
    display.text_size = 24
    display.fill_text("SCORE: #{@score}  HIGHSCORE: #{@high_score}",
                      V[0, 30])
    if @state == :gameover
      display.fill_text("GAME OVER (PRESS ENTER)", V[0, 120])
    end
    display.text_size = 12
    display.fill_color = C[255, 255, 255]
    display.fill_text("[S] sound(#{@play_sound})", V[0, 480])
  end
end
