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

# Copy the source (except anything in .dockerignore) and AOT compile it.
COPY . .
RUN dart pub get --offline && dart compile exe lib/main.dart -o /server

# The sqlite3 package opens the system's `libsqlite3.so` through FFI: copy it next to the libc of
# the AOT runtime (plus any dependency the runtime lacks). `scratch` has no /tmp either, and the
# zip downloads are built there.
RUN apt-get update && apt-get install -y --no-install-recommends libsqlite3-0 \
    && lib=$(ldconfig -p | awk '/libsqlite3\.so\.0 /{print $NF; exit}') \
    && libdir=$(dirname "$(find /runtime -name 'libc.so.6' | head -n 1)") \
    && cp -L "$lib" "$libdir/libsqlite3.so" \
    && for dep in $(ldd "$lib" | awk '/=>/{print $3}'); do \
         [ -e "$libdir/$(basename "$dep")" ] || cp -L "$dep" "$libdir/"; \
       done \
    && mkdir -p -m 1777 /runtime/tmp

# Minimal serving image: the AOT runtime of the base image, sqlite and the server.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /server /app/server

ENV STORAGE_VOLUME_PATH=/data
VOLUME /data
EXPOSE 8080
CMD ["/app/server"]
