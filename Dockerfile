# Build stage
FROM rust:1.75-bookworm AS builder

WORKDIR /usr/src/app

# Install SQLite development headers
RUN apt-get update && apt-get install -y libsqlite3-dev && rm -rf /var/lib/apt/lists/*

# Copy manifests
COPY Cargo.toml Cargo.lock ./

# Copy source code and migrations
COPY src ./src
COPY migrations ./migrations
COPY diesel.toml Rocket.toml ./

# Build release binary
RUN cargo build --release

# Runtime stage
FROM debian:bookworm-slim

WORKDIR /app

RUN apt-get update && apt-get install -y libsqlite3-0 ca-certificates && rm -rf /var/lib/apt/lists/*

# Copy binary from builder
COPY --from=builder /usr/src/app/target/release/ai-safety-incidents /app/ai-safety-incidents
COPY Rocket.toml /app/Rocket.toml

# Create directory for SQLite database
RUN mkdir -p /app/data

ENV ROCKET_ADDRESS=0.0.0.0
ENV ROCKET_PORT=8000

EXPOSE 8000

CMD ["/app/ai-safety-incidents"]
