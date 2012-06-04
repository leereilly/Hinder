window.Game =
  step: 0
  levels: []
  init: ->
    @level = Store.get "levels"
    Map.init()
  nextLevel: ->
    console.log "Next level"
    Map.level = Map.exit.right
    Player.movecount = 0
    Player.dir = "none"
    Player.locked = false
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
    #@levels.push(mapdata)

    window.history.pushState 'page2', 'Title', '/home/index?level=' + Map.level
    Player.contact = false

    Store.set "current level", mapdata.id
    #Store.set "levels", @levels

    Map.overlay = if mapdata.overlay then mapdata.overlay else "shadow_overlay.png"
    Map.floor = if mapdata.floor then mapdata.floor else "shadow_map.png"

    Resource.preload =>
      Render.init()

      Score.init()

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
      $("#mainWrapper").touchwipe {
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
    ), 20
    
  cycle: ->
    Score.changeStats()
    Player.locked = true
    placed_blocks = 0

    @move_enemy(Map.enemies.length) if Map.enemies.length > 0
      
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
    @step++
    setTimeout ( ->
      Player.unlock()
    ), 20
    return
    
  pause: ->
    console.log "stopped "
    return
