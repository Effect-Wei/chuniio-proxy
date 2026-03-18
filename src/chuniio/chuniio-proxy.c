#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <windows.h>

#include "chuniio/chuniio.h"
#include "chuniio/config.h"
#include "chuniio/ledoutput.h"
#include "util/dprintf.h"
#include "util/env.h"

/* Provide a fallback for _countof when building with non-MSVC toolchains */
#ifndef _countof
#define _countof(x) (sizeof(x) / sizeof((x)[0]))
#endif

/*
 * Proxy DLL which reads [chuniio] realPath from segatools.ini and forwards
 * all chuni_io_* calls to the real IO DLL while also emitting LED output
 * using the local ledoutput implementation.
 */

static HMODULE real_dll = NULL;
static bool real_tried = false;

static struct chuni_io_config proxy_cfg;

/* Function pointer types matching the real DLL exports */
typedef uint16_t (*fn_get_api_version_t)(void);
typedef HRESULT (*fn_jvs_init_t)(void);
typedef void (*fn_jvs_read_coin_counter_t)(uint16_t*);
typedef void (*fn_jvs_poll_t)(uint8_t*, uint8_t*);
typedef HRESULT (*fn_slider_init_t)(void);
typedef void (*fn_slider_start_t)(chuni_io_slider_callback_t);
typedef void (*fn_slider_stop_t)(void);
typedef void (*fn_slider_set_leds_t)(const uint8_t*);
typedef HRESULT (*fn_led_init_t)(void);
typedef void (*fn_led_set_colors_t)(uint8_t, uint8_t*);

static fn_get_api_version_t real_get_api_version;
static fn_jvs_init_t real_jvs_init;
static fn_jvs_read_coin_counter_t real_jvs_read_coin_counter;
static fn_jvs_poll_t real_jvs_poll;
static fn_slider_init_t real_slider_init;
static fn_slider_start_t real_slider_start;
static fn_slider_stop_t real_slider_stop;
static fn_slider_set_leds_t real_slider_set_leds;
static fn_led_init_t real_led_init;
static fn_led_set_colors_t real_led_set_colors;

static void load_real_dll_if_needed(void) {
    if (real_dll || real_tried) return;
    real_tried = true;

    wchar_t path[MAX_PATH];
    GetPrivateProfileStringW(L"chuniio", L"realPath", L"", path, _countof(path),
                             get_config_path());

    if (path[0] == L'\0') {
        dprintf(
            "chuniio-proxy: no realPath set in [chuniio] of segatools.ini\n");
        return;
    }

    real_dll = LoadLibraryW(path);
    if (!real_dll) {
        dwprintf(L"chuniio-proxy: failed to load real DLL '%s' (err %u)\n",
                 path, GetLastError());
        return;
    }

    real_get_api_version = (fn_get_api_version_t)GetProcAddress(
        real_dll, "chuni_io_get_api_version");
    real_jvs_init =
        (fn_jvs_init_t)GetProcAddress(real_dll, "chuni_io_jvs_init");
    real_jvs_read_coin_counter = (fn_jvs_read_coin_counter_t)GetProcAddress(
        real_dll, "chuni_io_jvs_read_coin_counter");
    real_jvs_poll =
        (fn_jvs_poll_t)GetProcAddress(real_dll, "chuni_io_jvs_poll");
    real_slider_init =
        (fn_slider_init_t)GetProcAddress(real_dll, "chuni_io_slider_init");
    real_slider_start =
        (fn_slider_start_t)GetProcAddress(real_dll, "chuni_io_slider_start");
    real_slider_stop =
        (fn_slider_stop_t)GetProcAddress(real_dll, "chuni_io_slider_stop");
    real_slider_set_leds = (fn_slider_set_leds_t)GetProcAddress(
        real_dll, "chuni_io_slider_set_leds");
    real_led_init =
        (fn_led_init_t)GetProcAddress(real_dll, "chuni_io_led_init");
    real_led_set_colors = (fn_led_set_colors_t)GetProcAddress(
        real_dll, "chuni_io_led_set_colors");

    dprintf("chuniio-proxy: loaded real DLL %ls\n", path);
}

uint16_t chuni_io_get_api_version(void) {
    load_real_dll_if_needed();
    if (real_get_api_version) {
        return real_get_api_version();
    }

    return 0x0102;  // advertise latest supported by proxy
}

HRESULT chuni_io_jvs_init(void) {
    // Load config for the LED output subsystem
    chuni_io_config_load(&proxy_cfg, get_config_path());

    // Ensure the led mutex exists (same behavior as original implementation)
    led_init_mutex = CreateMutex(NULL, FALSE, NULL);
    if (led_init_mutex == NULL) {
        return E_FAIL;
    }

    load_real_dll_if_needed();

    if (real_jvs_init) {
        return real_jvs_init();
    }

    return S_OK;
}

void chuni_io_jvs_read_coin_counter(uint16_t* out) {
    load_real_dll_if_needed();
    if (real_jvs_read_coin_counter) {
        real_jvs_read_coin_counter(out);
    }
}

void chuni_io_jvs_poll(uint8_t* opbtn, uint8_t* beams) {
    load_real_dll_if_needed();
    if (real_jvs_poll) {
        real_jvs_poll(opbtn, beams);
    }
}

HRESULT chuni_io_slider_init(void) {
    // Initialize LED outputs (slider uses LEDs)
    HRESULT hr = led_output_init(&proxy_cfg);

    load_real_dll_if_needed();
    if (real_slider_init) {
        HRESULT r = real_slider_init();
        if (FAILED(r)) return r;
    }

    return hr;
}

void chuni_io_slider_start(
    chuni_io_slider_callback_t callback) {
    load_real_dll_if_needed();
    if (real_slider_start) {
        real_slider_start(callback);
    }
}

void chuni_io_slider_stop(void) {
    load_real_dll_if_needed();
    if (real_slider_stop) {
        real_slider_stop();
    }
}

void chuni_io_slider_set_leds(const uint8_t* rgb) {
    // Emit LED output locally for slider
    led_output_update(2, rgb);

    load_real_dll_if_needed();
    if (real_slider_set_leds) {
        real_slider_set_leds(rgb);
    }
}

HRESULT chuni_io_led_init(void) {
    HRESULT hr = led_output_init(&proxy_cfg);

    load_real_dll_if_needed();
    if (real_led_init) {
        HRESULT r = real_led_init();
        if (FAILED(r)) return r;
    }

    return hr;
}

void chuni_io_led_set_colors(uint8_t board,
                                                   uint8_t* rgb) {
    // Mirror original behaviour: update local LED outputs
    led_output_update(board, rgb);

    load_real_dll_if_needed();
    if (real_led_set_colors) {
        real_led_set_colors(board, rgb);
    }
}
