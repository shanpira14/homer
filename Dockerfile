# build stage
FROM node:lts-alpine as build-stage

WORKDIR /app

COPY package*.json ./
RUN yarn install --frozen-lockfile

COPY . .
RUN yarn build

# production stage
FROM alpine:3.15

ENV USER lighttpd
ENV GROUP lighttpd
ENV GID 911
ENV UID 911
ENV PORT 8080
ENV SUBFOLDER "/_"

RUN addgroup -S ${GROUP} -g ${GID} && adduser -D -S -u ${UID} ${USER} ${GROUP} && \
    apk add -U --no-cache lighttpd

WORKDIR /www

COPY lighttpd.conf /lighttpd.conf
COPY --from=build-stage --chown=${USER}:${GROUP} /app/dist /www/

USER ${USER}
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:${PORT}/ || exit 1

EXPOSE ${PORT}
VOLUME /www/assets

CMD ["lighttpd", "-D", "-f", "/lighttpd.conf"]
