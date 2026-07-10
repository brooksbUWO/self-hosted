# Build headscale 0.29.1 with the /android endpoint added.
# The stock image has no /android route; this build patches in the three
# files that add it (same pattern as the existing /apple endpoint).

# headscale v0.29.1 go.mod requires go >= 1.26.4; golang images ship GOTOOLCHAIN=local
FROM golang:1.26.4-alpine@sha256:3ad57304ad93bbec8548a0437ad9e06a455660655d9af011d58b993f6f615648 AS builder

WORKDIR /src

# Fetch the upstream 0.29.1 source tree and verify the tag resolves to the
# expected release commit (guards against a force-pushed or compromised tag)
RUN apk add --no-cache git && \
    git clone --depth 1 --branch v0.29.1 \
        https://github.com/juanfont/headscale.git . && \
    git rev-parse HEAD | grep -qx 636f660caf3ca995fad5a9ed6f1b6b0578637b55

# Overlay the three patched files
COPY headscale-src/hscontrol/templates/android.go   hscontrol/templates/android.go
COPY headscale-src/hscontrol/platform_config.go     hscontrol/platform_config.go
COPY headscale-src/hscontrol/app.go                 hscontrol/app.go

RUN go build -o /headscale ./cmd/headscale

# Runtime image matches upstream base
FROM alpine:3.21@sha256:48b0309ca019d89d40f670aa1bc06e426dc0931948452e8491e3d65087abc07d

RUN apk add --no-cache ca-certificates

COPY --from=builder /headscale /usr/local/bin/headscale

EXPOSE 8080
ENTRYPOINT ["headscale"]
