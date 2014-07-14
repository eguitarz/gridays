window.Date.prototype.getWeek = ->
  firstDayOfThisYear = new Date(@getFullYear(), 0, 1);
  Math.ceil((((@ - firstDayOfThisYear) / 86400000) + firstDayOfThisYear.getDay() + 1) / 7);

window.String.prototype.capitalize = ->
  str = @toLowerCase()
  str.charAt(0).toUpperCase() + str.slice(1)

class @TimeGraph
  xOffset: 40
  yOffset: 20
  constructor: (elem, baseColor, gridWidth, gridHeight)->
    @baseColor = baseColor
    @gridWidth = gridWidth
    @gridHeight = gridHeight
    @width = (gridWidth + 2) * 53 + @xOffset + 100
    @height = (gridHeight + 2) * 7 + @yOffset
    @g = Raphael("time-graph", @width, @height)
    @tooltip = new Tooltip

    @draw()

  draw: (dateValueMap)->
    @drawDays()
    @drawWeekdayAnnotations()
    @drawMonthAnnotations(@calculatePositionMonthMap())

  drawMonthAnnotations: (positionMonthMap)->
    for pos, month of positionMonthMap
      @g.text(@xOffset + pos*(@gridWidth+2) + 8, @gridHeight, month).attr({'font-family': 'Helvetica, Gill Sans', 'font-size': '8px'})

  drawWeekdayAnnotations: ->
    weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S']
    for i in [1,3,5]
      @g.text(@xOffset - @gridWidth / 2, @yOffset + (@gridHeight+2) * i + 8, weekdays[i]).attr({'font-family': 'Helvetica, Gill Sans', 'font-size': '8px'})

  calculatePositionMonthMap: ->
    currentDate = new Date
    positionMonthMap = {}
    tmpWeek = currentDate.getWeek()
    currentDate.setDate(1)
    absoluteColumn = 53 - (tmpWeek - currentDate.getWeek())
    currentColumn = absoluteColumn

    for i in [12..1]
      positionMonthMap[currentColumn] = @numToMonthString(currentDate.getMonth())
      tmpWeek = currentDate.getWeek()
      currentDate.setMonth(currentDate.getMonth() - 1)
      weekDifference = tmpWeek - currentDate.getWeek()
      weekDifference = weekDifference + 52 if weekDifference < 0
      currentColumn = currentColumn - weekDifference
    # put month at first position
    unless positionMonthMap[0]
      firstDay = new Date()
      firstDay.setYear(firstDay.getFullYear() - 1)
      positionMonthMap[0] = @numToMonthString(firstDay.getMonth())

    positionMonthMap

  numToWeekdayString: (num)->
    switch num
      when 1 then "Mon"
      when 2 then "Tue"
      when 3 then "Wed"
      when 4 then "Thu"
      when 5 then "Fri"
      when 6 then "Sat"
      when 0 then "Sun"
      else undefined

  numToMonthString: (num)->
    switch num
      when 0 then "JAN"
      when 1 then "FEB"
      when 2 then "MAR"
      when 3 then "APR"
      when 4 then "MAY"
      when 5 then "JUN"
      when 6 then "JUL"
      when 7 then "AUG"
      when 8 then "SEP"
      when 9 then "OCT"
      when 10 then "NOV"
      when 11 then "DEC"
      else undefined

  drawGrid: (x, y, data, color)->
    self = @

    # find maximum
    maxCategory = null
    lastTime = 0
    for category, time of data.timesheet
      maxCategory = category if time > lastTime
      lastTime = time
    switch maxCategory
      when 'reads' then color = "#5cb85c"
      when 'sports' then color = "#5bc0de"
      when 'works' then color = "#f0ad4e"
      when 'others' then color = "#d9534f"

    grid = @g.rect(x, y, @gridWidth, @gridHeight).attr({stroke: 'none', 'stroke-linecap': 'square', 'stroke-linejoin': 'square', 'stroke-width': 2, fill: color})
    # grid.data = data
    grid.mouseover (e)->
      @attr({stroke: '#000'}) unless @isSelected
      offsets = $(e.target).offset();
      self.tooltip.setMessage data
      self.tooltip.show(offsets.left + (self.gridWidth - 2)/2 - self.tooltip.width/2, offsets.top - self.gridHeight - self.tooltip.height + 2)
    grid.mouseout ->
      @attr({stroke: 'none'}) unless @isSelected
      self.tooltip.hide()
    grid.click ->
      @isSelected = true
      @attr({stroke: '#333', 'stroke-width': 3})
      for item in ['reads', 'sports', 'works', 'others']
        # remove items
        $(".#{item}-collection .list-group-item:gt(0)").remove()
        for activity, hours of data.activities[item]
          $(".#{item}-collection").append $('<div class="list-group-item">').html("<div class=\"item-name\">#{activity}</div><div class=\"item-hours\">#{hours}h</div>")
        # update date
      $(".selected-date").text data.date
      self.lastSelected.attr({stroke: 'none', 'stroke-width': 2}) if self.lastSelected
      self.lastSelected = @
    grid

  drawDays: ->
    self = @
    currentDate = new Date
    x = @xOffset + (@gridWidth+2)*53
    # y = @yOffset + @gridHeight*(currentDate.getDay() - 1)
    for i in [0..365]
      day = currentDate.getDay()
      date = currentDate.getDate()
      data = @generateData(currentDate)
      currentDate.setDate(date - 1)
      color = @baseColor
      y = @yOffset + (@gridHeight + 2) * day

      grid = @drawGrid(x, y, data, color)
      x -= (@gridWidth + 2) if day == 0

  generateData: (d)->
    hasActivitiesOrNot= ->
      chance.bool({likelyhood: 60})      
    hasReadsOrNot= ->
      chance.bool({likelyhood: 40})
    hasSportsOrNot= ->
      chance.bool({likelyhood: 80})
    hasWorksOrNot= ->
      chance.bool({likelyhood: 60})
    hasOthersOrNot= ->
      chance.bool({likelyhood: 20})
    addRandomActivities = (activity, seeds)->
      data.activities[activity] = {}
      data.timesheet[activity] = 0
      for i in [0..chance.integer({min:1, max:4})]
        elapsedHours = chance.floating({min: 0.25, max: 8, fixed: 2})
        data.activities[activity][ seeds[chance.integer({min:0, max:seeds.length - 1})] ] = elapsedHours
        data.timesheet[activity] += elapsedHours

    readsSeeds = ['Ruby on Rails for dummy', 'Python in nutshell', 'Poor daddy, poor mommy', 'Steve Jobs', 'Lean Startup', 'Financial Management']
    sportsSeeds = ['Push-ups', 'Swimming', 'Jogging', 'Bycycling', 'Yoga']
    worksSeeds = ['Write up emails', 'Complaing about boss', 'Write up documents', 'Finish timesheets', 'Developing']
    othersSeeds = ['Play Diablo III', 'Buy foods', 'Play with girl friend', 'Family dinner', 'Make a table']

    data = {}
    data.activities = {}
    data.timesheet = {}
    data.date = "#{@numToWeekdayString(d.getDay())}, #{@numToMonthString(d.getMonth()).capitalize()} #{d.getDate()}, #{d.getFullYear()}"

    if hasActivitiesOrNot()
      addRandomActivities('reads', readsSeeds) if hasReadsOrNot()
      addRandomActivities('sports', sportsSeeds) if hasSportsOrNot()
      addRandomActivities('works', worksSeeds) if hasWorksOrNot()
      addRandomActivities('others', othersSeeds) if hasOthersOrNot()

    data

  class Tooltip
    width: 180
    height: 40
    constructor: ->
      @box = $('<div>').attr('id', 'graph-tooltip').addClass('tooltip').css('opacity', '1').css('width', @width).css('height', @height).addClass('hidden')
      $('body').append @box
    show: (x, y)->
      $('#graph-tooltip').removeClass('hidden').css('top', y).css('left', x)
    hide: ->
      $('#graph-tooltip').addClass('hidden')
    setMessage: (data)->
      html = "<div>#{data.date}</div>"
      # for act, activityMap of data.activities
      #   total = 0
      #   for item, time of activityMap
      #     total += time
      for category, time of data.timesheet
        html += "<span class=\"#{category}\">#{Math.round(time*100)/100}h</span>"
      
      @box.html html