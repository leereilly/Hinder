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
    Game.run_marker_check = true
  move: (dir, trigger_object) ->
    return false if @obstructed(dir)
    @move_block(@x, @y, dir) 

    trigger_object.fast_animate = true
    return true    
  obstructed: (dir) ->
    Map.next_block(@x, @y, dir).type != 0
  move_block: (x, y, dir) ->
    next_tile = Map.next_block(x, y, dir)
    Map.tiles[next_tile.y][next_tile.x] = Map.tiles[y][x]
    Map.tiles[y][x] = 0
    Render.block_update Map.block_at(@x, @y), Map.next_block(@x, @y, dir), @type
    #@animate()

class @Enemy
  name: ""
  type: "enemy"
  x: 0
  y: 0
  oldX: 2
  oldY: 2
  movecount: 0
  dir: "none"
  fast_animate: false
  old_direction: "none"
  movestate: 0
  distY: 0
  distX: 0
  states: []
  follows: false
  animationSteps: []

  init: ->
    @animationSteps = [
      Math.round(Map.tile_size * 0.9)
      Math.round(Map.tile_size * 0.8)
      Math.round(Map.tile_size * 0.6)
      Math.round(Map.tile_size * 0.4)
      Math.round(Map.tile_size * 0.2)

    ]
    @canvas = Render.canvases.enemies
    if @type == "enemy"
      if @moving == false
        @texture = Resource.images.enemy_passive.obj
      else
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
        @texture = Resource.images.enemy_active.obj
      if Map_block.type > 0 && Map_block.type != 7
        num = -1
      num--
      
    num = @y + 1
    while num <= Map.tiles.length
      Map_block = Map.block_at(@x, num)
      if Map_block.type == 3
        @follows = true
        @texture = Resource.images.enemy_active.obj
      if Map_block.type > 0 && Map_block.type != 7
        num = Map.tiles.length
      num++
      
    num = @x - 1
    while num >= 0
      Map_block = Map.block_at(num, @y)
      if Map_block.type == 3
        @follows = true
        @texture = Resource.images.enemy_active.obj
      if Map_block.type > 0 && Map_block.type != 7
        num = -1
      num--
      
    num = @x + 1
    while num <= Map.tiles[0].length
      Map_block = Map.block_at(num, @y)
      if Map_block.type == 3
        @follows = true
        @texture = Resource.images.enemy_active.obj
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
    @fast_animate = false
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
    step-- if @fast_animate == true
    step--

    @movecount = 0 unless @movecount
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
    return block.move dir, @      
        
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
  fast_animate: false
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
    @oldX = @x
    @oldY = @y
    @canvas = Render.canvases.player
    @texture = Resource.images.player.obj 
    @texture_high = Resource.images.player.obj
    @texture_low = Resource.images.player_low.obj
    Render.object @
  unlock: () ->
    @locked = false

  move: (dir) ->
    Player.locked = true
    @fast_animate = false
    jQuery(".notice").fadeOut("fast")
    return false if @contact == true
    @dir = dir
    if (@y == 0 && @dir == "up" && Map.exit.up != "")
      Render.clearCanvas(@canvas, @x*Map.tile_size, @y*Map.tile_size, Map.tile_size, Map.tile_size)
      Game.nextLevel()
      return
    if (@y == 14 && @dir == "down" && Map.exit.down != "")
      Render.clearCanvas(@canvas, @x*Map.tile_size, @y*Map.tile_size, Map.tile_size, Map.tile_size)
      Game.nextLevel()
      return
    if (@x == 0 && @dir == "left" && Map.exit.left != "")
      Render.clearCanvas(@canvas, @x*Map.tile_size, @y*Map.tile_size, Map.tile_size, Map.tile_size)
      Game.nextLevel()
      return
    if (@x == 14 && @dir == "right" && Map.exit.right != "")
      Render.clearCanvas(@canvas, @x*Map.tile_size, @y*Map.tile_size, Map.tile_size, Map.tile_size)
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
    
  animate: (step = @animationSteps.length) ->
    if step >= 1 
      @texture = @texture_low
      @movecount = @animationSteps[step] 
      requestAnimFrame(=> @animate(step))      
    else
      @texture = @texture_high
      @dir = "none"
      @movecount = 0
      Game.cycle()
       
    @movecount = 0 unless @movecount
    Render.object @
    step-- if @fast_animate == true
    step--
    return
    
  collision: (dir) ->
    map_block = Map.next_block(@x, @y, dir)  
    return true if map_block.type == 0
    return false if (map_block.type != 2 && map_block.type != 5)
    block = new Block(map_block.x, map_block.y, map_block.type)
    #console.log block.move dir
    return block.move dir, @

