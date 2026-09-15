FROM python:3.12-alpine
RUN addgroup -S app && adduser -S app -G app
WORKDIR /www
COPY www/ .
RUN chown -R app:app /www
USER app
EXPOSE 8000
CMD ["python3", "-m", "http.server", "8000"]
