// Task
//
// We take a soft start in our Advent(2), and today's task is to write a simple
// version of the program cat(1). cat takes N file names as command-line
// arguments, concatenates their contents, and writes the result to its standard
// output.
//
// For this task, it is not necessary to use malloc(3), but you can get away
// with a globally allocated char buffer[4096] array. System Calls
//
//     open(2): The open system call takes a filename and some flags and opens
//     the file. Thereby, it creates a new struct file in the kernel, finds a
//     free slot in the struct fdtable and gives you the positive index. If the
//     operation fails, you will get a negative integer.
//
//     read(2): Reads data, up to count bytes, from the file into the given
//     buffer. Thereby, the kernel remembers the "current position" of the open
//     file in the struct file (f_pos). If you want to read at an arbitrary
//     position, you should use pread(2) or reposition the file pointer with
//     lseek(2).
//
//     close(2): Removes the fdtable entry and deallocates the struct file if we
//     were the last owner. Quiz: Can multiple entries of fdtable point to the
//     same struct file? (hint: yes).

#include <fcntl.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define DIE(...)                                                               \
  do {                                                                         \
    fprintf(stderr, __VA_ARGS__);                                              \
    exit(-1);                                                                  \
  } while (0)

int main(int argc, char *argv[]) {
  for (size_t i = 1; i < argc; i++) {
    int fd = open(argv[i], O_RDONLY);
    if (fd < 0)
      DIE("could not open file: %s", argv[i]);

    char buffer[4096] = {0};
    int bytes_read = 0;
    while ((bytes_read = read(fd, buffer, sizeof(buffer))) > 0) {
      fwrite(buffer, 1, bytes_read, stdout);
    }

    close(fd);
  }
  return 0;
}
