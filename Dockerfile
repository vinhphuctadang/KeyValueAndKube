FROM node:8

RUN mkdir /app
ADD ./app /app
COPY ./app /app
WORKDIR /app
RUN npm install

CMD node index.js
