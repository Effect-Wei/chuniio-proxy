# chuniio-proxy (standalone)

This is the standalone build of the `chuniio-proxy` DLL, extracted from segatools.

## Build (MSVC)

```bat
msvc-build.bat build
```

Outputs:
- `dist/bin/x86/chuniio-proxy.dll`
- `dist/bin/x64/chuniio-proxy.dll`

## Build (Docker)

```bat
docker-build.bat
```

## Config

```ini
[chuniio]
path=chuniio-proxy.dll
realPath=path-to-your-real-chuniio.dll

[led]
; Output billboard LED strip data to a named pipe called "\\.\pipe\chuni_led"
cabLedOutputPipe=1
; Output billboard LED strip data to serial
cabLedOutputSerial=0

; Output slider LED data to the named pipe
controllerLedOutputPipe=1
; Output slider LED data to the serial port
controllerLedOutputSerial=0
; Use the OpeNITHM protocol for serial LED output
controllerLedOutputOpeNITHM=0

; Serial port to send data to if using serial output. Default is COM5.
;serialPort=COM5
; Baud rate for serial data (set to 115200 if using OpeNITHM)
;serialBaud=921600

; Data output a sequence of bytes, with JVS-like framing.
; Each "packet" starts with 0xE0 as a sync. To avoid E0 appearing elsewhere,
; 0xD0 is used as an escape character -- if you receive D0 in the output, ignore
; it and use the next sent byte plus one instead.
;
; After the sync is one byte for the board number that was updated, followed by
; the red, green and blue values for each LED.
;
; Board 0 has 53 LEDs:
;   [0]-[49]: snakes through left half of billboard (first column starts at top)
;   [50]-[52]: left side partition LEDs
;
; Board 1 has 63 LEDs:
;   [0]-[59]: right half of billboard (first column starts at bottom)
;   [60]-[62]: right side partition LEDs
;
; Board 2 is the slider and has 31 LEDs:
;   [0]-[31]: slider LEDs right to left BRG, alternating between keys and dividers
```

## Notes

Set `SEGATOOLS_CONFIG_PATH` to override the default `segatools.ini` location.
