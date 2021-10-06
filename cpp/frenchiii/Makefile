CC=g++
CFLAGS=-Wall -Wextra -Wpedantic

.PHONY: build clean rebuild

build: frenchiii.cpp
	$(CC) $(CFLAGS) -o french frenchiii.cpp

clean:
	rm -f french

rebuild: clean build

.DEFAULT_GOAL: build