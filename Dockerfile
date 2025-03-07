### builder
FROM golang:alpine AS builder

WORKDIR /app
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build  -v -o /bin/mmock cmd/mmock/main.go

#####################################################
### release
FROM alpine as release

RUN apk --no-cache add \
    ca-certificates curl

RUN mkdir /config
RUN mkdir /tls

VOLUME /config

COPY tls/server.crt /tls/server.crt
COPY tls/server.key /tls/server.key
COPY --from=builder /bin/mmock /usr/local/bin/mmock

EXPOSE 8082 8083 8084

ENTRYPOINT ["mmock","-config-path","/config","-tls-path","/tls"]
CMD ["-server-ip","0.0.0.0","-console-ip","0.0.0.0"]
HEALTHCHECK --interval=30s --timeout=3s --start-period=3s --retries=2 CMD curl -fsS http://localhost:8082 || exit 1
