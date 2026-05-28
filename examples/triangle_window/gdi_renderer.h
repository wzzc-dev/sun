#ifndef GDI_RENDERER_H
#define GDI_RENDERER_H

#include <stdint.h>

// Draw RGBA pixel buffer to window
void gdi_draw_pixels(
    uint64_t hwnd,
    const uint8_t* pixels,
    int32_t width,
    int32_t height
);

#endif // GDI_RENDERER_H
