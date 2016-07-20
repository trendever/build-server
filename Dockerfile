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
      if test -f start.sh; then exec sh ./start.sh; else exec ./service start; fi; \
    "]
