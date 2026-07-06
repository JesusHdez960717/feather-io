# Use latest stable channel SDK.
FROM dart:3.12.2 AS build

# Resolve app dependencies.
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

# Copy app source code (except anything in .dockerignore) and AOT compile app.
COPY .. .
RUN dart compile exe lib/main.dart -o lib/server

# Build minimal serving image from AOT-compiled `/server`
# and the pre-built AOT-runtime in the `/runtime/` directory of the base image.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/lib/server /app/lib/

# Start server.
EXPOSE 8080
CMD ["/app/lib/server"]
