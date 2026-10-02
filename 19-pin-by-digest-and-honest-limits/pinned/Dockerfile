# Which base image do we build on? By default, a TAG (a sticky note).
# Pass --build-arg BASE=alpine@sha256:... to pin it by DIGEST (a fingerprint).
ARG BASE=alpine:3.20
FROM ${BASE}
CMD ["sh", "-c", "echo Built on Alpine $(cat /etc/alpine-release)"]