@Map =
  level_id: ""
  level: ""
  password: ""
  tile_size: 20
  tiles: []
  markers: []
  enemies: []
  holes: []
  complete: false
  dark: ""
  overlay: ""
  floor: ""
  exit: ""
  jsonMap: ""

  init: () ->
    @tile_size = Math.round(jQuery("#viewfield")[0].width / 15)

    @enemies = []
    @markers = []

    $.getJSON('../test.json', @convertDataToMap)

    return
  
  convertDataToMap: (data) -> 

    Map.jsonMap = data
    
    if not Map.level
      Map.level = Game.getLevel('level')
    if not Map.level
      Map.level = Game.getLevel('pwd')
    if not Map.level
      Map.level = Store.get "level"
    if not Map.level
      Game.loadNew(data.map[0])
    else 
      for level in data.map 
        if level.id ==  Map.level || level.password ==  Map.level
          Game.loadNew(level)  
    return
  
  block_at: (x, y) ->
    if y > 14
      y = 14
    {type: @tiles[y][x], x: x, y: y}
    
  next_block: (x, y, dir) ->
    switch dir
      when "up" then @block_at(x,y-1)
      when "down" then @block_at(x,y+1)
      when "right" then @block_at(x+1,y)
      when "left" then @block_at(x-1,y)

@Score =
  moves: 0
  highscore_moves: 0
  init: ->
    @moves = 0
    @highscore_moves = 2000
    @updateScore @moves, ".level-moves-user"
    callback = (response) -> Score.updateHighscore response
    jQuery.get './../highscore.js?level=' + Map.level_id, {}, callback, 'json'
  
  changeStats: () ->
    @moves++
    @updateScore(@moves, ".level-moves-user")
  
  updateHighscore: (highscore_data) ->
    if highscore_data
      @highscore_moves = highscore_data.moves
      @updateScore highscore_data.moves, ".level-moves-highscore"
    else
      @updateScore "-", ".level-moves-highscore"

  submitScore: (level) ->
    if @highscore_moves > @moves
      jQuery.get './../highscore.js?level=' + level + '&moves=' + @moves, {}, 'json'
  
  updateScore: (score,element_class) ->
    jQuery(element_class).html(score)



