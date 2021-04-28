#include <iostream>
#include <string>
using namespace std;

int main() {
	cout << "OHOHO I LKOVE ME A STAR AND CROSSED!!!" << endl;
	string answer;
	cout << "DO YOU?!?!? ";
	getline(cin, answer);
	if (answer == "yes but only on yesterday") {
		cout << "that is the correct one answer so that is good goodbye" << endl;
	} else {
		while (true) {
			cout << "that is not the correct answer try again later i cannot believe that you would say such a thing" << endl;
		}
	}
	return 0;
}