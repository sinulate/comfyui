@Echo off&&cd /D %~dp0
set "CEI_Title=ComfyUI-Easy-Install (STABLE GPU)"
Title %CEI_Title%

:: ================================================================
:: STEP 0: PREVENT INTEL CRASHES (The "Affinity" Fix)
:: ================================================================
set KMP_AFFINITY=disabled
set KMP_DUPLICATE_LIB_OK=TRUE

:: ================================================================
:: STEP 1: CONDA ENVIRONMENT CHECK
:: ================================================================
echo Checking for Conda environment: comfyui-easy...

where conda >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Conda is not found in your PATH. 
    pause
    exit /b
)

conda info --envs | findstr /C:"comfyui-easy" >nul
if %errorlevel% neq 0 (
    echo [INFO] Creating 'comfyui-easy' environment...
    call conda create -n comfyui-easy python=3.12 -y
)

call conda activate comfyui-easy

:: ================================================================
:: STEP 2: SETUP VARIABLES
:: ================================================================
call :set_colors
set "PIPargs=--no-cache-dir --timeout=1000 --retries 10"
set GIT_LFS_SKIP_SMUDGE=1

:: Set local path for Git
for /f "delims=" %%G in ('cmd /c "where.exe git.exe 2>nul"') do (set "GIT_PATH=%%~dpG")
set "path=%GIT_PATH%;%PATH%"

:: Check for Existing Folder
if exist ComfyUI-Easy-Install (
    echo %warning%WARNING:%reset% 'ComfyUI-Easy-Install' folder already exists!
    echo %green%Move this file to another folder and run it again.%reset%
    pause
    goto :eof
)

:: Check for Helper Zip
set "HLPR_NAME=Helper-CEI.zip"
if not exist "%HLPR_NAME%" (
    echo %warning%WARNING:%reset% '%HLPR_NAME%' not exists!
    pause
    goto :eof
)

echo.
echo %green%Starting Install: OFFICIAL STABLE PyTorch (2.10 + CU130)%reset%
echo.

:: ================================================================
:: STEP 3: INSTALLATION
:: ================================================================

:: Install/Update Git
call :install_git

:: Create Folder
md "ComfyUI-Easy-Install"
cd "ComfyUI-Easy-Install"

:: Clone ComfyUI
call :install_comfyui

echo %green%::::::::::::::: %yellow%Installing Dependencies%green% :::::::::::::::%reset%
echo.

:: 1. CLEANUP
echo %yellow%Cleaning up old PyTorch versions...%reset%
python -m pip uninstall torch torchvision torchaudio -y

:: 2. INSTALL STABLE (From your screenshot)
echo %yellow%Installing Stable PyTorch 2.10 with CUDA 13.0...%reset%
python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130 %PIPargs%

:: 3. Install General Requirements
python -m pip install scikit-build-core %PIPargs%
python -m pip install onnxruntime-gpu %PIPargs%
python -m pip install onnx %PIPargs%
python -m pip install flet %PIPargs%
python -m pip install stringzilla %PIPargs%
python -m pip install transformers %PIPargs%
echo.

:: 4. Install Custom Nodes
call :get_node https://github.com/Comfy-Org/ComfyUI-Manager                        comfyui-manager
call :get_node https://github.com/yolain/ComfyUI-Easy-Use                        ComfyUI-Easy-Use
call :get_node https://github.com/Fannovel16/comfyui_controlnet_aux                comfyui_controlnet_aux
call :get_node https://github.com/rgthree/rgthree-comfy                            rgthree-comfy
call :get_node https://github.com/MohammadAboulEla/ComfyUI-iTools                comfyui-itools
call :get_node https://github.com/city96/ComfyUI-GGUF                            ComfyUI-GGUF
call :get_node https://github.com/gseth/ControlAltAI-Nodes                        controlaltai-nodes
call :get_node https://github.com/lquesada/ComfyUI-Inpaint-CropAndStitch        comfyui-inpaint-cropandstitch
call :get_node https://github.com/1038lab/ComfyUI-RMBG                            comfyui-rmbg
call :get_node https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite            comfyui-videohelpersuite
call :get_node https://github.com/shiimizu/ComfyUI-TiledDiffusion                ComfyUI-TiledDiffusion
call :get_node https://github.com/kijai/ComfyUI-KJNodes                            comfyui-kjnodes
call :get_node https://github.com/kijai/ComfyUI-WanVideoWrapper                    ComfyUI-WanVideoWrapper
call :get_node https://github.com/1038lab/ComfyUI-QwenVL                        ComfyUI-QwenVL

if not exist ".\ComfyUI\custom_nodes\.disabled" mkdir ".\ComfyUI\custom_nodes\.disabled"

:: Extracting helper folders
cd ..\
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%HLPR_NAME%' -DestinationPath '.' -Force"
cd ComfyUI-Easy-Install

:: Run AutoRun if it exists
if exist ".\Add-Ons\Tools\AutoRun.bat" (
    pushd %cd%
    call ".\Add-Ons\Tools\AutoRun.bat" nopause
    popd
    Title %CEI_Title%
    del  ".\Add-Ons\Tools\AutoRun.bat"
)

:: VERIFY INSTALLATION
echo.
echo %yellow%Verifying Stable GPU Support...%reset%
python -c "import torch; print(f'PyTorch Version: {torch.__version__}'); print(f'CUDA Available: {torch.cuda.is_available()}'); print(f'GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'NONE'}')"

echo %green%::::::::::::::::: Installation Complete ::::::::::::::::%reset%
echo %yellow%::::::::::::::::: Press any key to exit ::::::::::::::::%reset%&Pause>nul
exit

:: ================================================================
:: SUBROUTINES
:: ================================================================

:set_colors
set warning=[33m
set      red=[91m
set    green=[92m
set   yellow=[93m
set     bold=[1m
set    reset=[0m
goto :eof

:install_git
echo %green%::::::::::::::: Installing/Updating%yellow% Git %green%:::::::::::::::%reset%
echo.
winget.exe install --id Git.Git -e --source winget
set "path=%PATH%;%ProgramFiles%\Git\cmd"
echo.
goto :eof

:install_comfyui
echo %green%::::::::::::::: Installing%yellow% ComfyUI %green%:::::::::::::::%reset%
echo.
git.exe clone https://github.com/Comfy-Org/ComfyUI ComfyUI

cd ComfyUI
python -m pip install av==16.0.1 %PIPargs%
echo Installing ComfyUI requirements...
python -m pip install -r requirements.txt %PIPargs%
cd ..\
echo.
goto :eof

:get_node
set "git_url=%~1"
set "git_folder=%~2"
echo %green%::::::::::::::: Installing%yellow% %git_folder% %green%:::::::::::::::%reset%
echo.
git.exe clone %git_url% ComfyUI/custom_nodes/%git_folder%

setlocal enabledelayedexpansion
if exist ".\ComfyUI\custom_nodes\%git_folder%\requirements.txt" (
    for %%F in (".\ComfyUI\custom_nodes\%git_folder%\requirements.txt") do set filesize=%%~zF
    if not !filesize! equ 0 (
        python -m pip install -r ".\ComfyUI\custom_nodes\%git_folder%\requirements.txt" %PIPargs%
    )
)
if exist ".\ComfyUI\custom_nodes\%git_folder%\install.py" (
    for %%F in (".\ComfyUI\custom_nodes\%git_folder%\install.py") do set filesize=%%~zF
    if not !filesize! equ 0 (
    python ".\ComfyUI\custom_nodes\%git_folder%\install.py"
    )
)
endlocal
echo.
goto :eof
