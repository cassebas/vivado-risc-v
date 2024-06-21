/*!
 * \file    blockram.h
 * \author  Caspar Treijtel <18738369+cassebas@users.noreply.github.com>
 * \brief   Simple stub that reads from a block RAM device on the FPGA
 *          instead of a file from SD-card.
 * \version 0.1
 * \date    2024-06-19
 */

#ifndef BLOCK_RAM_H
#define BLOCK_RAM_H

#include <stdint.h>

#include "ff.h"

typedef struct {
    uint32_t *memptr;
    uint32_t byte_index;
} BlockRam;

/*--------------------------------------------------------------*/
/* FatFs module application interface                           */

/* Open or create a file */
FRESULT br_open (BlockRam *fp, const TCHAR *path, BYTE mode);
/* Close an open file object */
FRESULT br_close (BlockRam *fp);
/* Read data from the file */
FRESULT br_read (BlockRam *fp, void *buff, UINT btr, UINT *br);
/* Move file pointer of the file object */
FRESULT br_lseek (BlockRam *fp, FSIZE_t ofs);
/* Mount/Unmount a logical drive */
FRESULT br_mount (FATFS *fs, const TCHAR *path, BYTE opt);

#define br_tell(fp) ((fp)->byte_index)

#endif /* BLOCK_RAM_H */
