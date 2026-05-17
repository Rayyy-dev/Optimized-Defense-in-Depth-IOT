FROM alpine:latest

RUN apk add --no-cache fail2ban iptables python3

COPY jail.local /etc/fail2ban/jail.local
COPY suricata-filter.conf /etc/fail2ban/filter.d/suricata.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]