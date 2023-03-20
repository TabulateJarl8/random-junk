# a useless program to generate random ints in the worst possible way
import randfacts

def get_rand_index():
	fact_to_find = randfacts.get_fact()
	index = randfacts.safe_facts.index(fact_to_find)

	return index

def randint(low, up):
	random_number = get_rand_index()

	while not (low < random_number < up):
		if random_number > up:
			random_number -= get_rand_index()
		elif random_number < low:
			random_number += get_rand_index()

	return random_number

print(randint(0, 1))