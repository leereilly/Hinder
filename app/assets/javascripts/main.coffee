count = 1
window.requestAnimFrame = (->
  func =  window.requestAnimationFrame || 
          window.webkitRequestAnimationFrame || 
          window.mozRequestAnimationFrame || 
          window.oRequestAnimationFrame || 
          window.msRequestAnimationFrame     || 
          (callback,element) -> window.setTimeout(callback, 1000 / 60)
  return func
  )() 

class Marker
  occupied: false
  rendered: false
  constructor: (@x, @y) ->
    @texture = Resource.images.block_active.obj
  checkblock: () ->
    if Map.block_at(@x, @y).type == 2
      if @rendered == false
        console.log "Test"
        Render.object {"type": "block", "typeid": 2, "canvas": Render.canvases.main, "x": @x, "y": @y, "texture": @texture, "shadow": Resource.images.block_shadow_active.obj}
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
    Render.block_update Map.block_at(@x, @y), Map.next_block(@x, @y, dir), 0, @type
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

  init: ->
    console.log "Enemy loaded"
    @canvas = Render.canvases.main
    @texture = Resource.images.enemy.obj
    Render.object @
    
  constructor: (@x, @y, @moving) ->
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
          #console.log "Change dir"
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
      @watch()
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
    if @distY > 0 && @distX > 0
      if @distY > @distX
        @states[0] = "up"
        @states[1] = "left"
      if @distX > @distY
        @states[0] = "left"
        @states[1] = "up"
    else
      if @distY > 0
        @states[0] = "up"
        @states[1] = "right"
      if @distX > 0
        @states[0] = "left"
        @states[1] = "down"        
    if @distY < 0 && @distX < 0
        if @distY < @distX
            @states[0] = "down"
            @states[1] = "right"
        if @distX < @distY
            @states[0] = "right"
            @states[1] = "down"
    else
      if @distY < 0
        @states[0] = "down"
        @states[1] = "left"
      if @distX < 0
        @states[0] = "right"
        @states[1] = "up"

    @move(@states[0])    
    return
    
  move: (dir) ->
    @dir = dir
    #console.log "Enemy X:#{@distX} Y:#{@distY} state1:#{@states[0]} state2:#{@states[1]} movestate#{@movestate}"
    if @collision @dir
      @movecount = 0
      @oldX = @x
      @oldY = @y
      
      @x += 1 if @dir == "right"
      @x -= 1 if dir == "left"     
      @y += 1 if @dir == "down"      
      @y -= 1 if @dir == "up"
      
      @animate()
      Map.tiles[@oldY][@oldX] = 0
      #@old_direction = @dir
      #@dir = "none"
      #Render.object @ 
      Map.tiles[@y][@x] = 4
    else
      if @collision @states[1]
        @move(@states[1])   
    return
    
  animate: ->
    if @movecount < Map.tile_size - 10
      @movecount += 5
      #@movecount = ~~ (@movecount+0.5); 
      requestAnimFrame(=> @animate())      
    else
      @old_direction = @dir
      @dir = "none"
      @movecount = 0
    Render.object @ 
    return
  collision: (dir) ->
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

  init: (@x, @y) ->
    @oldX = @x
    @oldY = @y
    @canvas = Render.canvases.player
    @texture = Resource.images.player.obj
    console.log "Rendering player"    
    Render.object @
  unlock: () ->
    @locked = false

  move: (dir) ->
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
      Map.level = Map.exit.right
      Game.nextLevel()
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
    
  animate: ->
    if @movecount < Map.tile_size      
      @movecount += 3 + (@movecount /3)
      @movecount = ~~ (@movecount+0.5);      
      requestAnimFrame(=> @animate())      
    else
      @dir = "none"
      @movecount = 0
      Game.cycle() 
    Render.object @ 
    return
    
  collision: (dir) ->
    map_block = Map.next_block(@x, @y, dir)  
    return true if map_block.type == 0
    return false if (map_block.type != 2 && map_block.type != 5)
    block = new Block(map_block.x, map_block.y, map_block.type)
    return block.move dir

window.Map =
  level: ""
  tile_size: 40
  tiles: []
  markers: []
  enemies: []
  holes: []
  complete: false
  dark: ""
  exit: ""

  init: () ->
    
    @enemies = []
    @markers = []

    $.getJSON('../test.json', @convertDataToMap)
    return
  
  convertDataToMap: (data) -> 
    
    if Map.level == ""
      Map.level = Game.getLevel('level')
    if Map.level == ""
      Map.level = Store.get "current level"
    if Map.level == ""
      Game.loadNew(data.map[0])
    else 
      for level in data.map 
        if level.id ==  Map.level
          
          Game.loadNew(level)   
    return
  
  block_at: (x, y) ->
    {type: @tiles[y][x], x: x, y: y}
    
  next_block: (x, y, dir) ->
    switch dir
      when "up" then @block_at(x,y-1)
      when "down" then @block_at(x,y+1)
      when "right" then @block_at(x+1,y)
      when "left" then @block_at(x-1,y)

