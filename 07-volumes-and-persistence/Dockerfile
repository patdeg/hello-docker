FROM alpine:3.20

# Everything written under /data is meant to survive container restarts,
# as long as it's backed by a volume at run time.
VOLUME /data

CMD ["sh", "-c", "echo \"$(date): container ran\" >> /data/log.txt && cat /data/log.txt"]
