FROM node:8
RUN mkdir /app
WORKDIR /app
COPY package.json /app
RUN npm install

ADD ./app /app
COPY ./app /app
CMD node index.js
