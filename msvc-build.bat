@echo off
setlocal enabledelayedexpansion

set BUILD_DIR=build
set BUILD_DIR_32=%BUILD_DIR%\build32
set BUILD_DIR_64=%BUILD_DIR%\build64
set DIST_DIR=dist
set DIST_DIR_X86=%DIST_DIR%\bin\x86
set DIST_DIR_X64=%DIST_DIR%\bin\x64

REM Set your Visual Studio install path if Visual Studio installation can not be detected
set VS_INSTALLATION=C:\Program Files\Microsoft Visual Studio\2022\Community

if /I "%1"=="build" (
    call :detect-visual-studio
    if ERRORLEVEL 2 exit /b
    if ERRORLEVEL 1 (
        echo Failed to detect Visual Studio installation path.
        echo.
        echo If Visual Studio is installed then edit VS_INSTALLATION in this file
        echo to manually specify Visual Studio install path.
        exit /b
    )

    call :detect-meson
    if ERRORLEVEL 1 (
        echo Meson is not installed.
        exit /b
    )

    set VSVARSALL=!VSVARSALL!
    set MESON=!MESON!

    call :build %2

    echo.
    echo Build done!
    call :dist
    echo Distribution files are copied to %DIST_DIR_X86% and %DIST_DIR_X64%
    exit /b
)

if /I "%1"=="dist" (
    call :dist
    exit /b
)

echo %~nx0 [action] [switch]
echo     build: Build for both x86 and x64
echo        /PROJECTONLY: Only create projects
echo.
echo     dist: Copy outputs to dist/bin/x86 and dist/bin/x64
echo.
exit /b

rem This should work for Visual Studio 2017+
:detect-visual-studio (
    rem Fall back to x86 program directory for MSVC standalone if it can't be found in x64
    set VSWHERE="%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe"
    if not exist %VSWHERE% (
        set VSWHERE="%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
    )

    if exist %VSWHERE% (
        set VSVARSALL=""
        for /f "tokens=* usebackq" %%i in (`%VSWHERE% -products * -find VC\Auxiliary\Build\vcvarsall.bat`) do set VSVARSALL="%%i"
    ) else (
        set VSVARSALL="%VS_INSTALLATION%\VC\Auxiliary\Build\vcvarsall.bat"
    )

    :check-vcvarsall
    if /i %VSVARSALL%=="" (
        echo Microsoft Visual C++ Component is not installed
        echo Install it from Visual Studio Installer
        exit /b 2
    )

    if not exist %VSVARSALL% (
        echo vcvarsall.bat not exists in VS_INSTALLATION,
        echo either Visual C++ Component is not installed
        echo or VS_INSTALLATION is wrong.
        exit /b 1
    )

    exit /b 0
)

:detect-meson (
    set MESON=""
    for /f "tokens=* usebackq" %%i in (`where meson`) do set MESON="%%i"
    if not exist %MESON% (
        exit /b 1
    )

    exit /b 0
)

:build (
    :build_x64 (
        call %VSVARSALL% x64

        if exist %BUILD_DIR_64% (
            %MESON% setup %BUILD_DIR_64% --buildtype release --reconfigure
        ) else (
            %MESON% setup %BUILD_DIR_64% --backend vs --buildtype release
        )

        if /I not "%1"=="/PROJECTONLY" (
            pushd %BUILD_DIR_64%
            msbuild /m /p:Configuration=release /p:Platform=x64 chuniio-proxy.sln
            popd
        )
    )

    :build_x86 (
        call %VSVARSALL% x86

        if exist %BUILD_DIR_32% (
            %MESON% setup %BUILD_DIR_32% --buildtype release --reconfigure
        ) else (
            %MESON% setup %BUILD_DIR_32% --backend vs --buildtype release
        )

        if /I not "%1"=="/PROJECTONLY" (
            pushd %BUILD_DIR_32%
            msbuild /m /p:Configuration=release /p:Platform=Win32 chuniio-proxy.sln
            popd
        )
    )

    call :dist
    exit /b
)

:dist (
    if not exist %DIST_DIR_X86% mkdir %DIST_DIR_X86%
    if not exist %DIST_DIR_X64% mkdir %DIST_DIR_X64%

    if exist %BUILD_DIR_32%\src\chuniio-proxy.dll copy /y %BUILD_DIR_32%\src\chuniio-proxy.dll %DIST_DIR_X86%\chuniio-proxy.dll >nul
    if exist %BUILD_DIR_64%\src\chuniio-proxy.dll copy /y %BUILD_DIR_64%\src\chuniio-proxy.dll %DIST_DIR_X64%\chuniio-proxy.dll >nul

    exit /b
)
