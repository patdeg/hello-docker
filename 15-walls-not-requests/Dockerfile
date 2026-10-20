# The "latched windows" version. Two walls instead of one rule:
#
#   1. The robot runs as an ordinary user ("robot"), not root.
#   2. The robot's program belongs to ROOT and is read-only. The robot can
#      read it and run it, but it does not own it, so it cannot change it.
FROM alpine:3.20

# -D = no password, -H = no home directory, -u = a fixed, unusual user number
RUN adduser -D -H -u 10001 robot

COPY robot.sh /app/robot.sh

# COPY makes files owned by root. We keep it that way on purpose, and make
# the folder and file read-only for everybody (a = everybody, r = read, x = run).
#
# Compare with lesson 10, which did `chown -R app:app /www`. That was fine for
# web pages, but for a PROGRAM it would hand the robot the key to rewrite
# itself. The app only needs to READ its code, so that's all we give it.
RUN chmod a=rx /app && chmod a=r /app/robot.sh

USER robot

CMD ["sh", "/app/robot.sh"]
