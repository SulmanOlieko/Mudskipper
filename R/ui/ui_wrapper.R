# 2. Define the Wrapper UI (Handles Auth + Main App Visibility)
ui <- fluidPage(
  useShinyjs(),
  # --- NEW: Custom Compile Button Animation ---
  tags$head(
    tags$style(HTML("
      .btn-compiling {
        background-image: linear-gradient(45deg, rgba(255, 255, 255, .15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, .15) 50%, rgba(255, 255, 255, .15) 75%, transparent 75%, transparent) !important;
        background-size: 1rem 1rem !important;
        /* Using a unique name to prevent Tabler from hijacking the animation */
        animation: mudskipper-stripes 1s linear infinite !important;
      }
      
      @keyframes mudskipper-stripes {
        0% { background-position: 1rem 0; }
        100% { background-position: 0 0; }
      }
    "))
  ),
  # ------------------------------------------
  HTML(paste(readLines("www/preloader.html", warn = FALSE), collapse = "\n")),
  # --- 2.1 LOGIN WRAPPER (Visible by Default, Z-Index: 1) ---
  # Strategy: Let it render immediately so it's ready. The preloader covers it.
  div(
    id = "auth_wrapper",
    style = "width: 100%; height: 100vh; display: block;",
    tags$iframe(
      id = "auth_frame",
      src = "sign_in.html",
      style = "width:100%; height:100%; border:none;"
    )
  ),

  # --- 2.2 LOCK WRAPPER ---
  div(
    id = "lock_wrapper",
    style = "width: 100%; height: 100vh; display: none; position: fixed; top: 0; left: 0; z-index: 2000; background: white;",
    tags$iframe(
      id = "lock_frame",
      src = "locked.html",
      style = "width:100%; height:100%; border:none;"
    )
  ),

  # --- 3. MAIN APP WRAPPER (Hidden by Default) ---
  div(
    id = "main_app_wrapper",
    style = "display: none;",
    app_ui # <--- This loads your main app UI defined above
  )
)
