count = 0
window.requestAnimFrame = (->
  func =  window.requestAnimationFrame || 
          window.webkitRequestAnimationFrame || 
          window.mozRequestAnimationFrame || 
          window.oRequestAnimationFrame || 
          window.msRequestAnimationFrame     || 
          (callback,element) -> window.setTimeout(callback, 1000 / 60)
  return func
  )() 

class window.Marker
  occupied: false
  rendered: false
  constructor: (@x, @y) ->
    @texture = Resource.images.block_active.obj
  checkblock: () ->
    if Map.block_at(@x, @y).type == 2
      if @rendered == false
        Render.object {"type": "block", "typeid": 2, "canvas": Render.canvases.main, "x": @x, "y": @y, "texture": @texture}
        @rendered = true
      @occupied = true
    else      
      @occupied = false
      @rendered = false
    return
    
class Block
  movecount: 0
  constructor: (@x, @y, @type) ->
  move: (dir) ->
    return false if @obstructed(dir)
    @move_block(@x, @y, dir)    
    return true    
  obstructed: (dir) ->
    Map.next_block(@x, @y, dir).type != 0
  move_block: (x, y, dir) ->
    next_tile = Map.next_block(x, y, dir)
    Map.tiles[next_tile.y][next_tile.x] = Map.tiles[y][x]
    Map.tiles[y][x] = 0
    Render.block_update Map.block_at(@x, @y), Map.next_block(@x, @y, dir), @type
    #@animate()

class Enemy
  name: ""
  type: "enemy"
  x: 0
  y: 0
  oldX: 2
  oldY: 2
  movecount: 0
  dir: "none"
  old_direction = "none"
  movestate: 0
  distY: 0
  distX: 0
  states: []
  follows: false
  animationSteps: []

  init: ->
    @animationSteps = [
      Math.round(Map.tile_size * 0.8)
      Math.round(Map.tile_size * 0.6)
      Math.round(Map.tile_size * 0.4)
      Math.round(Map.tile_size * 0.2)
    ]
    console.log "Enemy loaded"
    @canvas = Render.canvases.main
    if @type == "enemy"
      @texture = Resource.images.enemy.obj
    if @type == "rescue"
      @texture = Resource.images.rescue.obj
    
    Render.object @
    
  constructor: (@x, @y, @moving, @type = "enemy") ->
    @oldX = @x
    @oldY = @y
    @old_direction = "right"
    @init()
  
  maketurn: (_turn) ->
    if @follows == true
      @follow()
    else
      if @moving == false
        #Map.tiles[@y][@x] = 4
      else
        @old_direction = "right" if @old_direction == "none"
        if @collision @old_direction
          @dir = @old_direction
        else
          @dir = "up" if @old_direction == "right"
          @dir = "left" if @old_direction == "up"
          @dir = "down" if @old_direction == "left"
          @dir = "right" if @old_direction == "down"
        if @collision @dir
          @move @dir
        else
          if _turn < 4
            @old_direction = @dir
            _turn++
            @maketurn _turn
      @watch() if @type == "enemy"
      Map.tiles[@y][@x] = 4
    return
  
  watch: ->
    num = @y - 1
    while num >= 0
      Map_block = Map.block_at(@x, num)
      if Map_block.type == 3
        @follows = true
        console.log "Found player"
      if Map_block.type > 0 && Map_block.type != 7
        num = -1
      num--
      
    num = @y + 1
    while num <= Map.tiles.length
      Map_block = Map.block_at(@x, num)
      if Map_block.type == 3
        @follows = true
        console.log "Found player"
      if Map_block.type > 0 && Map_block.type != 7
        num = Map.tiles.length
      num++
      
    num = @x - 1
    while num >= 0
      Map_block = Map.block_at(num, @y)
      if Map_block.type == 3
        @follows = true
        console.log "Found player"
      if Map_block.type > 0 && Map_block.type != 7
        num = -1
      num--
      
    num = @x + 1
    while num <= Map.tiles[0].length
      Map_block = Map.block_at(num, @y)
      if Map_block.type == 3
        @follows = true
        console.log "Found player"
      if Map_block.type > 0 && Map_block.type != 7
        num = Map.tiles.length
      num++
    return
    
  follow: ->       
    @distY = @y - Player.y
    @distX = @x - Player.x
    if @nextToPlayer(@distX, @distY)
      return
    

    if @distY > 0 && @distX > 0
      if @distY > @distX
        @states = ["up", "left"]
      if @distX > @distY
        @states = ["left", "up"]
    else
      if @distY > 0
        @states = ["up", "right"]
      if @distX > 0
        @states = ["left", "down"]        
    if @distY < 0 && @distX < 0
        if @distY < @distX
            @states = ["down", "right"] 
        if @distX < @distY
            @states = ["right", "down"] 
    else
      if @distY < 0
        @states = ["down", "left"] 
      if @distX < 0
        @states = ["right", "up"]
    @move(@states[0])    
    return
  
  nextToPlayer: (_distX, _distY) ->
    if (_distY == 0 && _distX < 2 && _distX > -2) || (_distX == 0 && _distY < 2 && _distY > -2)
      Player.locked = false
      Map.init()
      return true
    return false
    
    
  move: (dir) ->
    @dir = dir

    if @collision @dir
      @movecount = 0
      @oldX = @x
      @oldY = @y
      
      @x += 1 if @dir == "right"
      @x -= 1 if @dir == "left"     
      @y += 1 if @dir == "down"      
      @y -= 1 if @dir == "up"
      
      if @nextToPlayer(@x - Player.x, @y - Player.y)
        return
      
      @animate()

      Map.tiles[@oldY][@oldX] = 0
      Map.tiles[@y][@x] = 4

        #location.reload true
    else
      if @collision @states[1]
        @move(@states[1])   
    return

  animate: (step = @animationSteps.length) ->
    if step >= 1     
      @movecount = @animationSteps[step] 
      requestAnimFrame(=> @animate(step))      
    else
      @old_direction = @dir
      @dir = "none"
      @movecount = 0
    step--
    Render.object @ 

    return
  collision: (dir) ->
    if @x > 13 || @y < 1
      Map.tiles[@y][@x] = 0
      Render.clearCanvas(@canvas, @x*Map.tile_size, @y*Map.tile_size, Map.tile_size, Map.tile_size)
      @type = "none"
      @x = 1
      @y = 1
    
    map_block = Map.next_block(@x, @y, dir)
 
    return true if map_block.type == 0

    return false if (map_block.type != 2 && map_block.type != 5)
    block = new Block(map_block.x, map_block.y, map_block.type)
    return block.move dir
    #map_block = Map.next_block(@x, @y, dir)
    #return false if map_block.type == 1
    #return true if map_block.type == 0       
        
