#include <iostream>
#include "frenchiii_enemies.hpp"

using namespace std;

bool inRange(unsigned low, unsigned high, unsigned x) {
	return  ((x-low) <= (high-low));
}

int main() {
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

	frenchiii_enemies::FrenchEnemy enemy = frenchiii_enemies::enemies[0];
	cout << enemy.description << endl;

	return 0;
}