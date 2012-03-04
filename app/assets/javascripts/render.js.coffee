window.Render =
  canvases: {}
  init: ->
    @main_canvas = jQuery("#viewfield")[0]

    @canvases.dark = {context: jQuery("#darkness")[0].getContext("2d")} 
    @canvases.shadow_overlay = {context: jQuery("#shadow_overlay")[0].getContext("2d")} 
    @canvases.main = {context: jQuery("#viewfield")[0].getContext("2d")} 
    @canvases.shadow_map = {context: jQuery("#shadow_map")[0].getContext("2d")} 
    @canvases.wall_shadows = {context: jQuery("#wall_shadows")[0].getContext("2d")} 
    @canvases.object_shadows = {context: jQuery("#object_shadows")[0].getContext("2d")} 
    @canvases.player = {context: jQuery("#player")[0].getContext("2d")} 
    @canvases.markers = {context: jQuery("#markers")[0].getContext("2d")} 

    @clearAllCanvases()
    
    @canvases.shadow_map.context.drawImage(Resource.images.shadow_map.obj, 0, 0,@main_canvas.width,@main_canvas.height)
    @canvases.shadow_overlay.context.globalAlpha = 1
    @canvases.shadow_overlay.context.drawImage(Resource.images.shadow_overlay.obj, 0, 0,@main_canvas.width,@main_canvas.height)
    
    @walls = [Resource.images.wall_1, Resource.images.wall_2, Resource.images.wall_3]
  
  clearAllCanvases: () ->
    for canvas, context of @canvases
      context.context.clearRect(0, 0, @main_canvas.width, @main_canvas.height)
    return

  clearCanvas: (canvascontext, x, y, width, height) ->
    canvascontext.context.clearRect(x, y, width, height)
    return
  
  renderCanvas: (canvascontext, x, y, width, height, texture) ->
    canvascontext.context.drawImage(texture, x, y, width, height)
    return

  block_update: (clear_tile, draw_tile, @type) ->
    clear_x = clear_tile.x*Map.tile_size
    clear_y = clear_tile.y*Map.tile_size
    draw_x = draw_tile.x*Map.tile_size
    draw_y = draw_tile.y*Map.tile_size
    shadow_x = Map.tile_size + (Map.tile_size / 4)
    shadow_y = Map.tile_size +  (Map.tile_size / 2)

    @clearCanvas(@canvases.object_shadows, 0, 0, @main_canvas.width, @main_canvas.height)

    @clearCanvas(@canvases.main, clear_x, clear_y, Map.tile_size, Map.tile_size)

    if @type == 2
        @renderCanvas(@canvases.main, draw_x, draw_y, Map.tile_size, Map.tile_size, Resource.images.block.obj)
    if @type == 5
        @renderCanvas(@canvases.main, draw_x, draw_y, Map.tile_size, Map.tile_size, Resource.images.crate.obj)
      
    for row, y in Map.tiles     
      for block, x in row                       
        if block == 2
          @renderCanvas(@canvases.object_shadows, x*Map.tile_size, y*Map.tile_size,shadow_x,shadow_y, Resource.images.block_shadow.obj)  
        if block == 5
          @renderCanvas(@canvases.object_shadows, x*Map.tile_size, y*Map.tile_size,shadow_x,shadow_y, Resource.images.crate_shadow.obj)    
    return

  render_darkness: (x, y) ->
    @canvases.dark.context.fillstyle = "rgb(0,0,0)"
    @canvases.dark.context.fillRect(0,0,@main_canvas.width, @main_canvas.height)
    @canvases.dark.context.clearRect(x - 140, y - 140, 300, 300)
    @canvases.dark.context.drawImage(Resource.images.darkness.obj,x - 140,y - 140,300,300)
    return

  object: (obj) ->
    if obj.type == "marker"
      @renderCanvas(obj.canvas, obj.x*Map.tile_size + 1, obj.y*Map.tile_size + (Map.tile_size/5), Map.tile_size, Map.tile_size, obj.texture)

    if obj.type == "hole"
      @renderCanvas(obj.canvas, obj.x*Map.tile_size, obj.y*Map.tile_size + (Map.tile_size/5), Map.tile_size, Map.tile_size, obj.texture)    
    
    if obj.type == "block"
      @renderCanvas(obj.canvas, obj.x*Map.tile_size, (obj.y*Map.tile_size), Map.tile_size, Map.tile_size, obj.texture)
      if obj.typeid == 1
        @renderCanvas(@canvases.wall_shadows, obj.x*Map.tile_size, obj.y*Map.tile_size,Map.tile_size + (Map.tile_size / 4),Map.tile_size +  (Map.tile_size / 2), obj.shadow)
      if obj.typeid == 2
        @renderCanvas(@canvases.object_shadows, obj.x*Map.tile_size, obj.y*Map.tile_size,Map.tile_size + (Map.tile_size / 4),Map.tile_size +  (Map.tile_size / 2), obj.shadow)  
      if obj.typeid == 5
        @renderCanvas(@canvases.object_shadows, obj.x*Map.tile_size, obj.y*Map.tile_size,Map.tile_size + (Map.tile_size / 4),Map.tile_size +  (Map.tile_size / 2), obj.shadow)       
      if obj.typeid == 8
        @renderCanvas(@canvases.wall_shadows, obj.x*Map.tile_size, obj.y*Map.tile_size,Map.tile_size + (Map.tile_size / 4),Map.tile_size +  (Map.tile_size / 2), obj.shadow)

    if obj.type == "player"

      @clearCanvas(obj.canvas, obj.oldX*Map.tile_size, obj.oldY*Map.tile_size, Map.tile_size, Map.tile_size)

      if Player.dir == "right"
        @renderCanvas(obj.canvas, ((obj.x*Map.tile_size) + Player.movecount) - Map.tile_size, obj.y*Map.tile_size, Map.tile_size, Map.tile_size, obj.texture)
      if Player.dir == "left" 
        @renderCanvas(obj.canvas, ((obj.x*Map.tile_size) - Player.movecount) + Map.tile_size, obj.y*Map.tile_size, Map.tile_size, Map.tile_size, obj.texture)
      if Player.dir == "up"
        @renderCanvas(obj.canvas, obj.x*Map.tile_size, ((obj.y*Map.tile_size) + Map.tile_size) - Player.movecount, Map.tile_size, Map.tile_size, obj.texture)
      if Player.dir == "down"
        @renderCanvas(obj.canvas, obj.x*Map.tile_size, ((obj.y*Map.tile_size) - Map.tile_size) + Player.movecount, Map.tile_size, Map.tile_size, obj.texture)
      if Player.dir == "none"  

        @clearCanvas(obj.canvas, obj.x*Map.tile_size, obj.y*Map.tile_size, Map.tile_size, Map.tile_size)
        @renderCanvas(obj.canvas, obj.x*Map.tile_size, obj.y*Map.tile_size, Map.tile_size, Map.tile_size, obj.texture)

        if (Map.dark == "start" && Map.complete == false) || (Map.dark == "end" && Map.complete == true) || Map.dark == "all"
          @render_darkness(obj.x*Map.tile_size + 10, obj.y*Map.tile_size + 2)
        else
          if (Map.dark == "start" && Map.complete == true)
            Map.dark = "none"
            @clearCanvas @canvases.dark, 0, 0, @main_canvas.width, @main_canvas.height     

    if obj.type == "enemy" || obj.type == "rescue"
      @clearCanvas(obj.canvas, obj.oldX*Map.tile_size, obj.oldY*Map.tile_size, Map.tile_size, Map.tile_size)

      if obj.dir == "right"
        @renderCanvas(obj.canvas, (((obj.x*Map.tile_size) + obj.movecount) - Map.tile_size)  + 3, (obj.y*Map.tile_size) + 3, Map.tile_size - 5, Map.tile_size - 5, obj.texture)
      if obj.dir == "left" 
        @renderCanvas(obj.canvas, (((obj.x*Map.tile_size) - obj.movecount) + Map.tile_size)  + 3, (obj.y*Map.tile_size) + 3, Map.tile_size - 5, Map.tile_size - 5, obj.texture)
      if obj.dir == "up"  
        @renderCanvas(obj.canvas, (obj.x*Map.tile_size)  + 3, (((obj.y*Map.tile_size) + Map.tile_size) - obj.movecount) + 3, Map.tile_size - 5, Map.tile_size - 5, obj.texture)
      if obj.dir == "down" 
        @renderCanvas(obj.canvas, (obj.x*Map.tile_size)  + 3, (((obj.y*Map.tile_size) - Map.tile_size) + obj.movecount) + 3, Map.tile_size - 5, Map.tile_size - 5, obj.texture) 
      if obj.dir == "none"
        @clearCanvas(obj.canvas, obj.x*Map.tile_size, obj.y*Map.tile_size, Map.tile_size, Map.tile_size)
        @renderCanvas(obj.canvas, (obj.x*Map.tile_size)  + 3, (obj.y*Map.tile_size) + 3, Map.tile_size - 5, Map.tile_size - 5, obj.texture) 
    return