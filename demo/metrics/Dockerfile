FROM golang:1.21.5 AS builder

WORKDIR /src

COPY . .

# Cache for repeated builds
RUN go mod download

RUN go build -mod=readonly -v -o server .

FROM debian:stable-slim

WORKDIR /metrics

# Copy the binary to the production image from the BUILDER stage.
COPY --from=BUILDER /src/server /metrics/server