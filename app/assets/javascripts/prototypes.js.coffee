$(document).on 'page:change', ->
	window.App.TimeGraph = new TimeGraph( $('#time-graph > svg'), 'rgb(225,225,225)', 15, 15)