#include <iostream>
#include <vector>
#include <chrono>
#include <thread>
#include "frenchiii_enemies.hpp"
#include "utilities.hpp"

using namespace std;
using namespace std::literals::chrono_literals;

int main() {
	srand(time(0));
	string options[] = {
		"Baguette",
		"Mime",
		"Cheese",
		"Wine",
		"Beret",
		"Eiffel Tower",
		"Emmanuel Macron"
	};

	cout << "\033[0;1;4mWelcome to French III: La Vengeance de L'escroc Baguette\033[0m" << endl << endl;
	cout << "Choose your weapon:" << endl;
	for (unsigned int i = 0; i < size(options); i++) {
		cout << "	[" << i + 1 << "] " << options[i] << endl;
	}

	int user_choice = 0;
	while (!utilities::in_range(1, size(options), user_choice)) {
		cout << "\033[0;1m>>>\033[0m ";
		cin >> user_choice;
	}

	user_choice--;

	cout << "You chose " << options[user_choice] << " as your weapon." << endl;

	this_thread::sleep_for(2s);

	// choose random enemy
	vector<frenchiii_enemies::FrenchEnemy> enemies_vector = frenchiii_enemies::enemies;
	int random_index = rand() % enemies_vector.size();
	frenchiii_enemies::FrenchEnemy current_enemy = enemies_vector[random_index];

	cout << endl << "Your Enemy:" << endl << current_enemy.name << " - " << current_enemy.description << endl;

	this_thread::sleep_for(3.5s);

	// clear terminal screen by scrolling up
	int terminal_width = 0, terminal_height = 0;
	utilities::get_terminal_size(terminal_width, terminal_height);

	for (int i = 0; i < terminal_height; i++) {
		this_thread::sleep_for(50ms);
		cout << endl;
	}

	return 0;
}