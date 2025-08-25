FROM swift:6.0-jammy AS build
WORKDIR /app
COPY . .
# Build only the CLI product to avoid compiling Apple-only library targets on Linux
RUN swift build -c release --product SpeziRunner

FROM debian:bookworm-slim AS runtime
RUN useradd -m app
WORKDIR /home/app
COPY --from=build /app/.build/release/SpeziRunner /usr/local/bin/SpeziRunner
USER app
ENTRYPOINT ["/usr/local/bin/SpeziRunner"]

