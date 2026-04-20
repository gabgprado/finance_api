FROM ruby:3.3-alpine

LABEL maintainer="Gabriel Prado"
LABEL ruby_version="3.3"
LABEL app="finance_api"

ENV APP=finance_api
ENV RUBY_VERSION=3.3
ENV RAILS_ENV=development

# Instala dependências do sistema
RUN apk add --update --no-cache \
  bash \
  git \
  build-base \
  curl \
  curl-dev \
  file \
  g++ \
  gcc \
  less \
  libstdc++ \
  libffi-dev \
  libc-dev \
  linux-headers \
  libxml2-dev \
  libxslt-dev \
  libgcrypt-dev \
  make \
  netcat-openbsd \
  openssl \
  openssl-dev \
  pkgconfig \
  tzdata \
  yaml-dev \
  libpq \
  postgresql-dev \
  postgresql-client \
  shared-mime-info \
  ca-certificates

# Define diretório de trabalho fixo
WORKDIR /app

# Instala bundler compatível com Gemfile.lock
COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v "$(grep -A 1 'BUNDLED WITH' Gemfile.lock | tail -1 | tr -d ' ')" \
  && bundle install --jobs 4 --retry 3

# Copia e configura entrypoint customizado
COPY docker-entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/docker-entrypoint.sh

# Copia restante do projeto
COPY . .

# Expõe a porta padrão
EXPOSE 3000

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["server"]
