#!/bin/bash

docker run --name redis -d \
    -p 6379:6379 \
    --restart unless-stopped \
    redis:7 \
    redis-server --requirepass "${redis_password}"