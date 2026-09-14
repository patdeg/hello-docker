FROM python:3.12-alpine

# By default, containers run as root. If an attacker ever finds a way to
# execute code inside your container, running as root hands them far more
# power than they need — including, in some misconfigurations, a path to
# the host. Always create and switch to a dedicated, unprivileged user.

# -S = "system" account (no password, no home dir clutter needed)
RUN addgroup -S app && adduser -S app -G app

WORKDIR /www
COPY www/ .

# Make sure the app user can actually read the files it needs to serve.
RUN chown -R app:app /www

# Everything from this line down runs as "app", not root — including the
# CMD below, and any `docker exec` shell you open into the container.
USER app

EXPOSE 8000
CMD ["python3", "-m", "http.server", "8000"]
