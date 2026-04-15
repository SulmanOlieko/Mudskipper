  # ---------------- SESSIONS MANAGEMENT UI LOGIC ----------------
  
  # Trigger to refresh the session list
  sessionListTrigger <- reactiveVal(0)
  
  # Refresh list when settings overlay is opened
  observeEvent(input$railSettingsPageBtn, {
    sessionListTrigger(sessionListTrigger() + 1)
  })
  
  # Render the list
  observeEvent(sessionListTrigger(), {
    req(user_session$logged_in)
    uid <- user_session$user_info$user_id
    curr_token <- user_session$token 
    
    con <- get_db_connection()
    if (is.null(con)) {
      message("Database connection failed in sessionListTrigger")
      return()
    }
    sessions <- dbGetQuery(con, "SELECT * FROM active_sessions WHERE user_id = $1 ORDER BY last_active DESC", list(uid))
    poolReturn(con)
    
    html_out <- tagList()
    
    # 1. Current Session Section
    # Safety check: ensure token exists in DB (might be missing if DB was wiped manually)
    curr_sess <- sessions[sessions$token == curr_token, ]
    
    # If current session isn't in DB (edge case), default to empty/placeholder
    current_ip <- if(nrow(curr_sess) > 0) curr_sess$ip_address else "Current"
    current_created <- if(nrow(curr_sess) > 0) {
      tryCatch(format(as.POSIXct(curr_sess$created_at, origin="1970-01-01"), "%d %b %Y, %I:%M %p UTC"), error=function(e) "-")
    } else { "Just now" }
    
    html_out <- tagList(html_out, 
                        tags$h4("Your Sessions"),
                        tags$div(class="card mb-3",
                                 tags$div(class="card-header", tags$h3(class="card-title", "Current Session")),
                                 tags$div(class="card-body",
                                          tags$div(class="row",
                                                   tags$div(class="col",
                                                            tags$div(class="font-weight-medium", "IP Address"),
                                                            tags$div(class="text-muted", current_ip)
                                                   ),
                                                   tags$div(class="col-auto",
                                                            tags$div(class="font-weight-medium", "Session Created At"),
                                                            tags$div(class="text-muted", current_created)
                                                   )
                                          )
                                 )
                        )
    )
    
    # 2. Other Sessions Section
    other_sess <- sessions[sessions$token != curr_token, ]
    
    html_out <- tagList(html_out, tags$h4("Other Sessions"))
    
    if(nrow(other_sess) > 0) {
      list_items <- lapply(1:nrow(other_sess), function(i) {
        row <- other_sess[i,]
        created_str <- tryCatch(format(as.POSIXct(row$created_at, origin="1970-01-01"), "%d %b %Y, %I:%M %p UTC"), error=function(e) "-")
        tags$div(class="list-group-item",
                 tags$div(class="row align-items-center",
                          tags$div(class="col",
                                   tags$strong(row$ip_address),
                                   tags$div(class="text-muted small", paste("Created:", created_str))
                          )
                 )
        )
      })
      
      html_out <- tagList(html_out,
                          tags$p(class="text-muted", "This is a list of other sessions (logins) which are active on your account, not including your current session. Click the \"Clear sessions\" button below to log them out."),
                          tags$div(class="list-group mb-3", list_items),
                          tags$button(
                            class="btn btn-danger w-100",
                            onclick="Shiny.setInputValue('revokeOtherSessions', Math.random())",
                            "Clear sessions" 
                          )
      )
    } else {
      html_out <- tagList(html_out, tags$p(class="text-muted", "No other sessions active."))
    }
    
    # --- CRITICAL FIX: Explicitly clear innerHTML using JS before inserting ---
    shinyjs::runjs("document.getElementById('sessionsListContainer').innerHTML = '';")
    insertUI(selector = "#sessionsListContainer", ui = html_out)
  })
  
  # Handle Revocation (Log out others)
  observeEvent(input$revokeOtherSessions, {
    req(user_session$logged_in)
    uid <- user_session$user_info$user_id
    curr_token <- user_session$token
    
    con <- get_db_connection()
    if (!is.null(con)) {
      # Delete everything for this user EXCEPT the current token
      dbExecute(con, "DELETE FROM active_sessions WHERE user_id = $1 AND token != $2", list(uid, curr_token))
      poolReturn(con)
    } else {
      showTablerAlert("danger", "Database Error", "Could not connect to database to clear sessions.")
    }
    
    showTablerAlert("success", "Sessions Cleared", "All other sessions have been logged out.")
    sessionListTrigger(sessionListTrigger() + 1)
  })

  #==================================================================================

  # Helper function for safe NULL handling (add this near the top)
  `%||%` <- function(x, y) {
    if (is.null(x)) y else x
  }

  # Tabler Alert Helper
  showTablerAlert <- function(
    type = "info",
    heading = "",
    message = "",
    duration = 5000
  ) {
    session$sendCustomMessage(
      'showTablerAlert',
      list(
        type = type,
        heading = heading,
        message = message,
        duration = duration
      )
    )
  }

  # Helper to get the current picture URL (returns NULL for fallback)
  getProfilePicUrl <- reactive({
    userProfileTrigger() # Depend on the trigger

    profile <- loadUserProfile()
    pic_path <- profile$profilePicture

    if (is.null(pic_path) || !nzchar(pic_path)) {
      return(NULL) # Return NULL to signal fallback
    } else {
      return(pic_path) # e.g., "profile_pictures/my_image.png"
    }
  })

  # Helper to generate the <a> tag for navbars
  generateAvatarLinkHTML <- function(avatarClass = "avatar-sm") {
    profile_pic_url <- getProfilePicUrl() # Call reactive

    if (is.null(profile_pic_url)) {
      # Case 1: FALLBACK. Use the user's provided SVG icon.
      # We replace "avatar" with the correct class.
      fallback_html <- sub(
        'class="avatar"',
        paste0('class="avatar ', avatarClass, '"'),
        '<span class="avatar">  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"    viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"    stroke-linecap="round" stroke-linejoin="round" class="icon icon-1 text-muted">    <path d="M8 7a4 4 0 1 0 8 0a4 4 0 0 0 -8 0" />    <path d="M6 21v-2a4 4 0 0 1 4 -4h4a4 4 0 0 1 4 4v2" />  </svg></span>',
        fixed = TRUE
      )
      avatar_content <- HTML(fallback_html)
    } else {
      # Case 2: IMAGE EXISTS. Create the <span> as before.
      avatar_content <- tags$span(
        class = paste("avatar", avatarClass),
        style = paste0("background-image: url(", profile_pic_url, ")"),
        tags$span(class = "badge bg-success")
      )
    }

    # Wrap the generated avatar content (either SVG or image) in the <a> tag
    avatar_tag <- tags$a(
      href = "javascript:void(0);",
      class = "nav-link d-flex lh-1 p-0 px-2",
      `data-bs-toggle` = "dropdown",
      `aria-label` = "Open user menu",
      avatar_content # Add the content here
    )

    return(as.character(avatar_tag))
  }

  # Helper to generate the <span> tag for the profile page
  generateAvatarSpanHTML <- function(avatarClass = "avatar-md") {
    profile_pic_url <- getProfilePicUrl() # Call reactive

    if (is.null(profile_pic_url)) {
      # Case 1: FALLBACK. Use the user's provided SVG icon.
      # We replace "avatar" with the correct class.
      fallback_html <- sub(
        'class="avatar"',
        paste0('class="avatar ', avatarClass, '"'),
        '<span class="avatar">  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"    viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"    stroke-linecap="round" stroke-linejoin="round" class="icon icon-1 text-muted">    <path d="M8 7a4 4 0 1 0 8 0a4 4 0 0 0 -8 0" />    <path d="M6 21v-2a4 4 0 0 1 4 -4h4a4 4 0 0 1 4 4v2" />  </svg></span>',
        fixed = TRUE
      )
      avatar_content <- HTML(fallback_html)
    } else {
      # Case 2: IMAGE EXISTS. Create the <span> as before.
      avatar_content <- tags$span(
        class = paste("avatar", avatarClass),
        style = paste0("background-image: url(", profile_pic_url, ")"),
        tags$span(class = "badge bg-success")
      )
    }

    # This function just returns the span
    return(as.character(avatar_content))
  }

