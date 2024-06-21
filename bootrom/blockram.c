/*!
 * \file    blockram.c
 * \author  Caspar Treijtel <18738369+cassebas@users.noreply.github.com>
 * \brief   Simple stub that reads from a block RAM device on the FPGA
 *          instead of a file from SD-card.
 * \version 0.1
 * \date    2024-06-19
 */

#include "blockram.h"
#include <stddef.h>

/* Open or create a file */
FRESULT br_open (BlockRam *fp, const TCHAR *path, BYTE mode)
{
    if (fp == NULL) {
        return FR_INVALID_PARAMETER;
    }

    fp->memptr = (uint32_t *)0x60050000;
    fp->byte_index = 0;

    return FR_OK;
}

/* Close an open file object */
FRESULT br_close (BlockRam *fp)
{
    if (fp == NULL) {
        return FR_INVALID_PARAMETER;
    }

    fp->byte_index = 0;

    return FR_OK;
}

static uint8_t get_byte_from_word(uint32_t word, uint8_t idx)
{
    if (idx == 0) {
        return (uint8_t) ((word >> 24) & 0xFF);
    } else if (idx == 1) {
        return (uint8_t) ((word >> 16) & 0xFF);
    } else if (idx == 2) {
        return (uint8_t) ((word >> 8) & 0xFF);
    } else if (idx == 3) {
        return (uint8_t) (word & 0xFF);
    } else {
        return 0;
    }
}

/* Read data from the file */
FRESULT br_read (BlockRam *fp, void *buff, UINT btr, UINT *br)
{
    if (fp == NULL) {
        return FR_INVALID_PARAMETER;
    }

    /* Clear read byte counter */
    *br = 0;

    uint8_t *mybuff = (uint8_t *) buff;
    uint32_t blockmem_idx = fp->byte_index >> 2;
    uint8_t blockmem_offset = fp->byte_index & 0x3;

    while (btr-- > 0) {
        *mybuff++ = get_byte_from_word(fp->memptr[blockmem_idx],
                                       blockmem_offset);
        fp->byte_index++;
        (*br)++;
        if (++blockmem_offset == 4) {
            blockmem_idx++;
            blockmem_offset = 0;
        }
    }

    return FR_OK;
}

/* Move file pointer of the file object */
FRESULT br_lseek (BlockRam *fp, FSIZE_t ofs)
{
    if (fp == NULL) {
        return FR_INVALID_PARAMETER;
    }

    fp->byte_index = ofs;
    return FR_OK;
}

/* Mount/Unmount a logical drive */
FRESULT br_mount (FATFS *fs, const TCHAR *path, BYTE opt)
{
    return FR_OK;
}
