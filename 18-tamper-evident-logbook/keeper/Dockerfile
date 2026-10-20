# Lesson 17's keeper, upgraded: every line it writes is chained to the line
# before it with a SHA-256 fingerprint.
FROM alpine:3.20

RUN adduser -D -H -u 10002 keeper \
 && mkdir /logs && chown keeper:keeper /logs

COPY chain-append.sh /keeper/chain-append.sh
RUN chmod a=rx /keeper && chmod a=rx /keeper/chain-append.sh

USER keeper
CMD ["nc", "-lk", "-p", "5140", "-e", "/keeper/chain-append.sh"]
