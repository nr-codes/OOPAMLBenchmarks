@echo off

REM if memory is an issue uncomment lines below; be careful as it overwrites config files
REM echo increasing memory usage for docker containers; overwriting .wslconfig file
REM copy wslconfig "%USERPROFILE%\.wslconfig"
REM wsl --shutdown

REM echo "waiting for all wsl instances to shutdown"
REM timeout /t 10 /nobreak

start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"

echo Waiting for Docker Desktop to become ready...
:waitloop
docker version >nul 2>&1
if errorlevel 1 (
  timeout /t 2 >nul
  goto waitloop
)
echo Docker is ready!

wsl bash ./docker_local_bash.sh %*
REM del "%USERPROFILE%\.wslconfig"
