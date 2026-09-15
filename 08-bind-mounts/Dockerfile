FROM python:3.12-alpine

WORKDIR /www

# This page is baked INTO the image at build time. In this lesson we'll run
# the same image with a folder from your computer mounted over /www, and
# watch the baked-in page disappear behind it.
COPY www/ .

EXPOSE 8000
CMD ["python3", "-m", "http.server", "8000"]
