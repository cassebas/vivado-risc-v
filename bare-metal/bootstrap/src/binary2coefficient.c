/*!
 * \file    binary2coefficient.c
 * \author  Caspar Treijtel <18738369+cassebas@users.noreply.github.com>
 * \brief   Simple program that reads an input file and writes the input
 *          to an output file in the 'COE' (COEfficient) format.
 *          The output file is intended to be used as initialization data
 *          for a block memory module.
 * \version 0.1
 * \date    2024-06-19
 */

#define RADIX 16
#define MAX_BUF 256

#define BYTES_PER_LINE 4

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>


int main(int argc, char *argv[])
{
    if (argc != 3) {
        printf("Error: the input and output filenames are required!\n");
        printf("Usage: %s <input file> <output file>\n\n", argv[0]);
        printf("Example: ");
        printf("%s boot.elf boot.coe\n", argv[0]);
        exit(1);
    }
    printf("Reading input file %s.\n", argv[1]);

    FILE *ifp, *ofp;
    if ((ifp = fopen(argv[1], "rb")) == NULL) {
        printf("Error: couldn't open input file for reading!\n");
        exit(1);
    }

    printf("Writing to output file %s.\n", argv[2]);
    if ((ofp = fopen(argv[2], "w")) == NULL) {
        printf("Error: couldn't open output file for writing!\n");
        exit(1);
    }

    fprintf(ofp, "memory_initialization_radix = %d;\n", RADIX);
    fprintf(ofp, "memory_initialization_vector =\n");

    int c;
    int line[BYTES_PER_LINE+1];
    uint8_t cnt = 0;
    int bytes_read = 0;
    while ((c = fgetc(ifp)) != EOF) {
        if (cnt == BYTES_PER_LINE) {
            cnt = 0;
            fprintf(ofp, ",\n");
        }
        bytes_read++;
        line[cnt++] = c;
        fprintf(ofp, "%02x", c);
    }

    // Maybe pad last line with zeroes?
    if (cnt > 0) {
        for (int i=cnt; i<BYTES_PER_LINE; i++) {
            fprintf(ofp, "%02x", 0);
        }
    }
    fprintf(ofp, ";\n");

    printf("Total bytes read and written is %d\n", bytes_read);

    exit(0);
}