Game =
  step: 0
  levels: []
  init: ->
    @level = Store.get "levels"
    Map.init()
  nextLevel: ->
    console.log "Next level"
    Player.movecount = 0
    Player.dir = "none"
    Map.init()
    return
  loadNew: (mapdata) ->
    console.log mapdata
    @levels.push(mapdata)
    Store.set "current level", mapdata.id
    Store.set "levels", @levels

    console.log Store.get "levels"

    Resource.preload =>
      Render.init()
      Map.tiles = mapdata.tile
      Map.dark = mapdata.dark
      Map.exit = mapdata.exit
      for row, y in Map.tiles
        for block, x in row
          if block == 1
            Render.object {"type": "block", "typeid": block, "canvas": Render.canvases.main, "x": x, "y": y, "texture": Render.walls[Math.floor(Math.random() * Render.walls.length)].obj, "shadow": Resource.images.wall_shadow.obj}
          if block == 2
            Render.object {"type": "block", "typeid": block, "canvas": Render.canvases.main, "x": x, "y": y, "texture": Resource.images.block.obj, "shadow": Resource.images.block_shadow.obj}
          if block == 5
            Render.object {"type": "block", "typeid": block, "canvas": Render.canvases.main, "x": x, "y": y, "texture": Resource.images.crate.obj, "shadow": Resource.images.crate_shadow.obj}
          if block == 8
            Render.object {"type": "block", "typeid": block, "canvas": Render.canvases.main, "x": x, "y": y, "texture": Resource.images.door.obj, "shadow": Resource.images.door_shadow.obj}
          if block == 9
            Render.object {"type": "marker", "typeid": block, "canvas": Render.canvases.markers, "x": x, "y": y, "texture": Resource.images.marker.obj}
          if block == 7
            Render.object {"type": "hole", "typeid": block, "canvas": Render.canvases.markers, "x": x, "y": y, "texture": Resource.images.crack.obj}
            Map.holes.push({"x": x, "y": y, "canvas": Render.canvases.markers, "type": "hole", "typeid": block, "texture": Resource.images.hole.obj})
            Map.tiles[y][x] = 0

          if block == 4
            Map.enemies[Map.enemies.length] = new Enemy(x,y,false)
            Map.tiles[y][x] = 0
          if block == 6
            Map.enemies[Map.enemies.length] = new Enemy(x,y,true)
            Map.tiles[y][x] = 0
          if block == 9
            Map.markers[Map.markers.length] = new Marker(x,y)
            Map.tiles[y][x] = 0
          if block == 3
            Map.tiles[y][x] = 0
            Player.init(x,y)
    
    if Player.events == ""
      $("#container").touchwipe {
        wipeLeft: ->
          Player.move "left"
          return
        wipeRight: ->
          Player.move "right"
          return
        wipeDown: ->
          Player.move "up"
          return
        wipeUp: ->
          Player.move "down"
          return
      }

      $(document).keydown (e) ->
        if Player.locked == false
          Player.locked = true
          Player.move "right" if e.keyCode == 39  
          Player.move "left" if e.keyCode == 37 
          Player.move "down" if e.keyCode == 40           
          Player.move "up" if e.keyCode == 38
        return

      Player.events = "loaded"

    return
  
  getLevel: (name) ->
    name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]")
    regexS = "[\\?&]#{name}=([^&#]*)"
    regex = new RegExp( regexS )
    results = regex.exec( window.location.href )
    if results == null
      return ""
    else
      return results[1]

  move_enemy: (i) ->
    setTimeout ( =>
      Map.enemies[i - 1].maketurn 0
      @move_enemy(i) if --i
    ), 50
    
  cycle: ->
    Player.locked = true
    placed_blocks = 0
    console.log Map.enemies.length

    @move_enemy(Map.enemies.length)
    #for enemy in Map.enemies
      #enemy.maketurn 0
      
    for marker in Map.markers
      marker.checkblock()
      if marker.occupied == true
        placed_blocks++
    #console.log "Placed blocks: #{placed_blocks} / #{Map.markers.length}"
    if placed_blocks == Map.markers.length
      Map.complete = true
      #console.log "Done"
      for hole in Map.holes
        Map.tiles[hole.y][hole.x] = 7
        Render.object hole
      Map.holes = []

      for row, y in Map.tiles
        for block, x in row  
          if block == 8
            Map.tiles[y][x] = 0
            Render.clearCanvas(Render.canvases.main, x*Map.tile_size, y*Map.tile_size, Map.tile_size, Map.tile_size)
            #Render.clear_tile(x,y) 
    else
      Map.complete = false     
    @step++
    setTimeout ( ->
      Player.unlock()
    ), 50

    return
    
  pause: ->
    console.log "stopped "
    return
 
jQuery ->
  Game.init()  
  return