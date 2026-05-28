#ifndef WIN_RENDERER_H
#define WIN_RENDERER_H

#include <stdint.h>

// Create a window and return HWND
uint64_t create_render_window(int32_t width, int32_t height, const char* title);

// Draw RGBA pixel buffer to window
void draw_pixels(
    uint64_t hwnd,
    const uint8_t* pixels,
    int32_t width,
    int32_t height
);

// Process window messages (non-blocking)
int32_t process_messages(void);

// Check if window is still open
int32_t is_window_open(uint64_t hwnd);

#endif // WIN_RENDERER_H
