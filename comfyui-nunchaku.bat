@echo off&&cd /d %~dp0
set "node_name=Nunchaku (Conda)"
Title '%node_name%' Installer

:: ================================================================
:: 1. ACTIVATE CONDA ENV
:: ================================================================
call conda activate comfyui-easy || (
    echo [ERROR] Could not activate 'comfyui-easy'. 
    echo Please check your Conda installation.
    pause
    exit /b
)

:: Set colors
call :set_colors

:: Set arguments
set "PIPargs=--no-cache-dir --no-warn-script-location --timeout=1000 --retries 200"

:: ================================================================
:: 2. CHECK VERSIONS
:: ================================================================
call :get_versions

:: ================================================================
:: 3. INSTALLATION
:: ================================================================
echo %green%::::::::::::::: Installing%yellow% %node_name%%reset%
echo.

:: Clone Repo
if not exist "ComfyUI\custom_nodes" (
    echo %red%[ERROR] Could not find ComfyUI\custom_nodes folder!%reset%
    echo Please make sure this script is in your base "ComfyUI-Easy-Install" folder.
    pause
    exit /b
)

if exist "ComfyUI\custom_nodes\ComfyUI-nunchaku" rmdir /s /q "ComfyUI\custom_nodes\ComfyUI-nunchaku"
git.exe clone https://github.com/nunchaku-ai/ComfyUI-nunchaku ComfyUI\custom_nodes\ComfyUI-nunchaku

:: Install Requirements
echo.
echo %yellow%Installing Python Requirements...%reset%
python -m pip install -r ComfyUI\custom_nodes\ComfyUI-nunchaku\requirements.txt %PIPargs%

echo.

:: ================================================================
:: 4. DOWNLOAD & INSTALL WHEEL
:: ================================================================
echo %yellow%Selecting Nunchaku Wheel...%reset%

set "NUNCHAKU_WHL="

:: EXACT MATCH: PyTorch 2.10 + CUDA 13.0 (Official Wheel)
if "%PYTHON_VERSION%"=="3.12" if "%TORCH_VERSION%"=="2.10" if "%CUDA_VERSION%"=="13.0" (
    set "NUNCHAKU_WHL=v1.2.1/nunchaku-1.2.1+cu13.0torch2.10-cp312-cp312-win_amd64.whl"
)

:: Fallback: PyTorch 2.9 + CUDA 13.0 (For other users)
if "%PYTHON_VERSION%"=="3.12" if "%TORCH_VERSION%"=="2.9" if "%CUDA_VERSION%"=="13.0" (
    set "NUNCHAKU_WHL=v1.2.1/nunchaku-1.2.1+cu13.0torch2.9-cp312-cp312-win_amd64.whl"
)

if "%NUNCHAKU_WHL%"=="" (
    echo %red%[ERROR] No matching wheel found for your PyTorch/CUDA version!%reset%
    echo Python: %PYTHON_VERSION% | Torch: %TORCH_VERSION% | CUDA: %CUDA_VERSION%
    echo Please ensure you are running PyTorch 2.10 or 2.9 with CUDA 13.0.
    pause
    exit /b
)

echo.
echo %green%Downloading and Installing: %NUNCHAKU_WHL%%reset%
python -m pip install "https://github.com/nunchaku-ai/nunchaku/releases/download/%NUNCHAKU_WHL%" %PIPargs%


:: ================================================================
:: 5. DOWNLOAD MODEL CONFIGS
:: ================================================================
echo.
echo %yellow%Downloading Model Configs...%reset%
powershell -Command "try { Invoke-WebRequest 'https://nunchaku.tech/cdn/nunchaku_versions.json' -OutFile 'ComfyUI\custom_nodes\ComfyUI-nunchaku\nunchaku_versions.json' -UseBasicParsing -ErrorAction Stop } catch { Write-Host 'Download failed (Non-critical).' }"


:: ================================================================
:: 6. FORCE NUMPY DOWNGRADE (REQUIRED FOR NUNCHAKU)
:: ================================================================
:: Nunchaku binaries WILL CRASH if run with Numpy 2.0+
echo.
echo %yellow%Checking Numpy Compatibility...%reset%
for /f "tokens=*" %%i in ('python -c "import numpy; print(numpy.__version__)"') do set NUMPY_VERSION=%%i
echo Current: %NUMPY_VERSION%

if not "%NUMPY_VERSION%"=="1.26.4" (
	echo %warning%[ATTENTION] Downgrading Numpy to 1.26.4 for Nunchaku compatibility...%reset%
	python -m pip install "numpy==1.26.4" --force-reinstall %PIPargs%
)

:: Final Messages
echo.
echo %green%::::::::::::::: %yellow%Installation Complete%reset%
echo %green%::::::::::::::: %yellow%Press any key to exit%reset%&Pause>nul
exit /b


:: ================================================================
:: SUBROUTINES
:: ================================================================

:set_colors
set warning=[33m
set      red=[91m
set    green=[92m
set   yellow=[93m
set     bold=[97m
set    reset=[0m
goto :eof

:get_versions
echo %green%::::::::::::::: Checking Versions...%reset%
:: Python
for /f "tokens=2" %%i in ('python --version 2^>^&1') do (
    for /f "tokens=1,2 delims=." %%a in ("%%i") do set PYTHON_VERSION=%%a.%%b
)
:: Torch (Parses 2.10.0 -> 2.10)
python -c "import torch; print(torch.__version__)" > temp_torch.txt
for /f "tokens=1,2,3 delims=." %%a in (temp_torch.txt) do set TORCH_VERSION=%%a.%%b
del temp_torch.txt >nul 2>&1
:: CUDA
python -c "import torch; print(torch.version.cuda)" > temp_cuda.txt
for /f "tokens=1,2 delims=." %%a in (temp_cuda.txt) do set CUDA_VERSION=%%a.%%b
del temp_cuda.txt >nul 2>&1

echo Python: %PYTHON_VERSION%
echo Torch:  %TORCH_VERSION%
echo CUDA:   %CUDA_VERSION%
echo.
goto :eof
