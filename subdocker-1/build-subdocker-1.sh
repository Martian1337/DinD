#!/bin/bash

echo "Building subdocker-1 from local Dockerfile..."
if ! docker build -t subdocker-1 ./subdocker-1; then
    echo "Failed to build subdocker-1"
    exit 1
fi

echo "Running subdocker-1..."
if ! docker run --name subdocker-1-container -d subdocker-1; then
    echo "Failed to run subdocker-1"
    exit 1
fi

echo "subdocker-1 is up and running!"
