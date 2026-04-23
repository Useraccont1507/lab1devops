# Stage 1: build
FROM swift:6.0.1-jammy AS build

WORKDIR /build

COPY Package.swift Package.resolved ./
RUN swift package resolve

COPY Sources ./Sources
COPY Resources ./Resources
RUN swift build -c release --static-swift-stdlib 2>&1

# Stage 2: runtime
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    libcurl4 \
    libxml2 \
    ca-certificates \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /build/.build/release/lab1devops /app/
COPY --from=build /build/Resources /app/Resources

EXPOSE 8000

CMD ["/app/lab1devops", "serve", "--hostname", "0.0.0.0", "--port", "8000"]
