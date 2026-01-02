FROM ghcr.io/cirruslabs/flutter:stable

WORKDIR /app
COPY src/pubspec.* ./
RUN flutter pub get
COPY src/ .
RUN flutter build apk --release
