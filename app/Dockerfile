# ---------- build Flutter Web ----------
FROM ghcr.io/cirruslabs/flutter:3.35.1 AS build
WORKDIR /app

ARG API_BASE_URL=http://localhost:3000
ARG DEMO_MODE=false

COPY pubspec.* ./
RUN flutter pub get

COPY . .
RUN flutter build web --release \
      --dart-define=API_BASE_URL=$API_BASE_URL \
      --dart-define=DEMO_MODE=$DEMO_MODE

# ---------- serve ----------
FROM nginx:alpine AS runtime
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
