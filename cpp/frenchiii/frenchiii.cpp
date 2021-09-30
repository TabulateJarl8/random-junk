#include <iostream>
#include <vector>
#include <chrono>
#include <thread>
#include <cstdlib>
#include "frenchiii_enemies.hpp"

using namespace std;
using namespace std::literals::chrono_literals;

bool inRange(unsigned low, unsigned high, unsigned x) {
	return  ((x-low) <= (high-low));
}

void clear_screen() {
	#ifdef WINDOWS
		system("cls");
	#else
		system("clear");
	#endif
}

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
	for (int i = 0; i < (sizeof(options) / sizeof(options[0])); i++) {
		cout << "	[" << i + 1 << "] " << options[i] << endl;
	}

	int user_choice = 0;
	while (!inRange(1, sizeof(options) / sizeof(options[0]), user_choice)) {
		cout << "\033[0;1m>>>\033[0m ";
		cin >> user_choice;
	}

	user_choice--;

	cout << "You chose " << options[user_choice] << " as your weapon." << endl;

	this_thread::sleep_for(2s);

	vector<frenchiii_enemies::FrenchEnemy> enemies_vector = frenchiii_enemies::enemies;
	int random_index = rand() % enemies_vector.size();
	frenchiii_enemies::FrenchEnemy current_enemy = enemies_vector[random_index];

	cout << endl << "Your Enemy:" << endl << current_enemy.name << " - " << current_enemy.description << endl;

	this_thread::sleep_for(4s);

	clear_screen();

	return 0;
}