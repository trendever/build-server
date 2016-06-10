# Dockerfile is suitable to run any our go-service

FROM alpine:latest

RUN apk add --no-cache su-exec ca-certificates

RUN addgroup service && \
    adduser -S -G service service

COPY ./service /project

RUN chown -R service:service /project

CMD ["su-exec", "service:service", "/bin/sh", "-c", "\
      cd /project; \
      if ! test -f MIGRATED; then  ./bin/service migrate;  touch MIGRATED ; fi; \
      if test -f start.sh; then exec sh start.sh; else exec ./bin/service start; fi; \
    "]

