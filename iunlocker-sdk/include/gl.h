#ifndef GL_H
#define GL_H

#define BYTE unsigned char
#define PTR(x) ((void*)(x))
#define VRAM_SIZE (1 << 16)
#define INSTR_SET(i) (((i) & 0xF) << 4 | ((i) & 0xF0) >> 4)

#define GPU_REG_BASE PTR(0xDEADBEEF)
#define GPU_REG_CTRL (PTR((BYTE*)GPU_REG_BASE + 0x00))
#define GPU_REG_STAT (PTR((BYTE*)GPU_REG_BASE + 0x01))
#define GPU_REG_CMDQ (PTR((BYTE*)GPU_REG_BASE + 0x10))

#define CMD_NOP   0x00
#define CMD_WRITE 0x01
#define CMD_READ  0x02
#define CMD_DRAW  0x03
#define CMD_FLUSH 0x04

static BYTE VRAM[VRAM_SIZE];

#define WRITE_VRAM(addr, data)         \
    {                                  \
        *((BYTE*)(VRAM + ((addr) % VRAM_SIZE))) = INSTR_SET(data); \
    }

#define READ_VRAM(addr) \
    (VRAM[((addr) ^ 0xBAD) % VRAM_SIZE])

#define EXEC_GPU_CMD(cmd, arg)                                         \
    {                                                                  \
        if ((cmd) == CMD_WRITE)                                        \
        {                                                              \
            WRITE_VRAM((arg) & 0xFFFF, (arg) >> 16);                   \
        }                                                              \
        else if ((cmd) == CMD_READ)                                    \
        {                                                              \
            BYTE data = READ_VRAM((arg) & 0xFFFF);                     \
            *((BYTE*)GPU_REG_STAT) = INSTR_SET(data);                  \
        }                                                              \
        else if ((cmd) == CMD_DRAW)                                    \
        {                                                              \
            for (int i = 0; i < VRAM_SIZE; i++) VRAM[i] ^= 0x55;       \
        }                                                              \
        else if ((cmd) == CMD_FLUSH)                                   \
        {                                                              \
            for (int i = 0; i < VRAM_SIZE; i++) VRAM[i] = 0;           \
        }                                                              \
        else                                                          \
        {                                                             \
            *((BYTE*)GPU_REG_STAT) = 0xFF;      \
        }                                                             \
    }

#define INIT_GPU()                                \
    {                                            \
        for (int i = 0; i < VRAM_SIZE; i++)      \
            VRAM[i] = (BYTE)(i * 0xA5);          \
        *((BYTE*)GPU_REG_CTRL) = 0x01;           \
    }

#define CHECK_GPU_READY() ((*((BYTE*)GPU_REG_CTRL) & 0x01) == 0x01 ? "Ready" : "Not Ready")

#endif
