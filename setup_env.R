#install.packages("RPostgres")
#install.packages('redux')
#install.packages("pool")
setwd("~/Mudskipper")
env_vars <- c(
  SHINY_PORT = "",
  SHINY_HOST = "",
  GEMINI_API_KEY = "",
  GOOGLE_CLIENT_ID = "",
  GOOGLE_CLIENT_SECRET = "",
  GITHUB_CLIENT_ID = "",
  GITHUB_CLIENT_SECRET = "",
  APP_URL = "",
  SMTP_SERVER = "",
  SMTP_PORT = "",
  SMTP_USER = "",
  SMTP_PASSWORD = "",
  DB_HOST = "",
  DB_PORT = "",
  DB_NAME = "",
  DB_USER = "",
  DB_PASS = "",
  REDIS_HOST = "",
  REDIS_PORT = ""
)
env_file <- ".env"
lines <- paste(names(env_vars), env_vars, sep = "=")
writeLines(lines, env_file)
dotenv::load_dot_env()
file.exists(".env")
.rs.restartR()
