@echo off
rem Configures and builds Barony (game + editor) with MSVC, vcpkg deps, FMOD and Steamworks (no EOS).
setlocal
set ROOT=%~dp0
rem Override any of these by setting the variable before running this script.
if not defined VCPKG set VCPKG=C:\vcpkg
set VCI=%VCPKG%\installed\x64-windows
if not defined FMOD_SDK set FMOD_SDK=C:\Program Files (x86)\FMOD SoundSystem\FMOD Studio API Windows\api\core
if not defined STEAM_SDK set STEAM_SDK=C:\deps\steamworks_sdk\sdk
if not defined NFD_DIR set NFD_DIR=C:\deps\nfd
set PATH=C:\Program Files\CMake\bin;%PATH%
rem /FI can't take a path with spaces inside CMAKE_CXX_FLAGS, so stage the prelude in C:\deps
if not exist C:\deps\msvc mkdir C:\deps\msvc
copy /y "%ROOT%build-msvc-prelude.h" C:\deps\msvc\build-msvc-prelude.h >nul

cmake -S "%ROOT%." -B "%ROOT%build" -G "Visual Studio 17 2022" -A x64 ^
  -DCMAKE_TOOLCHAIN_FILE=%VCPKG%\scripts\buildsystems\vcpkg.cmake ^
  -DVCPKG_TARGET_TRIPLET=x64-windows ^
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 ^
  -DFMOD_ENABLED=ON ^
  -DFMOD_INCLUDE_DIR="%FMOD_SDK%\inc" ^
  -DFMOD_LIBRARY="%FMOD_SDK%\lib\x64\fmod_vc.lib" ^
  -DSTEAMWORKS_ENABLED=1 ^
  -DSTEAMWORKS_INCLUDE_DIR="%STEAM_SDK%\public" ^
  -DSTEAMWORKS_LIBRARY="%STEAM_SDK%\redistributable_bin\win64\steam_api64.lib" ^
  -DSTEAMWORKS_LIBRARIES="%STEAM_SDK%\redistributable_bin\win64\steam_api64.lib" ^
  -DEOS_ENABLED=0 ^
  "-DCMAKE_CXX_FLAGS=/DWIN32 /D_WINDOWS /EHsc /std:c++17 /D_CRT_SECURE_NO_WARNINGS /DF_CALLBACK=F_CALL /I%VCI%\include /FIC:\deps\msvc\build-msvc-prelude.h" ^
  "-DCMAKE_C_FLAGS=/DWIN32 /D_WINDOWS /I%VCI%\include" ^
  "-DCMAKE_CXX_STANDARD_LIBRARIES=kernel32.lib user32.lib gdi32.lib shell32.lib ole32.lib uuid.lib comdlg32.lib advapi32.lib %VCI%\lib\glew32.lib glu32.lib" ^
  || exit /b 1

cmake --build "%ROOT%build" --config Release -- /m /v:minimal || exit /b 1
echo BUILD OK
