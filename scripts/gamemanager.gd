extends Node
@onready var pointslabel: Label = %pointslabel


var points = 0

func add_points():
	points += 1
	print(points)
	pointslabel.text = "Keys: " + str(points)
	
