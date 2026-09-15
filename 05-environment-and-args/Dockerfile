FROM alpine:3.20

# ARG: only exists at BUILD time. Lets you parameterize the build itself.
ARG GREETING_NAME=World

# ENV: exists at build time AND run time, and becomes a real environment
# variable inside running containers. Here we seed it from the ARG above,
# so it has a default, but it can still be overridden later with `docker run -e`.
ENV GREETING_NAME=${GREETING_NAME}

COPY greet.sh /greet.sh
RUN chmod +x /greet.sh

ENTRYPOINT ["/greet.sh"]
