defmodule TodolistWeb.Router do
  use TodolistWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", TodolistWeb do
    pipe_through :api

    resources "/users", UserController, except: [:new, :edit] # Added User Resources

    # =========================================================================
    # ADDED: Dedicated /tasks scope for task-user association and CRUD routes
    # EXPLANATION: Defines the nested scope `/api/tasks` required by Page 4 of 
    # the subject. Places the custom `GET /users/:idUser` route before the standard
    # resource mapping to prevent URL parameter conflicts.
    # =========================================================================

    scope "/tasks" do
      get "/users/:idUser", TaskController, :user_tasks
      resources "/", TaskController, except: [:new, :edit] # Added Task Resources
    end

  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:todolist, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: TodolistWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
