FROM alpine:3.20

# Copy our script from the build context (this folder) into the image.
COPY hello.sh /hello.sh

# Make it executable inside the image.
RUN chmod +x /hello.sh

# ENTRYPOINT is the "fixed" part of the command — harder to override than CMD.
ENTRYPOINT ["/hello.sh"]
