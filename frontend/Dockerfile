FROM node:18-alpine
WORKDIR /usr/app
COPY . /usr/app/
RUN npm install && npm run build
CMD ["npm", "run", "preview"]
