FROM --platform=$BUILDPLATFORM quay.io/projectquay/golang:1.27 AS builder

ARG TARGETOS
ARG TARGETARCH

WORKDIR /src
COPY go.* ./
RUN go mod download
COPY . .

RUN EXT=""; [ "$TARGETOS" = "windows" ] && EXT=".exe"; \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -o /out/app$EXT . && \
    cp /out/app$EXT /out/app.bin

FROM scratch
COPY --from=builder /out/app.bin /app
ENTRYPOINT ["/app"]
