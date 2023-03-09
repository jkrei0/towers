extends StaticBody2D


func is_placed():
	# blocks will only collide with other placed objects
	# the base needs to define this to count as a placed object
	return true
