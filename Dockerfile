FROM alpine:latest

RUN apk add curl jq bash

COPY ./check.sh /check.sh

RUN chmod +x /check.sh

ENTRYPOINT [ "/check.sh" ]