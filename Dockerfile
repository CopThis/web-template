# Sharetribe marketplace (merchagogo). Replaces the GCP buildpack build.
# App Platform can't execute a CNB/buildpack image's launcher run command for a
# pre-built image, so we use an explicit Dockerfile with a plain CMD instead.

FROM node:18-bullseye-slim AS builder
WORKDIR /app

# Build-time REACT_APP_* are baked into the client bundle by sharetribe-scripts
# (create-react-app). Recovered from the live GCP bundle; all client-side public.
ARG REACT_APP_ENV=production
ARG REACT_APP_SHARETRIBE_USING_SSL=true
ARG REACT_APP_SHARETRIBE_SDK_TRANSIT_VERBOSE=false
ARG REACT_APP_SHARETRIBE_SDK_CLIENT_ID
ARG REACT_APP_MARKETPLACE_ROOT_URL
ARG REACT_APP_MARKETPLACE_NAME
ARG REACT_APP_GOOGLE_CLIENT_ID
ARG REACT_APP_STRIPE_PUBLISHABLE_KEY
ENV REACT_APP_ENV=$REACT_APP_ENV \
    REACT_APP_SHARETRIBE_USING_SSL=$REACT_APP_SHARETRIBE_USING_SSL \
    REACT_APP_SHARETRIBE_SDK_TRANSIT_VERBOSE=$REACT_APP_SHARETRIBE_SDK_TRANSIT_VERBOSE \
    REACT_APP_SHARETRIBE_SDK_CLIENT_ID=$REACT_APP_SHARETRIBE_SDK_CLIENT_ID \
    REACT_APP_MARKETPLACE_ROOT_URL=$REACT_APP_MARKETPLACE_ROOT_URL \
    REACT_APP_MARKETPLACE_NAME=$REACT_APP_MARKETPLACE_NAME \
    REACT_APP_GOOGLE_CLIENT_ID=$REACT_APP_GOOGLE_CLIENT_ID \
    REACT_APP_STRIPE_PUBLISHABLE_KEY=$REACT_APP_STRIPE_PUBLISHABLE_KEY

# Install with dev deps (sharetribe-scripts is a devDependency needed to build).
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile
COPY . .
RUN yarn build-web && yarn build-server

FROM node:18-bullseye-slim AS runner
WORKDIR /app
ENV NODE_ENV=production
# Copy the full built app (node_modules incl. full-icu, build/, server/).
COPY --from=builder /app ./

# Server binds process.env.PORT (App Platform sets it).
ENV PORT=8080
EXPOSE 8080
CMD ["yarn", "start"]
