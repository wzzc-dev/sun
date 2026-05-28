#ifdef _WIN32
#include <windows.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

static const char* CLASS_NAME = "MoonBitTriangleWindow";

static LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    switch (uMsg) {
        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;
        case WM_PAINT: {
            // The actual painting is done by draw_pixels
            ValidateRect(hwnd, NULL);
            return 0;
        }
    }
    return DefWindowProc(hwnd, uMsg, wParam, lParam);
}

uint64_t create_render_window(int32_t width, int32_t height, const char* title) {
    // Register window class
    WNDCLASSA wc = {0};
    wc.lpfnWndProc = WindowProc;
    wc.hInstance = GetModuleHandle(NULL);
    wc.lpszClassName = CLASS_NAME;
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    RegisterClassA(&wc);

    // Create window
    RECT rect = {0, 0, width, height};
    AdjustWindowRect(&rect, WS_OVERLAPPEDWINDOW, FALSE);

    HWND hwnd = CreateWindowExA(
        0,
        CLASS_NAME,
        title,
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT,
        rect.right - rect.left,
        rect.bottom - rect.top,
        NULL,
        NULL,
        GetModuleHandle(NULL),
        NULL
    );

    if (hwnd) {
        ShowWindow(hwnd, SW_SHOW);
        UpdateWindow(hwnd);
    }

    return (uint64_t)hwnd;
}

void draw_pixels(
    uint64_t hwnd_val,
    const uint8_t* pixels,
    int32_t width,
    int32_t height
) {
    HWND hwnd = (HWND)hwnd_val;
    HDC hdc = GetDC(hwnd);
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

    ReleaseDC(hwnd, hdc);
}

int32_t process_messages(void) {
    MSG msg;
    while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
        if (msg.message == WM_QUIT) {
            return 0; // Window closed
        }
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return 1; // Still running
}

int32_t is_window_open(uint64_t hwnd_val) {
    HWND hwnd = (HWND)hwnd_val;
    return IsWindow(hwnd) ? 1 : 0;
}

#else

// Stubs for non-Windows platforms
#include <stdint.h>

uint64_t create_render_window(int32_t width, int32_t height, const char* title) {
    return 0;
}

void draw_pixels(
    uint64_t hwnd,
    const uint8_t* pixels,
    int32_t width,
    int32_t height
) {
}

int32_t process_messages(void) {
    return 0;
}

int32_t is_window_open(uint64_t hwnd) {
    return 0;
}

#endif
