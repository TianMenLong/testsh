@echo off
setlocal

REM Number of VMs to create
set NUM_VMS=5

REM Base name for VMs
set BASE_NAME=myvm

REM VM configuration
set CPUS=4
set MEMORY=8G
set DISK=200G

REM Loop to create VMs
for /L %%i in (1,1,%NUM_VMS%) do (
    set VM_NAME=%BASE_NAME%-%%i
    echo Creating VM: %VM_NAME%
    multipass launch --name %VM_NAME% --cpus %CPUS% --mem %MEMORY% --disk %DISK%
    if %errorlevel% neq 0 (
        echo Failed to create VM: %VM_NAME%
        exit /b %errorlevel%
    )
)

echo All VMs created successfully!
endlocal
pause
