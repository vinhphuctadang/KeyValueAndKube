FROM node:8
RUN mkdir /app
WORKDIR /app
COPY ./app/package.json /app
RUN npm install

COPY ./app /app
CMD node index.js
