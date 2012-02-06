window.Resource =
  images: {
            wall_1: {path: "/assets/textures/wall_1.png"}, 
            wall_2: {path: "/assets/textures/wall_2.png"}, 
            wall_3: {path: "/assets/textures/wall_3.png"},
            door: {path: "/assets/textures/door.png"},
            player: {path: "/assets/textures/player.png"},
            enemy: {path: "/assets/textures/monster.png"},
            rescue: {path: "/assets/textures/rescue.png"},  
            block: {path: "/assets/textures/box.png"},
            block_active: {path: "/assets/textures/box_active.png"},
            crate: {path: "/assets/textures/crate.png"},
            wall_shadow: {path: "/assets/textures/wall_shadow.png"},
            door_shadow: {path: "/assets/textures/door_shadow.png"},
            block_shadow: {path: "/assets/textures/box_shadow.png"},
            block_shadow_active: {path: "/assets/textures/box_shadow_active.png"},
            crate_shadow: {path: "/assets/textures/crate_shadow.png"},
            shadow_map: {path: "/assets/textures/shadow_map.png"},
            marker: {path: "/assets/textures/marker.png"},
            crack: {path: "/assets/textures/crack_tile_2.png"},
            hole: {path: "/assets/textures/hole_tile.png"},
            darkness: {path: "/assets/textures/darkness.png"},
            shadow_overlay: {path: "/assets/textures/shadow_overlay.png"}
          }
  preload: (@callback) ->
    @images.shadow_map = {path: "/assets/textures/#{Map.floor}"} if Map.floor
    @images.shadow_overlay = {path: "/assets/textures/#{Map.overlay}"} if Map.overlay
    @unloaded = 0
    for own name, image of @images
      @unloaded++
      obj = $("<img src=\"#{image.path}\">")
      @images[name].obj = obj.get(0)
      obj.load => @loaded()
  loaded: ->
    @unloaded--
    if @unloaded == 0
      @callback()