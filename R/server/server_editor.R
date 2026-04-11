  # =================== INLINE RENAME HANDLER ===================
  observeEvent(
    input$confirmInlineRename,
    {
      req(input$confirmInlineRename)

      data <- input$confirmInlineRename
      oldPathRel <- data$oldPath
      newName <- trimws(data$newName)

      projDir <- getActiveProjectDir()
      req(projDir)

      oldFullPath <- file.path(projDir, oldPathRel)

      # Calculate new relative path
      parentDir <- dirname(oldPathRel)
      if (parentDir == ".") {
        newPathRel <- newName
      } else {
        newPathRel <- file.path(parentDir, newName)
      }
      newFullPath <- file.path(projDir, newPathRel)

      # Validations
      if (!file.exists(oldFullPath)) {
        showTablerAlert("danger", "File not found", "Original file not found.", 5000)
        rv_files(getVisibleFiles(projDir))
        return()
      }

      if (file.exists(newFullPath)) {
        showTablerAlert(
          "warning",
          "Name already exists",
          "A file with that name already exists.",
          5000
        )
        rv_files(getVisibleFiles(projDir))
        return()
      }

      # Perform Rename
      success <- file.rename(oldFullPath, newFullPath)

      if (success) {
        # 1. Update Project Metadata (CRITICAL FIX for persistence)
        # If we renamed the mainFile, update projects.json so it loads correctly next time
        projects <- loadProjects()
        updatedMeta <- FALSE
        currentProjId <- activeProjectId()

        for (i in seq_along(projects)) {
          if (projects[[i]]$id == currentProjId) {
            # Check if the OLD path matches the stored mainFile
            if (
              !is.null(projects[[i]]$mainFile) &&
                projects[[i]]$mainFile == oldPathRel
            ) {
              projects[[i]]$mainFile <- newPathRel
              updatedMeta <- TRUE
            }
            break
          }
        }
        if (updatedMeta) {
          saveProjects(projects)
        }

        # 2. Update Active Editor State
        # If the file currently open is the one we renamed, point editor to new name
        if (currentFile() == oldPathRel) {
          currentFile(newPathRel)
          updateStatus(newPathRel)

          # Determine mode for the new name (e.g. if extension changed)
          newMode <- getAceModeFromExtension(newName)
          # We don't need to reload content (it's in RAM), just update mode
          shinyjs::runjs(sprintf(
            "var editor = ace.edit('sourceEditor'); editor.getSession().setMode('ace/mode/%s');",
            newMode
          ))
        }

        # 3. Refresh UI
        rv_files(getVisibleFiles(projDir))
        if (!is.null(activeProjectId())) {
          updateProjectFileCount(activeProjectId())
        }

        showTablerAlert(
          "success",
          "File renamed",
          paste("Renamed file to", newName),
          5000
        )
      } else {
        showTablerAlert("danger", "Error renaming file", "Failed to rename file.", 5000)
        rv_files(getVisibleFiles(projDir))
      }
    },
    once = FALSE
  )

  # Helper function to detect Ace mode from file extension
  getAceModeFromExtension <- function(filename) {
    ext <- tolower(tools::file_ext(filename))

    mode_map <- list(
      # LaTeX and related
      "tex" = "latex",
      "bib" = "bibtex",
      "rnw" = "latex",
      "bst" = "latex",
      "sty" = "latex",

      # Programming languages
      "r" = "r",
      "py" = "python",
      "js" = "javascript",
      "ts" = "typescript",
      "java" = "java",
      "c" = "c_cpp",
      "cpp" = "c_cpp",
      "cc" = "c_cpp",
      "cxx" = "c_cpp",
      "h" = "c_cpp",
      "hpp" = "c_cpp",
      "cs" = "csharp",
      "php" = "php",
      "rb" = "ruby",
      "go" = "golang",
      "rs" = "rust",
      "swift" = "swift",
      "kt" = "kotlin",
      "scala" = "scala",
      "sh" = "sh",
      "bash" = "sh",
      "zsh" = "sh",
      "fish" = "sh",
      "ps1" = "powershell",
      "pl" = "perl",
      "lua" = "lua",

      # Web technologies
      "html" = "html",
      "htm" = "html",
      "xml" = "xml",
      "css" = "css",
      "scss" = "scss",
      "sass" = "sass",
      "less" = "less",
      "json" = "json",
      "yaml" = "yaml",
      "yml" = "yaml",
      "toml" = "toml",

      # Markup and documentation
      "md" = "markdown",
      "markdown" = "markdown",
      "rst" = "rst",
      "txt" = "text",

      # Data formats
      "csv" = "text",
      "tsv" = "text",
      "sql" = "sql",

      # Configuration files
      "ini" = "ini",
      "cfg" = "ini",
      "conf" = "text",
      "properties" = "properties",

      # Others
      "dockerfile" = "dockerfile",
      "makefile" = "makefile",
      "gitignore" = "gitignore"
    )

    # Return the mode or default to text
    mode <- mode_map[[ext]]
    if (is.null(mode)) {
      return("text")
    }
    return(mode)
  }

  observeEvent(currentFile(), {
    session$sendCustomMessage("renderCommentMarkers", list())
    commentUpdate(commentUpdate() + 1)
  })

  # Handle file single-clicks (Robust Binary Detection & Enhanced Preview)
  observeEvent(input$fileClick, {
    req(input$fileClick$path)

    projectId <- activeProjectId()
    req(projectId)
    projDir <- getActiveProjectDir()
    filePath <- input$fileClick$path
    fullPath <- file.path(projDir, filePath)

    if (!file.exists(fullPath)) {
      return()
    }

    # --- 1. SAFETY CHECKS ---
    finfo <- file.info(fullPath)
    if (is.na(finfo$size)) {
      return()
    }

    # Guard: Prevent opening files > 5MB in the text editor
    is_too_large <- finfo$size > (5 * 1024 * 1024)

    ext <- tolower(tools::file_ext(filePath))
    isEditable <- isTRUE(input$fileClick$isEditable)

    # Comprehensive Binary Extensions List
    binary_exts <- c(
      # Documents & Office
      "pdf",
      "doc",
      "docx",
      "xls",
      "xlsx",
      "xlsm",
      "ppt",
      "pptx",
      "odt",
      "ods",
      "odp",
      "rtf",
      "epub",
      "pages",
      "key",
      "numbers",
      "vsd",
      "vsdx",
      # Images & Design
      "png",
      "jpg",
      "jpeg",
      "gif",
      "bmp",
      "tiff",
      "tif",
      "ico",
      "webp",
      "heic",
      "psd",
      "ai",
      "raw",
      "eps",
      "ps",
      "xcf",
      "indd",
      "cdr",
      "sketch",
      "fig",
      # Audio
      "mp3",
      "wav",
      "ogg",
      "m4a",
      "flac",
      "aac",
      "wma",
      "aiff",
      "mid",
      "midi",
      "opus",
      "pcm",
      # Video
      "mp4",
      "mov",
      "avi",
      "webm",
      "mkv",
      "flv",
      "wmv",
      "m4v",
      "3gp",
      "mpeg",
      "mpg",
      "m2ts",
      "mts",
      "vob",
      # Archives
      "zip",
      "tar",
      "gz",
      "tgz",
      "7z",
      "rar",
      "bz2",
      "xz",
      "iso",
      "dmg",
      "pkg",
      "z",
      "cab",
      "rpm",
      "deb",
      "img",
      "vhd",
      "vdi",
      "vmdk",
      # Fonts
      "woff",
      "woff2",
      "ttf",
      "eot",
      "otf",
      "pfb",
      "pfm",
      # Data & Science
      "parquet",
      "rds",
      "rdata",
      "rda",
      "feather",
      "fst",
      "avro",
      "h5",
      "hdf5",
      "nc",
      "fits",
      # Database
      "db",
      "sqlite",
      "sqlite3",
      "mdb",
      "accdb",
      "sqlitedb",
      "mdf",
      "ldf",
      # Executables
      "exe",
      "dll",
      "so",
      "dylib",
      "bin",
      "o",
      "obj",
      "pyc",
      "class",
      "jar",
      "war",
      "ear",
      "dat",
      "msi",
      "com",
      "apk",
      "ds_store",
      "thumbs.db",
      "lnk",
      # 3D
      "glb",
      "fbx",
      "blend",
      "3ds",
      "max",
      "c4d",
      "stl",
      "ply"
    )

    # --- CRITICAL FIX: TRUE BINARY DETECTION ---
    # Read the first 1024 bytes to check for NUL characters.
    # This prevents 'readLines' from crashing on files that look like text but aren't.
    is_binary_content <- tryCatch(
      {
        con <- file(fullPath, "rb")
        on.exit(close(con))
        bytes <- readBin(con, "raw", n = 1024)
        any(bytes == 00)
      },
      error = function(e) TRUE
    ) # Assume binary on error

    # Determine if we should open in Ace Editor
    # Must be: Editable flag + Not in binary list + No NUL bytes detected
    should_open_editor <- isEditable &&
      !(ext %in% binary_exts) &&
      !is_binary_content

    if (should_open_editor) {
      # ================= EDITABLE TEXT FILE =================

      if (is_too_large) {
        showTablerAlert(
          "warning",
          "File too large",
          "This file is too large to edit directly (> 5MB).", 5000)
        return()
      }

      # 1. Clear Old Markers & UI
      session$sendCustomMessage("clearLocalAnchors", list())
      session$sendCustomMessage("hideFilePreview", list(path = filePath))

      # 2. Safe Read
      content <- tryCatch(
        {
          paste(readLines(fullPath, warn = FALSE), collapse = "\n")
        },
        error = function(e) {
          showTablerAlert(
            "danger",
            "Read error",
            paste("Could not read file:", e$message)
          )
          return(NULL)
        }
      )

      if (is.null(content)) {
        return()
      }

      aceMode <- getAceModeFromExtension(filePath)

      # 3. SAFE LOAD
      session$sendCustomMessage(
        "cmdSafeLoadFile",
        list(
          content = content,
          mode = aceMode
        )
      )

      # 4. Update State
      currentFile(filePath)
      updateStatus(filePath)

      if (ext == "tex") {
        if (
          is.null(input$fileClick$context) ||
            input$fileClick$context != "synctex"
        ) {
          updateSelectInput(session, "compileMainFile", selected = filePath)
        }
      }

      # 5. Restore Comments & Cursor
      later::later(
        function() {
          isolate({
            specificComments <- loadComments(projectId, filePath)
            session$sendCustomMessage(
              "renderCommentMarkers",
              list(
                comments = specificComments,
                force = TRUE
              )
            )
            rv$fileJustLoaded <- TRUE

            savedRow <- 0
            savedCol <- 0
            projects <- loadProjects()
            for (p in projects) {
              if (p$id == projectId) {
                if (!is.null(p$cursorRow)) {
                  savedRow <- p$cursorRow
                }
                if (!is.null(p$cursorCol)) {
                  savedCol <- p$cursorCol
                }
                break
              }
            }

            if (!is.null(input$fileClick$gotoLine)) {
              session$sendCustomMessage(
                'aceGoTo',
                list(line = as.numeric(input$fileClick$gotoLine))
              )
            } else {
              session$sendCustomMessage(
                'cursorRestore',
                list(file = filePath, row = savedRow, column = savedCol)
              )
            }

            commentUpdate(commentUpdate() + 1)
          })
        },
        delay = 0.25
      )
    } else {
      # ================= PREVIEW / BINARY =================

      uid <- isolate(user_session$user_info$user_id)
      pUrl <- file.path("project", uid, "projects", projectId, filePath)

      if (ext %in% c("png", "jpg", "jpeg", "gif", "svg", "webp", "bmp")) {
        session$sendCustomMessage(
          "showFilePreview",
          list(
            filename = basename(filePath),
            type = "image",
            url = pUrl,
            relPath = filePath
          )
        )
      } else if (ext == "pdf") {
        pUrl <- paste0(pUrl, "?t=", as.numeric(Sys.time()))
        session$sendCustomMessage(
          "showFilePreview",
          list(
            filename = basename(filePath),
            type = "pdf",
            url = pUrl,
            relPath = filePath
          )
        )
      } else if (ext %in% c("mp4", "webm", "ogg", "mov")) {
        session$sendCustomMessage(
          "showFilePreview",
          list(
            filename = basename(filePath),
            type = "video",
            url = pUrl,
            relPath = filePath
          )
        )
      } else if (ext %in% c("mp3", "wav")) {
        session$sendCustomMessage(
          "showFilePreview",
          list(
            filename = basename(filePath),
            type = "audio",
            url = pUrl,
            relPath = filePath
          )
        )
      } else {
        # FALLBACK: Unknown type or explicit binary
        # Only try to read as text if we CONFIRMED it is NOT binary and is small
        if (!is_binary_content && finfo$size < 500 * 1024) {
          content <- tryCatch(
            {
              paste(readLines(fullPath, warn = FALSE), collapse = "\n")
            },
            error = function(e) "File cannot be previewed."
          )

          session$sendCustomMessage(
            "showFilePreview",
            list(
              filename = basename(filePath),
              type = "text",
              content = content
            )
          )
        } else {
          session$sendCustomMessage(
            "showFilePreview",
            list(
              filename = basename(filePath),
              type = "text",
              content = "File cannot be previewed as text."
            )
          )
        }
      }

      shinyjs::runjs(
        "
        if (document.getElementById('historyOverlay') && document.getElementById('historyOverlay').classList.contains('show')) {
          Shiny.setInputValue('openHistoryBtn', Math.random(), {priority: 'event'});
        }
      "
      )
    }
  })

  # --- NEW HELPER: Save Main File Preference ---
  updateProjectMainFilePreference <- function(projectId, filename) {
    req(projectId, filename)
    projects <- loadProjects()
    updated <- FALSE

    if (length(projects) > 0) {
      for (i in seq_along(projects)) {
        if (projects[[i]]$id == projectId) {
          # Only save if different to avoid disk churn
          if (
            is.null(projects[[i]]$mainFile) ||
              projects[[i]]$mainFile != filename
          ) {
            projects[[i]]$mainFile <- filename
            projects[[i]]$lastEdited <- as.character(Sys.time())
            updated <- TRUE
          }
          break
        }
      }
      if (updated) saveProjects(projects)
    }
  }

  # ---------------- CURSOR PERSISTENCE (SERVER SIDE) ----------------
  # Debounce inputs to write to disk max once every 2 seconds
  cursor_debounced <- reactive({
    input$cursorPosition
  }) %>%
    debounce(2000)

  observeEvent(cursor_debounced(), {
    req(activeProjectId())
    pos <- cursor_debounced()

    # Only save if coordinates are valid numbers
    if (!is.null(pos$row) && !is.null(pos$column)) {
      projects <- loadProjects()
      updated <- FALSE

      for (i in seq_along(projects)) {
        if (projects[[i]]$id == activeProjectId()) {
          # Update the list in memory
          projects[[i]]$cursorRow <- pos$row
          projects[[i]]$cursorCol <- pos$column
          updated <- TRUE
          break
        }
      }

      if (updated) {
        saveProjects(projects)
      }
    }
  })

  # Function to find .bib files referenced in main .tex file
  findBibFiles <- function(texContent, projDir) {
    if (is.null(texContent) || !nzchar(texContent)) {
      return(character(0))
    }

    # Vectorize by line to avoid Catastrophic Backtracking on huge strings
    lines <- strsplit(texContent, "\n")[[1]]
    bibFiles <- character(0)

    # Check for \bibliography{} command
    idx1 <- grep("\\\\bibliography\\{", lines)
    if (length(idx1) > 0) {
      match_lines <- lines[idx1]
      matches <- gregexpr("\\\\bibliography\\{([^}]+)\\}", match_lines, perl = TRUE)
      bibStrs <- unlist(regmatches(match_lines, matches))
      bibStrs <- sub("\\\\bibliography\\{([^}]+)\\}", "\\1", bibStrs, perl = TRUE)
      
      for (bibStr in bibStrs) {
        bibNames <- trimws(strsplit(bibStr, ",")[[1]])
        for (bibName in bibNames) {
          if (!grepl("\\.bib$", bibName, ignore.case = TRUE)) {
            bibName <- paste0(bibName, ".bib")
          }
          if (file.exists(file.path(projDir, bibName))) {
            bibFiles <- c(bibFiles, bibName)
          }
        }
      }
    }

    # Check for \addbibresource{} (biblatex)
    idx2 <- grep("\\\\addbibresource\\{", lines)
    if (length(idx2) > 0) {
      match_lines <- lines[idx2]
      matches <- gregexpr("\\\\addbibresource\\{([^}]+)\\}", match_lines, perl = TRUE)
      bibStrs <- unlist(regmatches(match_lines, matches))
      bibStrs <- sub("\\\\addbibresource\\{([^}]+)\\}", "\\1", bibStrs, perl = TRUE)
      
      for (bibName in bibStrs) {
        bibName <- trimws(bibName)
        if (!grepl("\\.bib$", bibName, ignore.case = TRUE)) {
          bibName <- paste0(bibName, ".bib")
        }
        if (file.exists(file.path(projDir, bibName))) {
          bibFiles <- c(bibFiles, bibName)
        }
      }
    }

    # If no explicit references, look for any .bib files in project
    if (length(bibFiles) == 0) {
      allBibFiles <- list.files(
        projDir,
        pattern = "\\.bib$",
        ignore.case = TRUE,
        recursive = TRUE
      )
      if (length(allBibFiles) > 0) {
        bibFiles <- allBibFiles
      }
    }

    return(unique(bibFiles))
  }

  # Function to parse .bib file and extract citation keys
  parseBibFile <- function(bibPath) {
    if (!file.exists(bibPath)) return(character(0))
    
    # Read natively without concatenating
    lines <- readLines(bibPath, warn = FALSE)
    
    # Rapid vectorized search for @ strings
    idx <- grep("^@", lines)
    if (length(idx) == 0) return(character(0))
    
    valid_lines <- lines[idx]
    keys <- sub("^@\\w+\\s*\\{\\s*([^,\\s]+).*", "\\1", valid_lines, perl = TRUE)
    return(unique(trimws(keys)))
  }

  # Function to parse LaTeX content and extract label keys
  parseLabelsFromContent <- function(content) {
    if (is.null(content) || !nzchar(trimws(content))) return(character(0))
    
    lines <- strsplit(content, "\n")[[1]]
    idx <- grep("\\\\label\\{", lines)
    
    if (length(idx) == 0) return(character(0))
    
    match_lines <- lines[idx]
    matches <- gregexpr("\\\\label\\{([^}]+)\\}", match_lines, perl = TRUE)
    matchData <- unlist(regmatches(match_lines, matches))
    
    keys <- sub("\\\\label\\{([^}]+)\\}", "\\1", matchData, perl = TRUE)
    return(unique(trimws(keys)))
  }

  # ---------------- HELPER: PUSH BIB CITATIONS TO JS ----------------
  pushBibCitations <- function(texContent, projDir) {
    # 0. Reset to 0 initially
    session$sendCustomMessage("updateCitationCount", 0)

    # 1. Find .bib files referenced in the content
    bibFiles <- findBibFiles(texContent, projDir)

    # 2. If no files found, clear the JS array and exit
    if (length(bibFiles) == 0) {
      shinyjs::runjs(
        "if (window.updateBibEntries) window.updateBibEntries([]);"
      )
      # Explicitly ensure count stays at 0
      session$sendCustomMessage("updateCitationCount", 0)
      return()
    }

    # 3. Parse all found .bib files
    allKeys <- character(0)
    for (bibFile in bibFiles) {
      bibPath <- file.path(projDir, bibFile)
      keys <- parseBibFile(bibPath)
      allKeys <- c(allKeys, keys)
    }

    allKeys <- unique(allKeys)

    # 4. Push directly to JavaScript
    keysJSON <- jsonlite::toJSON(allKeys, auto_unbox = TRUE)
    shinyjs::runjs(sprintf(
      "if (window.updateBibEntries) window.updateBibEntries(%s);",
      keysJSON
    ))

    # 5. Update the visual counter with the final length (even if 0)
    session$sendCustomMessage("updateCitationCount", length(allKeys))
  }

  # ---------------- HELPER: PUSH LABEL KEYS TO JS ----------------
  pushLabelKeys <- function(texContent) {
    # 0. Reset to 0 initially
    session$sendCustomMessage("updateLabelCount", 0)

    # 1. Parse labels from content
    allKeys <- parseLabelsFromContent(texContent)

    # 2. If no labels found, clear the JS array and exit
    if (length(allKeys) == 0) {
      shinyjs::runjs(
        "if (window.updateLabelEntries) window.updateLabelEntries([]);"
      )
      # Explicitly ensure count stays at 0
      session$sendCustomMessage("updateLabelCount", 0)
      return()
    }

    # 3. Push directly to JavaScript
    keysJSON <- jsonlite::toJSON(allKeys, auto_unbox = TRUE)
    shinyjs::runjs(sprintf(
      "if (window.updateLabelEntries) window.updateLabelEntries(%s);",
      keysJSON
    ))

    # 4. Update the visual counter with the final length
    session$sendCustomMessage("updateLabelCount", length(allKeys))
  }

  # Check for .bib files and send entries to JavaScript
  observeEvent(
    input$checkBibFiles,
    {
      projDir <- getActiveProjectDir()
      if (is.null(projDir)) {
        session$sendCustomMessage(
          "type",
          list(
            js = "if (window.showNoBibMessage) window.showNoBibMessage('No active project');"
          )
        )
        return()
      }

      # Get current editor content to find referenced .bib files
      texContent <- input$sourceEditor

      if (is.null(texContent) || !nzchar(texContent)) {
        session$sendCustomMessage(
          "type",
          list(
            js = "if (window.showNoBibMessage) window.showNoBibMessage('No .tex content');"
          )
        )
        return()
      }

      # Find .bib files
      bibFiles <- findBibFiles(texContent, projDir)

      if (length(bibFiles) == 0) {
        shinyjs::runjs(
          "if (window.showNoBibMessage) window.showNoBibMessage('No .bib files in your project');"
        )
        return()
      }

      # Parse all .bib files and collect citation keys
      allKeys <- character(0)

      for (bibFile in bibFiles) {
        bibPath <- file.path(projDir, bibFile)
        keys <- parseBibFile(bibPath)
        allKeys <- c(allKeys, keys)
      }

      allKeys <- unique(allKeys)

      if (length(allKeys) == 0) {
        shinyjs::runjs(
          "if (window.showNoBibMessage) window.showNoBibMessage('Your .bib file is empty');"
        )
        return()
      }

      # Send to JavaScript
      keysJSON <- jsonlite::toJSON(allKeys, auto_unbox = TRUE)
      shinyjs::runjs(sprintf(
        "if (window.updateBibEntries) window.updateBibEntries(%s);",
        keysJSON
      ))
    },
    ignoreInit = TRUE
  )

  # Also update bib entries when file changes
  observeEvent(
    currentFile(),
    {
      # Trigger bib check after a delay to let file load
      later::later(
        function() {
          session$sendCustomMessage(
            "type",
            list(
              js = "if (window.Shiny) Shiny.setInputValue('checkBibFiles', Math.random(), {priority: 'event'});"
            )
          )
        },
        0.5
      )
    },
    ignoreInit = TRUE
  )

  # Check for label keys and send entries to JavaScript
  observeEvent(
    input$checkLabelKeys,
    {
      projDir <- getActiveProjectDir()
      if (is.null(projDir)) {
        session$sendCustomMessage(
          "type",
          list(
            js = "if (window.showNoLabelMessage) window.showNoLabelMessage('No active project');"
          )
        )
        return()
      }

      # Get current editor content
      texContent <- input$sourceEditor

      if (is.null(texContent) || !nzchar(texContent)) {
        shinyjs::runjs(
          "if (window.showNoLabelMessage) window.showNoLabelMessage('No .tex content');"
        )
        return()
      }

      # Parse labels from content
      allKeys <- parseLabelsFromContent(texContent)

      if (length(allKeys) == 0) {
        shinyjs::runjs(
          "if (window.showNoLabelMessage) window.showNoLabelMessage('No labels in your document');"
        )
        return()
      }

      # Send to JavaScript
      keysJSON <- jsonlite::toJSON(allKeys, auto_unbox = TRUE)
      shinyjs::runjs(sprintf(
        "if (window.updateLabelEntries) window.updateLabelEntries(%s);",
        keysJSON
      ))
    },
    ignoreInit = TRUE
  )

  # Also update label entries when file changes
  observeEvent(
    currentFile(),
    {
      # Trigger label check after a delay to let file load
      later::later(
        function() {
          session$sendCustomMessage(
            "type",
            list(
              js = "if (window.Shiny) Shiny.setInputValue('checkLabelKeys', Math.random(), {priority: 'event'});"
            )
          )
        },
        0.5
      )
    },
    ignoreInit = TRUE
  )

  # Render user profile data
  output$userName <- renderText({
    trigger <- userProfileTrigger() # Make reactive to changes
    profile <- loadUserProfile()
    profile$username
  })

  output$welcomeUserName <- renderText({
    trigger <- userProfileTrigger() # Make reactive to changes
    profile <- loadUserProfile()
    profile$username
  })

  output$userInstitution <- renderText({
    trigger <- userProfileTrigger()
    profile <- loadUserProfile()
    profile$institution
  })

  output$userEmail <- renderText({
    trigger <- userProfileTrigger()
    profile <- loadUserProfile()
    if (is.null(profile$email) || profile$email == "") {
      "No email set"
    } else {
      profile$email
    }
  })

  output$userBio <- renderText({
    trigger <- userProfileTrigger()
    profile <- loadUserProfile()
    if (is.null(profile$bio) || profile$bio == "") {
      "No bio available. Click 'Edit profile' to add one."
    } else {
      profile$bio
    }
  })

  # Renders the avatar in the main editor navbar
  output$editorNavbarAvatar <- renderUI({
    HTML(generateAvatarLinkHTML(avatarClass = "avatar-sm"))
  })

  output$userVerified <- renderText({
    trigger <- userProfileTrigger()
    profile <- loadUserProfile()
    if (isTRUE(profile$verified)) "verified" else ""
  })

  output$userCollaborators <- renderText({
    trigger <- userProfileTrigger()
    profile <- loadUserProfile()
    as.character(profile$collaborators)
  })

  output$userMemberSince <- renderText({
    trigger <- userProfileTrigger()
    profile <- loadUserProfile()
    if (!is.null(profile$memberSince)) {
      format(as.POSIXct(profile$memberSince), "%B %Y")
    } else {
      format(Sys.time(), "%B %Y")
    }
  })

  # Render profile picture upload input
  output$editProfilePictureContainer <- renderUI({
    fileInput(
      "editProfilePicture",
      NULL,
      multiple = FALSE,
      accept = c("image/png", "image/jpeg", "image/jpg", "image/gif"),
      width = "100%"
    )
  })

  # FORCE RENDER: Tell Shiny to update these even if the Profile Overlay is hidden
  outputOptions(output, "userName", suspendWhenHidden = FALSE)
  outputOptions(output, "welcomeUserName", suspendWhenHidden = FALSE)
  outputOptions(output, "userInstitution", suspendWhenHidden = FALSE)
  outputOptions(output, "userEmail", suspendWhenHidden = FALSE)
  outputOptions(output, "userBio", suspendWhenHidden = FALSE)
  outputOptions(output, "userVerified", suspendWhenHidden = FALSE)
  outputOptions(output, "userCollaborators", suspendWhenHidden = FALSE)
  outputOptions(output, "userMemberSince", suspendWhenHidden = FALSE)


  # ----------------------------- ACTIVITY TRACKING OBSERVERS ----------------------------
  # Track MANUAL file edits only (not auto-save)
  # Use a reactive value to track last manual edit
  lastManualEdit <- reactiveVal(list(
    file = NULL,
    projectId = NULL,
    time = NULL
  ))

  observeEvent(input$sourceEditor, {
    file <- currentFile()
    projId <- activeProjectId()

    if (!is.null(file) && nzchar(file) && !is.null(projId)) {
      lastEdit <- lastManualEdit()
      currentTime <- Sys.time()

      # Only record if it's been > 5 minutes since last edit of this file
      shouldRecord <- TRUE
      if (!is.null(lastEdit$file) && !is.null(lastEdit$time)) {
        if (
          lastEdit$file == file &&
            lastEdit$projectId == projId &&
            difftime(currentTime, lastEdit$time, units = "mins") < 5
        ) {
          shouldRecord <- FALSE
        }
      }

      if (shouldRecord) {
        recordDailyActivity(
          "fileEdit",
          list(
            file = file,
            projectId = projId,
            manual = TRUE
          )
        )
        lastManualEdit(list(
          file = file,
          projectId = projId,
          time = currentTime
        ))
      }
    }
  }) %>%
    debounce(30000) # 30 seconds debounce for typing bursts

  # Track project opens (only when explicitly loaded by user)
  observeEvent(input$loadProject, {
    req(input$loadProject)
    recordDailyActivity(
      "projectOpen",
      list(
        projectId = input$loadProject,
        source = "user_action"
      )
    )
  })

  # Track compilations (each compile is meaningful)
  observeEvent(input$compile, {
    projId <- activeProjectId()
    file <- currentFile()
    recordDailyActivity(
      "compile",
      list(
        projectId = projId,
        file = file
      )
    )
  })

  # Track session start ONCE per day (not every 5 minutes)
  sessionTracked <- reactiveVal(FALSE)

  observe({
    if (!sessionTracked()) {
      recordDailyActivity(
        "session",
        list(
          action = "app_start",
          timestamp = Sys.time()
        )
      )
      sessionTracked(TRUE)
    }
  })

  # COMPREHENSIVE VS Code Material Icon Theme Implementation
  # Verified icon names from the official repository

  getFileIcon <- function(fname) {
    ext <- tolower(tools::file_ext(fname))
    base_name <- tolower(basename(fname))

    # Base CDN URL for VS Code Material Icons
    icon_base <- "https://raw.githubusercontent.com/PKief/vscode-material-icon-theme/main/icons"

    # Helper to create icon element
    mk_icon <- function(icon_name) {
      icon_url <- sprintf("%s/%s.svg", icon_base, icon_name)
      tags$img(
        src = icon_url,
        class = "file-icon",
        style = "width: 16px; height: 16px; margin-right: 6px; vertical-align: middle; flex-shrink: 0;",
        alt = "",
        onerror = "this.style.display='none'" # Hide if icon fails to load
      )
    }

    # Special files (exact name matches) - check these first
    special_files <- list(
      # Git & Version Control
      ".gitignore" = "git",
      ".gitattributes" = "git",
      ".gitmodules" = "git",
      ".gitkeep" = "git",

      # Docker
      ".dockerignore" = "docker",
      "dockerfile" = "docker",
      "docker-compose.yml" = "docker",
      "docker-compose.yaml" = "docker",

      # Documentation
      "readme.md" = "readme",
      "readme" = "readme",
      "changelog.md" = "changelog",
      "changelog" = "changelog",
      "license" = "certificate",
      "license.md" = "certificate",
      "license.txt" = "certificate",

      # Package/Config files
      "package.json" = "nodejs",
      "package-lock.json" = "nodejs_alt",
      "yarn.lock" = "yarn",
      "pnpm-lock.yaml" = "pnpm",
      "composer.json" = "composer",
      "composer.lock" = "composer",
      "gemfile" = "ruby",
      "gemfile.lock" = "ruby",
      "cargo.toml" = "cargo",
      "cargo.lock" = "cargo",

      # R specific
      ".rprofile" = "r",
      ".rhistory" = "r",
      "description" = "r",
      "namespace" = "r",

      # Build files
      "makefile" = "settings",
      "cmake" = "cmake",
      "cmakelists.txt" = "cmake",
      "rakefile" = "ruby",

      # CI/CD
      ".travis.yml" = "travis",
      ".gitlab-ci.yml" = "gitlab",
      "jenkinsfile" = "jenkins",
      "azure-pipelines.yml" = "azurepipelines",

      # Editor configs
      ".editorconfig" = "editorconfig",
      ".eslintrc" = "eslint",
      ".prettierrc" = "prettier",
      ".babelrc" = "babel"
    )

    if (base_name %in% names(special_files)) {
      return(mk_icon(special_files[[base_name]]))
    }

    # Extension-based mapping using VERIFIED VS Code Material Icon Theme names
    icon_name <- switch(
      ext,
      # ============ R & RELATED ============
      "r" = "r",
      "rmd" = "rmarkdown",
      "qmd" = "quarto",
      "rnw" = "r",
      "rproj" = "r",
      "rdata" = "database",
      "rds" = "database",
      "rda" = "database",

      # ============ LATEX & DOCUMENTS ============
      # LaTeX source files - VERIFIED ICON NAMES
      "tex" = "tex",
      "latex" = "tex",
      "ltx" = "tex",

      # Bibliography & Citations - VERIFIED: uses "tex" icon family
      "bib" = "tex", # BibTeX files use tex icon
      "bibtex" = "tex",
      "biblatex" = "tex",

      # LaTeX class and style files
      "sty" = "tex", # Style file
      "cls" = "tex", # Class file
      "dtx" = "tex", # Documented LaTeX source
      "ins" = "tex", # Installation file
      "bst" = "tex",

      # LaTeX auxiliary files
      "aux" = "log",
      "bbl" = "log",
      "blg" = "log",
      "out" = "log",
      "toc" = "log",
      "lof" = "log",
      "lot" = "log",
      "fls" = "log",
      "fdb_latexmk" = "log",
      "synctex.gz" = "log",
      "nav" = "log",
      "snm" = "log",
      "vrb" = "log",

      # PDF and output
      "pdf" = "pdf",
      "dvi" = "document",
      "ps" = "document",
      "eps" = "image",

      # ============ MARKDOWN & TEXT ============
      "md" = "markdown",
      "markdown" = "markdown",
      "mdown" = "markdown",
      "mkd" = "markdown",
      "mkdown" = "markdown",
      "txt" = "text",
      "text" = "text",
      "log" = "log",
      "rtf" = "document",
      "doc" = "word",
      "docx" = "word",
      "odt" = "document",

      # ReStructuredText and others
      "rst" = "rst",
      "rest" = "rst",
      "adoc" = "asciidoc",
      "asciidoc" = "asciidoc",
      "org" = "org",

      # ============ WEB LANGUAGES ============
      "html" = "html",
      "htm" = "html",
      "xhtml" = "html",
      "css" = "css",
      "scss" = "sass",
      "sass" = "sass",
      "less" = "less",
      "stylus" = "stylus",

      # JavaScript & TypeScript
      "js" = "javascript",
      "mjs" = "javascript",
      "cjs" = "javascript",
      "jsx" = "react",
      "ts" = "typescript",
      "tsx" = "react_ts",
      "mts" = "typescript",
      "cts" = "typescript",

      # Other web
      "vue" = "vue",
      "svelte" = "svelte",
      "angular" = "angular",

      # ============ PROGRAMMING LANGUAGES ============
      # Python
      "py" = "python",
      "pyw" = "python",
      "pyc" = "python-misc",
      "pyd" = "python",
      "pyo" = "python",
      "pyi" = "python",
      "ipynb" = "jupyter",

      # Java & JVM
      "java" = "java",
      "class" = "javaclass",
      "jar" = "jar",
      "jsp" = "java",
      "kt" = "kotlin",
      "kts" = "kotlin",
      "scala" = "scala",
      "sc" = "scala",
      "groovy" = "groovy",

      # C/C++
      "c" = "c",
      "h" = "h",
      "cpp" = "cpp",
      "cc" = "cpp",
      "cxx" = "cpp",
      "c++" = "cpp",
      "hpp" = "hpp",
      "hh" = "hpp",
      "hxx" = "hpp",

      # C#/.NET
      "cs" = "csharp",
      "csx" = "csharp",
      "vb" = "vb",
      "fs" = "fsharp",
      "fsx" = "fsharp",

      # Systems programming
      "go" = "go",
      "rs" = "rust",
      "zig" = "zig",
      "nim" = "nim",

      # Scripting
      "php" = "php",
      "phtml" = "php",
      "rb" = "ruby",
      "erb" = "ruby",
      "swift" = "swift",
      "perl" = "perl",
      "pl" = "perl",
      "pm" = "perl",
      "lua" = "lua",

      # Shell
      "sh" = "shell",
      "bash" = "shell",
      "zsh" = "shell",
      "fish" = "shell",
      "ps1" = "powershell",
      "psm1" = "powershell",
      "bat" = "console",
      "cmd" = "console",

      # ============ DATA & CONFIG ============
      # Data serialization
      "json" = "json",
      "jsonc" = "json",
      "json5" = "json",
      "yaml" = "yaml",
      "yml" = "yaml",
      "toml" = "toml",
      "xml" = "xml",
      "plist" = "plist",

      # Config files
      "ini" = "settings",
      "cfg" = "config",
      "conf" = "config",
      "config" = "config",
      "env" = "tune",
      "properties" = "properties",

      # ============ DATA FILES ============
      # Tabular data
      "csv" = "csv",
      "tsv" = "tsv",
      "tab" = "table",

      # Spreadsheets
      "xlsx" = "excel",
      "xls" = "excel",
      "xlsm" = "excel",
      "xlsb" = "excel",
      "ods" = "table",

      # Database
      "sql" = "database",
      "db" = "database",
      "sqlite" = "database",
      "sqlite3" = "database",
      "mdb" = "access",
      "accdb" = "access",

      # Big data
      "parquet" = "parquet",
      "avro" = "avro",
      "feather" = "feather",

      # ============ IMAGES ============
      "png" = "image",
      "jpg" = "image",
      "jpeg" = "image",
      "gif" = "image",
      "bmp" = "image",
      "tiff" = "image",
      "tif" = "image",
      "webp" = "image",
      "svg" = "svg",
      "ico" = "favicon",
      "icon" = "image",
      "icns" = "image",

      # ============ AUDIO/VIDEO ============
      "mp3" = "audio",
      "wav" = "audio",
      "flac" = "audio",
      "ogg" = "audio",
      "m4a" = "audio",
      "mp4" = "video",
      "avi" = "video",
      "mov" = "video",
      "mkv" = "video",
      "webm" = "video",

      # ============ ARCHIVES ============
      "zip" = "zip",
      "tar" = "zip",
      "gz" = "zip",
      "gzip" = "zip",
      "bz2" = "zip",
      "xz" = "zip",
      "rar" = "zip",
      "7z" = "zip",
      "tgz" = "zip",
      "tar.gz" = "zip",

      # ============ FONTS ============
      "ttf" = "font",
      "otf" = "font",
      "woff" = "font",
      "woff2" = "font",
      "eot" = "font",

      # ============ BUILD/PACKAGE ============
      "lock" = "lock",
      "gradle" = "gradle",
      "cmake" = "cmake",
      "bazel" = "bazel",
      "ninja" = "ninja",

      # ============ DEFAULT ============
      # Use "document" as fallback
      "document"
    )

    mk_icon(icon_name)
  }
  rv_files <- reactiveVal(character(0)) # Will be populated when project loads
  currentFile <- reactiveVal("")
  compileLog <- reactiveVal("")
  rv_compiled <- reactiveVal(character(0)) # Initialize empty, update when user logs in
  dockerLog <- reactiveVal("")
  outlineData <- reactiveVal(NULL)
  lintAnnotations <- reactiveVal(list())
  compileAnnotations <- reactiveVal(list())
  commentUpdate <- reactiveVal(0)

  # --- REAL-TIME LINTING (restored from legacy app) ---
  # Debounced observer fires 1 second after last keystroke; never waits for compilation
  lint_trigger <- reactive({
    input$sourceEditor
  }) %>%
    debounce(1000)

  observeEvent(lint_trigger(), {
    req(activeProjectId())
    req(currentFile())

    # Only run on .tex files
    if (!grepl("\\.tex$", currentFile(), ignore.case = TRUE)) {
      lintAnnotations(list())
      session$sendCustomMessage("setAnnotations", compileAnnotations())
      return()
    }

    projDir <- getActiveProjectDir()

    # Write current editor content to a temp hidden file so chktex can read it
    actual_filename <- basename(currentFile())
    temp_lint_filename <- paste0(".lint_", actual_filename)
    temp_lint_path <- file.path(projDir, temp_lint_filename)

    tryCatch(
      writeLines(input$sourceEditor, temp_lint_path),
      error = function(e) return()
    )

    # Run chktex inside the texlive Docker image (already pulled on your machine)
    fmt <- "%l|%c|%d|%k|%m\n"
    docker_args <- c(
      "run", "--rm",
      "-v", paste0(normalizePath(projDir), ":/project"),
      "-w", "/project",
      "texlive/texlive:latest",
      "chktex", "-q", "-v0", "-f", fmt,
      temp_lint_filename
    )

    output_raw <- tryCatch({
      res <- processx::run("docker", docker_args, error_on_status = FALSE, timeout = 5)
      res$stdout
    }, error = function(e) "")

    # Clean up temp file
    if (file.exists(temp_lint_path)) unlink(temp_lint_path)

    # Parse chktex output
    annotations <- list()
    if (nzchar(output_raw)) {
      raw_lines <- strsplit(output_raw, "\n")[[1]]
      for (raw_line in raw_lines) {
        parts <- strsplit(raw_line, "\\|")[[1]]
        if (length(parts) >= 5) {
          row <- max(0, as.integer(parts[1]) - 1)
          col <- max(0, as.integer(parts[2]) - 1)
          kind_char <- toupper(substr(trimws(parts[4]), 1, 1))
          type <- switch(kind_char, "E" = "error", "W" = "warning", "M" = "info", "info")
          annotations[[length(annotations) + 1]] <- list(
            row = row, column = col, text = parts[5], type = type
          )
        }
      }
    }

    # Merge with persistent compilation annotations and push to Ace
    lintAnnotations(annotations)
    session$sendCustomMessage("setAnnotations", c(isolate(compileAnnotations()), annotations))
  })

  # Function to load user preferences and state
  loadUserAppCache <- function(uid) {
    req(uid)
    cacheDir <- getUserAppCacheDir(uid)
    if (is.null(cacheDir) || !dir.exists(cacheDir)) {
      return()
    }

    compileLogFile <- file.path(cacheDir, "compileLog.txt")
    dockerLogFile <- file.path(cacheDir, "dockerLog.txt")
    themeFile <- file.path(cacheDir, "theme.txt")
    lastFileFile <- file.path(cacheDir, "lastFile.txt")
    activeProjectFile <- file.path(cacheDir, "activeProject.txt")

    # Compile Logs
    cachedCompileLog <- ""
    cachedDockerLog <- ""
    if (file.exists(compileLogFile)) {
      cachedCompileLog <- paste(
        readLines(compileLogFile, warn = FALSE),
        collapse = "\n"
      )
      compileLog(cachedCompileLog)
    }
    if (file.exists(dockerLogFile)) {
      cachedDockerLog <- paste(
        readLines(dockerLogFile, warn = FALSE),
        collapse = "\n"
      )
    }
    if (nchar(cachedCompileLog) > 0 || nchar(cachedDockerLog) > 0) {
      combinedLog <- paste(
        c(cachedCompileLog, cachedDockerLog),
        collapse = ifelse(
          nzchar(cachedCompileLog) && nzchar(cachedDockerLog),
          "\n",
          ""
        )
      )
      dockerLog(combinedLog)
      updateAceEditor(session, "dockerConsole", value = combinedLog)
    }

    # Theme
    if (file.exists(themeFile)) {
      savedTheme <- readLines(themeFile, warn = FALSE)
      updateAceEditor(session, "sourceEditor", theme = savedTheme)
      updateAceEditor(session, "dockerConsole", theme = savedTheme)
      session$sendCustomMessage(
        "saveSettingsToLocal",
        list(editorTheme = savedTheme)
      )
    }

    # Last File (Loaded after Active Project)

    # Active Project
    if (file.exists(activeProjectFile)) {
      lastProj <- readLines(activeProjectFile, warn = FALSE)
      if (nzchar(lastProj)) {
        # Verify project exists
        pDir <- getUserProjectDir(uid)
        projPath <- file.path(pDir, lastProj)

        if (dir.exists(projPath)) {
          showHomepage(FALSE)
          loadProjectToWorkspace(lastProj)

          # --- THE FIX STARTS HERE ---
          # Restore last file content if available
          if (file.exists(lastFileFile)) {
            lastF <- readLines(lastFileFile, warn = FALSE)
            # 1. Collapse to ensure single string (safety against vector output)
            lastF <- paste(lastF, collapse = "")

            # 2. Check if filename is not empty
            if (nzchar(trimws(lastF))) {
              fullPath <- file.path(projPath, lastF)

              # 3. Check if exists AND is NOT a directory (Fixes the crash)
              if (file.exists(fullPath) && !dir.exists(fullPath)) {
                # CRITICAL: Use 'later' to delay this until AFTER the UI swap is done.
                later::later(
                  function() {
                    # 1. Read and Load Content
                    content <- paste(
                      readLines(fullPath, warn = FALSE),
                      collapse = "\n"
                    )
                    aceMode <- getAceModeFromExtension(lastF)

                    session$sendCustomMessage(
                      "cmdSafeLoadFile",
                      list(
                        content = content,
                        mode = aceMode
                      )
                    )

                    # 2. Update Reactive Values (Triggers UI updates)
                    currentFile(lastF)
                    updateStatus(lastF)

                    # 3. Explicitly Render Comments & Cursor
                    later::later(
                      function() {
                        # Restore Cursor
                        session$sendCustomMessage(
                          'cursorRestore',
                          list(file = lastF)
                        )

                        # Restore Comments (Force Render)
                        cmts <- loadComments(lastProj, lastF)
                        session$sendCustomMessage(
                          "renderCommentMarkers",
                          list(
                            comments = cmts,
                            force = TRUE
                          )
                        )

                        # Ensure the "Gate" is open
                        rv$editor_active <- TRUE
                      },
                      0.2
                    )
                  },
                  0.8
                ) # Delay execution by 0.8 seconds
              }
            }
          }
          # --- THE FIX ENDS HERE ---
        }
      }
    }

    # UI Settings
    uiSettingsFile <- file.path(cacheDir, ".uiSettings.json")
    if (file.exists(uiSettingsFile)) {
      tryCatch(
        {
          savedUI <- jsonlite::fromJSON(readLines(uiSettingsFile, warn = FALSE))
          uiSettings$dockerConsoleVisible <- savedUI$dockerConsoleVisible
          uiSettings$pdfPreviewSizes <- savedUI$pdfPreviewSizes
          if (!is.null(savedUI$pdfPreviewVisible)) {
            uiSettings$pdfPreviewVisible <- savedUI$pdfPreviewVisible
          }
          session$sendCustomMessage(
            "applyUISettings",
            list(
              dockerConsoleVisible = isolate(uiSettings$dockerConsoleVisible),
              pdfPreviewSizes = c(0, isolate(uiSettings$pdfPreviewSizes)),
              pdfPreviewVisible = isolate(uiSettings$pdfPreviewVisible)
            )
          )
        },
        error = function(e) {}
      )
    }
  }

  # --------------------------------------------------------------------------
  # FIX: Load cached active project (Robust Sequence) - DEPRECATED
  # --------------------------------------------------------------------------
  if (FALSE) {
    # activeProjectFile is undefined in global scope
    savedProjectId <- NULL # readLines(activeProjectFile, warn = FALSE)
    if (length(savedProjectId) > 0 && nzchar(savedProjectId)) {
      # Verify project still exists
      projects <- loadProjects()
      projectExists <- any(sapply(projects, function(p) {
        !is.null(p$id) && p$id == savedProjectId
      }))

      if (projectExists) {
        # Restore the active project
        activeProjectId(savedProjectId)
        activeProject(savedProjectId)
        showHomepage(FALSE)

        # Load project workspace
        session$onFlushed(
          function() {
            success <- loadProjectToWorkspace(savedProjectId)
            if (success) {
              # Find the main file
              uid <- isolate(user_session$user_info$user_id)
              if (!is.null(uid)) {
                pDir <- getUserProjectDir(uid)
                projDir <- file.path(pDir, savedProjectId)
              } else {
                projDir <- ""
              }
              mainFile <- NULL

              for (proj in projects) {
                if (
                  proj$id == savedProjectId &&
                    !is.null(proj$mainFile) &&
                    nzchar(proj$mainFile)
                ) {
                  mainFile <- proj$mainFile
                  break
                }
              }

              if (
                !is.null(mainFile) && file.exists(file.path(projDir, mainFile))
              ) {
                # --- STEP 1: PREVENT BLEEDING (Client Side) ---
                session$sendCustomMessage("clearLocalAnchors", list())

                # --- STEP 2: LOAD CONTENT ---
                content <- paste(
                  readLines(file.path(projDir, mainFile), warn = FALSE),
                  collapse = "\n"
                )
                aceMode <- getAceModeFromExtension(mainFile)

                # SAFE LOAD (Prevents Undo Bleeding)
                session$sendCustomMessage(
                  "cmdSafeLoadFile",
                  list(
                    content = content,
                    mode = aceMode
                  )
                )
                currentFile(mainFile)
                updateStatus(mainFile)

                # --- STEP 3: ASYNC RESTORATION (Delayed & Context Aware) ---
                later::later(
                  function() {
                    # THIS WRAPPER FIXES THE SHINYJS CRASH:
                    shiny::withReactiveDomain(session, {
                      isolate({
                        # A. Restore Cursor
                        savedRow <- 0
                        savedCol <- 0
                        currentProjs <- loadProjects()
                        for (p in currentProjs) {
                          if (p$id == savedProjectId) {
                            if (!is.null(p$cursorRow)) {
                              savedRow <- p$cursorRow
                            }
                            if (!is.null(p$cursorCol)) {
                              savedCol <- p$cursorCol
                            }
                            break
                          }
                        }

                        session$sendCustomMessage(
                          'cursorRestore',
                          list(
                            file = mainFile,
                            row = savedRow,
                            column = savedCol
                          )
                        )

                        # B. Load & Render Comments (FORCE update)
                        specificComments <- loadComments(
                          savedProjectId,
                          mainFile
                        )
                        session$sendCustomMessage(
                          "renderCommentMarkers",
                          list(
                            comments = specificComments,
                            force = TRUE
                          )
                        )

                        # C. Refresh UI
                        commentUpdate(commentUpdate() + 1)

                        # D. Load Bib/Labels (These use shinyjs::runjs, so they need the wrapper)
                        pushBibCitations(content, projDir)
                        pushLabelKeys(content)
                      })
                    })
                  },
                  0.5
                )
              }
            }
          },
          once = TRUE
        )
      }
    }
  }

  uiSettings <- reactiveValues(
    dockerConsoleVisible = TRUE,
    pdfPreviewSizes = c(96, 4),
    pdfPreviewVisible = TRUE
  )
  # UI settings loading moved to loadUserAppCache

  saveUISettings <- function() {
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return()
    }
    cacheDir <- getUserAppCacheDir(uid)
    if (is.null(cacheDir)) {
      return()
    }

    settings <- list(
      dockerConsoleVisible = uiSettings$dockerConsoleVisible,
      pdfPreviewSizes = uiSettings$pdfPreviewSizes,
      pdfPreviewVisible = uiSettings$pdfPreviewVisible
    )
    writeLines(
      toJSON(settings, auto_unbox = TRUE, pretty = TRUE),
      file.path(cacheDir, ".uiSettings.json")
    )
  }
  observeEvent(input$pdfPreviewSizes, {
    uiSettings$pdfPreviewSizes <- input$pdfPreviewSizes
    saveUISettings()
  })

  # Drag-n-drop move
  observeEvent(
    input$dragDropMove,
    {
      req(input$dragDropMove$file)
      req(input$dragDropMove$folder)
      projDir <- getActiveProjectDir()
      req(projDir)

      oldRelPath <- input$dragDropMove$file
      newFolderRel <- input$dragDropMove$folder
      oldPath <- file.path(projDir, oldRelPath)
      newPath <- if (newFolderRel == "" || newFolderRel == ".") {
        file.path(projDir, basename(oldRelPath))
      } else {
        file.path(projDir, newFolderRel, basename(oldRelPath))
      }

      if (!dir.exists(dirname(newPath))) {
        dir.create(dirname(newPath), recursive = TRUE)
      }
      if (file.exists(oldPath)) {
        file.rename(oldPath, newPath)
        rv_files(getVisibleFiles(projDir))
      }
    },
    ignoreNULL = TRUE
  )

  # Settings round-trip (persist + reflect)
  observeEvent(
    input$saveSettings,
    {
      settings <- input$saveSettings
      if (!is.null(settings$editorTheme) && settings$editorTheme != "") {
        updateAceEditor(session, "sourceEditor", theme = settings$editorTheme)
        updateAceEditor(session, "dockerConsole", theme = settings$editorTheme)

        uid <- isolate(user_session$user_info$user_id)
        if (!is.null(uid)) {
          cacheDir <- getUserAppCacheDir(uid)
          if (!is.null(cacheDir)) {
            writeLines(settings$editorTheme, file.path(cacheDir, "theme.txt"))
          }
        }
      }
      if (
        !is.null(settings$fontSize) && !is.na(as.numeric(settings$fontSize))
      ) {
        fs <- as.numeric(settings$fontSize)
        updateAceEditor(session, "sourceEditor", fontSize = fs)
        updateAceEditor(session, "dockerConsole", fontSize = fs)
        session$sendCustomMessage(
          "updateStatus",
          paste0("Font size set to ", fs)
        )
      }
      if (!is.null(settings$showDocker)) {
        uiSettings$dockerConsoleVisible <- as.logical(settings$showDocker)
        session$sendCustomMessage(
          'applyUISettings',
          list(dockerConsoleVisible = uiSettings$dockerConsoleVisible)
        )
      }
      if (!is.null(settings$showPdf)) {
        uiSettings$pdfPreviewVisible <- as.logical(settings$showPdf)
        session$sendCustomMessage(
          'applyUISettings',
          list(pdfPreviewVisible = uiSettings$pdfPreviewVisible)
        )
      }
      if (!is.null(settings$autocomplete)) {
        if (isTRUE(as.logical(settings$autocomplete))) {
          updateAceEditor(session, "sourceEditor", autoComplete = "live")
        } else {
          updateAceEditor(session, "sourceEditor", autoComplete = "disabled")
        }
      }
      if (!is.null(settings$tabSize) && !is.na(as.numeric(settings$tabSize))) {
        ts <- as.numeric(settings$tabSize)
        updateAceEditor(session, "sourceEditor", tabSize = ts)
      }
      if (!is.null(settings$wordWrap)) {
        updateAceEditor(
          session,
          "sourceEditor",
          wordWrap = as.logical(settings$wordWrap)
        )
      }
      if (!is.null(settings$lineNumbers)) {
        updateAceEditor(
          session,
          "sourceEditor",
          showLineNumbers = as.logical(settings$lineNumbers)
        )
      }
      saveUISettings()
      session$sendCustomMessage('saveSettingsToLocal', settings)
      later(
        function() {
          try(updateAceEditor(
            session,
            "sourceEditor",
            value = isolate(input$sourceEditor)
          ))
        },
        0.05
      )
    },
    ignoreNULL = TRUE
  )

  observeEvent(currentFile(), {
    val <- currentFile()
    uid <- isolate(user_session$user_info$user_id)
    if (!is.null(val) && !is.null(uid)) {
      cacheDir <- getUserAppCacheDir(uid)
      if (!is.null(cacheDir)) {
        writeLines(val, file.path(cacheDir, "lastFile.txt"))
      }
    }
  })

  updateStatus <- function(txt) {
    session$sendCustomMessage("updateStatus", txt)
  }

  # Immediate UI update for unsaved (dirty) files ---
  observeEvent(
    input$sourceEditor,
    {
      req(currentFile())

      # Do not trigger if the file was just programmatically loaded
      if (isTRUE(rv$fileJustLoaded)) {
        return()
      }

      # Create a visually distinct unsaved state
      dirty_html <- paste0(
        "<span style='color: orange; font-style: italic;'>",
        currentFile(),
        "*</span>"
      )
      updateStatus(dirty_html)
    },
    ignoreInit = TRUE
  )

  appendDockerLog <- function(msg) {
    newLog <- paste0(dockerLog(), msg, "\n")
    dockerLog(newLog)
    updateAceEditor(session, "dockerConsole", value = newLog)
    session$sendCustomMessage("scrollDockerConsole", "")
  }
  appendLog <- function(msg) {
    newLog <- paste0(compileLog(), msg, "\n")
    compileLog(newLog)
    appendDockerLog(msg)
  }
  refreshCompiled <- function() {
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return()
    }
    uCompiledDir <- getUserCompiledDir(uid)
    rv_compiled(list.files(uCompiledDir))
  }

  output$fileListSidebar <- renderUI({
    # Show spinner while rendering
    session$sendCustomMessage("toggleFilesSpinner", TRUE)

    # Triggers
    dummy <- rv_files()
    activePath <- currentFile()

    projDir <- getActiveProjectDir()
    if (is.null(projDir)) {
      return(tags$div(
        class = "filetree-wrap",
        style = "padding:12px; color:var(--bs-secondary-color);",
        tags$em("No project loaded.")
      ))
    }

    projId <- activeProjectId()

    # Recursive function to build the file tree UI
    build_tree_recursive <- function(current_rel_path = "") {
      full_path <- file.path(projDir, current_rel_path)

      # List files in current directory
      items <- list.files(full_path, full.names = FALSE, include.dirs = TRUE)

      # --- NEW: HIDE CACHE AND CHAT FOLDERS FROM UI ---
      items <- items[!items %in% c("compiled_cache", "chat_files", "history")]
      items <- items[!grepl("\\.json$", items, ignore.case = TRUE)]

      if (length(items) == 0) {
        return(NULL)
      }

      # Sort: Folders first, then files, both alphabetical
      is_dir <- dir.exists(file.path(full_path, items))

      df <- data.frame(
        name = items,
        is_dir = is_dir,
        stringsAsFactors = FALSE
      )

      # Order: Directories (TRUE > FALSE) descending, Names ascending
      df <- df[order(-df$is_dir, df$name), ]

      # Generate UI elements
      ui_elems <- lapply(seq_len(nrow(df)), function(i) {
        item_name <- df$name[i]
        item_is_dir <- df$is_dir[i]

        # Construct relative path for this item
        item_rel_path <- if (current_rel_path == "") {
          item_name
        } else {
          file.path(current_rel_path, item_name)
        }

        # ID for context menus
        safeId <- paste0(projId, "_", gsub("[^A-Za-z0-9]", "_", item_rel_path))

        if (item_is_dir) {
          # --- FOLDER NODE ---
          tags$li(
            style = "list-style: none; margin-bottom: 2px;",
            div(
              class = "filetree-item-row folder-item",
              `data-path` = item_rel_path,
              style = "display: flex; align-items: center; cursor: pointer; padding: 4px 0; border-radius: var(--tblr-border-radius);",

              # Chevron Toggle
              span(
                class = "filetree-toggle",
                style = "width: 24px; display: inline-flex; justify-content: center; align-items: center; color: var(--bs-secondary-color); transition: transform 0.2s; height: 24px;",
                onclick = "var childUl = this.parentElement.nextElementSibling; childUl.classList.toggle('d-none'); this.querySelector('i').classList.toggle('fa-chevron-right'); this.querySelector('i').classList.toggle('fa-chevron-down'); event.stopPropagation();",
                tags$i(
                  class = "fa-solid fa-chevron-down",
                  style = "font-size: 0.75rem;"
                )
              ),

              # Icon & Name
              span(
                class = "filetree-label folder-name",
                style = "flex: 1; display: flex; align-items: center; gap: 8px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; padding-left: 4px;",
                # Folder click toggles expansion
                onclick = "this.parentElement.querySelector('.filetree-toggle').click();",
                icon(
                  "folder",
                  style = "color: var(--tblr-primary); opacity: 1;"
                ),
                item_name
              ),

              # Kebab Menu
              div(
                class = "kebab-wrap",
                style = "padding-right: 8px;",
                # Add stopPropagation here so clicking menu doesn't toggle folder
                onclick = "event.stopPropagation();",

                # --- WRAPPER FOR TOOLTIP ---
                tags$span(
                  title = "More actions",
                  `data-bs-toggle` = "tooltip",
                  `data-bs-placement` = "bottom",

                  tags$button(
                    class = "kebab-btn",
                    `aria-label` = "Folder actions",
                    `data-menu-id` = paste0("menu_", safeId),
                    "⋮"
                  )
                ),
                # ---------------------------

                tags$div(
                  id = paste0("menu_", safeId),
                  class = "context-menu",
                  tags$a(
                    class = "menu-item",
                    `data-id` = paste0("download_", safeId),
                    `data-action` = "trigger",
                    "Download"
                  ),
                  tags$a(
                    class = "menu-item",
                    `data-id` = paste0("rename_", safeId),
                    `data-action` = "trigger",
                    "Rename"
                  ),
                  tags$a(
                    class = "menu-item",
                    `data-id` = paste0("delete_", safeId),
                    `data-action` = "trigger",
                    "Delete"
                  )
                )
              )
            ),
            # Children Container
            tags$ul(
              class = "filetree-children",
              style = "list-style: none; padding-left: 0; margin: 0; margin-left: 12px; border-left: 1px solid var(--tblr-secondary);",
              build_tree_recursive(item_rel_path)
            )
          )
        } else {
          # --- FILE NODE (UPDATED) ---
          isEditable <- tolower(tools::file_ext(item_name)) %in% text_extensions
          isActive <- !is.null(activePath) &&
            identical(item_rel_path, activePath)

          tags$li(
            style = "list-style: none; margin-bottom: 2px;",
            div(
              class = paste0(
                "filetree-item-row file-item",
                if (isActive) " active" else ""
              ),
              draggable = "true",
              `data-path` = item_rel_path,
              `data-editable` = tolower(isEditable),
              style = "display: flex; align-items: center; cursor: pointer; padding: 4px 0; border-radius: var(--tblr-border-radius);",

              # SINGLE CLICK HANDLER
              onclick = sprintf(
                "
                  var path = '%s';
                  var isEditable = %s;
                  if (window.Shiny && Shiny.setInputValue) {
                    Shiny.setInputValue('fileClick', {
                      path: path,
                      isEditable: isEditable,
                      nonce: Math.random()
                    }, {priority: 'event'});
                  }
                ",
                item_rel_path,
                tolower(isEditable)
              ),

              # Spacer
              span(style = "width: 24px; display: inline-block;"),

              # Icon & Name
              span(
                class = "filetree-label file-name",
                # 1. min-width: 0 is CRITICAL. It tells the flex container it's allowed to shrink.
                style = "flex: 1; display: flex; align-items: center; gap: 8px; min-width: 0; padding-left: 4px;",

                getFileIcon(item_name),

                # 2. Wrap the text in a span and apply truncation here
                span(
                  item_name,
                  style = "overflow: hidden; text-overflow: ellipsis; white-space: nowrap;"
                )
              ),

              # Kebab Menu
              div(
                class = "kebab-wrap",
                style = "padding-right: 8px;",
                # Add stopPropagation here so clicking menu doesn't open file
                onclick = "event.stopPropagation();",

                # --- WRAPPER FOR TOOLTIP ---
                tags$span(
                  title = "More actions",
                  `data-bs-toggle` = "tooltip",
                  `data-bs-placement` = "bottom",

                  tags$button(
                    class = "kebab-btn",
                    `aria-label` = "File actions",
                    `data-menu-id` = paste0("menu_", safeId),
                    "⋮"
                  )
                ),
                # ---------------------------

                tags$div(
                  id = paste0("menu_", safeId),
                  class = "context-menu",
                  tags$a(
                    class = "menu-item",
                    `data-id` = paste0("download_", safeId),
                    `data-action` = "trigger",
                    "Download"
                  ),
                  tags$a(
                    class = "menu-item",
                    `data-id` = paste0("rename_", safeId),
                    `data-action` = "trigger",
                    "Rename"
                  ),
                  tags$a(
                    class = "menu-item",
                    `data-id` = paste0("delete_", safeId),
                    `data-action` = "trigger",
                    "Delete"
                  )
                )
              )
            )
          )
        }
      })

      # Hide spinner after render completes
      session$onFlushed(
        function() {
          session$sendCustomMessage("toggleFilesSpinner", FALSE)
        },
        once = TRUE
      )

      return(ui_elems)
    }

    # CSS: Uses !important to enforce the lighter background over the drag-drop classes
    styles <- tags$style(HTML(
      "
        /* Reuse hover and active styles */
        .filetree-item-row:hover {
          background-color: var(--tblr-border-color) !important;
        }
        .filetree-item-row:hover .filetree-toggle {
          background-color: var(--tblr-border-color) !important;
        }
        .filetree-item-row.active {
          background-color: var(--tblr-border-color) !important;
          border-left: 4px solid var(--tblr-primary) !important;
        }
        
        /* Ensure icons have consistent size */
        .filetree-label i {
          width: 16px;
          text-align: center;
        }

        /* Kebab menu visibility on hover */
        .filetree-item-row .kebab-wrap {
          opacity: 0;
          transition: opacity 0.2s;
        }
        .filetree-item-row:hover .kebab-wrap {
          opacity: 1;
        }
        .context-menu.open ~ .kebab-wrap {
          opacity: 1;
        }
      "
    ))

    # Main Output with Root Drop Wrapper
    tagList(
      styles,
      tags$div(
        class = "folder-item",
        `data-path` = ".",
        style = "min-height: 100%; background-color: transparent !important; color: inherit !important; display: block !important; padding: 0 !important; cursor: default !important; border: none !important;",

        tags$ul(
          style = "padding-left: 5px; margin: 0;",
          build_tree_recursive("")
        )
      )
    )
  })

