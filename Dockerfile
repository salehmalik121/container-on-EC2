FROM node:trixie-slim

WORKDIR /app 

COPY package*.json ./

RUN npm install 

COPY . .

ENV PORT=3001

EXPOSE 3001

RUN npm i -g nodemon

CMD [ "node" , "index.js" ]


