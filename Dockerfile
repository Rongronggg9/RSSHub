FROM node:14-buster-slim as dep-builder

#RUN ln -sf /bin/bash /bin/sh  # bash is already the default shell
# these deps are no longer needed since dropping them would not make npm / yarn complain
#RUN \
#    set -ex && \
#    apt-get update && \
#    apt-get install -yq --no-install-recommends \
#        libgconf-2-4 apt-transport-https git dumb-init python3 build-essential \
#    && \
#    apt-get clean && \
#    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# placing ARG statement before RUN statement which need it to avoid cache miss
ARG USE_CHINA_NPM_REGISTRY=0
RUN \
    if [ "$USE_CHINA_NPM_REGISTRY" = 1 ]; then \
    echo 'use npm mirror' ; \
    npm config set registry https://registry.npmmirror.com; \
    fi;

# update npm before copying anything to avoid cache miss
RUN npm i -g npm

COPY ./yarn.lock /app
COPY ./package.json /app

# lazy install Chromium to avoid cache miss
RUN \
    export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true ; \
    yarn --frozen-lockfile --network-timeout 1000000

COPY . /app
RUN node scripts/docker/minify-docker.js


FROM debian:buster-slim as cache-maximizer
# This stage is necessary to limit the cache miss scope.
# With this stage, any modification on package.json won't break the build cache of the next stage as long as the version
# of puppeteer unchanged.

RUN \
    set -ex && \
    apt-get update && \
    apt-get install -yq --no-install-recommends \
        dumb-init \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY ./package.json /app
RUN grep -Po '(?<="puppeteer": ")[^"]*' package.json | tee .puppeteer_version


FROM node:14-buster-slim as app

LABEL MAINTAINER="https://github.com/DIYgod/RSSHub/"

ENV NODE_ENV production
ENV TZ Asia/Shanghai

RUN npm i -g npm

WORKDIR /app

# install Chromium deps first to avoid cache miss or disturbing buildkit to build concurrently
ARG PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1
# https://github.com/puppeteer/puppeteer/blob/main/docs/troubleshooting.md#chrome-headless-doesnt-launch-on-unix
RUN \
    if [ "$PUPPETEER_SKIP_CHROMIUM_DOWNLOAD" = 0 ]; then \
    set -ex && \
    apt-get update && \
    apt-get install -yq --no-install-recommends \
        ca-certificates fonts-liberation libappindicator3-1 libasound2 libatk-bridge2.0-0 libatk1.0-0 libc6 libcairo2 \
        libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 libgcc1 libglib2.0-0 libgtk-3-0 libnspr4 libnss3 \
        libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 \
        libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 lsb-release wget xdg-utils \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* ; \
    fi;

# install Chromium first to avoid cache miss or disturbing buildkit to build concurrently
COPY --from=cache-maximizer /app/.puppeteer_version /app/.puppeteer_version
# https://github.com/puppeteer/puppeteer#q-why-doesnt-puppeteer-vxxx-work-with-chromium-vyyy
RUN \
    if [ "$PUPPETEER_SKIP_CHROMIUM_DOWNLOAD" = 0 ]; then \
    echo 'Downloading Chromium...' ; \
    unset PUPPETEER_SKIP_CHROMIUM_DOWNLOAD ; \
    npm i puppeteer@$(cat /app/.puppeteer_version) ; \
    fi;

COPY --from=cache-maximizer /usr/bin/dumb-init /usr/bin/dumb-init
COPY --from=dep-builder /app/app-minimal/node_modules /app/node_modules
COPY . /app

EXPOSE 1200
ENTRYPOINT ["dumb-init", "--"]

CMD ["npm", "run", "start"]