@Game =
  step: 0
  levels: []
  run_marker_check: false
  init: ->
    #@level = Store.get "levels"
    Map.init()
		
  nextLevel: ->
    Player.locked = true
    jQuery(".notice").html("")
    #Score.submitScore(Map.level_id) 
    Map.level = Map.exit.right if Player.dir == "right"
    Map.level = Map.exit.left if Player.dir == "left"
    Map.level = Map.exit.up if Player.dir == "up"
    Map.level = Map.exit.down if Player.dir == "down"
    Player.movecount = 0
    Player.dir = "none"
    Map.enemies = []
    Map.markers = []
    Map.complete = false
    Map.dark = ""
    for level in Map.jsonMap.map
      if level.id ==  Map.level  
        Game.loadNew(level)
    #Map.init()
    return
  loadNew: (mapdata) ->
    jQuery(".ajax-loader").show()
    #@levels.push(mapdata)
    #window.history.pushState 'page2', 'Title', '/home/index?level=' + Map.level
    Map.level_id =  mapdata.id
    window.history.pushState 'page2', 'Title', '?pwd=' + mapdata.password
    #window.history.pushState 'page2', 'Title', '/home/index?pwd=' + mapdata.password
    Player.contact = false

    Store.set "level", mapdata.id
    Map.overlay = if mapdata.overlay then mapdata.overlay else "shadow_overlay.png"
    Map.floor = if mapdata.floor then mapdata.floor else "shadow_map.png"

    Resource.preload =>
      Render.init()

      #Score.init()

      Player.locked = false
      jQuery(".ajax-loader").hide()
      @step = 0

      if mapdata.bubble
        Game.speech = mapdata.bubble
      else
        Game.speech = null
        jQuery(".bubble").hide()

      if mapdata.note
        Game.show_notice(mapdata.note)
      else
        jQuery(".notice").hide()
        
      Map.tiles = mapdata.tile
      Map.dark = mapdata.dark
      Map.exit = mapdata.exit
      for row, y in Map.tiles
        for block, x in row
          
          if block == 1
            Render.object {"type": "block", "typeid": block, "canvas": Render.canvases.main, "x": x, "y": y, "texture": Render.walls[Math.floor(Math.random() * Render.walls.length)].obj, "shadow": Resource.images.wall_shadow.obj}
          else
            Render.clearCanvas(Render.canvases.shadow_overlay, (x*Map.tile_size), (y*Map.tile_size), Map.tile_size, Map.tile_size)

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
          if block == 10
            Map.enemies[Map.enemies.length] = new Enemy(x,y,true, "rescue")
            Map.tiles[y][x] = 0
          if block == 9
            Map.markers[Map.markers.length] = new Marker(x,y)
            Map.tiles[y][x] = 0
          if block == 3
            Map.tiles[y][x] = 0
            Player.init(x,y)
    
    if Player.events == ""
      if $("body").touchwipe
        $("body").touchwipe {
          wipeLeft: ->
            Player.move "left" if Player.locked == false
            return
          wipeRight: ->
            Player.move "right" if Player.locked == false
            return
          wipeDown: ->
            Player.move "up" if Player.locked == false
            return
          wipeUp: ->
            Player.move "down" if Player.locked == false
            return
        }

      $(document).keydown (e) ->
        if Player.locked == false
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
      @check_markers() if @run_marker_check == true
      @move_enemy(i) if --i
    ), 20
    
  cycle: ->
    #Score.changeStats()
    Player.locked = true

    @move_enemy(Map.enemies.length) if Map.enemies.length > 0
    
    @check_markers() if @run_marker_check == true

    @step++

    if Game.speech && @step == Game.speech.step
      jQuery(".bubble").html("")
      Game.show_bubble(Game.speech)

    setTimeout ( ->
      Player.unlock()
    ), 70
    return

  check_markers: ->
    placed_blocks = 0
    for marker in Map.markers
      marker.checkblock()
      if marker.occupied == true
        placed_blocks++

    if placed_blocks == Map.markers.length
      Map.complete = true
      for hole in Map.holes
        Map.tiles[hole.y][hole.x] = 7
        Render.object hole
      Map.holes = []

      for row, y in Map.tiles
        for block, x in row  
          if block == 8
            Map.tiles[y][x] = 0
            Render.clearCanvas(Render.canvases.main, x*Map.tile_size, y*Map.tile_size, Map.tile_size, Map.tile_size)
            Render.block_update({x: x, y: y},{x: x, y: y}, 8)
    else
      Map.complete = false 
    @run_marker_check = false
    
  pause: ->
    return

  show_bubble: (notice) ->
    jQuery(".bubble").css 'left', notice.x * Map.tile_size
    jQuery(".bubble").css 'top', notice.y * Map.tile_size
    jQuery(".bubble").html(jQuery(".bubble").html() + notice.text)
    jQuery(".bubble").fadeIn("fast")
    setTimeout ( ->
      jQuery(".bubble").fadeOut("slow")
    ), 1500
    return

  show_notice: (notice) ->
    jQuery(".notice").css 'left', notice.x * Map.tile_size
    jQuery(".notice").css 'top', notice.y * Map.tile_size
    jQuery(".notice").html(jQuery(".notice").html() + notice.text)
    jQuery(".notice").fadeIn("fast")
    return


jQuery ->
  Game.init()  
  return