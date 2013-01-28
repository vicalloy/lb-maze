getRandomInt = (min, max) ->
  Math.floor(Math.random() * (max - min + 1)) + min


fmtTime = (t) ->
  d = new Date(null);
  d.setSeconds(t/1000);
  return d.toTimeString().substr 3, 5


addPX = (px, step) ->
  px = px.substring 0, px.length - 2
  parseInt(px) + step + 'px'


move = (obj, direction, step) ->
  if !step?
    step = 10
  attr = 'left'
  attr = 'top' if direction in [0, 2]
  step = -step if direction in [0, 3]
  d = addPX obj.css(attr), step
  obj.css attr, d


getNextBlockPos = (x, y, direction) ->
  switch direction 
    when 0 then y -= 1
    when 1 then x += 1
    when 2 then y += 1
    when 3 then x -= 1
  return [x, y]


class Block
  constructor: (@mmap, @x, @y, direction) ->
    @walls = [true, true, true, true]  # top,right,bottom,left
    if mmap
      mmap.mmap[x][y] = @
    if direction?
      direction = (direction + 2) % 4
      @walls[direction] = false

  getNextBlockPos: (direction) ->
    return getNextBlockPos(@x, @y, direction)

  getNextBlock: ->
    directions = _.shuffle [0..3]
    for direction in directions
      if !@walls[direction]  # if no wall
        continue
      pt = @getNextBlockPos(direction)
      x = pt[0]
      y = pt[1]
      if x >= @mmap.maxX || x < 0 || y >= @mmap.maxY || y < 0
        continue
      if @mmap.mmap[x][y]  # if walked
        continue
      @walls[direction] = false
      return new Block @mmap, x, y, direction
    return false


class Solver
  getNextStep: (mmap, steps, block) ->
    directions = [0..3]
    for direction in directions
      if block.walls[direction]  # if wall
        continue
      pt = block.getNextBlockPos(direction)
      x = pt[0]
      y = pt[1]
      if x >= mmap.maxX || x < 0 || y >= mmap.maxY || y < 0
        continue
      if steps[x][y]  # if walked
        continue
      steps[x][y] = true
      return mmap.mmap[x][y]
    return false

  solve: (mmap) ->
    steps = for x in [0...mmap.maxX]
      for y in [0...mmap.maxY]
        false
    maxX = mmap.maxX
    maxY = mmap.maxY
    solution = []
    blockStack = [mmap.mmap[0][0]]
    dowhile = (so) ->
      block = blockStack.pop()
      nextBlock = so.getNextStep mmap, steps, block
      if nextBlock
        blockStack.push block
        blockStack.push nextBlock
        if nextBlock.x == maxX - 1 && nextBlock.y == maxY - 1  # is end
          for o in blockStack
            solution.push [o.x, o.y]
          solution.push [maxX - 1, maxY - 1]
    dowhile(@) while blockStack.length
    return solution


class Map
  resetMap: ->
    @genMap @maxX, @maxY

  genMap: (@maxX, @maxY) ->
    @mmap = for x in [0...@maxX]
      for y in [0...@maxY]
        false
    blockStack = [new Block @, getRandomInt(0, maxX - 1), getRandomInt(0, maxY - 1)]
    dowhile = ->
      if getRandomInt(0, maxX + maxY) == 0
        blockStack = _.shuffle(blockStack)
      block = blockStack.pop()
      nextBlock = block.getNextBlock()
      if nextBlock
        blockStack.push block
        blockStack.push nextBlock
    dowhile() while blockStack.length

  moveNext: (x, y, direction) ->
    if @mmap[x][y].walls[direction] # has wall
      return false
    return getNextBlockPos(x, y, direction)


