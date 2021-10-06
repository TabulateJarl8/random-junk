#pragma once

#include <vector>

namespace frenchiii_enemies {
	class FrenchEnemy {
	public:
		int health = 100;
		std::string name;
		std::string description;
		FrenchEnemy(std::string set_name, std::string set_description) {
			name = set_name;
			description = set_description;
		}
	};

	const std::vector<FrenchEnemy> enemies {
		{"Bad Grammar", "une puissant ennemi"},
		{"The British", "They\'ll dip your baguette in tea"},
		{"Tourist", "Thinks Paris and Franch are the same thing."},
		{"The Bastille", "Time to get some ammunition."},
		{"Robespierre", "I mean to be fair they liked him for a while. He should\'ve gotten his head out of the gutter."}
	};

}