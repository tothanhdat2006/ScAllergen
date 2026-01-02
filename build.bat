@echo off
echo Checking if Docker is running...
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker is not running!
    echo Please start Docker Desktop and wait for it to be ready.
    pause
    exit /b 1
)


cd ./src

echo Building Flutter APK...
docker build -t flutter-app .
if %errorlevel% neq 0 (
    echo ERROR: Docker build failed!
    pause
    exit /b 1   
)

echo Extracting APK from the Docker container...
docker create --name temp-container flutter-app

echo Copying APK to host machine...
docker cp temp-container:/src/build/app/outputs/flutter-apk/app-release.apk .

echo Cleaning up temporary container...
docker rm temp-container

echo Done! APK saved to current directory.
pause