#!/bin/bash
set -e

IMAGE=${IMAGE:-"myobf"}
# make a function to build the image
build_image() {
  IMAGE_NAME=$1
  DOCKERFILE=$2

  echo "Building image. IMAGE=$IMAGE_NAME"
  docker build . \
    --file $DOCKERFILE \
    -t "$IMAGE_NAME"
}

build_image $IMAGE Dockerfile