window.Player =
  name: "Player_1"
  type: "player"
  x: 0
  y: 0
  oldX: 0
  oldY: 0
  movecount: 0
  dir: "none"
  events: ""
  locked: false
  contact: false
  animationSteps: []

  init: (@x, @y) ->
    @animationSteps = [
      Math.round(Map.tile_size * 0.9)
      Math.round(Map.tile_size * 0.8)
      Math.round(Map.tile_size * 0.6)
      Math.round(Map.tile_size * 0.4)
      Math.round(Map.tile_size * 0.2)
      #Math.round(Map.tile_size * 0.1)
    ]
    console.log @animationSteps
    @oldX = @x
    @oldY = @y
    @canvas = Render.canvases.player
    @texture = Resource.images.player.obj    
    Render.object @
  unlock: () ->
    @locked = false

  move: (dir) ->
    return false if @contact == true
    @dir = dir
    if (@y == 0 && @dir == "up" && Map.exit.up != "")
      Map.level = Map.exit.up
      Game.nextLevel()
      return
    if (@y == 14 && @dir == "down" && Map.exit.down != "")
      Map.level = Map.exit.down
      Game.nextLevel()
      return
    if (@x == 0 && @dir == "left" && Map.exit.left != "")
      Map.level = Map.exit.left
      Game.nextLevel()
      return
    if (@x == 14 && @dir == "right" && Map.exit.right != "")
      Score.submitScore()
      @locked = false
      return

    if @collision @dir
      @oldX = @x
      @oldY = @y
      if @dir == "right"
        @x += 1
      if dir == "left"
        @x -= 1
      if @dir == "down"
        @y += 1
      if @dir == "up"
        @y -= 1
      @movecount = 0
      @animate()
      Map.tiles[@oldY][@oldX] = 0
      Map.tiles[@y][@x] = 3
    else
      @locked = false   
    return
    
  animate: (step = @animationSteps.length) ->
    if step >= 1     
      @movecount = @animationSteps[step] 
      requestAnimFrame(=> @animate(step))      
    else
      @dir = "none"
      @movecount = 0
      Game.cycle() 
    Render.object @ 
    step--
    return
    
  collision: (dir) ->
    map_block = Map.next_block(@x, @y, dir)  
    return true if map_block.type == 0
    return false if (map_block.type != 2 && map_block.type != 5)
    block = new Block(map_block.x, map_block.y, map_block.type)
    return block.move dir
 
jQuery ->
  setTimeout ( =>
		window.scrollTo(0, 1)
  ), 0
	
  Game.init()  
  return