FROM alpine:3.20

# Alpine's package manager is "apk". --no-cache avoids leaving the package
# index cached in the image layer (keeps the image smaller).
RUN apk add --no-cache figlet

CMD ["figlet", "Docker!"]
