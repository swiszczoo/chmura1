# Build using node
FROM node:18-alpine as build
WORKDIR /usr/app
COPY . /usr/app/
RUN npm install && npm run build

# Run using nginx
FROM nginx:stable-alpine-slim
COPY --from=build /usr/app/dist /var/www/html
COPY nginx/nginx.conf /etc/nginx/nginx.conf
CMD ["nginx", "-g", "daemon off;"]
