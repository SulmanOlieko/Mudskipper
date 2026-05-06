  # =================== TABLER MODAL HANDLERS ===================

  # New File Handler (Updated for Overlay)
  observeEvent(
    input$createNewFileTrigger,
    {
      req(input$createNewFileTrigger$name)

      # Check if type is provided; if not, extract it from name
      rawName <- trimws(input$createNewFileTrigger$name)
      suppliedType <- input$createNewFileTrigger$type

      if (is.null(suppliedType) || suppliedType == "") {
        # User typed full name (e.g., "script.R")
        fileExtension <- paste0(".", tools::file_ext(rawName))
        fileName <- tools::file_path_sans_ext(rawName)

        # If no extension was typed, default to .tex
        if (fileExtension == ".") {
          fileExtension <- ".tex"
          fileName <- rawName
        }
        fileType <- fileExtension
      } else {
        # Fallback for old behavior if needed
        fileName <- rawName
        fileType <- suppliedType
      }

      projDir <- getActiveProjectDir()
      req(projDir)

      # Ensure unique naming for common names
      if (
        fileName %in%
          c("main", "document", "paper", "thesis") &&
          fileType == ".tex"
      ) {
        # Check if specific file exists before appending timestamp
        if (file.exists(file.path(projDir, paste0(fileName, fileType)))) {
          fileName <- paste0(fileName, "_", format(Sys.time(), "%Y%m%d_%H%M%S"))
        }
      }

      new_name <- paste0(fileName, fileType)
      new_path <- file.path(projDir, new_name)

      if (file.exists(new_path)) {
        showTablerAlert(
          "warning",
          "File already exists",
          paste("A file named", new_name, "already exists."),
          5000
        )
      } else {
        # Create file with template content based on type
        content <- switch(
          fileType,
          ".tex" = paste(
            "\\documentclass{article}",
            "\\title{Your LaTeX Document}",
            "\\author{User}",
            "\\date{\\today}",
            "",
            "\\begin{document}",
            "\\maketitle",
            "",
            "\\section{Introduction}",
            "Start writing here.",
            "",
            "\\end{document}",
            sep = "\n"
          ),
          ".bib" = paste(
            "@article{example2025,",
            "  author = {Smith, John},",
            "  title = {Example Title},",
            "  journal = {Journal of Examples},",
            "  year = {2025}",
            "}",
            sep = "\n"
          ),
          "" # Empty for other types
        )

        writeLines(content, new_path)
        rv_files(getVisibleFiles(projDir))

        # Load the new file into editor
        updateAceEditor(session, "sourceEditor", value = content)
        currentFile(new_name)
        updateStatus(paste0(new_name, " created"))
        session$sendCustomMessage('cursorRestore', list(file = new_name))

        # If the new file is a .tex file, force it to be the main project file immediately
        if (fileType == ".tex") {
          updateProjectMainFilePreference(activeProjectId(), new_name)
          # Force UI update immediately so compile button works right away
          updateSelectInput(session, "compileMainFile", selected = new_name)
        }

        showTablerAlert(
          "success",
          "File created",
          paste("Successfully created", new_name),
          5000
        )

        if (!is.null(activeProjectId())) {
          updateProjectFileCount(activeProjectId())
        }
      }
    },
    ignoreInit = TRUE
  )

  # New Folder Handler
  observeEvent(
    input$createNewFolderTrigger,
    {
      req(input$createNewFolderTrigger$name)

      projDir <- getActiveProjectDir()
      req(projDir)

      folderName <- trimws(input$createNewFolderTrigger$name)
      new_folder_path <- file.path(projDir, folderName)

      if (dir.exists(new_folder_path) || file.exists(new_folder_path)) {
        showTablerAlert(
          "warning",
          "Folder already exists",
          paste("A folder named", folderName, "already exists."),
          5000
        )
      } else {
        dir.create(new_folder_path, recursive = TRUE)
        rv_files(getVisibleFiles(projDir))

        showTablerAlert(
          "success",
          "Folder created",
          paste("Successfully created folder", folderName),
          5000
        )

        if (!is.null(activeProjectId())) {
          updateProjectFileCount(activeProjectId())
        }
      }
    },
    ignoreInit = TRUE
  )

  # Dropzone Upload Handler
  observeEvent(
    input$dropzoneFiles,
    {
      req(input$dropzoneFiles$files)

      projDir <- getActiveProjectDir()
      if (is.null(projDir)) {
        showTablerAlert("danger", "No project loaded", "You have no active project(s).", 5000)
        return()
      }

      files <- input$dropzoneFiles$files
      uploadedCount <- 0
      failedFiles <- character(0)

      for (i in seq_along(files)) {
        fileInfo <- files[[i]]

        tryCatch(
          {
            # Validate file info
            if (is.null(fileInfo$name) || is.null(fileInfo$data)) {
              failedFiles <- c(failedFiles, "Unknown file")
              next
            }

            # Decode base64 data
            dataURI <- fileInfo$data

            # Remove data URI prefix (e.g., "data:image/png;base64,")
            base64Data <- sub("^data:.*?;base64,", "", dataURI)

            # Decode and write file
            rawData <- base64enc::base64decode(base64Data)

            # Sanitize filename
            safeName <- gsub("[^A-Za-z0-9._-]", "_", fileInfo$name)
            destPath <- file.path(projDir, safeName)

            # Check if file already exists
            if (file.exists(destPath)) {
              # Add timestamp to make unique
              nameparts <- tools::file_path_sans_ext(safeName)
              ext <- tools::file_ext(safeName)
              safeName <- paste0(
                nameparts,
                "_",
                format(Sys.time(), "%Y%m%d_%H%M%S"),
                if (nchar(ext) > 0) paste0(".", ext) else ""
              )
              destPath <- file.path(projDir, safeName)
            }

            writeBin(rawData, destPath)

            uploadedCount <- uploadedCount + 1
          },
          error = function(e) {
            cat("Error uploading file", fileInfo$name, ":", e$message, "\n")
            failedFiles <- c(failedFiles, fileInfo$name)
          }
        )
      }

      # Refresh file list
      rv_files(getVisibleFiles(projDir))

      # Show results
      if (uploadedCount > 0) {
        showTablerAlert(
          "success",
          "Upload complete",
          paste("Successfully uploaded", uploadedCount, "file(s)."),
          5000
        )
      }

      if (length(failedFiles) > 0) {
        showTablerAlert(
          "warning",
          "Some uploads failed",
          paste("Failed:", paste(failedFiles, collapse = ", ")),
          5000
        )
      }

      if (!is.null(activeProjectId())) {
        updateProjectFileCount(activeProjectId())
      }
    },
    ignoreInit = TRUE
  )

  # --- Import Project from Archive Handler ---
  observeEvent(input$importZipTrigger, {
    req(input$importZipTrigger)

    data <- input$importZipTrigger
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return()
    }

    pDir <- getUserProjectDir(uid)

    # 1. Determine Project Name
    raw_name <- if (nzchar(data$customName)) {
      data$customName
    } else {
      # Remove all known extensions to get a clean name
      name <- data$filename
      for (ext in c("\\.tar\\.gz$", "\\.tgz$", "\\.tar$", "\\.zip$")) {
        name <- sub(ext, "", name, ignore.case = TRUE)
      }
      name
    }

    proj_name <- trimws(raw_name)
    if (!nzchar(proj_name)) {
      proj_name <- "Untitled Import"
    }

    # Generate ID
    new_id <- uuid::UUIDgenerate()

    # 2. Create Project Directory
    new_proj_dir <- file.path(pDir, new_id)
    if (!dir.exists(new_proj_dir)) {
      dir.create(new_proj_dir, recursive = TRUE)
    }

    tryCatch(
      {
        # 3. Save and Extract based on extension
        # We attempt to determine the extension from the original filename
        file_lower <- tolower(data$filename)

        if (grepl("\\.zip$", file_lower)) {
          # --- Handle ZIP ---
          temp_file <- file.path(new_proj_dir, "upload.zip")
          writeBin(base64enc::base64decode(data$content), temp_file)
          utils::unzip(temp_file, exdir = new_proj_dir)
          file.remove(temp_file)
        } else if (grepl("(\\.tar\\.gz|\\.tgz|\\.tar)$", file_lower)) {
          # --- Handle TAR / TAR.GZ ---
          # Note: untar handles gzip automatically if supported by system or internal method
          temp_file <- file.path(new_proj_dir, "upload.tar.gz")
          writeBin(base64enc::base64decode(data$content), temp_file)
          utils::untar(temp_file, exdir = new_proj_dir)
          file.remove(temp_file)
        } else {
          stop("Unsupported file format.")
        }

        # 4. Cleanup Garbage (MACOSX hidden folders)
        macosx_dir <- file.path(new_proj_dir, "__MACOSX")
        if (dir.exists(macosx_dir)) {
          unlink(macosx_dir, recursive = TRUE)
        }

        # Also cleanup common hidden files that might pollute the project
        hidden_files <- list.files(
          new_proj_dir,
          pattern = "^\\._",
          full.names = TRUE,
          recursive = TRUE
        )
        if (length(hidden_files) > 0) {
          unlink(hidden_files)
        }

        # 5. Metadata for projects.json
        files <- list.files(new_proj_dir, pattern = "\\.tex$", recursive = TRUE)
        main_file <- if (length(files) > 0) files[1] else ""

        all_files <- list.files(new_proj_dir, recursive = TRUE)
        file_count <- length(all_files)

        projects <- loadProjects()
        new_project <- list(
          id = new_id,
          name = proj_name,
          description = paste("Imported from", data$filename),
          created = as.character(Sys.time()),
          lastEdited = as.character(Sys.time()),
          mainFile = main_file,
          fileCount = file_count,
          tags = list()
        )

        projects <- c(list(new_project), projects)
        saveProjects(projects)

        # 6. Trigger UI Refresh
        projectChangeTrigger(projectChangeTrigger() + 1)

        showTablerAlert(
          "success",
          "Import successful",
          paste("Project", proj_name, "has been created successfully."),
          5000
        )
      },
      error = function(e) {
        showTablerAlert("danger", "Import failed", e$message, 5000)
        if (dir.exists(new_proj_dir)) unlink(new_proj_dir, recursive = TRUE)
      }
    )
  })

  # Toggle Visibility of compiled fileds Cache Download Button ---
  observe({
    # Triggers: Project load, compilation finish (via rv_compiled), or file changes
    req(activeProjectId())
    trigger <- rv_compiled()

    projDir <- getActiveProjectDir()
    if (is.null(projDir)) {
      return()
    }

    cacheDir <- file.path(projDir, "compiled_cache")

    # Check if cache exists and has files
    hasCache <- dir.exists(cacheDir) && length(list.files(cacheDir)) > 0

    # Toggle UI visibility
    if (hasCache) {
      shinyjs::show("downloadCacheContainer")
    } else {
      shinyjs::hide("downloadCacheContainer")
    }
  })

  # --- HANDLER: Download Compiled Cache ---
  output$bulkDownloadCompiled <- downloadHandler(
    filename = function() {
      projectName <- "project"
      if (!is.null(activeProjectId())) {
        # Try to get actual project name, fallback to ID
        projects <- loadProjects()
        for (p in projects) {
          if (p$id == activeProjectId()) {
            projectName <- p$name
            break
          }
        }
      }
      cleanName <- gsub("[^A-Za-z0-9_-]", "_", projectName)
      paste0(
        cleanName,
        "_compiled_",
        format(Sys.time(), "%Y%m%d_%H%M%S"),
        ".zip"
      )
    },
    content = function(file) {
      # Use the refactored getActiveProjectDir which now uses uid
      projDir <- getActiveProjectDir()
      req(projDir)

      # We still expect compiled_cache inside the project dir OR user compiled dir
      # The previous logic had: cacheDir <- file.path(projDir, "compiled_cache")
      # But wait, initUserDirectories creates `project/<uid>/compiled/cache`
      # Let's check where saveCompiledToProjectCache puts it.
      # It puts it in `file.path(projDir, "compiled_cache")` usually.
      # Let's assume it stays inside the project directory for now.

      cacheDir <- file.path(projDir, "compiled_cache")

      if (dir.exists(cacheDir)) {
        # List all files in the cache directory
        files <- list.files(cacheDir, full.names = FALSE, recursive = TRUE)

        if (length(files) > 0) {
          # Zip specific cache folder contents
          # 'root' ensures the zip structure starts inside compiled_cache (no parent folders)
          zip::zip(
            zipfile = file,
            files = files,
            root = cacheDir,
            mode = "cherry-pick"
          )
        } else {
          # Fallback empty zip
          zip::zip(zipfile = file, files = character(0))
        }
      } else {
        # Fallback if folder missing
        zip::zip(zipfile = file, files = character(0))
      }
    },
    contentType = "application/zip"
  )

  # ----------------------------- FILE SEARCH SERVER LOGIC -----------------------------

  searchQuery <- reactiveVal(NULL)

  observeEvent(input$fileSearchQuery, {
    searchQuery(input$fileSearchQuery)
  })

  # Defined at top-level so the output exists immediately, regardless of editor mode
  output$fileSearchResults <- renderUI({
    query <- searchQuery()
    if (is.null(query) || nchar(trimws(query)) < 2) {
        return(div(
          style = "text-align:center; color:var(--bs-secondary-color); padding-top:20px;",
          div(
            class = "empty",
            ui_success_illustration(),
            HTML(
              '
                         <p class="empty-title">EMPTY SEARCH</p>
                         <p class="empty-subtitle text-secondary">Type at least 2 characters to search.</p>
            '
            )
          )
        ))
      }

      projDir <- getActiveProjectDir()
      if (is.null(projDir)) {
        return(NULL)
      }

      # 1. Get all files
      all_files <- list.files(projDir, recursive = TRUE)
      # Exclude cache, chat_files, and hidden files
      all_files <- all_files[
        !grepl("^(compiled_cache|chat_files|history)/|/\\.", all_files)
      ]

      results_html <- list()

      # Pre-compile regex for case-insensitive search
      safe_query <- gsub("([.|()\\^{}+$*?]|\\[|\\])", "\\\\\\1", query)

      # Define what we consider "Editable" (Text files) vs "Previewable" (Binary)
      # This prevents the app from crashing by trying to load a PNG into Ace Editor
      editable_exts <- c(
        "tex",
        "bib",
        "bst",
        "cls",
        "sty",
        "txt",
        "rnw",
        "md",
        "json",
        "xml",
        "html",
        "js",
        "css",
        "r",
        "py",
        "sh",
        "yaml",
        "yml",
        "csv"
      )

      for (file_rel in all_files) {
        full_path <- file.path(projDir, file_rel)
        file_name <- basename(file_rel)
        ext <- tolower(tools::file_ext(file_name))

        # Determine if this file should open in Editor (true) or Preview (false)
        is_editable_logical <- ext %in% editable_exts
        is_editable_js <- if (is_editable_logical) "true" else "false"

        matches_found <- FALSE
        snippets <- list()

        # A. CHECK FILENAME
        if (grepl(safe_query, file_name, ignore.case = TRUE)) {
          matches_found <- TRUE
        }

        # B. CHECK CONTENT (Only for editable text extensions)
        if (is_editable_logical && file.size(full_path) < 1024 * 1024 * 10) {
          # Skip files > 10MB

          lines <- tryCatch(
            readLines(full_path, warn = FALSE),
            error = function(e) NULL
          )

          if (!is.null(lines)) {
            match_indices <- grep(safe_query, lines, ignore.case = TRUE)

            if (length(match_indices) > 0) {
              matches_found <- TRUE

              # Limit matches
              display_indices <- head(match_indices, 99)

              for (idx in display_indices) {
                line_content <- lines[idx]

                # Truncate
                if (nchar(line_content) > 100) {
                  m_pos <- regexpr(
                    safe_query,
                    line_content,
                    ignore.case = TRUE
                  )[1]
                  start <- max(1, m_pos - 40)
                  end <- min(nchar(line_content), m_pos + 60)
                  line_content <- paste0(
                    "...",
                    substr(line_content, start, end),
                    "..."
                  )
                }

                # Highlight
                m <- gregexpr(safe_query, line_content, ignore.case = TRUE)
                regmatches(line_content, m) <- lapply(
                  regmatches(line_content, m),
                  function(x) {
                    paste0('<span class="search-highlight">', x, '</span>')
                  }
                )

                # SNIPPET CLICK: Passes 'gotoLine' to jump specific position
                snippets[[length(snippets) + 1]] <- div(
                  class = "search-result-snippet",
                  onclick = sprintf(
                    "
                    // Open file AND go to line
                    if (window.Shiny) Shiny.setInputValue('fileClick', {path: '%s', isEditable: true, gotoLine: %d, nonce: Math.random()}, {priority: 'event'});
                  ",
                    file_rel,
                    idx - 1
                  ), # Ace is 0-indexed
                  span(class = "snippet-line-num", idx),
                  span(class = "snippet-content", HTML(line_content))
                )
              }

              if (length(match_indices) > 99) {
                snippets[[length(snippets) + 1]] <- div(
                  class = "search-result-snippet",
                  style = "font-style: italic;",
                  paste0("...and ", length(match_indices) - 99, " more matches")
                )
              }
            }
          }
        }

        # C. BUILD RESULT CARD
        if (matches_found) {
          file_icon <- getFileIcon(file_name)

          # FILENAME CLICK: Uses calculated 'is_editable_js' to prevent crashing on binaries
          card <- div(
            class = "search-result-group",
            div(
              class = "search-result-file",
              onclick = sprintf(
                "
                            if (window.Shiny) Shiny.setInputValue('fileClick', {path: '%s', isEditable: %s, nonce: Math.random()}, {priority: 'event'});
                          ",
                file_rel,
                is_editable_js
              ),
              file_icon,
              span(file_rel)
            ),
            if (length(snippets) > 0) {
              div(class = "search-result-snippets", snippets)
            }
          )
          results_html[[length(results_html) + 1]] <- card
        }
      }

      if (length(results_html) == 0) {
        return(div(
          style = "text-align:center; padding:20px; color:var(--bs-secondary-color);",
          div(
            class = "empty",
            ui_empty_illustration(),
            HTML(
              '
                         <p class="empty-title">NO MATCHES FOUND</p>
                         <p class="empty-subtitle text-secondary">Search query produced 0 matches.</p>
            '
            )
          )
        ))
      }

      tagList(results_html)
  })
  # -------------------- MAKE A COPY LOGIC --------------------
  observeEvent(input$copyProjectSubmit, {
    req(input$copyProjectSubmit)
    req(activeProjectId())

    oldProjId <- activeProjectId()
    newName <- input$copyProjectSubmit

    # 1. Create New ID and Directory
    newId <- uuid::UUIDgenerate()

    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return()
    }
    pDir <- getUserProjectDir(uid)

    oldDir <- file.path(pDir, oldProjId)
    newDir <- file.path(pDir, newId)

    if (!dir.exists(oldDir)) {
      return()
    }
    dir.create(newDir, recursive = TRUE)

    tryCatch(
      {
        files_to_copy <- list.files(
          oldDir,
          all.files = TRUE,
          full.names = FALSE,
          no.. = TRUE,
          recursive = TRUE
        )
        files_to_copy <- files_to_copy[
          !grepl("^compiled_cache|history|chat_files", files_to_copy)
        ]

        for (f in files_to_copy) {
          from <- file.path(oldDir, f)
          to <- file.path(newDir, f)
          if (dir.exists(from)) {
            dir.create(to, recursive = TRUE, showWarnings = FALSE)
          } else {
            dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
            file.copy(from, to)
          }
        }

        # 3. Update projects.json
        projects <- loadProjects()

        # Find old project data to copy metadata (description, etc)
        oldProjData <- list()
        for (p in projects) {
          if (p$id == oldProjId) {
            oldProjData <- p
            break
          }
        }

        newProject <- list(
          id = newId,
          name = newName,
          description = oldProjData$description %||% "",
          created = as.character(Sys.time()),
          lastEdited = as.character(Sys.time()),
          mainFile = oldProjData$mainFile %||% "",
          fileCount = {
            allFiles <- list.files(
              newDir,
              recursive = TRUE,
              all.files = FALSE,
              no.. = TRUE
            )
            filteredFiles <- allFiles[
              !grepl("^compiled_cache|history|chat_files", allFiles)
            ]
            length(filteredFiles)
          }
        )

        projects <- c(list(newProject), projects)
        saveProjects(projects)

        # 4. Trigger UI Update & Switch
        projectChangeTrigger(projectChangeTrigger() + 1)
        showTablerAlert(
          "success",
          "Project copied",
          paste("Switched to", newName),
          5000
        )

        # Record activity
        recordDailyActivity(activityType = "projectCopy", details = list(
          oldId = oldProjId,
          oldName = oldProjData$name,
          newId = newId,
          newName = newName
        ))

        # Switch workspace
        loadProjectToWorkspace(newId)
      },
      error = function(e) {
        showTablerAlert("danger", "Could not copy project", e$message, 5000)
        # Cleanup
        if (dir.exists(newDir)) unlink(newDir, recursive = TRUE)
      }
    )
  })

  # -------------------- DOWNLOAD HANDLERS --------------------

  # Download PDF
  output$pdf_download_link <- downloadHandler(
    filename = function() {
      pName <- "document"
      projects <- loadProjects()
      for (p in projects) {
        if (p$id == activeProjectId()) {
          pName <- p$name
          break
        }
      }
      paste0(gsub("[^a-zA-Z0-9_-]", "_", pName), ".pdf")
    },
    content = function(file) {
      req(activeProjectId())

      uid <- isolate(user_session$user_info$user_id)
      if (is.null(uid)) {
        stop("User not logged in")
      }

      # Check compiled dir first (user specific)
      uCompiledDir <- getUserCompiledDir(uid)
      pdfPath <- file.path(uCompiledDir, "output.pdf")

      if (!file.exists(pdfPath)) {
        # Check cache (user specific)
        pDir <- getUserProjectDir(uid)
        cachePdf <- file.path(
          pDir,
          activeProjectId(),
          "compiled_cache",
          "output.pdf"
        )
        if (file.exists(cachePdf)) {
          pdfPath <- cachePdf
        } else {
          stop("No PDF available. Please compile the project first.")
        }
      }
      file.copy(pdfPath, file)
    },
    contentType = "application/pdf"
  )
  #==========================

  # ================= FIGURE OVERLAY HANDLERS =================
  # Improved population of lists when overlay opens
  observeEvent(input$figureOverlayOpened, {
    req(activeProjectId())

    # Populate all tabs immediately when overlay opens
    update_figure_tabs()

    # Set sensible defaults for all inputs
    updateTextInput(session, "fig_upload_name", value = "")
    updateTextInput(session, "fig_other_name", value = "")
    updateTextInput(session, "fig_url_name", value = "")
    updateTextInput(session, "fig_upload_label", value = "fig:figure")
    updateTextInput(session, "fig_proj_label", value = "fig:figure")
    updateTextInput(session, "fig_other_label", value = "fig:figure")
    updateTextInput(session, "fig_url_label", value = "fig:figure")
  })

  # Central function to update all figure tabs
  update_figure_tabs <- function() {
    req(activeProjectId())
    projDir <- getActiveProjectDir()

    # --- Tab 2: Project Files ---
    files <- list.files(projDir, recursive = TRUE)
    # Filter for images/pdfs only
    img_files <- files[grepl(
      "\\.(png|jpg|jpeg|gif|pdf|svg)$",
      files,
      ignore.case = TRUE
    )]
    # Exclude system folders
    img_files <- img_files[
      !grepl("^(chat_files|compiled_cache|history|compiled)", img_files)
    ]

    if (length(img_files) > 0) {
      output$figProjFileSelectUI <- renderUI({
        selectInput(
          "figProjFileSelect",
          "Select File",
          choices = c("Choose..." = "", img_files),
          width = "100%",
          selected = ""
        )
      })
    } else {
      output$figProjFileSelectUI <- renderUI({
        div(class = "alert alert-info", "No image files found in this project.")
      })
    }

    # --- Tab 3: Other Projects ---
    all_projects <- loadProjects()
    other_projs <- all_projects[sapply(all_projects, function(p) {
      p$id != activeProjectId()
    })]

    if (length(other_projs) > 0) {
      proj_choices <- setNames(
        sapply(other_projs, function(p) p$id),
        sapply(other_projs, function(p) {
          if (!is.null(p$name) && nzchar(p$name)) p$name else p$id
        })
      )

      output$figOtherProjSelectUI <- renderUI({
        selectInput(
          "figOtherProjSelect",
          "Select Project",
          choices = c("Choose..." = "", proj_choices),
          width = "100%",
          selected = ""
        )
      })
    } else {
      output$figOtherProjSelectUI <- renderUI({
        div(class = "alert alert-info", "No other projects available.")
      })
      # Clear file selection
      output$figOtherFileSelectUI <- renderUI(NULL)
    }
  }

  # Auto-fill name when picking from project files
  observeEvent(input$figProjFileSelect, {
    req(input$figProjFileSelect)
    if (input$figProjFileSelect != "") {
      updateTextInput(session, "fig_proj_name", value = input$figProjFileSelect)
      # Auto-generate label
      baseName <- tools::file_path_sans_ext(basename(input$figProjFileSelect))
      updateTextInput(
        session,
        "fig_proj_label",
        value = paste0("fig:", baseName)
      )
    }
  })

  # Tab 3: Populate Files when Project Selected
  observeEvent(input$figOtherProjSelect, {
    req(input$figOtherProjSelect)
    req(input$figOtherProjSelect != "")

    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return()
    }
    pDir <- getUserProjectDir(uid)

    targetDir <- file.path(pDir, input$figOtherProjSelect)

    if (dir.exists(targetDir)) {
      files <- list.files(targetDir, recursive = TRUE)
      # Filter images, exclude system folders
      files <- files[grepl(
        "\\.(png|jpg|jpeg|gif|pdf|svg)$",
        files,
        ignore.case = TRUE
      )]
      files <- files[
        !grepl("^(chat_files|compiled_cache|history|compiled)", files)
      ]

      if (length(files) > 0) {
        output$figOtherFileSelectUI <- renderUI({
          selectInput(
            "figOtherFileSelect",
            "Select File",
            choices = c("Choose..." = "", files),
            width = "100%",
            selected = ""
          )
        })
      } else {
        output$figOtherFileSelectUI <- renderUI({
          div(
            class = "alert alert-info",
            "No image files found in selected project."
          )
        })
      }
    }
  })

  # Auto-fill name when picking from other project
  observeEvent(input$figOtherFileSelect, {
    req(input$figOtherFileSelect)
    if (input$figOtherFileSelect != "") {
      fileName <- basename(input$figOtherFileSelect)
      updateTextInput(session, "fig_other_name", value = fileName)
      # Auto-generate label
      baseName <- tools::file_path_sans_ext(basename(fileName))
      updateTextInput(
        session,
        "fig_other_label",
        value = paste0("fig:", baseName)
      )
    }
  })

  # --- INSERT HELPERS ---
  insertLatexFigure <- function(path, caption, label, width) {
    # Ensure label has proper prefix
    if (!grepl("^fig:", label)) {
      label <- paste0("fig:", label)
    }

    # Generate LaTeX with proper formatting and spacing
    latex <- sprintf(
      "\\begin{figure}[htbp]\n  \\centering\n  \\includegraphics[width=%s\\linewidth]{%s}\n  \\caption{%s}\n  \\label{%s}\n\\end{figure}",
      width,
      path,
      caption,
      label
    )

    # Insert via Ace
    session$sendCustomMessage("cmdInsertText", list(text = latex))

    # Close Overlay
    shinyjs::runjs("closeFigureOverlay();")
    showTablerAlert(
      "success",
      "Figure inserted",
      "Figure code inserted successfully.",
      5000
    )
  }

  # 1. Upload & Insert (Computer) - FIXED
  observeEvent(input$btnInsertFigUpload, {
    req(input$fig_upload_name)

    # Validation
    if (trimws(input$fig_upload_name) == "") {
      showTablerAlert(
        "warning",
        "No filename",
        "Please enter a filename.",
        5000
      )
      return()
    }

    # Inputs
    caption <- if (
      !is.null(input$fig_upload_caption) &&
        nzchar(trimws(input$fig_upload_caption))
    ) {
      trimws(input$fig_upload_caption)
    } else {
      "Figure caption"
    }

    label <- if (
      !is.null(input$fig_upload_label) && nzchar(trimws(input$fig_upload_label))
    ) {
      trimws(input$fig_upload_label)
    } else {
      paste0("fig:", tools::file_path_sans_ext(basename(input$fig_upload_name)))
    }
    width <- input$fig_upload_width %||% "0.75"

    projDir <- getActiveProjectDir()
    req(projDir)

    # Destination path (uses the renamed text from input, NOT the original filename)
    dest <- file.path(projDir, input$fig_upload_name)

    # LOGIC: Check Dropzone Data First
    if (!is.null(input$figDropzoneData)) {
      tryCatch(
        {
          # 1. Decode Base64
          dataURI <- input$figDropzoneData$data
          # Remove header "data:image/png;base64,"
          base64Data <- sub("^data:.*?;base64,", "", dataURI)
          raw <- base64enc::base64decode(base64Data)

          # 2. Write to Destination (using the custom name)
          writeBin(raw, dest)

          # 3. Insert Code
          insertLatexFigure(input$fig_upload_name, caption, label, width)
          rv_files(getVisibleFiles(projDir))

          # Record activity
          recordDailyActivity(activityType = "fileCreate", details = list(
            projectId = activeProjectId(),
            projectName = getActiveProjectName(),
            file = input$fig_upload_name
          ))

          # 4. Clean up Dropzone UI
          shinyjs::runjs(
            "
          var dz = Dropzone.forElement('#dropzone-figure'); 
          if(dz) dz.removeAllFiles(true);
          Shiny.setInputValue('figDropzoneData', null);
        "
          )
        },
        error = function(e) {
          showTablerAlert(
            "danger",
            "Upload failed",
            sprintf("Could not save file: %s", e$message),
            5000
          )
        }
      )

      # Fallback to standard file input (if dropzone fails or user used fallback)
    } else if (!is.null(input$fig_upload_fallback)) {
      tryCatch(
        {
          file.copy(input$fig_upload_fallback$datapath, dest, overwrite = TRUE)
          insertLatexFigure(input$fig_upload_name, caption, label, width)
          rv_files(getVisibleFiles(projDir))

          # Record activity
          recordDailyActivity(activityType = "fileCreate", details = list(
            projectId = activeProjectId(),
            projectName = getActiveProjectName(),
            file = input$fig_upload_name
          ))
        },
        error = function(e) {
          showTablerAlert(
            "danger",
            "Upload failed",
            sprintf("Could not save file: %s", e$message),
            5000
          )
        }
      )
    } else {
      showTablerAlert(
        "warning",
        "No file",
        "Please drop a file or select one to upload.",
        5000
      )
    }
  })

  # 2. Insert from Project Files
  observeEvent(input$btnInsertFigProj, {
    req(input$fig_proj_name)

    if (trimws(input$fig_proj_name) == "") {
      showTablerAlert(
        "warning",
        "No file",
        "Please select a file.",
        5000
      )
      return()
    }

    caption <- if (nzchar(trimws(input$fig_proj_caption))) {
      trimws(input$fig_proj_caption)
    } else {
      "Figure caption"
    }
    label <- if (nzchar(trimws(input$fig_proj_label))) {
      trimws(input$fig_proj_label)
    } else {
      paste0("fig:", tools::file_path_sans_ext(input$fig_proj_name))
    }
    width <- input$fig_proj_width %||% "0.75"

    insertLatexFigure(input$fig_proj_name, caption, label, width)
  })

  # 3. Import from Another Project
  observeEvent(input$btnInsertFigOther, {
    req(
      input$figOtherProjSelect,
      input$figOtherFileSelect,
      input$fig_other_name
    )

    if (trimws(input$fig_other_name) == "") {
      showTablerAlert(
        "warning",
        "No filename",
        "Please specify a filename.",
        5000
      )
      return()
    }

    caption <- if (nzchar(trimws(input$fig_other_caption))) {
      trimws(input$fig_other_caption)
    } else {
      "Figure caption"
    }
    label <- if (nzchar(trimws(input$fig_other_label))) {
      trimws(input$fig_other_label)
    } else {
      paste0("fig:", tools::file_path_sans_ext(input$fig_other_name))
    }
    width <- input$fig_other_width %||% "0.75"

    projDir <- getActiveProjectDir()

    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return()
    }
    pDir <- getUserProjectDir(uid)

    sourcePath <- file.path(
      pDir,
      input$figOtherProjSelect,
      input$figOtherFileSelect
    )
    destPath <- file.path(projDir, input$fig_other_name)

    if (file.exists(sourcePath)) {
      tryCatch(
        {
          file.copy(sourcePath, destPath, overwrite = TRUE)
          insertLatexFigure(input$fig_other_name, caption, label, width)
          rv_files(getVisibleFiles(projDir))

          # Record activity
          recordDailyActivity(activityType = "fileCreate", details = list(
            projectId = activeProjectId(),
            projectName = getActiveProjectName(),
            file = input$fig_other_name
          ))
        },
        error = function(e) {
          showTablerAlert(
            "danger",
            "Import failed",
            sprintf("Could not copy file: %s", e$message),
            5000
          )
        }
      )
    } else {
      showTablerAlert(
        "danger",
        "File not found",
        "The source file no longer exists.",
        5000
      )
    }
  })

  # 4. Link from URL

  # Auto-populate filename from URL
  observeEvent(input$fig_url_link, {
    req(input$fig_url_link)

    url <- trimws(input$fig_url_link)
    if (url != "") {
      # Extract filename from URL
      filename <- basename(url)

      # Remove query parameters if present (e.g., ?version=123)
      filename <- sub("\\?.*$", "", filename)

      # Only update if we got a valid filename with an extension
      if (grepl("\\.[a-zA-Z0-9]+$", filename)) {
        updateTextInput(session, "fig_url_name", value = filename)

        # Also update the label based on the filename
        label <- paste0("fig:", tools::file_path_sans_ext(filename))
        updateTextInput(session, "fig_url_label", value = label)
      }
    }
  })

  observeEvent(input$btnInsertFigUrl, {
    req(input$fig_url_link, input$fig_url_name)

    url <- input$fig_url_link
    if (trimws(url) == "" || trimws(input$fig_url_name) == "") {
      showTablerAlert(
        "warning",
        "Invalid URL/filename",
        "URL and filename are required.",
        5000
      )
      return()
    }

    caption <- if (nzchar(trimws(input$fig_url_caption))) {
      trimws(input$fig_url_caption)
    } else {
      paste0(tools::file_path_sans_ext(input$fig_url_name))
    }
    label <- if (nzchar(trimws(input$fig_url_label))) {
      trimws(input$fig_url_label)
    } else {
      paste0("fig:", tools::file_path_sans_ext(input$fig_url_name))
    }
    width <- input$fig_url_width %||% "0.75"

    projDir <- getActiveProjectDir()
    destPath <- file.path(projDir, input$fig_url_name)

    tryCatch(
      {
        utils::download.file(
          url,
          destfile = destPath,
          mode = "wb",
          quiet = TRUE
        )
        if (file.exists(destPath)) {
          insertLatexFigure(input$fig_url_name, caption, label, width)
          rv_files(getVisibleFiles(projDir))

          # Record activity
          recordDailyActivity(activityType = "fileCreate", details = list(
            projectId = activeProjectId(),
            projectName = getActiveProjectName(),
            file = input$fig_url_name
          ))
        } else {
          stop("Download completed but file not found.")
        }
      },
      error = function(e) {
        showTablerAlert(
          "warning",
          "Download failed",
          sprintf(
            "Could not download image locally (%s). Linking URL directly.",
            e$message
          ),
          5000
        )
        # Fallback: Insert the URL directly instead of local path
        insertLatexFigure(url, caption, label, width)
      }
    )
  })

  # ---------------- CITATION MANAGER LOGIC ----------------

  # 1. Render the Bibliography File Selector
  output$bibTargetSelector <- renderUI({
    req(activeProjectId()) # Ensure we have a project context
    projDir <- getActiveProjectDir()

    # List existing .bib files
    bib_files <- list.files(
      path = projDir,
      pattern = "\\.bib$",
      full.names = FALSE
    )

    # Logic: If files exist, list them. If not, offer "references.bib" as default.
    choices <- if (length(bib_files) > 0) bib_files else c("references.bib")

    # Attempt to select "references.bib" if it exists, otherwise the first one
    selected <- if ("references.bib" %in% bib_files) {
      "references.bib"
    } else {
      choices[1]
    }

    div(
      class = "mb-3",
      tags$label(class = "form-label", "Target Bibliography File"),
      selectInput(
        "selectedBibFile",
        label = NULL,
        choices = choices,
        selected = selected,
        width = "100%",
        selectize = FALSE
      )
    )
  })

  # 2. Handle Appending BibTeX (Production Ready)
  observeEvent(input$append_bibtex_entry, {
    req(input$append_bibtex_entry)

    projDir <- getActiveProjectDir()
    req(projDir)

    # --- 1. Identify Target File ---
    target_file <- input$selectedBibFile

    # Fallback: Scan directory if input is empty or null
    if (is.null(target_file) || target_file == "") {
      existing_bibs <- list.files(
        projDir,
        pattern = "\\.bib$",
        full.names = FALSE
      )
      if (length(existing_bibs) > 0) {
        target_file <- existing_bibs[1]
      } else {
        target_file <- "references.bib"
      }
    }

    bibFile <- file.path(projDir, target_file)

    # --- 2. Create & Append ---
    if (!file.exists(bibFile)) {
      file.create(bibFile)
      # Record activity if new file created
      recordDailyActivity(activityType = "fileCreate", details = list(
        projectId = activeProjectId(),
        projectName = getActiveProjectName(),
        file = target_file
      ))
    }

    # Append the new entry
    write(
      paste0("\n", input$append_bibtex_entry, "\n"),
      file = bibFile,
      append = TRUE
    )

    showTablerAlert(
      "success",
      "Citation imported",
      paste("Reference added to", target_file),
      5000
    )

    # --- 3. Refresh Sidebar & Metadata ---
    rv_files(getVisibleFiles(projDir))
    if (!is.null(activeProjectId())) {
      updateProjectFileCount(activeProjectId())
    }

    # --- 4. FORCE HISTORY SNAPSHOT ---
    # Since we modified the file programmatically, autoSaveSource won't trigger.
    # We must manually save the state to the history system.
    full_content <- paste(readLines(bibFile, warn = FALSE), collapse = "\n")
    saveHistorySnapshot(activeProjectId(), target_file, full_content)

    # --- 5. REFRESH CITATION CACHE ---
    # We must also manually refresh the available citations for autocomplete
    # (Replicating logic from autoSaveSource)
    try({
      projects <- loadProjects()
      mainFile <- NULL
      for (p in projects) {
        if (p$id == activeProjectId()) {
          mainFile <- p$mainFile
          break
        }
      }
      # We need the main .tex content to find active resources,
      # or just pass empty string to force scanning all .bib files in project
      texContent <- ""
      if (!is.null(mainFile) && file.exists(file.path(projDir, mainFile))) {
        texContent <- paste(
          readLines(file.path(projDir, mainFile), warn = FALSE),
          collapse = "\n"
        )
      }
      pushBibCitations(texContent, projDir)
    })

    # --- 6. TRIGGER STANDARD FILE CLICK (Synchronous) ---
    # Now load the file into the editor using the unified helper.
    last_line <- length(readLines(bibFile, warn = FALSE))
    handleFileOpening(
      filePath = target_file,
      isEditable = TRUE,
      gotoLine = last_line
    )
  })

