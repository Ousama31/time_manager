FROM elixir:1.17-slim AS builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential ca-certificates git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV MIX_ENV=prod

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get --only prod \
    && mix deps.compile

COPY lib lib
COPY priv priv

RUN mix compile \
    && mix phx.digest \
    && mix release

FROM debian:bookworm-slim AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      libstdc++6 \
      libncurses6 \
      openssl \
      postgresql-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV HOME=/app \
    MIX_ENV=prod \
    PHX_SERVER=true \
    PORT=4000

COPY --from=builder /app/_build/prod/rel/time_manager ./
COPY entrypoint.sh ./entrypoint.sh

RUN chmod +x entrypoint.sh

EXPOSE 4000

ENTRYPOINT ["./entrypoint.sh"]
