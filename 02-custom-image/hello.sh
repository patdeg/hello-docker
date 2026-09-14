#!/bin/sh
echo "Hello from inside a container!"
echo "My hostname is: $(hostname)"
echo "The current time in here is: $(date)"
echo "I am running as user: $(whoami)"
