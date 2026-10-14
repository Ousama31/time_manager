defmodule TimeManagerWeb.Router do
  use TimeManagerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug TimeManagerWeb.Plugs.AuthPlug
  end

  scope "/api", TimeManagerWeb do
    pipe_through :api

    # Unauthenticated Public Routes
    scope "/users" do
      post "/sign_up", UserController, :sign_up
      post "/sign_in", AuthController, :sign_in
    end

    scope "/" do
      pipe_through :authenticated

      # to sign out user
      post "/users/sign_out", AuthController, :sign_out

      get "/users/unassigned", UserController, :unassigned
      get "/users/:id/manager", UserController, :manager
      resources "/users", UserController, except: [:new, :edit]

      get "/workingtime/:userID", WorkingtimeController, :index
      get "/workingtime/:userID/:id", WorkingtimeController, :show
      post "/workingtime/:userID", WorkingtimeController, :create
      put "/workingtime/:id", WorkingtimeController, :update
      delete "/workingtime/:id", WorkingtimeController, :delete

      get "/clocks/:userID", ClockController, :show
      post "/clocks/:userID", ClockController, :create
    end
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:time_manager, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: TimeManagerWeb.Telemetry
    end
  end
end
