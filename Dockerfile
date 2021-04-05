ARG RUBY_VERSION=latest
LABEL org.opencontainers.image.source = "https://github.com/adrubesh/ruby-ide"

FROM ruby:${RUBY_VERSION}
ARG NODE_VERSION=12.22.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    git python g++ make curl;

RUN curl -o node.tar.gz -L https://nodejs.org/dist/latest-v12.x/node-v${NODE_VERSION}-linux-x64.tar.gz; \
    tar xvf node.tar.gz; \
    rm -f node.tar.gz; \
    cp -r /node-v*/bin/* /usr/local/bin/; \
    cp -r /node-v*/include/* /usr/local/include/; \
    cp -r /node-v*/lib/* /usr/local/lib/; \
    cp -r /node-v*/share/* /usr/local/share/;

RUN npm install --global yarn

WORKDIR /home/theia
ADD package.json ./package.json 

RUN yarn --pure-lockfile && \
    NODE_OPTIONS="--max_old_space_size=4096" yarn theia build && \
    yarn theia download:plugins && \
    yarn --production && \
    yarn autoclean --init && \
    echo *.ts >> .yarnclean && \
    echo *.ts.map >> .yarnclean && \
    echo *.spec.* >> .yarnclean && \
    yarn autoclean --force && \
    yarn cache clean

RUN mkdir -p /home/project
ENV HOME /home/theia

EXPOSE 3000
ENV SHELL=/bin/bash \
    THEIA_DEFAULT_PLUGINS=local-dir:/home/theia/plugins
ENV USE_LOCAL_GIT true
ENTRYPOINT [ "node", "/home/theia/src-gen/backend/main.js", "/home/project", "--hostname=0.0.0.0" ]
