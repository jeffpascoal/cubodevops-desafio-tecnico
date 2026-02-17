FROM node:20-alpine

WORKDIR /app
ENV NODE_ENV=production

RUN apk add --no-cache tini

COPY package*.json ./
RUN if [ -f package-lock.json ]; then npm ci --omit=dev; else npm install --omit=dev; fi

COPY --chown=node:node . .

EXPOSE 3000
USER node

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "index.js"]
