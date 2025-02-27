#####################################################
# use following command to build a release
#
# docker login artifacts.cnco.tucows.systems
#
# NOTE: replace x.y with the version number
#
# docker buildx build -t artifacts.cnco.tucows.systems/mse-platform-docker/tucows-mmock:latest -t artifacts.cnco.tucows.systems/mse-platform-docker/tucows-mmock:x.y  .
#
# after building push new version
#
# docker push artifacts.cnco.tucows.systems/mse-platform-docker/tucows-mmock:latest
#
# NOTE: replace x.y with the version number
#
# docker push artifacts.cnco.tucows.systems/mse-platform-docker/tucows-mmock:x.y
#
# after it is built, use this to run it
# docker run -it artifacts.cnco.tucows.systems/mse-platform-docker/tucows-mmock:latest
### builder
FROM golang:alpine as builder

WORKDIR /app
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    GOOS=linux GOARCH=amd64 CGO_ENABLED=0 \
    go build -tags netgo -a -v -o /bin/mmock cmd/mmock/main.go

#####################################################
### release
FROM alpine as release

RUN apk --no-cache add \
    ca-certificates curl bash

RUN mkdir /config

# add tucows root ca
RUN curl https://vault.prod-hashicorp-ent.bra2.tucows.systems:8200/v1/pki/ca/pem -o /usr/local/share/ca-certificates/tucows-root-ca-v2.crt -k
RUN update-ca-certificates

VOLUME /config

COPY --from=builder /bin/mmock /usr/local/bin/mmock

EXPOSE 8082 8083 8084

ENTRYPOINT ["mmock","-config-path","/config"]
CMD ["-server-ip","0.0.0.0","-console-ip","0.0.0.0"]
HEALTHCHECK --interval=30s --timeout=3s --start-period=3s --retries=2 CMD curl -fsS http://localhost:8082 || exit 1
