# Stage 1: build
FROM swift:6.0.1-jammy AS build

WORKDIR /build

COPY Package.swift Package.resolved ./
RUN swift package resolve

COPY Sources ./Sources
COPY Resources ./Resources
RUN mkdir -p Tests/AppTests

RUN swift build -c release --static-swift-stdlib --product lab1devops

# Stage 2: runtime
FROM ubuntu:22.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        libcurl4 \
        libxml2 \
        ca-certificates \
        tzdata \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --system --create-home --shell /bin/false vapor
WORKDIR /app
RUN chown vapor:vapor /app

COPY --from=build --chown=vapor:vapor /build/.build/release/lab1devops ./
COPY --from=build --chown=vapor:vapor /build/Resources ./Resources

USER vapor

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/health/alive || exit 1

CMD ["/app/lab1devops", "serve", "--hostname", "0.0.0.0", "--port", "8000"]
