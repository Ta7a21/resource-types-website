FROM concourse/golang-builder as builder
COPY . /src
RUN apt-get update \
     && apt-get install -y --no-install-recommends curl ca-certificates apt-transport-https software-properties-common

# install Node 8.x
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get update && apt-get install -y nodejs

# install Yarn for web UI tests
RUN curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN add-apt-repository "deb https://dl.yarnpkg.com/debian/ stable main"
RUN apt-get update && apt-get -y install yarn

WORKDIR /src/web
RUN yarn install && yarn build

WORKDIR /src/warehouse
ENV CGO_ENABLED 0
RUN go get -d ./... && go get -u github.com/gobuffalo/packr/v2/packr2
RUN packr2 build
RUN go build ./main.go

FROM ubuntu:bionic AS dutyfree
EXPOSE 9090
COPY --from=builder src/warehouse/dutyfree /usr/local/bin/
RUN chmod +x /usr/local/bin/dutyfree

FROM dutyfree
ENTRYPOINT ["dutyfree"]
