import matplotlib.pyplot as plt

statistics = {
	'Red Bull': {
		'caffeine': 111,
		'sugar': 37,
		'calories': 168
	},
	'Monster': {
		'caffeine': 86,
		'sugar': 27,
		'calories': 101
	},
	'Rockstar': {
		'caffeine': 160,
		'sugar':  59,
		'calories': 278
	},
	'NOS': {
		'caffeine': 160,
		'sugar':  54,
		'calories': 210
	},
	'Burn': {
		'caffeine': 112,
		'sugar':  19,
		'calories': 96
	},
	'Gatorade': {
		'caffeine': 0,
		'sugar': 34,
		'calories': 140
	},
	'Coca Cola': {
		'caffeine': 39,
		'sugar': 44,
		'calories': 182
	},
	'Pepsi': {
		'caffeine': 35,
		'sugar': 41,
		'calories': 150
	},
	'Dr. Pepper': {
		'caffeine': 41,
		'sugar': 40,
		'calories': 150
	},
	'Mountain Dew': {
		'caffeine': 54,
		'sugar': 46,
		'calories': 170
	},
	'Sprite': {
		'caffeine': 0,
		'sugar': 44,
		'calories': 192
	}
}

def bar_plot(ax, data, colors=None, total_width=0.8, single_width=1, legend=True):
	# Check if colors where provided, otherwhise use the default color cycle
	if colors is None:
		colors = plt.rcParams['axes.prop_cycle'].by_key()['color']

	# Number of bars per group
	n_bars = len(data)

	# The width of a single bar
	bar_width = total_width / n_bars

	# List containing handles for the drawn bars, used for the legend
	bars = []

	# Iterate over all data
	for i, (name, values) in enumerate(data.items()):
		# The offset in x direction of that bar
		x_offset = (i - n_bars / 2) * bar_width + bar_width / 2

		# Draw a bar for every value of that type
		for x, y in enumerate(values):
			bar = ax.bar(x + x_offset, y, width=bar_width * single_width, color=colors[i % len(colors)])

		# Add a handle to the last drawn bar, which we'll need for the legend
		bars.append(bar[0])

	# Draw legend if we need
	if legend:
		ax.legend(bars, data.keys())

if __name__ == '__main__':
	x = list(statistics.keys())

	caffeine = [value['caffeine'] for value in statistics.values()]
	sugar = [value['sugar'] for value in statistics.values()]
	calories = [value['calories'] for value in statistics.values()]

	data = {
		key: [caffeine[count], sugar[count], calories[count]]
		for count, key in enumerate(x)
	}

	fig, ax = plt.subplots()
	bar_plot(ax, data, total_width=0.8, single_width=0.9)

	stat_values = [
		'Caffeine (mg)',
		'Sugar (g)',
		'Calories'
	]

	fig.canvas.draw()
	labels = [item.get_text() for item in ax.get_xticklabels()]
	labels = [
		stat_values[int(float(item))]
		if '−' not in item and
		float(item).is_integer() and
		int(float(item)) in range(len(stat_values))
		else ''
		for item in labels
	]
	ax.set_xticklabels(labels)
	plt.title('Nutrition differences in popular energy drinks and soft drinks')

	plt.show()