class DrawMap
  constructor: (@mmap, @cellWidth) ->
    if @cellWidth == undefined
      @cellWidth = 10

  getMapSize: ->
    return [(@mmap.maxX + 2) * @cellWidth, (@mmap.maxY + 2) * @cellWidth]

  createLine: (x1, y1, x2, y2, color) ->
    #pass

  createSolutionLine: (x1, y1, x2, y2) ->
    @createLine(x1, y1, x2, y2, "blue")

  drawStart: ->
  
  drawEnd: ->

  getCellCenter: (x, y) ->
    w = @cellWidth
    return [(x + 1) * w + w / 2, (y + 1) * w + w / 2]

  drawSolution: ->
    pre = [0, 0]
    solution = (new Solver()).solve(@mmap)
    for o in solution
      p1 = @getCellCenter(pre[0], pre[1])
      p2 = @getCellCenter(o[0], o[1])
      @createSolutionLine(p1[0], p1[1], p2[0], p2[1])
      pre = o

  drawCell: (block) ->
    width = @cellWidth
    x = block.x + 1
    y = block.y + 1
    walls = block.walls
    if walls[0]
      @createLine(x * width, y * width, (x + 1) * width, y * width)
    if walls[1]
      @createLine((x + 1) * width, y * width, (x + 1) * width, (y + 1) * width)
    if walls[2]
      @createLine(x * width, (y + 1) * width, (x + 1) * width, (y + 1) * width)
    if walls[3]
        @createLine(x * width, y * width, x * width, (y + 1) * width)

  drawMap: ->
    for y in [0...@mmap.maxY]
      for x in [0...@mmap.maxX]
        @drawCell(@mmap.mmap[x][y])
    @drawStart()
    @drawEnd()

class HTML5DrawMap extends DrawMap
  constructor: (@ctx, @mmap, @cellWidth) ->
    super @mmap, @cellWidth

  createLine: (x1, y1, x2, y2, color) ->
    if color
      @ctx.strokeStyle = color
    @ctx.beginPath()
    @ctx.moveTo x1, y1
    @ctx.lineTo x2, y2
    @ctx.stroke()
    @ctx.closePath()
    @ctx.strokeStyle = "black"

  drawStart: ->
    @ctx.fillStyle = "red"
    @ctx.fillText "S", @cellWidth + 1, @cellWidth * 2 - 1
  
  drawEnd: ->
    @ctx.fillStyle = "red"
    @ctx.fillText "E", @cellWidth * @mmap.maxX + 1, @cellWidth * (@mmap.maxY + 1) - 1

#init params
elCanvas = $ "#id-canvas"
elMapsize = $ '#id-mapsize'
elMan = $ '#id-man'
elTimer = $('#id-timer');
ctx = elCanvas[0].getContext "2d"
startTime = new Date()
mmap = new Map()
dmap = new HTML5DrawMap(ctx, mmap, 10)
manX = 0
manY = 0
end = false
timer = setInterval(->
  if !end
    elTimer.text fmtTime(new Date() - startTime)
, 1000)


newGame = ->
  manX = 0
  manY = 0
  end = false
  #map size
  size = parseInt elMapsize.val()
  if size > 100
    alert 'map size mast <= 100'
    return
  mmap.genMap size, size
  #clear canvas
  elTimer.text '00:00'
  ctx.beginPath()
  ctx.clearRect 0, 0, 1500, 1500
  startTime = new Date()
  #set canvas size
  pt = dmap.getMapSize()
  elCanvas.attr('width', pt[0])
  elCanvas.attr('height', pt[1])
  #set man to start pos
  #elMan.css 'left', addPX("-" + elCanvas.css('width'), 8)
  #elMan.css 'top', addPX("-" + elCanvas.css('height'), 10)
  elMan.css 'left', "12px"
  elMan.css 'top', addPX("-" + elCanvas.css('height'), -1)
  #draw
  dmap.drawMap()


isWin = ->
  manX == mmap.maxX - 1 && manY == mmap.maxY - 1


go = (direction)->
  if end
    return
  n = mmap.moveNext(manX, manY, direction)
  if n
    manX = n[0]
    manY = n[1]
    move(elMan, direction)
    if isWin()
      end = true
			#clearInterval(timer);
      alert('you win');


$(document).keydown((e) ->
  k = e.keyCode || e.which
  switch k 
    when 37 then go 3
    when 38 then go 0
    when 39 then go 1
    when 40 then go 2
    else return true
  return false
)


$('#id-btn-newgame').click(->
  newGame()
)


$('#id-btn-solution').click(->
 dmap.drawSolution() 
)


newGame()
