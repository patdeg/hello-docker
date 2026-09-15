FROM alpine:3.20

COPY ticker.sh /ticker.sh
RUN chmod +x /ticker.sh

# CMD (not ENTRYPOINT) on purpose: that way `docker run -it --rm ticker sh`
# replaces the ticker with a shell, which is handy for poking around.
CMD ["/ticker.sh"]
