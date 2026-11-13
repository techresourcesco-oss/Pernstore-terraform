FROM node:18

WORKDIR /usr/src/app

ARG VITE_API_URL=/api
ARG VITE_GOOGLE_CLIENT_ID=1002365365078-ptgtl7jq2uubd0a9cenjb7kvk8346nnk.apps.googleusercontent.com
ARG VITE_STRIPE_PUB_KEY=pk_test_51SNyAoRAFfdynZnnvsXpNcmnvdJviEDNDMKtvdxxu3Dlbu2D9ZfePrITOA9fJBrS1omT0YjDxU83e2ofJVPoHjeb003RJJua03
ARG VITE_PAYSTACK_PUB_KEY=pk_test_51SNyAoRAFfdynZnnvsXpNcmnvdJviEDNDMKtvdxxu3Dlbu2D9ZfePrITOA9fJBrS1omT0YjDxU83e2ofJVPoHjeb003RJJua03

ENV VITE_API_URL=${VITE_API_URL}
ENV VITE_GOOGLE_CLIENT_ID=${VITE_GOOGLE_CLIENT_ID}
ENV VITE_STRIPE_PUB_KEY=${VITE_STRIPE_PUB_KEY}
ENV VITE_PAYSTACK_PUB_KEY=${VITE_PAYSTACK_PUB_KEY}

COPY package*.json ./
RUN npm ci --no-audit --legacy-peer-deps || npm ci --no-audit --legacy-peer-deps --maxsockets 1

COPY . .

RUN npm run build

RUN npm install -g serve

EXPOSE 3000

CMD ["serve", "-s", "dist"]
