#!/usr/bin/env python3

"""
A turtle program to draw colored sqares on the canvas.

If run directly, will make an 8x8 checkerboard pattern alternating between
red and blue.

PEP-8 Compliant.
"""

import turtle


def draw_square(local_turtle_object, start_x_coord, start_y_coord, box_size_px, bg_color):
	"""
	Draw a square on the canvas.
	"""
	local_turtle_object.penup()
	local_turtle_object.goto(start_x_coord, start_y_coord)
	local_turtle_object.pendown()
	local_turtle_object.fillcolor(bg_color)
	local_turtle_object.begin_fill()
	for _ in range(4):
		local_turtle_object.forward(box_size_px)
		local_turtle_object.right(90)
	local_turtle_object.end_fill()


def draw_example(width=450, height=450):
	"""
	Draw an 8x8 checkerboard pattern alternating between red and blue.

	If width or height is None, it will be set to the default value.
	"""

	window = turtle.Screen()

	if width is None:
		width = window.window_width()
	if height is None:
		height = window.window_height()

	window.setup(width, height)

	start_x = -width / 2
	start_y = height / 2
	current_color = 'red'

	turtle_object = turtle.Turtle()
	turtle_object.speed('fastest')
	turtle_object.hideturtle()

	for i in range(8):
		for j in range(8):
			draw_square(turtle_object, start_x + (50 * j), start_y - (50 * i), 50, current_color)
			current_color = 'blue' if current_color == 'red' else 'red'
		current_color = 'blue' if current_color == 'red' else 'red'

	turtle.done()


if __name__ == "__main__":
	draw_example()
