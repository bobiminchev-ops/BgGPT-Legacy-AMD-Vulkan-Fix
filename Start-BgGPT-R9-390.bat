@echo off
setlocal
cd /d "%~dp0"

rem Working Vulkan settings for AMD Radeon R9 390 (GCN 2.0 / Hawaii)
set "GGML_VK_DISABLE_F16=1"
set "GGML_VK_DISABLE_ASYNC=1"

if not exist "llama-server.exe" (
    echo ERROR: llama-server.exe is not in this folder.
    echo Place this BAT file beside llama-server.exe.
    pause
    exit /b 1
)

if not exist "BgGPT-Gemma-3-4B-IT-Q6_K.gguf" (
    echo ERROR: BgGPT-Gemma-3-4B-IT-Q6_K.gguf was not found.
    echo Place this BAT file in the folder containing the model.
    pause
    exit /b 1
)

echo Starting BgGPT locally with Vulkan GPU acceleration...
echo Open http://127.0.0.1:8080 after the server finishes loading.
echo Press Ctrl+C in this window to stop the server.
echo.
"llama-server.exe" -m "BgGPT-Gemma-3-4B-IT-Q6_K.gguf" -ngl 99 -fa off -c 2048 --host 127.0.0.1 --port 8080

echo.
echo Server has stopped.
pause
