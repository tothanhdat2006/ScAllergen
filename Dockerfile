FROM ghcr.io/cirruslabs/flutter:stable

WORKDIR /src
COPY pubspec.* ./
RUN flutter pub get
COPY . .
RUN flutter build apk --release
