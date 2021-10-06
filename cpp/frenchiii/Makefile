CC=g++
CFLAGS=-Wall -Wextra -Wpedantic
MINGW=x86_64-w64-mingw32-g++

.PHONY: build clean rebuild rebuild_windows build_windows dist help

build: frenchiii.cpp
	$(CC) $(CFLAGS) -o french frenchiii.cpp

build_windows: frenchiii.cpp
	$(MINGW) $(CFLAGS) -o french frenchiii.cpp

clean:
	rm -f french
	rm -f french.exe

rebuild: clean build

rebuild_windows: clean build_windows

dist: CFLAGS += -static
dist: clean build build_windows

help:
	@echo 'Targets:'
	@echo '    build             build Linux version'
	@echo '    build_windows     use mingw to cross-compile Windows version'
	@echo '    clean             Clean the binary files'
	@echo '    rebuild           Clean and then build the Linux version'
	@echo '    rebuild_windows   Clean and then build the Windows version'
	@echo '    dist              Compile a Linux and a Windows static binary'

.DEFAULT_GOAL: build