#include <iostream>
#include <string>
#include <regex>
#include <type_traits>
using namespace std;

template<typename T>
int getSum(T n) {
	if constexpr (is_same_v<T, int> || is_same_v<T, long>) {
		int sum;
		for (sum = 0; n > 0; sum += n % 10, n /= 10);
		return sum;
	}
}

int main() {
	// Credit card validator in C++
	// Uses the Luhn algorithm to determine if the card could exist, partnered
	// with a regular expression to test if the beginning of the card
	// Valid card number: 4532115680546236
	cout << "Card Number: ";

	string card_numbers;
	cin >> card_numbers;

	regex valid_card("^(?:4[0-9]{12}(?:[0-9]{3})?"         // Visa
			"|  (?:5[1-5][0-9]{2}"                         // MasterCard
			"| 222[1-9]|22[3-9][0-9]|2[3-6][0-9]{2}|27[01][0-9]|2720)[0-9]{12}"
			"|  3[47][0-9]{13}"                            // American Express
			"|  3(?:0[0-5]|[68][0-9])[0-9]{11}"            // Diners Club
			"|  6(?:011|5[0-9]{2})[0-9]{12}"               // Discover
			"|  (?:2131|1800|35\\d{3})\\d{11}"             // JCB
			")$"
	);

	if (!regex_match(card_numbers, valid_card)) {
		cout << "Credit card number is not possible." << endl;
		return 1;
	}

	for (int i = 1; i < card_numbers.length(); i += 2) {
		// Multiply every other number by two, and get the sum of the resuling
		// digits
		int value = stoi(string(1, card_numbers[i])) * 2;
		value = getSum(value);
		card_numbers[i] = value + '0';
	}

	// Get the total sum of all digits in the new number
	int total_sum = getSum(stol(card_numbers));

	// Is valid number if the total_sum modulo 10 is equal to 0
	int is_valid_number = (total_sum % 10 == 0) ? 1 : 0;

	if (is_valid_number) {
		cout << "Credit card number is possible." << endl;
	} else {
		cout << "Credit card number is not possible." << endl;
	}

	return is_valid_number;
}