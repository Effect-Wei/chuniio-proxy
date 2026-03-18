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

## Notes

Set `SEGATOOLS_CONFIG_PATH` to override the default `segatools.ini` location.
