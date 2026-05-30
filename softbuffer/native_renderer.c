#include <stdint.h>
#include <stdlib.h>

#ifdef _WIN32
// ============================================================================
// Windows Implementation
// ============================================================================
#include <windows.h>

typedef uint64_t native_window_t;

static const char* WINDOW_CLASS_NAME = "MoonBitSoftbufferWindow";
static int class_registered = 0;

typedef struct {
    int32_t width;
    int32_t height;
    int32_t should_close;
} WindowData;

static LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    WindowData* data = (WindowData*)GetWindowLongPtr(hwnd, GWLP_USERDATA);
    
    switch (uMsg) {
        case WM_CREATE: {
            CREATESTRUCT* cs = (CREATESTRUCT*)lParam;
            WindowData* new_data = (WindowData*)malloc(sizeof(WindowData));
            new_data->width = cs->cx;
            new_data->height = cs->cy;
            new_data->should_close = 0;
            SetWindowLongPtr(hwnd, GWLP_USERDATA, (LONG_PTR)new_data);
            return 0;
        }
        case WM_DESTROY: {
            if (data) {
                data->should_close = 1;
            }
            PostQuitMessage(0);
            return 0;
        }
        case WM_SIZE: {
            if (data) {
                data->width = LOWORD(lParam);
                data->height = HIWORD(lParam);
            }
            return 0;
        }
        case WM_PAINT: {
            ValidateRect(hwnd, NULL);
            return 0;
        }
    }
    return DefWindowProc(hwnd, uMsg, wParam, lParam);
}

static void ensure_class_registered(void) {
    if (class_registered) return;
    
    WNDCLASSA wc = {0};
    wc.lpfnWndProc = WindowProc;
    wc.hInstance = GetModuleHandle(NULL);
    wc.lpszClassName = WINDOW_CLASS_NAME;
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    RegisterClassA(&wc);
    class_registered = 1;
}

native_window_t renderer_create_window(int32_t width, int32_t height, const char* title) {
    ensure_class_registered();
    
    RECT rect = {0, 0, width, height};
    AdjustWindowRect(&rect, WS_OVERLAPPEDWINDOW, FALSE);
    
    HWND hwnd = CreateWindowExA(
        0,
        WINDOW_CLASS_NAME,
        title,
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT,
        rect.right - rect.left,
        rect.bottom - rect.top,
        NULL, NULL,
        GetModuleHandle(NULL),
        NULL
    );
    
    if (hwnd) {
        ShowWindow(hwnd, SW_SHOW);
        UpdateWindow(hwnd);
    }
    
    return (native_window_t)(uintptr_t)hwnd;
}

void renderer_destroy_window(native_window_t window) {
    HWND hwnd = (HWND)(uintptr_t)window;
    WindowData* data = (WindowData*)GetWindowLongPtr(hwnd, GWLP_USERDATA);
    if (data) {
        free(data);
    }
    DestroyWindow(hwnd);
}

void renderer_present(native_window_t window, const uint8_t* pixels, int32_t width, int32_t height) {
    renderer_present_rect(window, pixels, 0, 0, width, height);
}

void renderer_present_rect(
    native_window_t window,
    const uint8_t* pixels,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height
) {
    HWND hwnd = (HWND)(uintptr_t)window;
    HDC hdc = GetDC(hwnd);
    if (!hdc) return;
    
    BITMAPINFO bmi = {0};
    bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bmi.bmiHeader.biWidth = width;
    bmi.bmiHeader.biHeight = -height; // Top-down
    bmi.bmiHeader.biPlanes = 1;
    bmi.bmiHeader.biBitCount = 32;
    bmi.bmiHeader.biCompression = BI_RGB;
    
    StretchDIBits(
        hdc,
        x, y, width, height,
        0, 0, width, height,
        pixels,
        &bmi,
        DIB_RGB_COLORS,
        SRCCOPY
    );
    
    ReleaseDC(hwnd, hdc);
}

int32_t renderer_process_events(void) {
    MSG msg;
    while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
        if (msg.message == WM_QUIT) {
            return 0;
        }
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return 1;
}

int32_t renderer_is_window_valid(native_window_t window) {
    return IsWindow((HWND)(uintptr_t)window) ? 1 : 0;
}

int32_t renderer_get_window_width(native_window_t window) {
    HWND hwnd = (HWND)(uintptr_t)window;
    WindowData* data = (WindowData*)GetWindowLongPtr(hwnd, GWLP_USERDATA);
    return data ? data->width : 0;
}

int32_t renderer_get_window_height(native_window_t window) {
    HWND hwnd = (HWND)(uintptr_t)window;
    WindowData* data = (WindowData*)GetWindowLongPtr(hwnd, GWLP_USERDATA);
    return data ? data->height : 0;
}

void renderer_set_window_title(native_window_t window, const char* title) {
    SetWindowTextA((HWND)(uintptr_t)window, title);
}

void renderer_request_redraw(native_window_t window) {
    InvalidateRect((HWND)(uintptr_t)window, NULL, FALSE);
}

#else
// ============================================================================
// Stub Implementation for non-Windows platforms
// ============================================================================

typedef uint64_t native_window_t;

native_window_t renderer_create_window(int32_t width, int32_t height, const char* title) {
    return 0;
}

void renderer_destroy_window(native_window_t window) {}

void renderer_present(native_window_t window, const uint8_t* pixels, int32_t width, int32_t height) {}

void renderer_present_rect(
    native_window_t window,
    const uint8_t* pixels,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height
) {}

int32_t renderer_process_events(void) { return 0; }

int32_t renderer_is_window_valid(native_window_t window) { return 0; }

int32_t renderer_get_window_width(native_window_t window) { return 0; }

int32_t renderer_get_window_height(native_window_t window) { return 0; }

void renderer_set_window_title(native_window_t window, const char* title) {}

void renderer_request_redraw(native_window_t window) {}

#endif
