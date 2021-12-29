ARG GO_VER
ARG ALPINE_VER
FROM alpine:${ALPINE_VER} as base

FROM golang:${GO_VER}-alpine AS builder
RUN apk add --no-cache make gcc musl-dev linux-headers git
ADD . /src
WORKDIR /src
RUN make build

FROM alpine:$ALPINE_VER
MAINTAINER PixieChain
COPY --from=builder /src/build /opt/app/
WORKDIR /opt/app
ENTRYPOINT [ "/opt/app/relayer" ]
CMD ["--cliconfig", "/opt/app/conf/config.json"]
