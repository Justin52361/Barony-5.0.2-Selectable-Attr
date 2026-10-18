// Force-included by build-windows.bat for MSVC builds.
// <wingdi.h> defines GetObject -> GetObjectA, which breaks rapidjson's Value::GetObject().
#pragma once
#include <winsock2.h>
#include <windows.h>
#undef GetObject
