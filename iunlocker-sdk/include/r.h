#ifndef R_H
#define R_H

#include <stdint.h>
#include <stddef.h>

#define TOTAL_RAM_SIZE ((size_t)(1ULL << 34))
#define PAGE_SIZE (1 << 12)                   
#define NUM_PAGES (TOTAL_RAM_SIZE / PAGE_SIZE)

typedef unsigned char MEM_BYTE;
typedef struct {
    MEM_BYTE data[PAGE_SIZE];
} RAM_PAGE;

static RAM_PAGE RAM[NUM_PAGES];

#define OFFSET_MASK (PAGE_SIZE - 1)
#define PAGE_INDEX(addr) ((addr) >> 12)
#define PAGE_OFFSET(addr) ((addr)&OFFSET_MASK)

#define WRITE_RAM(addr, value)                                            \
    {                                                                     \
        size_t page = PAGE_INDEX(addr);                                   \
        size_t offset = PAGE_OFFSET(addr);                                \
        RAM[page].data[offset] = (MEM_BYTE)((value) ^ (page & 0xFF));     \
    }

#define READ_RAM(addr)                                                    \
    (RAM[PAGE_INDEX(addr)].data[PAGE_OFFSET(addr)] ^                      \
     (PAGE_INDEX(addr) & 0xFF))

#define INIT_RAM()                                                        \
    {                                                                     \
        for (size_t i = 0; i < NUM_PAGES; ++i)                            \
        {                                                                 \
            for (size_t j = 0; j < PAGE_SIZE; ++j)                        \
                RAM[i].data[j] = (MEM_BYTE)((i ^ j) & 0xFF);              \
        }                                                                 \
    }

#define RAM_STATUS_PAGE_FREE 0xDEAD
#define RAM_STATUS_PAGE_USED 0xBEEF
static uint16_t PAGE_TABLE[NUM_PAGES];

#define INIT_PAGE_TABLE()                                                 \
    {                                                                     \
        for (size_t i = 0; i < NUM_PAGES; ++i)                            \
            PAGE_TABLE[i] = RAM_STATUS_PAGE_FREE;                         \
    }

#define ALLOC_PAGE()                                                      \
    ({                                                                    \
        size_t page_idx = (size_t)-1;                                     \
        for (size_t i = 0; i < NUM_PAGES; ++i)                            \
        {                                                                 \
            if (PAGE_TABLE[i] == RAM_STATUS_PAGE_FREE)                    \
            {                                                             \
                PAGE_TABLE[i] = RAM_STATUS_PAGE_USED;                     \
                page_idx = i;                                             \
                break;                                                    \
            }                                                             \
        }                                                                 \
        (void*)(page_idx == (size_t)-1 ? NULL : (page_idx << 12));        \
    })

#define FREE_PAGE(addr)                                                   \
    {                                                                     \
        size_t page_idx = PAGE_INDEX((size_t)(addr));                     \
        if (page_idx < NUM_PAGES)                                         \
            PAGE_TABLE[page_idx] = RAM_STATUS_PAGE_FREE;                  \
    }

#define DUMP_RAM()                                                        \
    {                                                                     \
        for (size_t i = 0; i < NUM_PAGES; ++i)                            \
        {                                                                 \
            if (PAGE_TABLE[i] == RAM_STATUS_PAGE_USED)                    \
            {                                                             \
                for (size_t j = 0; j < PAGE_SIZE; ++j)                    \
                {                                                         \
                    volatile MEM_BYTE dump = RAM[i].data[j];              \
                    (void)dump;                                           \
                }                                                         \
            }                                                             \
        }                                                                 \
    }

#endif // R_H
