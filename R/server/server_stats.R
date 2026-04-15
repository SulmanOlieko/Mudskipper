  # ----------------------------- USAGE STATISTICS SETUP ------------------------------
  app_start_recorded <- reactiveVal(NULL)
  usageStatsTrigger <- reactiveVal(0)

  # Helper function
  `%||%` <- function(x, y) if (is.null(x)) y else x

  # ----------------------------- USAGE STATISTICS FUNCTIONS -----------------------------

  loadUsageStats <- function() {
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return(list())
    }

    sDir <- getUserStatsDir(uid)
    if (is.null(sDir)) {
      return(list())
    }

    userStatsFile <- file.path(sDir, ".usage_stats.json")

    tryCatch(
      {
        if (!file.exists(userStatsFile)) {
          defaultStats <- list(
            userId = uid,
            dailyStats = list(),
            lastUpdated = as.character(Sys.time())
          )
          jsonlite::write_json(
            defaultStats,
            userStatsFile,
            auto_unbox = TRUE,
            pretty = TRUE
          )
        }

        stats_json <- readLines(userStatsFile, warn = FALSE)
        stats_json <- paste(stats_json, collapse = "\n")

        if (nchar(trimws(stats_json)) == 0) {
          return(list(
            userId = uid,
            dailyStats = list(),
            lastUpdated = as.character(Sys.time())
          ))
        }

        stats <- fromJSON(stats_json, simplifyVector = FALSE)
        return(stats)
      },
      error = function(e) {
        message("Error loading usage stats: ", e$message)
        return(list(
          userId = uuid::UUIDgenerate(),
          dailyStats = list(),
          lastUpdated = as.character(Sys.time())
        ))
      }
    )
  }

  saveUsageStats <- function(stats) {
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return(FALSE)
    }

    sDir <- getUserStatsDir(uid)
    if (is.null(sDir)) {
      return(FALSE)
    }

    userStatsFile <- file.path(sDir, ".usage_stats.json")

    tryCatch(
      {
        if (!is.list(stats)) {
          stats <- as.list(stats)
        }

        stats$lastUpdated <- as.character(Sys.time())

        # Keep only last 4 years (1460 days) to support multi-year view
        if (!is.null(stats$dailyStats) && length(stats$dailyStats) > 0) {
          dates <- names(stats$dailyStats)
          if (length(dates) > 0) {
            cutoff_date <- Sys.Date() - 1460
            stats$dailyStats <- stats$dailyStats[
              dates >= as.character(cutoff_date)
            ]
          }
        }

        stats_json <- toJSON(stats, auto_unbox = TRUE, pretty = TRUE)
        writeLines(stats_json, userStatsFile)

        return(TRUE)
      },
      error = function(e) {
        message("Error saving usage stats: ", e$message)
        return(FALSE)
      }
    )
  }

  recordDailyActivity <- function(activityType = "general", details = NULL) {
    # If no user logged in, skip stats
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return(FALSE)
    }

    stats <- loadUsageStats()

    today <- as.character(Sys.Date())

    # Initialize today's stats if needed
    if (is.null(stats$dailyStats[[today]])) {
      stats$dailyStats[[today]] <- list(
        date = today,
        active = TRUE,
        filesEdited = 0,
        projectsOpened = 0,
        compilations = 0,
        totalEdits = 0,
        projectCreate = 0,
        fileCreate = 0,
        fileDelete = 0,
        projectCopy = 0,
        projectStatus = 0,
        profileUpdate = 0,
        sessionDuration = 0,
        activities = list(),
        # NEW: Track unique items to prevent double counting
        uniqueFilesEdited = list(),
        uniqueProjectsOpened = list()
      )
    }

    # Handle different activity types with deduplication
    if (activityType == "fileEdit") {
      # Only count if we have file and project context
      if (!is.null(details$file) && !is.null(details$projectId)) {
        fileKey <- paste0(details$projectId, ":", details$file)

        # Only increment if this file hasn't been edited today
        if (!(fileKey %in% stats$dailyStats[[today]]$uniqueFilesEdited)) {
          stats$dailyStats[[today]]$uniqueFilesEdited <-
            c(stats$dailyStats[[today]]$uniqueFilesEdited, fileKey)
          stats$dailyStats[[today]]$filesEdited <-
            length(stats$dailyStats[[today]]$uniqueFilesEdited)
        }

        # totalEdits can increment (tracks actual edit actions)
        stats$dailyStats[[today]]$totalEdits <-
          stats$dailyStats[[today]]$totalEdits + 1
      }
    } else if (activityType == "projectOpen") {
      # Only count unique projects opened today
      if (!is.null(details$projectId)) {
        if (
          !(details$projectId %in%
            stats$dailyStats[[today]]$uniqueProjectsOpened)
        ) {
          stats$dailyStats[[today]]$uniqueProjectsOpened <-
            c(stats$dailyStats[[today]]$uniqueProjectsOpened, details$projectId)
          stats$dailyStats[[today]]$projectsOpened <-
            length(stats$dailyStats[[today]]$uniqueProjectsOpened)
        }
      }
    } else if (activityType == "compile") {
      # Compiles always count (each one is meaningful)
      stats$dailyStats[[today]]$compilations <-
        stats$dailyStats[[today]]$compilations + 1
    } else if (activityType %in% c("projectCreate", "fileCreate", "fileDelete", "projectCopy", "projectStatus", "profileUpdate")) {
      # Increment specific counters if they exist
      if (!is.null(stats$dailyStats[[today]][[activityType]])) {
        stats$dailyStats[[today]][[activityType]] <- stats$dailyStats[[today]][[activityType]] + 1
      }
    }

    # Record activity with timestamp
    activityEntry <- list(
      timestamp = as.character(Sys.time()),
      type = activityType,
      details = details
    )

    stats$dailyStats[[today]]$activities[[
      length(stats$dailyStats[[today]]$activities) + 1
    ]] <- activityEntry

    saveUsageStats(stats)

    if (exists("usageStatsTrigger")) {
      isolate({
        usageStatsTrigger(usageStatsTrigger() + 1)
      })
    }
  }

  calculateWeightedActivities <- function(dayStats) {
    if (is.null(dayStats)) return(0)
    score <- 0
    if (!is.null(dayStats$filesEdited)) {
      score <- score + (dayStats$filesEdited * 0.2)
    }
    if (!is.null(dayStats$compilations)) {
      score <- score + (dayStats$compilations * 0.5)
    }
    if (!is.null(dayStats$projectsOpened)) {
      score <- score + (dayStats$projectsOpened * 0.05)
    }
    
    # NEW: Add weights for new activity types
    if (!is.null(dayStats$projectCreate)) {
      score <- score + (dayStats$projectCreate * 1.0)
    }
    if (!is.null(dayStats$fileCreate)) {
      score <- score + (dayStats$fileCreate * 0.1)
    }
    if (!is.null(dayStats$fileDelete)) {
      score <- score + (dayStats$fileDelete * 0.1)
    }
    if (!is.null(dayStats$projectCopy)) {
      score <- score + (dayStats$projectCopy * 0.5)
    }
    if (!is.null(dayStats$projectStatus)) {
      score <- score + (dayStats$projectStatus * 0.2)
    }
    if (!is.null(dayStats$profileUpdate)) {
      score <- score + (dayStats$profileUpdate * 0.3)
    }
    
    return(round(score))
  }

  getActivityLevel <- function(stats, date) {
    dateStr <- as.character(date)
    if (is.null(stats$dailyStats[[dateStr]])) return("none")

    dayStats <- stats$dailyStats[[dateStr]]
    score <- calculateWeightedActivities(dayStats)

    if (score == 0) return("none")
    if (score <= 1) return("low")
    if (score <= 3) return("moderate")
    if (score <= 5) return("high")
    return("high")
  }

  generateGitHubHeatmap <- function(period = "year") {
    stats <- loadUsageStats()
    today <- Sys.Date()
    current_year_system <- as.integer(format(today, "%Y"))

    # 1. Determine Date Range based on Period
    # Period can be "year" (current), or a specific year string like "2025"
    if (period == "year") {
        startDate <- as.Date(paste0(current_year_system, "-01-01"))
        endDate <- as.Date(paste0(current_year_system, "-12-31"))
    } else if (grepl("^[0-9]{4}$", period)) {
        selected_year <- as.integer(period)
        startDate <- as.Date(paste0(selected_year, "-01-01"))
        endDate <- as.Date(paste0(selected_year, "-12-31"))
    } else {
        # Fallback to current year
        startDate <- as.Date(paste0(current_year_system, "-01-01"))
        endDate <- as.Date(paste0(current_year_system, "-12-31"))
    }

    # 2. Grid Alignment (Find the Sunday before/on startDate)
    startDayOfWeek <- as.integer(format(startDate, "%w")) # 0=Sun
    gridStartDate <- startDate - startDayOfWeek
    
    # End date adjustment for grid: Find the Saturday after/on endDate
    endDayOfWeek <- as.integer(format(endDate, "%w"))
    gridEndDate <- endDate + (6 - endDayOfWeek)

    # Generate full date sequence
    dateSeq <- seq.Date(from = gridStartDate, to = gridEndDate, by = "day")

    # 3. CSS (Restored to Original Aesthetics)
    css_styles <- "
  <style>
    .gh-container {
       display: inline-block; /* Fits content width */
       padding: 10px;
    }
    .gh-wrapper { 
       display: flex; 
       font-family: -apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;
    }
    
    /* LEFT COLUMN (Days) */
    .gh-col-days { 
       display: flex; 
       flex-direction: column; 
       gap: 4px; /* Gap between day labels */
       padding-top: 25px; /* Pushes Mon/Wed/Fri down to align with squares */
       margin-right: 8px; 
    }
    .gh-day-label { 
       height: 12px; 
       line-height: 12px; 
       color: var(--tblr-body-color); 
       font-size: 11px; /* LARGER TEXT */
       font-weight: 500;
       text-align: right;
    }
    
    /* RIGHT COLUMN (Months + Grid) */
    .gh-col-content { 
       display: flex; 
       flex-direction: column; 
    }
    
    .gh-months-row { 
       display: flex; 
       gap: 4px; 
       height: 20px; 
       margin-bottom: 5px; 
    }
    .gh-month-label { 
       width: 12px; /* Must match .gh-day-cell width */
       font-size: 12px; /* LARGER TEXT */
       font-weight: 600;
       color: var(--tblr-body-color); 
       white-space: nowrap; 
       overflow: visible; 
    }
    
    .gh-heatmap-grid { 
       display: flex; 
       gap: 4px; /* Gap between columns */
    }
    .gh-week { 
       display: flex; 
       flex-direction: column; 
       gap: 4px; /* Gap between rows */
    }
    .gh-day-cell { 
       width: 12px;  /* LARGER SQUARES */
       height: 12px; 
       border-radius: 2px; 
    }
    
    /* COLORS */
    .gh-lvl-0 { background-color: #ebedf0; }
    .gh-lvl-1 { background-color: #9be9a8; }
    .gh-lvl-2 { background-color: #40c463; }
    .gh-lvl-3 { background-color: #30a14e; }
    .gh-lvl-4 { background-color: #216e39; }
    
    /* DARK MODE */
    [data-bs-theme='dark'] .gh-lvl-0 { background-color: #161b22; }
    [data-bs-theme='dark'] .gh-lvl-1 { background-color: #0e4429; }
    [data-bs-theme='dark'] .gh-lvl-2 { background-color: #006d32; }
    [data-bs-theme='dark'] .gh-lvl-3 { background-color: #26a641; }
    [data-bs-theme='dark'] .gh-lvl-4 { background-color: #39d353; }

  </style>
  "

    # 4. Generate Layout Parts
    days_html <- '<div class="gh-col-days">
                  <div class="gh-day-label"></div> <div class="gh-day-label">Mon</div>
                  <div class="gh-day-label"></div> <div class="gh-day-label">Wed</div>
                  <div class="gh-day-label"></div> <div class="gh-day-label">Fri</div>
                  <div class="gh-day-label"></div> </div>'

    months_html <- '<div class="gh-months-row">'
    heatmap_html <- '<div class="gh-heatmap-grid">'

    # Split dates into Weeks (chunks of 7)
    total_days <- length(dateSeq)
    week_indices <- split(1:total_days, ceiling(seq_along(1:total_days) / 7))

    last_month_str <- ""

    for (wk_idx in week_indices) {
      week_dates <- dateSeq[wk_idx]
      current_month_str <- format(week_dates[1], "%b")

      label_text <- ""
      if (current_month_str != last_month_str && week_dates[1] >= startDate) {
        label_text <- current_month_str
        last_month_str <- current_month_str
      }

      months_html <- paste0(months_html, '<div class="gh-month-label">', label_text, '</div>')

      heatmap_html <- paste0(heatmap_html, '<div class="gh-week">')
      for (d in 1:7) {
        if (d <= length(week_dates)) {
          currDate <- week_dates[d]
          
          # Visibility logic for specific year grid
          is_out_of_year <- format(currDate, "%Y") != format(startDate, "%Y")
          is_future <- currDate > today

          if (is_out_of_year) {
             heatmap_html <- paste0(heatmap_html, '<div class="gh-day-cell" style="visibility:hidden;"></div>')
          } else {
            level <- getActivityLevel(stats, currDate)
            if (is_future) level <- "none"

            colorClass <- switch(level,
              "none" = "gh-lvl-0",
              "low" = "gh-lvl-1",
              "moderate" = "gh-lvl-2",
              "high" = "gh-lvl-3", # Use lvl 3 for standard high
              "gh-lvl-0"
            )
            
            # Weighted Count for Tooltip
            ds <- stats$dailyStats[[as.character(currDate)]]
            weighted_count <- calculateWeightedActivities(ds)
            
            # Use trimws to remove leading space from %e (day with space-padding)
            month_day <- trimws(format(currDate, "%B %e"))
            if (weighted_count > 0) {
              tooltip <- sprintf("%d activities on %s", weighted_count, month_day)
            } else {
              tooltip <- sprintf("No activities on %s", month_day)
            }

            heatmap_html <- paste0(
              heatmap_html,
              '<div class="gh-day-cell ', colorClass, '" ',
              'data-ms-tooltip="', tooltip, '"></div>'
            )
          }
        }
      }
      heatmap_html <- paste0(heatmap_html, '</div>')
    }

    months_html <- paste0(months_html, '</div>')
    heatmap_html <- paste0(heatmap_html, '</div>')

    final_html <- paste0(
      css_styles,
      '<div class="gh-container">',
      '<div class="gh-wrapper">',
      days_html,
      '<div class="gh-col-content">',
      months_html,
      heatmap_html,
      '</div>',
      '</div>',
      '</div>',
      # JS to initialize custom singleton tooltip
      '<script>
        (function() {
          var tooltip = document.querySelector(".ms-tooltip");
          if (!tooltip) {
            tooltip = document.createElement("div");
            tooltip.className = "ms-tooltip";
            document.body.appendChild(tooltip);
          }
          
          var grid = document.querySelector(".gh-heatmap-grid");
          if (!grid) return;
          
          grid.addEventListener("mouseover", function(e) {
            var target = e.target.closest(".gh-day-cell");
            if (target && target.dataset.msTooltip) {
              tooltip.textContent = target.dataset.msTooltip;
              tooltip.classList.add("show");
            }
          });
          
          grid.addEventListener("mousemove", function(e) {
            if (tooltip.classList.contains("show")) {
              tooltip.style.left = e.clientX + "px";
              tooltip.style.top = e.clientY + "px";
            }
          });
          
          grid.addEventListener("mouseout", function(e) {
            var target = e.target.closest(".gh-day-cell");
            if (target) {
              tooltip.classList.remove("show");
            }
          });
        })();
      </script>'
    )

    return(final_html)
  }

  getUsageSummary <- function(period = "year") {
    stats <- loadUsageStats()

    endDate <- Sys.Date()
    
    # Handle Year string (e.g., "2025") in getUsageSummary
    if (grepl("^[0-9]{4}$", period)) {
        selected_year <- as.integer(period)
        startDate <- as.Date(paste0(selected_year, "-01-01"))
        endDate <- as.Date(paste0(selected_year, "-12-31"))
    } else {
        startDate <- switch(
          period,
          "week" = endDate - 7,
          "month" = endDate - 30,
          "quarter" = endDate - 90,
          "year" = as.Date(paste0(format(endDate, "%Y"), "-01-01")),
          as.Date(paste0(format(endDate, "%Y"), "-01-01"))
        )
    }

    summary <- list(
      totalDays = 0,
      activeDays = 0,
      filesEdited = 0,
      compilations = 0,
      projectsOpened = 0,
      totalEdits = 0,
      # NEW: Add totals for context
      totalFiles = 0,
      totalProjects = 0
    )

    if (!is.null(stats$dailyStats) && length(stats$dailyStats) > 0) {
      for (dateStr in names(stats$dailyStats)) {
        date <- as.Date(dateStr)
        if (date >= startDate && date <= endDate) {
          dayStats <- stats$dailyStats[[dateStr]]
          summary$totalDays <- summary$totalDays + 1
          if (isTRUE(dayStats$active)) {
            summary$activeDays <- summary$activeDays + 1
          }

          # Use the counts directly (already deduplicated)
          summary$filesEdited <- summary$filesEdited +
            (dayStats$filesEdited %||% 0)
          summary$compilations <- summary$compilations +
            (dayStats$compilations %||% 0)
          summary$projectsOpened <- summary$projectsOpened +
            (dayStats$projectsOpened %||% 0)
          summary$totalEdits <- summary$totalEdits +
            (dayStats$totalEdits %||% 0)
        }
      }
    }

    # Calculate total files across all projects
    projects <- loadProjects()
    if (length(projects) > 0) {
      summary$totalProjects <- length(projects)

      # Count all files across all projects
      totalFileCount <- 0

      uid <- isolate(user_session$user_info$user_id)
      pDir <- if (!is.null(uid)) getUserProjectDir(uid) else NULL

      if (!is.null(pDir)) {
        for (proj in projects) {
          if (!is.null(proj$id)) {
            projDir <- file.path(pDir, proj$id)
            if (dir.exists(projDir)) {
              projectFiles <- list.files(projDir, recursive = TRUE)
              totalFileCount <- totalFileCount + length(projectFiles)
            }
          }
        }
      }
      summary$totalFiles <- totalFileCount
    }

    return(summary)
  }

  output$userActivityTracking <- renderUI({
    trigger <- usageStatsTrigger()
    
    # Get last 4 years dynamically
    current_year <- as.integer(format(Sys.Date(), "%Y"))
    years <- as.character(current_year:(current_year - 3))
    
    currentPeriod <- if (!is.null(input$activityPeriod)) {
      input$activityPeriod
    } else {
      "year"
    }

    blocks_html <- generateGitHubHeatmap(currentPeriod)

    periodText <- if (currentPeriod == "year") {
      as.character(current_year)
    } else if (grepl("^[0-9]{4}$", currentPeriod)) {
      currentPeriod
    } else {
      as.character(current_year)
    }

    # Generate Dynamic Year Dropdown Items
    dropdown_items <- lapply(years, function(y) {
      is_active <- (currentPeriod == y) || (currentPeriod == "year" && y == as.character(current_year))
      sprintf(
        '<a class="dropdown-item %s" href="#" onclick="Shiny.setInputValue(\'activityPeriod\', \'%s\', {priority: \'event\'}); return false;">%s</a>',
        if (is_active) "active" else "",
        y,
        y
      )
    })
    dropdown_html <- paste(dropdown_items, collapse = "\n")

    html <- HTML(paste0(
      '
      <div class="card" style="width: 100%; height: 100%; padding-top: 0; padding-bottom: 0;">
        <div class="card-body">
          <div class="d-flex align-items-center mb-2">
            <h3 class="card-title mb-0">Activity</h3>
            <div class="ms-auto lh-1">
              <div class="dropdown">
                <a class="dropdown-toggle" href="#" data-bs-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                  ', periodText, '
                </a>
                <div class="dropdown-menu dropdown-menu-end">
                  ', dropdown_html, '
                </div>
              </div>
            </div>
          </div>
          
          <div class="d-flex justify-content-center">
             ', blocks_html, '
          </div>
          
          <div class="d-flex align-items-center justify-content-end mt-1 gap-1 small" style="font-size: 0.75rem;">
            <span>Less</span>
            <div class="gh-lvl-0" style="width:12px; height:12px; border-radius:2px;"></div>
            <div class="gh-lvl-1" style="width:12px; height:12px; border-radius:2px;"></div>
            <div class="gh-lvl-2" style="width:12px; height:12px; border-radius:2px;"></div>
            <div class="gh-lvl-3" style="width:12px; height:12px; border-radius:2px;"></div>
            <div class="gh-lvl-4" style="width:12px; height:12px; border-radius:2px;"></div>
            <span>More</span>
          </div>
        </div>
      </div>
    '
    ))

    return(html)
  })

  # Update display when period changes
  observeEvent(input$activityPeriod, {
    usageStatsTrigger(usageStatsTrigger() + 1)
  })

  # ----------------------------- RENDER HOMEPAGE -----------------------------
  output$tabler_home <- renderUI({
    htmlTemplate(
      filename = "www/Mudskipper_home.html",

      homepageNavbarAvatar = HTML(generateAvatarLinkHTML(
        avatarClass = "avatar-sm rounded-circle"
      )),
      profilePageAvatar = HTML(generateAvatarSpanHTML(
        avatarClass = "avatar-md rounded-circle"
      )),
      editorNavbarAvatar = HTML(generateAvatarLinkHTML(
        avatarClass = "avatar-sm rounded-circle"
      )),

      projectTagsCounter = uiOutput("projectTagsCounter"),
      projectsDashboard = uiOutput("projectsDashboard"),
      projects_count = textOutput("projectCount", inline = TRUE),
      countActive = textOutput("countActive", inline = TRUE),
      countArchived = textOutput("countArchived", inline = TRUE),
      countTrashed = textOutput("countTrashed", inline = TRUE),
      dashboardTitle = textOutput("dashboardTitle", inline = TRUE),
      files_count = textOutput("totalFiles", inline = TRUE),
      last_activity = textOutput("lastActivity", inline = TRUE),
      fileUploadContainer = uiOutput("fileUploadContainer"),
      fileUploadContainerNew = uiOutput("fileUploadContainerNew"),
      fileUploadContainerFirst = uiOutput("fileUploadContainerNew"),

      # User profile outputs
      userName = textOutput("userName", inline = TRUE),
      welcomeUserName = textOutput("welcomeUserName", inline = TRUE),
      userInstitution = textOutput("userInstitution", inline = TRUE),
      userEmail = textOutput("userEmail", inline = TRUE),
      userBio = textOutput("userBio", inline = TRUE),

      # userProfilePicture is no longer needed here
      userVerified = textOutput("userVerified", inline = TRUE),
      userCollaborators = textOutput("userCollaborators", inline = TRUE),
      userMemberSince = textOutput("userMemberSince", inline = TRUE),
      editProfilePictureContainer = uiOutput("editProfilePictureContainer"),

      # Activity tracking outputs
      userActivityTracking = htmlOutput("userActivityTracking")
    )
  })

  # Profile picture upload handler
  observeEvent(input$profilePictureUpload, {
    req(input$profilePictureUpload)

    newPath <- handleProfilePictureUpload(input$profilePictureUpload)

    if (!is.null(newPath)) {
      profile <- loadUserProfile()
      profile$profilePicture <- newPath
      saveUserProfile(profile)
      userProfileTrigger(userProfileTrigger() + 1)
      showTablerAlert(
        "success",
        "Profile picture updated",
        "Profile picture updated successfully.",
        5000
      )
    } else {
      showTablerAlert("danger", "Error updating", "Error updating profile picture", 5000)
    }
  })

  # 1. Populate Edit Profile Form (When Overlay Opens)
  observeEvent(input$editProfileBtn, {
    profile <- loadUserProfile()

    # Push values to the UI via JavaScript updates
    # (Since we are using direct HTML inputs in the overlay, not Shiny inputs)
    shinyjs::runjs(sprintf(
      "
      document.getElementById('editProfileUsername').value = '%s';
      document.getElementById('editProfileEmail').value = '%s';
      document.getElementById('editProfileInstitution').value = '%s';
      document.getElementById('editProfileBio').value = '%s';
    ",
      gsub("'", "\\\\'", profile$username),
      gsub("'", "\\\\'", profile$email),
      gsub("'", "\\\\'", profile$institution),
      gsub("'", "\\\\'", gsub("\n", "\\\\n", profile$bio)) # Handle newlines in bio
    ))
  })

  # 2. Save Profile Changes (Text + Dropzone Image)
  observeEvent(input$saveProfileChanges, {
    data <- input$saveProfileChanges
    req(data$username) # Username is required

    profile <- loadUserProfile()

    # Update text fields
    profile$username <- trimws(data$username)
    profile$email <- trimws(data$email)
    profile$institution <- trimws(data$institution)
    profile$bio <- trimws(data$bio)

    # Handle Profile Picture from Dropzone
    # We check if 'dropzoneProfilePic' has been set recently
    picData <- input$dropzoneProfilePic

    if (!is.null(picData)) {
      tryCatch(
        {
          # 1. Create directory (User Scoped)
          uid <- isolate(user_session$user_info$user_id)
          if (is.null(uid)) {
            stop("User not logged in")
          }

          profilePicsDir <- file.path(getUserBaseDir(uid), "profile_pictures")
          if (!dir.exists(profilePicsDir)) {
            dir.create(profilePicsDir, recursive = TRUE)
          }

          # 2. Decode Base64
          dataURI <- picData$data
          base64Data <- sub("^data:.*?;base64,", "", dataURI)
          rawData <- base64enc::base64decode(base64Data)

          # 3. Generate Filename
          fileExt <- tools::file_ext(picData$name)
          if (fileExt == "") {
            fileExt <- "png"
          } # Fallback
          newFileName <- paste0(uuid::UUIDgenerate(), ".", fileExt)
          destPath <- file.path(profilePicsDir, newFileName)

          # 4. Write File
          writeBin(rawData, destPath)

          # 5. Update Profile Path (Relative to project resource path)
          # URL structure: project/<uid>/profile_pictures/<filename>
          profile$profilePicture <- file.path(
            "project",
            uid,
            "profile_pictures",
            newFileName
          )

          # 6. Reset the input so it doesn't trigger again on next save if image wasn't changed
          shinyjs::runjs("Shiny.setInputValue('dropzoneProfilePic', null);")
        },
        error = function(e) {
          showTablerAlert(
            "danger",
            "Error saving",
            "Failed to save profile picture.",
            5000
          )
        }
      )
    }

    # Save to JSON
    success <- saveUserProfile(profile)

    if (success) {
      recordDailyActivity(activityType = "profileUpdate", details = list(
        username = profile$username,
        institution = profile$institution
      ))
      userProfileTrigger(userProfileTrigger() + 1)
      showTablerAlert(
        "success",
        "Profile updated",
        "Your profile has been updated successfully.",
        5000
      )
    } else {
      showTablerAlert(
        "danger",
        "Update failed",
        "There was an error updating your profile.",
        5000
      )
    }
  })

  # ----------------------------- PROFILE PAGE & TIMELINE -----------------------------
  
  renderTimelineHTML <- function() {
    stats <- loadUsageStats()
    if (is.null(stats$dailyStats) || length(stats$dailyStats) == 0) {
      return(HTML('<div class="text-secondary p-4 text-center">No activities recorded yet.</div>'))
    }

    # Flatten all activities from all days into a single list
    all_activities <- list()
    for (day in stats$dailyStats) {
      if (!is.null(day$activities) && length(day$activities) > 0) {
        # Filter out session events
        filtered_day_acts <- Filter(function(act) act$type != "session", day$activities)
        all_activities <- c(all_activities, filtered_day_acts)
      }
    }

    if (length(all_activities) == 0) {
      return(HTML('<div class="text-secondary p-4 text-center">No activities recorded yet.</div>'))
    }

    # Sort latest to earliest
    all_activities <- all_activities[order(sapply(all_activities, function(x) x$timestamp), decreasing = TRUE)]

    # Take latest 50 for the immersive page
    latest_activities <- head(all_activities, 50)

    timeline_items <- lapply(latest_activities, function(act) {
      ts <- as.POSIXct(act$timestamp)
      time_diff <- difftime(Sys.time(), ts, units = "auto")
      
      # Friendly time string
      friendly_time <- if (units(time_diff) == "secs" && time_diff < 60) {
        "Just now"
      } else if (units(time_diff) == "mins" && time_diff < 60) {
        sprintf("%.0f mins ago", time_diff)
      } else if (units(time_diff) == "hours" && time_diff < 24) {
        sprintf("%.0f hours ago", time_diff)
      } else {
        format(ts, "%b %d, %H:%M")
      }

      icon_html <- switch(act$type,
        "fileEdit" = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-1"><path d="M4 20h4l10.5 -10.5a2.828 2.828 0 1 0 -4 -4l-10.5 10.5v4" /><path d="M13.5 6.5l4 4" /></svg>',
        "projectOpen" = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-1"><path d="M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2 -2v-2" /><polyline points="7 9 12 4 17 9" /><line x1="12" y1="4" x2="12" y2="16" /></svg>',
        "compile" = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-1"><path d="M5 12l5 5l10 -10" /></svg>',
        "projectCreate" = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-1 text-success"><path d="M12 5l0 14" /><path d="M5 12l14 0" /></svg>',
        "projectDelete" = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-1 text-danger"><path d="M4 7l16 0" /><path d="M10 11l0 6" /><path d="M14 11l0 6" /><path d="M5 7l1 12a2 2 0 0 0 2 2h8a2 2 0 0 0 2 -2l1 -12" /><path d="M9 7v-3a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v3" /></svg>',
        "projectCopy" = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-1"><path d="M7 7m0 2.667a2.667 2.667 0 0 1 2.667 -2.667h8.666a2.667 2.667 0 0 1 2.667 2.667v8.666a2.667 2.667 0 0 1 -2.667 2.667h-8.666a2.667 2.667 0 0 1 -2.667 -2.667z" /><path d="M4.012 16.737a2.005 2.005 0 0 1 -1.012 -1.737v-10c0 -1.1 .9 -2 2 -2h10c.75 0 1.412 .412 1.737 1.012" /></svg>',
        "projectStatus" = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-1"><path d="M12 12m-9 0a9 9 0 1 0 18 0a9 9 0 1 0 -18 0" /><path d="M12 9l0 3" /><path d="M12 15l.01 0" /></svg>',
        "fileCreate" = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-1 text-success"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2z" /><path d="M12 11l0 6" /><path d="M9 14l6 0" /></svg>',
        "fileDelete" = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-1 text-danger"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2z" /><path d="M9 14l6 0" /></svg>',
        "profileUpdate" = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-1 text-info"><path d="M8 7a4 4 0 1 0 8 0a4 4 0 0 0 -8 0" /><path d="M6 21v-2a4 4 0 0 1 4 -4h4a4 4 0 0 1 4 4v2" /></svg>',
        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-1"><path d="M10.325 4.317c.426 -1.756 2.924 -1.756 3.35 0a1.724 1.724 0 0 0 2.573 1.066c1.543 -.94 3.31 .826 2.37 2.37a1.724 1.724 0 0 0 1.065 2.572c1.756 .426 1.756 2.924 0 3.35a1.724 1.724 0 0 0 -1.066 2.573c.94 1.543 -.826 3.31 -2.37 2.37a1.724 1.724 0 0 0 -2.572 1.065c-.426 1.756 -2.924 1.756 -3.35 0a1.724 1.724 0 0 0 -2.573 -1.066c-1.543 .94 -3.31 -.826 -2.37 -2.37a1.724 1.724 0 0 0 -1.065 -2.572c-1.756 -.426 -1.756 -2.924 0 -3.35a1.724 1.724 0 0 0 1.066 -2.573c-.94 -1.543 .826 -3.31 2.37 -2.37c1 .608 2.296 .07 2.572 -1.065z" /><path d="M9 12a3 3 0 1 0 6 0a3 3 0 0 0 -6 0" /></svg>'
      )

      title <- switch(act$type,
        "fileEdit" = sprintf("Edited %s", act$details$file),
        "projectOpen" = sprintf("Opened project: %s", act$details$projectName %||% act$details$projectId),
        "compile" = "Compiled project",
        "projectCreate" = sprintf("Created project: %s", act$details$name),
        "projectDelete" = sprintf("Deleted project: %s", act$details$name),
        "projectCopy" = sprintf("Duplicated project: %s", act$details$newName),
        "projectStatus" = sprintf("%s project: %s", tools::toTitleCase(act$details$status), act$details$projectName %||% act$details$projectId),
        "fileCreate" = sprintf("Added file: %s", act$details$file),
        "fileDelete" = sprintf("Removed file: %s", act$details$file),
        "profileUpdate" = "Updated profile details",
        sprintf("Event: %s", act$type %||% "Unspecified")
      )

      details_text <- if (!is.null(act$details$details)) {
        sprintf('<p class="text-secondary small mt-1">%s</p>', act$details$details)
      } else if (act$type == "fileCreate" || act$type == "fileDelete" || act$type == "fileEdit") {
        sprintf('<p class="text-secondary small mt-1">In project: %s</p>', act$details$projectName %||% act$details$projectId)
      } else if (act$type == "projectCopy") {
        sprintf('<p class="text-secondary small mt-1">Source: %s</p>', act$details$oldName)
      } else if (act$type == "profileUpdate") {
        sprintf('<p class="text-secondary small mt-1">Username set to: %s</p>', act$details$username)
      } else {
        ""
      }

      sprintf(
        '<li class="timeline-event">
          <div class="timeline-event-icon">%s</div>
          <div class="card timeline-event-card">
            <div class="card-body">
              <div class="text-secondary float-end">%s</div>
              <h4 class="mb-0">%s</h4>
              %s
            </div>
          </div>
        </li>',
        icon_html,
        friendly_time,
        title,
        details_text
      )
    })

    HTML(paste0('<ul class="timeline">', paste(timeline_items, collapse = ""), '</ul>'))
  }

  output$profile_page_ui <- renderUI({
    # Dependency on trigger
    trigger <- usageStatsTrigger()
    
    avatar_html <- generateAvatarSpanHTML(avatarClass = "avatar-github rounded-circle shadow-sm")
    profile <- loadUserProfile()
    
    # Scrollable Timeline Section
    timeline_content <- renderTimelineHTML()
    
    tags$div(
      class = "page",
      tags$div(
        class = "page-wrapper",
        tags$div(
          class = "profile-page-view",
          style = "min-height: 100vh; background: color-mix(in srgb, var(--tblr-primary) 4%, var(--tblr-bg-surface)) !important; padding: 2.5rem 0; font-family: var(--tblr-body-font-family); font-feature-settings: 'cv03', 'cv04', 'cv11';",
          tags$div(
            class = "container-xl",
        # Custom styles for the scrollable container
        tags$head(tags$style("
          .scrollable-timeline-container {
            max-height: 675px;
            overflow-y: auto;
            padding-right: 15px;
            scrollbar-width: thin;
            scrollbar-color: var(--tblr-border-color) transparent;
          }
          .scrollable-timeline-container::-webkit-scrollbar {
            width: 6px;
          }
          .scrollable-timeline-container::-webkit-scrollbar-thumb {
            background-color: var(--tblr-border-color);
            border-radius: 10px;
          }
          .avatar-github {
            width: 120px !important;
            height: 120px !important;
            font-size: 3rem !important;
            line-height: 120px !important;
            border: 3px solid var(--tblr-bg-surface);
          }
        ")),
        
        # Navigation Header
        tags$div(
          class = "d-flex align-items-center mb-5",
          tags$h1(class = "m-0", style = "font-weight: 700;", "User Profile"),
          tags$div(
            class = "ms-auto",
            tags$button(
              class = "btn btn-outline-secondary btn-pill",
              onclick = "if (window.Shiny) Shiny.setInputValue('showDashboard', Date.now(), {priority:'event'});",
              HTML('<svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="19" y1="12" x2="5" y2="12"></line><polyline points="12 19 5 12 12 5"></polyline></svg>'),
              "Back to Dashboard"
            )
          )
        ),
        
        tags$div(
          class = "row g-4",
          # Left Column: Profile Card
          tags$div(
            class = "col-lg-4",
            tags$div(
              class = "card h-100",
              tags$div(
                class = "card-body text-center p-5",
                HTML(avatar_html),
                tags$h2(class = "mt-3 mb-0", textOutput("userName", inline = TRUE)),
                tags$p(class = "text-secondary", textOutput("userInstitution", inline = TRUE)),
                tags$div(class = "hr-text", "About"),
                tags$div(
                  class = "text-start mt-4",
                  tags$label(class = "form-label text-muted small uppercase fw-bold", "Email"),
                  tags$p(class = "mb-3", textOutput("userEmail", inline = TRUE)),
                  tags$label(class = "form-label text-muted small uppercase fw-bold", "Bio"),
                  tags$p(class = "mb-3", textOutput("userBio", inline = TRUE)),
                  tags$label(class = "form-label text-muted small uppercase fw-bold", "Member Since"),
                  tags$p(class = "mb-0", textOutput("userMemberSince", inline = TRUE)),
                  
                  tags$div(class = "hr-text", "Project Composition"),
                  tags$div(
                    class = "mt-3",
                    tags$div(
                      class = "d-flex align-items-center justify-content-between mb-1",
                      tags$span(class = "text-muted small", "Active Projects"),
                      tags$span(class = "fw-bold small", textOutput("pctActive", inline = TRUE))
                    ),
                    uiOutput("activeProjectBar"),
                    tags$div(
                      class = "mt-4",
                      tags$label(class = "form-label text-muted small uppercase fw-bold", "Tag Distribution"),
                      uiOutput("tagDistributionBar"),
                      tags$div(class = "mt-2", uiOutput("tagDistributionLegend"))
                    )
                  )
                )
              ),
              tags$div(
                class = "card-footer text-center bg-transparent",
                tags$button(
                  class = "btn btn-primary w-100",
                  onclick = "openEditProfileOverlay()",
                  "Edit Profile"
                )
              )
            )
          ),
          
          # Right Column: Timeline & Stats
          tags$div(
            class = "col-lg-8",
            # Stats Cards Row
            tags$div(
              class = "row g-3 mb-4",
              tags$div(
                class = "col-4",
                tags$div(
                  class = "card card-sm",
                  tags$div(class = "card-body", tags$div(class = "row align-items-center", tags$div(class = "col-auto", tags$span(class = "bg-primary text-white avatar", HTML('<svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 19h-7a2 2 0 0 1 -2 -2v-11a2 2 0 0 1 2 -2h4l3 3h7a2 2 0 0 1 2 2v3.5" /></svg>'))), tags$div(class = "col", tags$div(class = "font-weight-medium", textOutput("projectCount", inline = TRUE)), tags$div(class = "text-secondary", "Projects"))))
                )
              ),
              tags$div(
                class = "col-4",
                tags$div(
                  class = "card card-sm",
                  tags$div(class = "card-body", tags$div(class = "row align-items-center", tags$div(class = "col-auto", tags$span(class = "bg-green text-white avatar", HTML('<svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2z" /></svg>'))), tags$div(class = "col", tags$div(class = "font-weight-medium", textOutput("totalFiles", inline = TRUE)), tags$div(class = "text-secondary", "Files"))))
                )
              ),
              tags$div(
                class = "col-4",
                tags$div(
                  class = "card card-sm",
                  tags$div(class = "card-body", tags$div(class = "row align-items-center", tags$div(class = "col-auto", tags$span(class = "bg-orange text-white avatar", HTML('<svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 8l0 4l2 2" /><path d="M3.05 11a9 9 0 1 1 .5 4m-.5 5v-5h5" /></svg>'))), tags$div(class = "col", tags$div(class = "font-weight-medium", textOutput("lastActivity", inline = TRUE)), tags$div(class = "text-secondary", "Last Seen"))))
                )
              )
            ),
            
            # Scrollable Timeline Card
            tags$div(
              class = "card",
              tags$div(
                class = "card-header",
                tags$h3(class = "card-title", "Activity Feed")
              ),
              tags$div(
                class = "card-body",
                # Wrap timeline in a scrollable div
                tags$div(
                  class = "scrollable-timeline-container",
                  timeline_content
                )
              )
            )
            )
          )
        )
      )
    )
  )
})

