:: ================================================================
:: STEP 1: CONDA ENVIRONMENT CHECK & CREATION
:: ================================================================
echo Checking for Conda environment: comfyui-easy...

where conda >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Conda is not found in your PATH. 
    echo Please install Miniconda or Anaconda and try again.
    pause
    exit /b
)

:: Check if the specific environment exists
conda info --envs | findstr /C:"comfyui-easy" >nul
if %errorlevel% neq 0 (
    echo [INFO] Environment 'comfyui-easy' not found. Creating it now...
    call conda create -n comfyui-easy python=3.12 -y
    
    :: DOUBLE CHECK: Did it actually get created?
    conda info --envs | findstr /C:"comfyui-easy" >nul
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to create environment.
        pause
        exit /b
    )
) else (
    echo [INFO] Environment 'comfyui-easy' already exists. Using it.
)

call conda activate comfyui-easy
if %errorlevel% neq 0 (
    echo [ERROR] Could not activate 'comfyui-easy'.
    pause
    exit /b
)

:: ================================================================
:: STEP 2: SETUP VARIABLES & COLORS
:: ================================================================
call :set_colors
set "PIPargs=--no-cache-dir --timeout=1000 --retries 10"
set GIT_LFS_SKIP_SMUDGE=1

:: Set local path for Git if it exists, otherwise rely on system git
for /f "delims=" %%G in ('cmd /c "where.exe git.exe 2>nul"') do (set "GIT_PATH=%%~dpG")
set "path=%GIT_PATH%;%PATH%"

:: Check for Existing ComfyUI Folder
if exist ComfyUI-Easy-Install (
    echo %warning%WARNING:%reset% '%bold%ComfyUI-Easy-Install%reset%' folder already exists!
    echo %green%Move this file to another folder and run it again.%reset%
    echo Press any key to Exit...&Pause>nul
    goto :eof
)

:: Check for Helper-CEI.zip (Required for Tavris1's specific setup)
set "HLPR_NAME=Helper-CEI.zip"
if not exist "%HLPR_NAME%" (
    echo %warning%WARNING:%reset% '%bold%%HLPR_NAME%%reset%' not exists!
    echo %green%Unzip the entire package and try again.%reset%
    echo Press any key to Exit...&Pause>nul
    goto :eof
)

:: Capture start time
for /f "delims=" %%i in ('powershell -command "Get-Date -Format yyyy-MM-dd_HH:mm:ss"') do set start=%%i

echo.
echo %green%Starting Install: Stable PyTorch 2.10 + CUDA 13.0 (RTX 5090)%reset%
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

:: 1. CRITICAL: Install OFFICIAL STABLE PyTorch 2.10.0 (CUDA 13.0) for RTX 5090
echo %yellow%Installing Stable PyTorch 2.10.0 with CUDA 13.0...%reset%
python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130 %PIPargs%

:: 2. Install General Requirements
python -m pip install scikit-build-core %PIPargs%
python -m pip install onnxruntime-gpu %PIPargs%
python -m pip install onnx %PIPargs%
python -m pip install flet %PIPargs%
python -m pip install stringzilla %PIPargs%
python -m pip install transformers %PIPargs%
echo.

:: 3. Install Custom Nodes (From original script)
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

:: Extracting helper folders (The "Magic" of the Tavris1 installer)
cd ..\
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%HLPR_NAME%' -DestinationPath '.' -Force"
cd ComfyUI-Easy-Install

:: Run AutoRun if it exists (Preserves original repo behavior)
if exist ".\Add-Ons\Tools\AutoRun.bat" (
    pushd %cd%
    call ".\Add-Ons\Tools\AutoRun.bat" nopause
    popd
    Title %CEI_Title%
    del  ".\Add-Ons\Tools\AutoRun.bat"
)

:: Capture end time
for /f "delims=" %%i in ('powershell -command "Get-Date -Format yyyy-MM-dd_HH:mm:ss"') do set end=%%i
for /f "delims=" %%i in ('powershell -command "$s=[datetime]::ParseExact('%start%','yyyy-MM-dd_HH:mm:ss',$null); $e=[datetime]::ParseExact('%end%','yyyy-MM-dd_HH:mm:ss',$null); if($e -lt $s){$e=$e.AddDays(1)}; ($e-$s).TotalSeconds"') do set diff=%%i

:: Final Messages
echo %green%::::::::::::::::: Installation Complete ::::::::::::::::%reset%
echo %green%::::::::::::::::: Total Running Time:%red% %diff% %green%seconds%reset%
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
:: https://git-scm.com/
echo %green%::::::::::::::: Installing/Updating%yellow% Git %green%:::::::::::::::%reset%
echo.
winget.exe install --id Git.Git -e --source winget
set "path=%PATH%;%ProgramFiles%\Git\cmd"
echo.
goto :eof

:install_comfyui
:: https://github.com/comfyanonymous/ComfyUI
echo %green%::::::::::::::: Installing%yellow% ComfyUI %green%:::::::::::::::%reset%
echo.
git.exe clone https://github.com/Comfy-Org/ComfyUI ComfyUI

cd ComfyUI

:: Install working version of av
python -m pip install av==16.0.1 %PIPargs%

:: Install Requirements (Using our active Conda env)
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
