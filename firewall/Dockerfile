FROM alpine:latest

RUN apk add --no-cache iptables socat

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]