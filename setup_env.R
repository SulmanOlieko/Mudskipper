setwd("~/Mudskipper")
env_vars <- c(
  SHINY_PORT = "8000",
  SHINY_HOST = "127.0.0.1",
  GEMINI_API_KEY = "",
  GOOGLE_CLIENT_ID = "",
  GOOGLE_CLIENT_SECRET = "",
  GITHUB_CLIENT_ID = "",
  GITHUB_CLIENT_SECRET = "",
  APP_URL = "http://localhost:8000",
  SMTP_SERVER = "smtps://smtp.gmail.com",
  SMTP_PORT = "465",
  SMTP_USER = "",
  SMTP_PASSWORD = ""
)
env_file <- ".env"
lines <- paste(names(env_vars), env_vars, sep = "=")
writeLines(lines, env_file)
dotenv::load_dot_env()
file.exists(".env")
.rs.restartR()
