#ifndef DISPLAY_H
#define DISPLAY_H

#include <stdint.h>
#include <stddef.h>

#define DISPLAY_WIDTH 1220
#define DISPLAY_HEIGHT 2652
#define PIXEL_DEPTH 32
#define TOTAL_PIXELS (DISPLAY_WIDTH * DISPLAY_HEIGHT)
#define FRAME_BUFFER_SIZE (TOTAL_PIXELS * (PIXEL_DEPTH / 8))

typedef struct {
    uint8_t r;
    uint8_t g;
    uint8_t b;
    uint8_t a;
} PIXEL;

typedef struct {
    PIXEL buffer[DISPLAY_HEIGHT][DISPLAY_WIDTH];
    volatile uint32_t vblank;
} DISPLAY;

static DISPLAY SCREEN;

#define COLOR_BLACK ((PIXEL){0, 0, 0, 255})
#define COLOR_WHITE ((PIXEL){255, 255, 255, 255})
#define COLOR_RED ((PIXEL){255, 0, 0, 255})
#define COLOR_GREEN ((PIXEL){0, 255, 0, 255})
#define COLOR_BLUE ((PIXEL){0, 0, 255, 255})

#define SET_PIXEL(x, y, color)                           \
    if ((x) < DISPLAY_WIDTH && (y) < DISPLAY_HEIGHT) {   \
        SCREEN.buffer[(y)][(x)] = (color);               \
    }

#define CLEAR_DISPLAY(color)                             \
    for (size_t y = 0; y < DISPLAY_HEIGHT; ++y) {        \
        for (size_t x = 0; x < DISPLAY_WIDTH; ++x) {     \
            SCREEN.buffer[y][x] = (color);               \
        }                                                \
    }

#define DRAW_RECTANGLE(x, y, w, h, color)                \
    for (size_t i = 0; i < (h) && (y + i) < DISPLAY_HEIGHT; ++i) { \
        for (size_t j = 0; j < (w) && (x + j) < DISPLAY_WIDTH; ++j) { \
            SET_PIXEL((x + j), (y + i), (color));        \
        }                                                \
    }

#define DISPLAY_REFRESH()                                \
    SCREEN.vblank++;                                     \
    asm volatile("" ::: "memory")

#endif // DISPLAY_H
