FROM python:3.12-alpine

RUN addgroup -S app && adduser -S app -G app

WORKDIR /www
COPY www/ .
RUN chown -R app:app /www
USER app

EXPOSE 8000

# Docker will run this command periodically INSIDE the container to decide
# whether it's "healthy". python3.12-alpine doesn't ship curl/wget by
# default, so we use Python itself to make the request.
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/', timeout=2)" || exit 1

CMD ["python3", "-m", "http.server", "8000"]
