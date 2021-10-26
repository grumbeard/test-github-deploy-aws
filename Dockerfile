FROM alpine:latest as base

RUN apk add --upgrade nodejs \
  npm

COPY package* ./

RUN npm install --production-only

COPY . .
CMD npm start