#include "gdi_renderer.h"

#ifdef _WIN32
#include <windows.h>

void gdi_draw_pixels(
    uint64_t hwnd,
    const uint8_t* pixels,
    int32_t width,
    int32_t height
) {
    HWND hWnd = (HWND)hwnd;
    HDC hdc = GetDC(hWnd);
    if (!hdc) return;

    // Create BITMAPINFO for DIB section
    BITMAPINFO bmi = {0};
    bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bmi.bmiHeader.biWidth = width;
    bmi.bmiHeader.biHeight = -height; // Top-down
    bmi.bmiHeader.biPlanes = 1;
    bmi.bmiHeader.biBitCount = 32; // RGBA
    bmi.bmiHeader.biCompression = BI_RGB;

    // Draw pixels using StretchDIBits
    StretchDIBits(
        hdc,
        0, 0, width, height,  // Destination
        0, 0, width, height,  // Source
        pixels,
        &bmi,
        DIB_RGB_COLORS,
        SRCCOPY
    );

    ReleaseDC(hWnd, hdc);
}

#else

// Stub for non-Windows platforms
void gdi_draw_pixels(
    uint64_t hwnd,
    const uint8_t* pixels,
    int32_t width,
    int32_t height
) {
    // No-op on non-Windows
}

#endif
