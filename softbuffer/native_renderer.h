#ifndef NATIVE_RENDERER_H
#define NATIVE_RENDERER_H

#include <stdint.h>

// Window handle type
typedef uint64_t native_window_t;

// Create a window, returns window handle (0 on failure)
native_window_t renderer_create_window(
    int32_t width,
    int32_t height,
    const char* title
);

// Destroy a window
void renderer_destroy_window(native_window_t window);

// Draw RGBA pixel buffer to window
void renderer_present(
    native_window_t window,
    const uint8_t* pixels,
    int32_t width,
    int32_t height
);

// Process window messages (non-blocking)
// Returns 1 if still running, 0 if quit requested
int32_t renderer_process_events(void);

// Check if window is still valid
int32_t renderer_is_window_valid(native_window_t window);

// Get window client area size
int32_t renderer_get_window_width(native_window_t window);
int32_t renderer_get_window_height(native_window_t window);

// Set window title
void renderer_set_window_title(native_window_t window, const char* title);

// Request window redraw
void renderer_request_redraw(native_window_t window);

#endif // NATIVE_RENDERER_H
