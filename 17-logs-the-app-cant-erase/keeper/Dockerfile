# The diary keeper: a tiny log service. It is the ONLY container that can
# write the diary. Other containers send it lines over the network; they
# never touch the diary file themselves.
FROM alpine:3.20

RUN adduser -D -H -u 10002 keeper \
 && mkdir /logs && chown keeper:keeper /logs

COPY append.sh /keeper/append.sh
RUN chmod a=rx /keeper && chmod a=rx /keeper/append.sh

USER keeper

# nc -l -p 5140   listen on port 5140
#      -k         keep listening after each visitor leaves
#      -e PROG    hand each visitor's messages to PROG
CMD ["nc", "-lk", "-p", "5140", "-e", "/keeper/append.sh"]
