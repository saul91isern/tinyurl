#!/bin/sh

docker build --build-arg APP_NAME=${APP_NAME} --build-arg APP_VERSION=${APP_VERSION} -t ${APP_NAME}:${APP_VERSION} .