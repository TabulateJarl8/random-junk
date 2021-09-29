#pragma once

#include <vector>
#include <memory>

namespace frenchiii_enemies {
	class EnemyBase {
	public:
		int health = 100;

	virtual ~EnemyBase();
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

	class Bastille: public EnemyBase {
	public:
		std::string name = "The Bastille";
		std::string description = "Time to get some ammunition.";
	};

	class Robespierre: public EnemyBase {
	public:
		std::string name = "Robespierre";
		std::string description = "I mean to be fair they liked him for a while. He should\'ve gotten his head out of the gutter.";
	};

	extern std::vector<EnemyBase*> classes = {
		new BadGrammar,
		new British,
		new Tourist,
		new Bastille,
		new Robespierre
	};

}