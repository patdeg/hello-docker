# ---- Stage 1: "builder" ----
# This stage has the full Go toolchain, which is huge. It's only used to
# produce a single compiled binary.
FROM golang:1.23-alpine AS builder

WORKDIR /src
COPY hello.go .

# Build a static binary so it runs on the minimal final image with no
# runtime dependencies (no libc, no Go runtime installed, nothing).
RUN CGO_ENABLED=0 go build -o /hello hello.go

# ---- Stage 2: final image ----
# We start a BRAND NEW image here — none of the Go toolchain from the
# builder stage comes along. We only copy the one file we need.
FROM scratch

COPY --from=builder /hello /hello

ENTRYPOINT ["/hello"]
