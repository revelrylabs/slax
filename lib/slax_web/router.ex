defmodule SlaxWeb.Router do
  use SlaxWeb, :router

  scope "/", SlaxWeb do
    post("/auth", AuthController, :start)
    get("/auth/github_redirect", AuthController, :github_redirect)
    get("/auth/github_callback", AuthController, :github_callback)

    post("/issue", IssueController, :start)
    post("/comment", CommentController, :start)
    post("/tarpon", TarponController, :start)
    post("/project", ProjectController, :start)
    post("/sprint", SprintController, :start)
    post("/slax", SlaxController, :start)

    get("/blockerbot", BlockerbotController, :start)
  end
end
