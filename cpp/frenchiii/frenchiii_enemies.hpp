#pragma once

namespace frenchiii_enemies {
	class EnemyBase {
	public:
		int health = 100;
	};

	class BadGrammar: public EnemyBase {
	public:
		std::string name = "Bad Grammar";
		std::string description = "une puissant ennemi";
	};

	class British: public EnemyBase {
	public:
		std::string name = "The British";
		std::string description = "They\'ll dip your baguette in tea";
	};

	class Tourist: public EnemyBase {
	public:
		std::string name = "Tourist";
		std::string description = "Thinks Paris and Franch are the same thing.";
	};

}