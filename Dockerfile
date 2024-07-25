# syntax=docker/dockerfile:1

# Comments are provided throughout this file to help you get started.
# If you need more help, visit the Dockerfile reference guide at
# https://docs.docker.com/go/dockerfile-reference/

# Want to help us make this template better? Share your feedback here: https://forms.gle/ybq9Krt8jtBL3iCk7

### SINGLE STAGE BUILD
# ARG NODE_VERSION=18.0.0
# FROM node:${NODE_VERSION}-alpine

# Use production node environment by default.
# ENV NODE_ENV production
# WORKDIR /usr/src/app

# Download dependencies as a separate step to take advantage of Docker's caching.
# Leverage a cache mount to /root/.npm to speed up subsequent builds.
# Leverage a bind mounts to package.json and package-lock.json to avoid having to copy them into
# into this layer.
# RUN --mount=type=bind,source=package.json,target=package.json \
#     --mount=type=bind,source=package-lock.json,target=package-lock.json \
#     --mount=type=cache,target=/root/.npm \
#     npm ci --omit=dev

# Run the application as a non-root user.
# USER node

# Copy the rest of the source files into the image.
# COPY . .

# Expose the port that the application listens on.
# EXPOSE 3000

# Run the application.
# CMD node src/index.js

### MULTI STAGE BUILD
ARG NODE_VERSION=18.0.0

# Add a label 'as base' to the 'FROM node:${NODE_VERSION}-alpine', to refer to this build stage in other build stages
FROM node:${NODE_VERSION}-alpine as base
WORKDIR /usr/src/app
EXPOSE 3000

# Add a new build stage labeled 'dev' to install development dependencies and start the container with 'npm run dev'
FROM base as dev
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci --include=dev
USER node
COPY . .
CMD npm run dev

# Add a new build stage labeled 'prod' to omit the dev dependencies and run the application with 'node src/index.js'
FROM base as prod
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev
USER node
COPY . .
CMD node src/index.js

# Add a new build stage labeled 'test' to run tests when building the application
FROM base as test
ENV NODE_ENV test
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci --include=dev
USER node
COPY . .
RUN npm run test

# Use CMD to run command when the container runs
# Use RUN to run commands when the image is being built and the build will fail if the tests fail