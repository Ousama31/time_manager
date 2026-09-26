#w'll use official image of elixir 
FROM elixir:1.14

#    Add dependencies for PostgreSQL and Node
RUN apt-get update && apt-get install -y postgresql-client nodejs npm inotify-tools

# Go to the working directory name /app
WORKDIR /app

# Install mix (which is present in the image of Elixir) and phoenix dependencies
RUN mix local.hex --force && mix local.rebar --force

# Copy the application inside the image
COPY . .

# install phoenix dependencies
RUN mix deps.get

#  Install dependencies of JS(node) and launch Webpack.
RUN cd assets && npm install

# create, give permission and execute entrypoint.sh
#execute actions on initialization of the image in a container.
RUN chmod +x entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]