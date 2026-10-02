# The robot's house for lesson 16. It is lesson 15's latched robot, plus one
# realistic mistake: a leftover "become root" helper.
FROM alpine:3.20

# doas is a small cousin of `sudo`. It is a SETUID program: whoever runs it,
# it starts with root's power, then checks its rule file to decide whether
# to let you keep it. Somebody installed it "for debugging" and wrote a rule
# saying the robot may use it. That rule is the mistake we'll exploit.
RUN apk add --no-cache doas \
 && adduser -D -H -u 10001 robot \
 && echo 'permit nopass robot as root' > /etc/doas.d/robot.conf

COPY robot.sh /app/robot.sh
RUN chmod 555 /app && chmod 444 /app/robot.sh

USER robot
CMD ["sh", "/app/robot.sh"]