#--Trash and archive helper--#  
  changeProjectStatus <- function(projectId, newStatus) {
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) return(FALSE)
    
    projects <- loadProjects()
    targetIdx <- NULL
    for (i in seq_along(projects)) {
      if (projects[[i]]$id == projectId) {
        targetIdx <- i
        break
      }
    }
    
    if (is.null(targetIdx)) return(FALSE)
    
    oldStatus <- projects[[targetIdx]]$status %||% "active"
    if (oldStatus == newStatus) return(TRUE)
    
    # Define physical paths based on status
    baseDir <- getUserBaseDir(uid)
    paths <- list(
      "active" = file.path(baseDir, "projects"),
      "trashed" = file.path(baseDir, "trashed"),
      "archived" = file.path(baseDir, "archived")
    )
    
    oldDir <- file.path(paths[[oldStatus]], projectId)
    newDir <- file.path(paths[[newStatus]], projectId)
    
    # Move physical folder
    if (dir.exists(oldDir)) {
      if (!dir.exists(paths[[newStatus]])) dir.create(paths[[newStatus]], recursive = TRUE)
      file.rename(oldDir, newDir)
    }
    
    # Update JSON metadata
    projects[[targetIdx]]$status <- newStatus
    projects[[targetIdx]]$lastEdited <- as.character(Sys.time())
    saveProjects(projects)
    
    # Trigger UI refresh
    if (shiny::isRunning()) {
      isolate({
        projectChangeTrigger(projectChangeTrigger() + 1)
      })
    }
    
    # Record activity
    recordDailyActivity(activityType = "projectStatus", details = list(
      projectId = projectId,
      projectName = projects[[targetIdx]]$name,
      status = newStatus
    ))
    
    return(TRUE)
  }
  
  
  
  
  
