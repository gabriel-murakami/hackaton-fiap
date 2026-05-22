FROM ruby:3.3-slim

RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  libyaml-dev \
  curl \
  git \
  nodejs \
  postgresql-client \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ARG UID=1000
ARG GID=1000

RUN addgroup --gid ${GID} appgroup \
 && adduser --disabled-password --gecos "" --uid ${UID} --gid ${GID} appuser

RUN mkdir -p /usr/local/bundle \
 && chown -R appuser:appgroup /usr/local/bundle

COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

USER appuser

WORKDIR /app

RUN mkdir -p tmp/pids log coverage

COPY --chown=appuser:appgroup Gemfile Gemfile.lock ./
RUN bundle install --jobs=4 --retry=3

COPY --chown=appuser:appgroup . .

RUN chown -R appuser:appgroup /app/coverage

EXPOSE 3000

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
