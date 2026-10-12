# Build from console/:
#   docker build -t feather-io-console .
# Run, pointing it at the service as the browser sees it:
#   docker run -p 8081:80 -e SERVICE_URL=http://localhost:8080 -e ADMIN_PREFIX=_admin feather-io-console
#
# The same image works for any service: web/env.js (window.env) is written when the container
# starts, from SERVICE_URL and ADMIN_PREFIX: the envsubst of the nginx image fills
# docker/env.js.template.

FROM debian:trixie-slim AS build

# Bump it with .fvmrc
ARG FLUTTER_VERSION=3.47.1

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Only the tag of the version (not the whole history) and only the web artifacts
RUN git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:${PATH}"
RUN flutter config --no-analytics --no-cli-animations \
    && flutter precache --web --no-android --no-ios --no-linux --no-windows --no-macos

WORKDIR /src

# Resolve dependencies (cached while the pubspec doesn't change)
COPY pubspec.* ./
RUN flutter pub get

# Copy the source (except anything in .dockerignore) and build
COPY . .
RUN flutter build web --release

# Static files on nginx
FROM nginx:1.29.1-alpine
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY docker/env.js.template /etc/nginx/env-templates/env.js.template
COPY --from=build /src/build/web /usr/share/nginx/html

# The envsubst of the image writes the templates into the web folder instead of nginx's config
ENV NGINX_ENVSUBST_TEMPLATE_DIR=/etc/nginx/env-templates \
    NGINX_ENVSUBST_OUTPUT_DIR=/usr/share/nginx/html \
    SERVICE_URL=http://localhost:8080 \
    ADMIN_PREFIX=_admin
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s CMD wget -q --spider http://127.0.0.1/health || exit 1
