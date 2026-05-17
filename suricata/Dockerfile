FROM alpine:latest

RUN apk add --no-cache suricata

COPY suricata.yaml /etc/suricata/suricata.yaml
COPY local.rules /var/lib/suricata/rules/local.rules

RUN mkdir -p /var/log/suricata

CMD ["suricata", "-c", "/etc/suricata/suricata.yaml", "-i", "eth0", "-v"]