# Cross-platform build and test

This repository contains a `Makefile` and a `Dockerfile` for building a Go application for Linux (amd64, arm64), macOS (arm64) and Windows (amd64), and for running tests in a container.

## How it works

- Uses the standard `docker build --platform=<os>/<arch>` (no buildx commands), following the [cross-compilation docs](https://docs.docker.com/build/building/multi-platform/#cross-compilation).
- The builder stage uses `FROM --platform=$BUILDPLATFORM` and compiles natively on the host via `GOOS`/`GOARCH`. No QEMU or Rosetta is needed.
- The base image `quay.io/projectquay/golang` comes from Quay rather than Docker Hub, which avoids Docker Hub licensing and rate limits.
- The final `scratch` image contains only the binary for the target platform.

## Requirements

- `make`.
- The project root must contain `go.mod` and `main.go` (with `package main`). If there is no `go.mod`, run `go mod init <module>`.

## Build

| Command        | Platform             | Purpose                                         |
|----------------|----------------------|-------------------------------------------------|
| `make image`   | host OS/architecture | build for the platform detected via `uname`     |
| `make linux`   | linux/amd64          |                                                 |
| `make arm`     | linux/arm64          | run in a container on Apple Silicon             |
| `make macos`   | darwin/arm64         | binary only, cannot run inside a container      |
| `make windows` | windows/amd64        | runs only on a Windows host                     |

The image tag has the form `<REGISTRY>/<APP>:<VERSION>-<OS>-<ARCH>`, where `VERSION` comes from `git describe`. List images with `docker images`.

## Test

Run in a container (on a Mac with Colima or Docker Desktop, use `make linux`):

```
make linux
docker run --rm <IMAGE_TAG>
response: hello
```

Expected `file` output:

- linux/amd64: `ELF 64-bit ... x86-64`
- linux/arm64: `ELF 64-bit ... ARM aarch64`
- darwin/arm64: `Mach-O 64-bit arm64`
- windows/amd64: `PE32+ executable`

The final image has no shell. To get a shell in the builder stage:

```
docker build --target builder -t app-debug .
docker run --rm -it app-debug sh
```

## Clean up

`make clean` removes the image for the host platform (`docker rmi <IMAGE_TAG>`). For another platform, specify it explicitly:

```
make clean TARGETOS=linux TARGETARCH=arm64
```

## Troubleshooting

| Error | Cause and fix |
|-------|---------------|
| `failed to parse platform : "" is an invalid OS component` | The legacy builder is in use. Install buildx. |
| `go: no modules specified` / `go.mod file not found` | The project has no `go.mod`. Run `go mod init <module>`. |
| `no Go files in /src` | No `.go` files in the build context root, they are excluded by `.dockerignore`, or the file has a build tag for another OS. |
| `expected 'package', found 'EOF'` | `main.go` is empty. |
| `exec format error` | The image was built for a different architecture than the host or VM. |
| `no such file or directory` when running in `scratch` | The binary is dynamically linked. Build with `CGO_ENABLED=0`. |