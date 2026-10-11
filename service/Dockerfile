# Build from service/:
#   docker build -t feather-io .
# Run with the objects and the SQLite database in a volume:
#   docker run -p 8080:8080 -v feather-data:/data \
#     -e FEATHER_ACCESS=… -e FEATHER_SECRET=… -e JWT_SECRET=… -e KEYS_ENCRYPTION_SECRET=… feather-io

FROM dart:3.13.1 AS build

WORKDIR /src

# Resolve app dependencies (cached while the pubspec doesn't change).
COPY pubspec.* ./
RUN dart pub get

# Copy the source (except anything in .dockerignore) and AOT compile it. `dart build cli` also runs
# the build hook of the sqlite3 package, which bundles SQLite: bundle/bin/main and
# bundle/lib/libsqlite3.so. `scratch` has no /tmp, and the zip downloads are built there.
COPY . .
RUN dart pub get --offline && dart build cli -t lib/main.dart -o /out     && mkdir -p -m 1777 /runtime/tmp

# Minimal serving image: the AOT runtime of the base image and the bundle.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /out/bundle/ /app/

ENV STORAGE_VOLUME_PATH=/data
EXPOSE 8080
CMD ["/app/bin/main"]
