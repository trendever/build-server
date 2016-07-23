# Dockerfile is suitable to run any our go-service

FROM alpine:latest

RUN apk add --no-cache su-exec ca-certificates

RUN addgroup service && \
    adduser -S -G service service

COPY ./container /project

RUN mkdir /var/persistent && chown -R service:service /project /var/persistent

CMD ["su-exec", "service:service", "/bin/sh", "-c", "\
      cd /project; \
      if ! test -f MIGRATED; then  ./service migrate;  touch MIGRATED ; fi; \
      export WEB_ROOT=$PWD; \
      export GOPATH=$PWD:$PWD/vendor; \
      exec ./service start; \
    "]
