#include <iostream>
#include <string>
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
	// 4532115680546236
	cout << "Card Number: ";

	string card_numbers;
	cin >> card_numbers;

	for (int i = 1; i < card_numbers.length(); i += 2) {
		int value = stoi(string(1, card_numbers[i])) * 2;
		value = getSum(value);
		card_numbers[i] = value + '0';
	}

	int total_sum = getSum(stol(card_numbers));

	int is_valid_number = (total_sum % 10 == 0) ? 1 : 0;

	if (is_valid_number) {
		cout << "Is possible credit card number" << endl;
	} else {
		cout << "Is not possible credit card number" << endl;
	}

	return is_valid_number;
}