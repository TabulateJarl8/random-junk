#pragma once

#if defined(_WIN32)
#define WIN32_LEAN_AND_MEAN
#define VC_EXTRALEAN
#include <windows.h>
#elif defined(__linux__)
#include <sys/ioctl.h>
#endif // Windows/Linux

#include <cstdlib>

namespace utilities {
	void get_terminal_size(int& width, int& height) {
		#if defined(_WIN32)
		    CONSOLE_SCREEN_BUFFER_INFO csbi;
		    GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &csbi);
		    width = (int)(csbi.srWindow.Right-csbi.srWindow.Left+1);
		    height = (int)(csbi.srWindow.Bottom-csbi.srWindow.Top+1);
		#elif defined(__linux__)
		    struct winsize w;
		    ioctl(fileno(stdout), TIOCGWINSZ, &w);
		    width = (int)(w.ws_col);
		    height = (int)(w.ws_row);
		#endif // Windows/Linux
	}

	void clear_screen() {
		#ifdef WINDOWS
			system("cls");
		#else
			system("clear");
		#endif
	}

	bool in_range(unsigned low, unsigned high, unsigned x) {
		return  ((x-low) <= (high-low));
	}

}