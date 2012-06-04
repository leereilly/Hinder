window.Map =
  level: ""
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

    $.getJSON('../maps.json', @convertDataToMap)

    return
  
  convertDataToMap: (data) -> 

    Map.jsonMap = data
    
    if not Map.level
      Map.level = Game.getLevel('level')
    if not Map.level
      Map.level = Store.get "current level"
    if not Map.level
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

window.Score =
  moves: 0
  highscore_moves: 0
  init: ->
    @moves = 0
    @highscore_moves = 1000
    @updateScore @moves, ".level-moves-user"
    callback = (response) -> Score.updateHighscore response
    jQuery.get './../highscore.js?level=' + Map.level, {}, callback, 'json'
  
  changeStats: () ->
    @moves++
    @updateScore(@moves, ".level-moves-user")
  
  updateHighscore: (highscore_data) ->
    if highscore_data
      @highscore_moves = highscore_data.moves
      @updateScore highscore_data.moves, ".level-moves-highscore"
    else
      @updateScore "-", ".level-moves-highscore"

  submitScore: () ->
    if @highscore_moves > @moves
      alert "New highscore with #{@moves} moves."
      callback = (response) -> Game.nextLevel()
      jQuery.get './../highscore.js?level=' + Map.level + '&moves=' + @moves, {}, callback, 'json'
    else
      Game.nextLevel()

  
  updateScore: (score,element_class) ->
    jQuery(element_class).html(score)
