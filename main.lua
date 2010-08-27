-- Totally experimenting with Love (v0.6.2)
-- This departs from love's bottom-up means (love.draw, love.update) and takes
-- a top-down approach, by forcing you to call friend.update each frame.

require "class"

----------

Friend = Class:subclass()
Friend.rate = 1.0 / 30.0
Friend.shutdown = false

function Friend:init()
  self.keys = {}
  self.xScale = math.floor(love.graphics.getWidth() / 320)
  self.yScale = math.floor(love.graphics.getHeight() / 240)
  self.frames = 0
  self.clock = 0
  love.timer.step()
  love.graphics.setColorMode("replace")
  love.graphics.setBlendMode("alpha")
end

function Friend:update()
  self:draw()
  self:delay()
  self:poll()
end

function Friend:delay()
  local now = love.timer.getDelta()
  local frameAdjust = math.min( self.clock, (self.rate * 2 / 3) )
  self.clock = 0
  while now < (self.rate - frameAdjust) do
    love.timer.step()
    love.timer.sleep( 1 )
    now = now + love.timer.getDelta()
  end
  self.clock = self.clock + ( now - self.rate )
  love.timer.step()
end

function Friend:handleKeypress( key )
  if key == "p" then
    print("change mod")
    self:playMod("fdwc-010.s3m")
  elseif key == "f10" then
    self.shutdown = true
  end
end

function Friend:poll()
  -- The documentation wiki is light on information about what a, b, and c are.
  local e, a, b, c
  for e, a, b, c in love.event.poll() do
    print( "--EVENT--" )
    print( "e", type(e), e )
    print( "a", type(a), a )
    print( "b", type(b), b )
    print( "c", type(c), c )
    if e == "q" then
      self.shutdown = true
    elseif e == "kp" then
      self:handleKeypress(a)
    end
  end
end

function Friend:draw()
  self.frames = self.frames + 1
  self:drawBackground()
  love.graphics.circle( "fill", self.sprite.x, self.sprite.y, 5 )
  love.graphics.present()
  love.graphics.clear()
end

function Friend:drawBackground()
  love.graphics.draw( self.batch, 0, 0 )
end

function Friend:loadTileset( filename )
  print( "loading tileset: "..filename )
  self.tileset = love.graphics.newImage( filename )
  self.tileset:setFilter("nearest", "nearest")
  self.batch = love.graphics.newSpriteBatch( self.tileset, 256 )
  local sw = self.tileset:getWidth()
  local sh = self.tileset:getHeight()
  local i
  for i = 0, 255 do
    local x = ( i % 16 ) * 16
    local y = math.floor( i / 16 ) * 16
    local quad = love.graphics.newQuad( x, y, 16, 16, sw, sh )
    self.batch:addq( quad, x, y )
  end
end

function Friend:addSprite( spr )
  self.sprite = spr
end

function Friend:playMod( mod )
  self:stopMod()
  self.bgm = love.audio.newSource(mod, "stream")
  self.bgm:setLooping( true )
  self.bgm:setVolume(0.2)
  love.audio.play(self.bgm)
end

function Friend:stopMod()
  if not self.bgm then return end
  love.audio.stop(self.bgm)
  self.bgm = nil
end

----------

local function bounded( a, b, c )
  return math.max( a, math.min( b, c ) )
end

local function random( l, r )
  local d = math.random( 0, 10000 ) / 10000 
  return l + (d * (r - l))
end

----------

Bouncy = Class:subclass()

function Bouncy:init( x, y )
  self.x = x or 160
  self.y = y or 120
  self.xMin = 0
  self.xMax = 320
  self.yMin = 0
  self.yMax = 240
  self.velocity = 4.0
  self.direction = 5.5
  self:randomize( false, false )
end

function Bouncy:randomize( horiz, vert )
  local pi = math.pi
  if horiz or vert then
    local y = math.sin( self.direction )
    local x = math.cos( self.direction )
    if horiz then x = x * -1 end
    if vert then y = y * -1 end
    if x < 0 then
      self.direction = -1 * math.asin( y ) + pi
    else
      self.direction = math.asin( y )
    end
  end
  self.velocity = bounded( 1.0, self.velocity + random( -2.0, 2.0 ), 10.0 )
  self.direction = self.direction + random( -0.4, 0.4 )
  while self.direction <= 0 do self.direction = self.direction + 2*pi end
  while self.direction > 2*pi do self.direction = self.direction - 2*pi end
end

function Bouncy:update()
  local newx = self.x + self.velocity * math.cos( self.direction )
  local newy = self.y + self.velocity * math.sin( self.direction )
  local horiz = false
  local vert = false
  if ( newx < self.xMin ) or ( newx > self.xMax ) then
    horiz = true
    newx = bounded( self.xMin, newx, self.xMax )
  end
  if ( newy < self.yMin ) or ( newy > self.yMax ) then
    vert = true
    newy = bounded( self.yMin, newy, self.yMax )
  end
  if horiz or vert then
    self:randomize( horiz, vert )
  end
  self.x = newx
  self.y = newy
end

----------

Tester = Friend:subclass()

function Tester:init()
  Friend.init(self)
  self:loadTileset("wayward-flat.png")
end

function Tester:run()
  -- self:playMod("fdwc-010.s3m")
  bouncy = Bouncy:new()
  self:addSprite( bouncy )
  while not self.shutdown do
    bouncy:update()
    self:update()
  end
  self:stopMod()
end

function love.run()
  math.randomseed( os.time() )
  local tester = Tester:new()
  local startTime = love.timer.getMicroTime( )
  tester:run()
  local endTime = love.timer.getMicroTime( )
  print( "Frames: "..tester.frames )
  print( "Time: "..(endTime-startTime) )
  print( "Rate: "..(tester.frames / (endTime-startTime) ) )
end

