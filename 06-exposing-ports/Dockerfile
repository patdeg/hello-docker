FROM python:3.12-alpine

WORKDIR /www
COPY www/ .

# EXPOSE is documentation — it tells humans (and some tools) which port the
# container listens on. It does NOT actually publish the port; -p at "docker
# run" time is what does that.
EXPOSE 8000

CMD ["python3", "-m", "http.server", "8000"]
