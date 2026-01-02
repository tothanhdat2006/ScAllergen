echo "Building Flutter APK..."
docker build -t flutter-app .

echo "Extracting APK from the Docker container..."
docker create --name temp-container flutter-app

echo "Copying APK to host machine..."
docker cp temp-container:/src/build/app/outputs/flutter-apk/app-release.apk .

echo "Cleaning up temporary container..."
docker rm temp-container