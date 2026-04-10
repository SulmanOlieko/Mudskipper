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

    userStatsFile <- file.path(sDir, "usage_stats.json")

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

    userStatsFile <- file.path(sDir, "usage_stats.json")

    tryCatch(
      {
        if (!is.list(stats)) {
          stats <- as.list(stats)
        }

        stats$lastUpdated <- as.character(Sys.time())

        # Keep only last 90 days
        if (!is.null(stats$dailyStats) && length(stats$dailyStats) > 0) {
          dates <- names(stats$dailyStats)
          if (length(dates) > 0) {
            cutoff_date <- Sys.Date() - 366
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

  getActivityLevel <- function(stats, date) {
    dateStr <- as.character(date)

    if (is.null(stats$dailyStats[[dateStr]])) {
      return("none")
    }

    dayStats <- stats$dailyStats[[dateStr]]

    # Score based on meaningful actions only
    score <- 0
    if (!is.null(dayStats$filesEdited)) {
      score <- score + (dayStats$filesEdited * 0.2)
    } # Weight files more
    if (!is.null(dayStats$compilations)) {
      score <- score + (dayStats$compilations * 0.5)
    } # Compiles are important
    if (!is.null(dayStats$projectsOpened)) {
      score <- score + (dayStats$projectsOpened * 0.05)
    }

    if (score == 0) {
      return("none")
    }
    if (score <= 5) {
      return("low")
    }
    if (score <= 100) {
      return("moderate")
    }
    return("high")
  }

  generateGitHubHeatmap <- function(period = "month") {
    stats <- loadUsageStats()
    today <- Sys.Date()
    current_year <- as.integer(format(today, "%Y"))

    # 1. Determine Date Range based on Period
    if (period == "year") {
      # Static Year: Jan 1 to Dec 31 of CURRENT YEAR
      startDate <- as.Date(paste0(current_year, "-01-01"))
      endDate <- as.Date(paste0(current_year, "-12-31"))
    } else {
      # Rolling window for shorter periods, but strict Left-to-Right
      days_back <- switch(period, "quarter" = 90, 30)
      startDate <- today - days_back
      endDate <- today
    }

    # 2. Grid Alignment (Find the Sunday before startDate)
    # This ensures the grid always starts at the top-left (Sunday)
    startDayOfWeek <- as.integer(format(startDate, "%w")) # 0=Sun
    gridStartDate <- startDate - startDayOfWeek

    # Generate full date sequence
    dateSeq <- seq.Date(from = gridStartDate, to = endDate, by = "day")

    # 3. CSS (Adjusted for larger text and tighter fit)
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

    # Days Column (Mon, Wed, Fri)
    days_html <- '<div class="gh-col-days">
                  <div class="gh-day-label"></div> <div class="gh-day-label">Mon</div>
                  <div class="gh-day-label"></div> <div class="gh-day-label">Wed</div>
                  <div class="gh-day-label"></div> <div class="gh-day-label">Fri</div>
                  <div class="gh-day-label"></div> </div>'

    months_html <- '<div class="gh-months-row">'
    heatmap_html <- '<div class="gh-heatmap-grid">'

    # Split dates into Weeks (chunks of 7)
    # We generate enough weeks to cover the dateSeq
    total_days <- length(dateSeq)
    week_indices <- split(1:total_days, ceiling(seq_along(1:total_days) / 7))

    last_month_str <- ""

    for (wk_idx in week_indices) {
      week_dates <- dateSeq[wk_idx]

      # --- Month Label Logic ---
      # We check the first day of the week to decide if we show the month label
      current_month_str <- format(week_dates[1], "%b")

      label_text <- ""
      # Only show label if month changed AND the date is actually within the requested range
      # (prevents labeling the padding days before Jan 1)
      if (current_month_str != last_month_str && week_dates[1] >= startDate) {
        label_text <- current_month_str
        last_month_str <- current_month_str
      }

      months_html <- paste0(
        months_html,
        '<div class="gh-month-label">',
        label_text,
        '</div>'
      )

      # --- Heatmap Grid Logic ---
      heatmap_html <- paste0(heatmap_html, '<div class="gh-week">')

      for (d in 0:6) {
        if ((d + 1) <= length(week_dates)) {
          currDate <- week_dates[d + 1]

          # VISIBILITY CHECK:
          # 1. If date < startDate (it's padding for the grid alignment), make it invisible
          # 2. If date > endDate (it's future or outside range), make it invisible or gray

          is_padding <- currDate < startDate
          is_future <- currDate > today

          if (is_padding) {
            heatmap_html <- paste0(
              heatmap_html,
              '<div class="gh-day-cell" style="background:transparent;"></div>'
            )
          } else {
            # Get Stats
            level <- getActivityLevel(stats, currDate)

            # Force future days to level 0 (Gray)
            if (is_future) {
              level <- "none"
            }

            colorClass <- switch(
              level,
              "none" = "gh-lvl-0",
              "low" = "gh-lvl-1",
              "moderate" = "gh-lvl-2",
              "high" = "gh-lvl-4",
              "gh-lvl-0"
            )

            # Tooltip
            if (is_future) {
              tooltip <- paste0(format(currDate, "%b %d, %Y"), " (Future)")
            } else {
              dateStr <- as.character(currDate)
              tooltip <- format(currDate, "%b %d, %Y")
              if (!is.null(stats$dailyStats[[dateStr]])) {
                ds <- stats$dailyStats[[dateStr]]
                tooltip <- paste0(
                  tooltip,
                  "\n",
                  (ds$filesEdited %||% 0),
                  " Files | ",
                  (ds$compilations %||% 0),
                  " Compiles"
                )
              } else {
                tooltip <- paste0(tooltip, ": No activity")
              }
            }

            heatmap_html <- paste0(
              heatmap_html,
              '<div class="gh-day-cell ',
              colorClass,
              '" ',
              'data-bs-toggle="tooltip" data-bs-placement="top" title="',
              tooltip,
              '"></div>'
            )
          }
        } else {
          # Empty slots for incomplete weeks
          heatmap_html <- paste0(
            heatmap_html,
            '<div class="gh-day-cell" style="background:transparent;"></div>'
          )
        }
      }
      heatmap_html <- paste0(heatmap_html, '</div>') # End Week
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
      '</div>'
    )

    return(final_html)
  }

  getUsageSummary <- function(period = "year") {
    stats <- loadUsageStats()

    endDate <- Sys.Date()
    startDate <- switch(
      period,
      "week" = endDate - 7,
      "month" = endDate - 30,
      "quarter" = endDate - 90,
      "year" = endDate - 365,
      endDate - 365
    )

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

  output$userActivityTracking <- renderText({
    trigger <- usageStatsTrigger()
    currentPeriod <- if (!is.null(input$activityPeriod)) {
      input$activityPeriod
    } else {
      "year"
    }

    # Pass the period name directly to the generator
    blocks_html <- generateGitHubHeatmap(currentPeriod)

    periodText <- switch(
      currentPeriod,
      "year" = paste("Year", format(Sys.Date(), "%Y")),
      "quarter" = "Last 90 Days",
      "month" = "Last 30 Days",
      "This year"
    )

    html <- paste0(
      '
      <div class="card" style="width: 100%; height: 100%; padding-top: 0; padding-bottom: 0;">
        <div class="card-body">
          <div class="d-flex align-items-center mb-2">
            <h3 class="card-title mb-0">Activity</h3>
            <div class="ms-auto lh-1">
              <div class="dropdown">
                <a class="dropdown-toggle" href="#" data-bs-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                  ',
      periodText,
      '
                </a>
                <div class="dropdown-menu dropdown-menu-end">
                  <a class="dropdown-item ',
      if (currentPeriod == "year") "active" else "",
      '" href="#" onclick="Shiny.setInputValue(\'activityPeriod\', \'year\', {priority: \'event\'}); return false;">Year ',
      format(Sys.Date(), "%Y"),
      '</a>
                  <a class="dropdown-item ',
      if (currentPeriod == "quarter") "active" else "",
      '" href="#" onclick="Shiny.setInputValue(\'activityPeriod\', \'quarter\', {priority: \'event\'}); return false;">Last 90 Days</a>
                  <a class="dropdown-item ',
      if (currentPeriod == "month") "active" else "",
      '" href="#" onclick="Shiny.setInputValue(\'activityPeriod\', \'month\', {priority: \'event\'}); return false;">Last 30 Days</a>
                </div>
              </div>
            </div>
          </div>
          
          <div class="d-flex justify-content-center">
             ',
      blocks_html,
      '
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
        
        <script>
          (function() {
            var updatePeriod = function() {
              var width = $(window).width();
              var target = \"year\";
              
              // Define your breakpoints here
              if (width < 600) { target = \"month\"; }       // Mobile
              else if (width < 1000) { target = \"quarter\"; } // Tablet
              
              // Only trigger update if the target differs from what is currently rendered
              // \"currentPeriod\" comes from the R variable injected below
              if (target !== \"',
      currentPeriod,
      '\") {
                 Shiny.setInputValue(\"activityPeriod\", target, {priority: \"event\"});
              }
            };
            
            // Run on load and whenever window resizes
            updatePeriod();
            $(window).off(\"resize.activity\").on(\"resize.activity\", updatePeriod);
          })();
        </script>
      </div>
    '
    )

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

