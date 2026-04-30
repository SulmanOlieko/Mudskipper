  # --- MODIFIED: Main TEX selector ---
  output$mainFileSelect <- renderUI({
    # CRITICAL: Depend on rv_files() so the dropdown rebuilds when files are added
    trigger <- rv_files()

    projDir <- getActiveProjectDir()
    if (is.null(projDir)) {
      return(p("No project loaded."))
    }

    # Get .tex files
    texFiles <- list.files(
      projDir,
      pattern = "\\.tex$",
      ignore.case = TRUE,
      recursive = TRUE
    )

    if (length(texFiles) > 0) {
      # 1. Determine the best default selection
      projects <- loadProjects()
      projId <- activeProjectId()
      savedMain <- NULL

      # Look for saved preference
      if (!is.null(projId)) {
        for (p in projects) {
          if (p$id == projId) {
            savedMain <- p$mainFile
            break
          }
        }
      }

      # Priority: Saved Preference -> First .tex file found
      # Since createNewFileTrigger now saves the preference immediately,
      # this will pick up the new file automatically when it re-renders.
      selectedFile <- if (!is.null(savedMain) && savedMain %in% texFiles) {
        savedMain
      } else {
        texFiles[1]
      }

      selectInput(
        "compileMainFile",
        "Selected main .tex",
        choices = texFiles,
        selected = selectedFile
      )
    } else {
      p("No .tex files available.")
    }
  })

  # When a .tex file is loaded, update activeProjectId based on the most recent 'lastEdited' timestamp
  # --- MODIFIED: Main File Dropdown Observer ---
  observeEvent(input$compileMainFile, {
    req(input$compileMainFile)
    projDir <- getActiveProjectDir()
    req(projDir)

    fileName <- input$compileMainFile
    filePath <- file.path(projDir, fileName)

    # 1. Update Preference (Remember this choice)
    if (!is.null(activeProjectId())) {
      updateProjectMainFilePreference(activeProjectId(), fileName)
    }

    # 2. CIRCUIT BREAKER: Stop the loop.
    # If the editor already has this file open, STOP.
    if (currentFile() == fileName) {
      return()
    }

    # 3. Load Content if file exists
    if (file.exists(filePath)) {
      content <- paste(readLines(filePath, warn = FALSE), collapse = "\n")
      aceMode <- getAceModeFromExtension(fileName)

      # THIS IS THE FIX: Load content + Wipe Undo History
      session$sendCustomMessage(
        "cmdSafeLoadFile",
        list(
          content = content,
          mode = aceMode
        )
      )

      currentFile(fileName)
      updateStatus(fileName)
      session$sendCustomMessage(
        "cursorRestore",
        list(file = isolate(currentFile()))
      )
      pushBibCitations(content, projDir)
      pushLabelKeys(content)
    }
  })

  # ---------------- FINAL PRODUCTION COMPILATION LOGIC -----------------
  compileState <- reactiveValues(
    active = FALSE,
    bg_proc = NULL,
    file_pos = 0
  )

  # ----------------------------- SERVER LOGIC -----------------------------
  # Updated start function to pass inputs
  startCompileAsync <- function() {
    if (isTRUE(compileState$active)) {
      showTablerAlert(
        "warning",
        "Worker is busy",
        "Compilation is already in progress.",
        5000
      )
      return()
    }

    # Prepare status text injection
    shinyjs::runjs("
      window.updateCompileButtonText = function(text) {
        const btn = document.getElementById('compile');
        if (!btn) return;
        const spinner = document.getElementById('compileSpinner');
        const spinnerHtml = spinner ? spinner.outerHTML : '';
        btn.innerHTML = text + ' &nbsp; ' + spinnerHtml;
      };
    ")
    
    req(input$compileMainFile)
    projDir <- getActiveProjectDir()
    req(projDir)

    uid <- isolate(user_session$user_info$user_id)
    req(uid)

    # User specific compiled dir
    uCompiledDir <- getUserCompiledDir(uid)

    # Capture Options (with defaults)
    mode <- if (!is.null(input$compileMode)) input$compileMode else "normal"
    syntax <- if (!is.null(input$syntaxCheck)) input$syntaxCheck else "none"
    errH <- if (!is.null(input$errorHandling)) {
      input$errorHandling
    } else {
      "tryCompile"
    }

    # Clean artifacts
    pdfPath <- file.path(uCompiledDir, "output.pdf")
    if (file.exists(pdfPath)) {
      unlink(pdfPath)
    }

    # Prepare Log
    logFile <- file.path(uCompiledDir, "compile_job.log")
    if (file.exists(logFile)) {
      unlink(logFile)
    }
    file.create(logFile)

    # UI Reset
    compileState$file_pos <- 0
    updateAceEditor(session, "dockerConsole", value = "")
    session$sendCustomMessage("toggleCompileSpinner", TRUE)
    shinyjs::enable("stopCompilation")
    shinyjs::addClass("compile", "btn-compiling")
    shinyjs::runjs("updateCompileButtonText('Syncing');")
    tryCatch(
      {
        absProjDir <- normalizePath(projDir, winslash = "/", mustWork = FALSE)
        absCompiledDir <- normalizePath(
          uCompiledDir,
          winslash = "/",
          mustWork = FALSE
        )

        # Launch Worker with NEW Arguments
        proc <- callr::r_bg(
          func = compile_bg_task,
          args = list(
            projDir = absProjDir,
            mainFile = input$compileMainFile,
            compiledDir = absCompiledDir,
            compileMode = mode,
            syntaxCheck = syntax,
            errorHandling = errH
          ),
          supervise = TRUE
        )

        compileState$bg_proc <- proc
        compileState$active <- TRUE
      },
      error = function(e) {
        showTablerAlert(
          "danger",
          "System error",
          "Could not start compile worker.",
          5000
        )
        session$sendCustomMessage("toggleCompileSpinner", FALSE)
        shinyjs::disable("stopCompilation")
        shinyjs::removeClass("compile", "btn-compiling")
        shinyjs::runjs("updateCompileButtonText('Recompile');")
      }
    )
  }

  # --- MONITOR LOOP (Crash-Proof & Freeze-Proof) ---
  observe({
    req(compileState$active)
    invalidateLater(500, session)

    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return()
    } # Should not happen if active
    uCompiledDir <- getUserCompiledDir(uid)

    # 1. READ LOGS SAFELY
    logFile <- file.path(uCompiledDir, "compile_job.log")

    if (file.exists(logFile)) {
      # Use tryCatch to prevent ANY file read error from stopping the app
      tryCatch(
        {
          con <- file(logFile, open = "r")

          # Seek to last position (Smart Seek)
          seek(con, where = compileState$file_pos, origin = "start")

          # Read new lines
          new_lines <- readLines(con, warn = FALSE)

          # Save new position
          compileState$file_pos <- seek(con)
          close(con)

          if (length(new_lines) > 0) {
            # CRITICAL FIX: Sanitize Encoding
            # This forces all text to valid UTF-8, replacing garbage bytes with "?"
            # This prevents the "invalid multibyte string" crash.
            new_lines <- iconv(new_lines, to = "UTF-8", sub = "?")

            # ANTI-FREEZE: Limit chunk size
            # If Docker dumps 1000 lines at once, we only show the last 100
            # to keep the browser responsive.
            if (length(new_lines) > 100) {
              new_lines <- c(
                paste0(
                  "... [Skipped ",
                  length(new_lines) - 100,
                  " lines for performance] ..."
                ),
                tail(new_lines, 100)
              )
            }

            # Check for [STATUS] markers
            status_lines <- grep("\\[STATUS\\]", new_lines, value = TRUE)
            if (length(status_lines) > 0) {
              last_status <- tail(status_lines, 1)
              status_msg <- sub(".*\\[STATUS\\]\\s*", "", last_status)
              shinyjs::runjs(sprintf("updateCompileButtonText('%s');", status_msg))
            }

            chunk <- paste(new_lines, collapse = "\n")

            # Update UI
            shinyjs::runjs(sprintf(
              "var editor = ace.edit('dockerConsole'); editor.navigateFileEnd(); editor.insert(%s + '\\n'); editor.renderer.scrollCursorIntoView();",
              jsonlite::toJSON(chunk, auto_unbox = TRUE)
            ))
          }
        },
        error = function(e) {
          # Silently ignore read errors (e.g. file locking) to keep app alive
          if (exists("con") && isOpen(con)) close(con)
        }
      )
    }

    # 2. CHECK WORKER STATUS
    proc <- compileState$bg_proc
    if (!is.null(proc) && !proc$is_alive()) {
      compileState$active <- FALSE
      session$sendCustomMessage("toggleCompileSpinner", FALSE)
      shinyjs::disable("stopCompilation")
      shinyjs::removeClass("compile", "btn-compiling")
      shinyjs::runjs("updateCompileButtonText('Recompile');")

      # Check if worker crashed internally
      try(proc$get_result(), silent = TRUE)

      # 3. HANDLE RESULTS
      pdfPath <- file.path(uCompiledDir, "output.pdf")

      if (file.exists(pdfPath)) {
        showTablerAlert("success", "Compilation finished", "Compilation finished successfully.", 5000)

        # Update PDF View - Use USERDATA resource path
        ts <- as.numeric(Sys.time())
        # project/<uid>/compiled/output.pdf
        viewer_url <- paste0(
          "Mudskipper_viewer.html?file=project/",
          uid,
          "/compiled/output.pdf&t=",
          ts,
          "#toolbar=0"
        )
        output$pdfViewUI <- renderUI({
          tags$iframe(
            id = "pdfIframe",
            src = viewer_url,
            style = "width:100% !important; height:100vh; border:none;"
          )
        })

        # ---AUTO-SYNC TO CURSOR AFTER COMPILE ---
        shinyjs::runjs(
          "
          setTimeout(function() {
            try {
              var editor = ace.edit('sourceEditor');
              if (editor && window.Shiny) {
                var pos = editor.getCursorPosition();
                Shiny.setInputValue('editorSyncClick', {
                  line: pos.row + 1, 
                  column: pos.column, 
                  nonce: Math.random()
                }, {priority: 'event'});
              }
            } catch(e) {}
          }, 1500); // 1.5s delay gives the PDF.js iframe time to fully mount
        "
        )
        # ----------------------------------------------

        # Parse Annotations
        log_file <- file.path(uCompiledDir, "output.log")
        if (file.exists(log_file)) {
          anns <- parse_tex_log(log_file)
          compileAnnotations(anns)
          current_lint <- isolate(lintAnnotations())
          session$sendCustomMessage("setAnnotations", c(anns, current_lint))
        }

        # Cache Result (Original Behavior)
        if (!is.null(activeProjectId())) {
          saveCompiledToProjectCache(activeProjectId())
          shinyjs::runjs(
            "var editor = ace.edit('dockerConsole'); editor.navigateFileEnd(); editor.insert('\\n[System] Project cached successfully.');"
          )
        }
      } else {
        showTablerAlert("danger", "Compilation failed", "Compilation failed. Please check error logs.", 5000)
      }
    }
  })

  observeEvent(input$compile, {
    startCompileAsync()
  })

  observeEvent(input$recompileFromScratch, {
    projId <- activeProjectId()
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return()
    }
    uCompiledDir <- getUserCompiledDir(uid)

    # 1. Clear the working directory
    compiled_files <- list.files(uCompiledDir, full.names = TRUE)
    if (length(compiled_files) > 0) {
      unlink(compiled_files, recursive = TRUE)
    }

    # 2. Clear the persistent project cache
    if (!is.null(projId)) {
      clearProjectCache(projId)
      #appendLog("Project cache cleared.")
    }

    rv_compiled(list.files(uCompiledDir))
    startCompileAsync()
  })

  # ---------------- STOP COMPILATION HANDLER ----------------
  observeEvent(input$stopCompilation, {
    # Only attempt to stop if a process is actually active
    if (isTRUE(compileState$active) && !is.null(compileState$bg_proc)) {
      # 1. Kill the background process
      tryCatch(
        {
          # kill() stops the R process.
          # Note: If Docker is running inside it, it might take a moment to clean up.
          compileState$bg_proc$kill()

          # Log to the on-screen console
          shinyjs::runjs(
            "var editor = ace.edit('dockerConsole'); editor.navigateFileEnd(); editor.insert('\\n>> [User] Compilation stopped manually.\\n'); editor.renderer.scrollCursorIntoView();"
          )

          showTablerAlert(
            "info",
            "Worker stopped",
            "Compilation stopped by you.",
            5000
          )
        },
        error = function(e) {
          showTablerAlert(
            "warning",
            "Error stopping worker",
            paste("Error stopping process:", e$message, "Try reloading the app."),
            5000
          )
        }
      )

      # 2. Reset App State immediately
      # Setting active = FALSE stops the monitoring loop defined in 'observe({ req(compileState$active) ... })'
      compileState$active <- FALSE
      compileState$bg_proc <- NULL

      # 3. Reset UI Elements
      session$sendCustomMessage("toggleCompileSpinner", FALSE)
      shinyjs::disable("stopCompilation")
      shinyjs::removeClass("compile", "btn-compiling")
      shinyjs::runjs("updateCompileButtonText('Recompile');")
    }
  })

  observe({
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return()
    }
    uCompiledDir <- getUserCompiledDir(uid)

    pdfPath <- file.path(uCompiledDir, "output.pdf")
    if (file.exists(pdfPath)) {
      # Case 1: PDF exists. Use iframe with our custom viewer.
      # We append a timestamp to bust cache.
      ts <- as.numeric(Sys.time())
      viewer_url <- paste0(
        "Mudskipper_viewer.html?file=project/",
        uid,
        "/compiled/output.pdf&t=",
        ts
      )

      output$pdfViewUI <- renderUI({
        tags$iframe(
          id = "pdfIframe",
          src = viewer_url,
          style = "width:100% !important; height:100vh; border:none;"
        )
      })
      shinyjs::removeClass("pdfViewUI", "placeholder-active")
    } else {
      # Case 2: No PDF. Show the centered logo.
      output$pdfViewUI <- renderUI({
        div(
          style = paste(
            "display: flex;",
            "align-items: center;",
            "justify-content: center;",
            "width: 100%;",
            "height: 100vh;",
            "padding: 2rem;",
            "box-sizing: border-box;",
            "overflow: hidden !important;",
            "overscroll-behavior: none !important;",
            "touch-action: none !important;"
          ),
          tags$img(
            src = "mudskipper_logo.svg",
            alt = "Mudskipper Logo",
            style = paste(
              "max-width: 60%;",
              "max-height: 60%;",
              "object-fit: contain;",
              "opacity: 0.025;"
            )
          )
        )
      })
      # Add the placeholder class to the #pdfViewUI container
      shinyjs::addClass("pdfViewUI", "placeholder-active")
    }
  })

  # Immediate editor theme/font mirror
  observeEvent(input$editorThemePanel, {
    req(input$editorThemePanel)
    updateAceEditor(session, "sourceEditor", theme = input$editorThemePanel)
    updateAceEditor(session, "dockerConsole", theme = input$editorThemePanel)

    uid <- isolate(user_session$user_info$user_id)
    if (!is.null(uid)) {
      cacheDir <- getUserAppCacheDir(uid)
      if (!is.null(cacheDir)) {
        writeLines(
          as.character(input$editorThemePanel),
          file.path(cacheDir, "theme.txt")
        )
      }
    }

    # Persist to localStorage to mirror the behaviour
    session$sendCustomMessage(
      "saveSettingsToLocal",
      list(editorTheme = as.character(input$editorThemePanel))
    )
  })

  observeEvent(input$editorFontSizePanel, {
    req(input$editorFontSizePanel)
    fs <- as.numeric(input$editorFontSizePanel)

    updateAceEditor(session, "sourceEditor", fontSize = fs)
    updateAceEditor(session, "dockerConsole", fontSize = fs)

    session$sendCustomMessage("saveSettingsToLocal", list(fontSize = fs))

    session$sendCustomMessage("updateStatus", paste0("Font size set to ", fs))
  })

  # Auto-save & Dynamic Bibliography Update (200ms)
  autoSaveSource <- debounce(reactive(input$sourceEditor), 200)

  observeEvent(
    autoSaveSource(),
    {
      isolate({
        file_name <- currentFile()
        projDir <- getActiveProjectDir()
      })
      req(file_name, projDir)
      if (isTRUE(rv$fileJustLoaded)) return()

      filePath <- file.path(projDir, file_name)
      new_content <- autoSaveSource()
      if (is.null(new_content)) return()

      if (file.exists(filePath)) {
        disk_content <- tryCatch({
          paste(readLines(filePath, warn = FALSE), collapse = "\n")
        }, error = function(e) NULL)
        if (!is.null(disk_content) && identical(new_content, disk_content)) return()
      }

      tryCatch({
        writeLines(new_content, filePath)
        updateStatus(file_name)
      }, error = function(e) {
        showTablerAlert("danger", "Save Error", paste("Failed to save:", e$message), 5000)
      })

      session$sendCustomMessage("requestLiveCommentCoordinates", NULL)

      if (tolower(tools::file_ext(file_name)) == "tex") {
        updateProjectMainFilePreference(activeProjectId(), file_name)
        updateSelectInput(session, "compileMainFile", selected = file_name)
      }
    },
    ignoreInit = TRUE
  )

  # History Saving & Timestamp update (5 seconds)
  historySaveDebounced <- debounce(reactive(input$sourceEditor), 5000)
  observeEvent(historySaveDebounced(), {
    isolate({
      projId <- activeProjectId()
      file_name <- currentFile()
      content <- historySaveDebounced()
    })
    req(projId, file_name, content)
    if (isTRUE(rv$fileJustLoaded)) return()
    
    if (exists("saveHistorySnapshot")) {
      saveHistorySnapshot(projId, file_name, content)
    }
    
    if (exists("updateProjectTimestamp")) {
      updateProjectTimestamp(projId)
    }
  })

  # Optimized Outline & metadata refresh (2 seconds)
  outlineSource <- debounce(reactive(input$sourceEditor), 2000)
  observeEvent(outlineSource(), {
    isolate({
      file_name <- currentFile()
      projId <- activeProjectId()
      projDir <- getActiveProjectDir()
      content <- outlineSource()
    })
    req(file_name, projId, projDir)
    if (isTRUE(rv$fileJustLoaded)) return()

    ext <- tolower(tools::file_ext(file_name))

    # 1. Update Outline
    if (ext == "tex") {
      odf <- parseOutline(content)
      outlineData(odf)
    }

    # 2. Update Bibliography & Labels
    if (ext == "bib") {
      # If editing a .bib file, refresh citation keys for the main file
      projects <- loadProjects()
      mainFile <- NULL
      for (proj in projects) {
        if (!is.null(proj$id) && proj$id == projId) {
          mainFile <- proj$mainFile
          break
        }
      }

      texContent <- ""
      if (!is.null(mainFile) && file.exists(file.path(projDir, mainFile))) {
        texContent <- tryCatch({
          paste(readLines(file.path(projDir, mainFile), warn = FALSE), collapse = "\n")
        }, error = function(e) "")
      }
      pushBibCitations(texContent, projDir)
    } else if (ext == "tex") {
      pushBibCitations(content, projDir)
      pushLabelKeys(content)
    }

    # 3. Auto-Compile Logic
    if (isTruthy(input$autoCompile) && input$autoCompile == "on") {
      if (!isTRUE(compileState$active)) {
        startCompileAsync()
      }
    }
  })

  # --- ACTIVE OUTLINE WITH CURSOR TRACKING ---
  
  parseOutline <- function(txt) {
    if (is.null(txt) || !nzchar(txt)) return(NULL)
    lines <- unlist(strsplit(txt, "\n", fixed = TRUE))
    if (length(lines) == 0) return(NULL)

    pats <- list(
      list(re = "^\\\\part\\*?\\{(.*)\\}", lv = 0),
      list(re = "^\\\\chapter\\*?\\{(.*)\\}", lv = 0),
      list(re = "^\\\\section\\*?\\{(.*)\\}", lv = 1),
      list(re = "^\\\\subsection\\*?\\{(.*)\\}", lv = 2),
      list(re = "^\\\\subsubsection\\*?\\{(.*)\\}", lv = 3),
      list(re = "^\\\\paragraph\\*?\\{(.*)\\}", lv = 4)
    )

    out <- list()
    for (p in pats) {
      indices <- grep(p$re, lines, perl = TRUE)
      if (length(indices) > 0) {
        for (i in indices) {
          ln <- trimws(lines[[i]])
          m <- regexec(p$re, ln, perl = TRUE)
          res <- regmatches(ln, m)[[1]]

          if (length(res) > 1) {
            title <- res[2]
            title <- sub("\\}\\s*\\\\label\\{.*$", "", title)
            title <- gsub("\\\\label\\{[^}]+\\}", "", title)
            if (grepl("\\}$", title)) title <- sub("\\}$", "", title)
            title <- gsub("\\\\[a-zA-Z]+\\{([^}]*)\\}", "\\1", title)

            out[[length(out) + 1]] <- list(
              line = i - 1L,
              level = p$lv,
              title = trimws(title)
            )
          }
        }
      }
    }

    if (length(out) == 0) return(NULL)
    res_df <- do.call(rbind, lapply(out, as.data.frame, stringsAsFactors = FALSE))
    res_df <- res_df[order(res_df$line), ]
    return(res_df)
  }

  # Track cursor position in editor
  observeEvent(
    input$cursorPosition,
    {
      req(input$cursorPosition)
      cursorLine <- input$cursorPosition$row

      odf <- outlineData()
      if (is.null(odf) || nrow(odf) == 0) {
        return()
      }

      # Find which outline item the cursor is in
      activeItem <- NULL
      for (i in seq_len(nrow(odf))) {
        if (odf$line[i] <= cursorLine) {
          if (i == nrow(odf) || odf$line[i + 1] > cursorLine) {
            activeItem <- i
            break
          }
        }
      }

      currentOutlineItem(activeItem)
    },
    ignoreInit = TRUE
  )


  output$outlineSidebar <- renderUI({
    # 1. Start spinner immediately
    session$sendCustomMessage("toggleOutlineSpinner", TRUE)

    odf <- outlineData()
    ui_content <- NULL

    if (is.null(odf) || nrow(odf) == 0) {
      ui_content <- tags$div(
        class = "outline-wrap",
        style = "padding:12px; color:var(--bs-secondary-color);",
        div(
          class = "empty",
          ui_empty_illustration(),
          HTML(
            '
                             <p class="empty-title">NO HEADINGS FOUND</p>
                             <p class="empty-subtitle text-secondary">This file has no outline.</p>
                                  '
          )
        )
      )
      # --- FIX: Explicitly stop spinner here ---
      # If outlineData was already NULL, renderUI won't run to stop it.
      # We must ensure it stops regardless.
      session$sendCustomMessage("toggleOutlineSpinner", FALSE)
      # -----------------------------------------
    } else {
      # Recursive function to build nested HTML
      render_tree <- function(df) {
        if (nrow(df) == 0) {
          return(NULL)
        }

        min_level <- min(df$level)
        roots <- which(df$level == min_level)

        ui_elems <- lapply(roots, function(idx) {
          row <- df[idx, ]

          # Calculate range for children
          next_root_idx <- if (idx == tail(roots, 1)) {
            nrow(df) + 1
          } else {
            roots[which(roots == idx) + 1]
          }

          child_start <- idx + 1
          child_end <- next_root_idx - 1

          if (child_start <= child_end) {
            children_df <- df[child_start:child_end, ]
          } else {
            children_df <- df[FALSE, ]
          }

          has_children <- nrow(children_df) > 0
          item_id <- paste0("outline-item-line-", row$line)

          if (has_children) {
            # PARENT NODE
            tags$li(
              style = "list-style: none; margin-bottom: 2px;",
              div(
                class = "outline-item-row",
                id = item_id,
                style = "display: flex; align-items: center; cursor: pointer; padding: 4px 0; border-radius: var(--tblr-border-radius);",
                span(
                  class = "outline-toggle",
                  style = "width: 24px; display: inline-flex; justify-content: center; align-items: center; color: var(--bs-secondary-color); transition: transform 0.2s; height: 24px;",
                  onclick = "var childUl = this.parentElement.nextElementSibling; childUl.classList.toggle('d-none'); this.querySelector('i').classList.toggle('fa-chevron-right'); this.querySelector('i').classList.toggle('fa-chevron-down'); event.stopPropagation();",
                  tags$i(
                    class = "fa-solid fa-chevron-down",
                    style = "font-size: 0.75rem;"
                  )
                ),
                span(
                  class = "outline-link",
                  style = "flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; padding-left: 4px;",
                  `data-line` = row$line,
                  onclick = sprintf(
                    "if(window.Shiny) Shiny.setInputValue('outlineGo', {line: %d, nonce: Math.random()}, {priority:'event'});",
                    row$line
                  ),
                  row$title
                )
              ),
              tags$ul(
                class = "outline-children",
                style = "list-style: none; padding-left: 0; margin: 0; margin-left: 12px; border-left: 1px solid var(--tblr-secondary);",
                render_tree(children_df)
              )
            )
          } else {
            # LEAF NODE
            tags$li(
              style = "list-style: none; margin-bottom: 2px;",
              div(
                class = "outline-item-row",
                id = item_id,
                style = "display: flex; align-items: center; cursor: pointer; padding: 4px 0; border-radius: var(--tblr-border-radius);",
                span(style = "width: 24px; display: inline-block;"),
                span(
                  class = "outline-link",
                  style = "flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; padding-left: 4px;",
                  `data-line` = row$line,
                  onclick = sprintf(
                    "if(window.Shiny) Shiny.setInputValue('outlineGo', {line: %d, nonce: Math.random()}, {priority:'event'});",
                    row$line
                  ),
                  row$title
                )
              )
            )
          }
        })
        return(ui_elems)
      }

      styles <- tags$style(HTML(
        "
        .outline-item-row:hover { background-color: var(--tblr-border-color) !important; }
        .outline-item-row:hover .outline-toggle { background-color: var(--tblr-border-color) !important; }
        .outline-item-row.active { background-color: var(--tblr-border-color) !important; border-left: 4px solid var(--tblr-primary) !important; }
        .outline-children { position: relative; }
      "
      ))

      ui_content <- tagList(
        styles,
        tags$ul(style = "padding-left: 5px; margin: 0;", render_tree(odf))
      )
    }

    # 2. Stop spinner ONLY after the UI has been flushed to the client
    session$onFlushed(
      function() {
        session$sendCustomMessage("toggleOutlineSpinner", FALSE)
      },
      once = TRUE
    )

    return(ui_content)
  })

  # Observer to update active outline item class and scroll to it
  observeEvent(currentOutlineItem(), {
    idx <- currentOutlineItem()
    odf <- outlineData()

    if (!is.null(idx) && !is.null(odf) && idx <= nrow(odf)) {
      # Get the line number associated with the active index
      active_line <- odf$line[idx]
      target_id <- paste0("outline-item-line-", active_line)

      # Execute JS to:
      # 1. Remove .active from everything
      # 2. Add .active to target
      # 3. Expand parents if they are collapsed (so we can see the item)
      # 4. Scroll into view
      shinyjs::runjs(sprintf(
        "
        (function() {
          // 1. Clear previous active
          document.querySelectorAll('.outline-item-row.active').forEach(el => el.classList.remove('active'));
          
          // 2. Find target
          var target = document.getElementById('%s');
          if (target) {
            target.classList.add('active');
            
            // 3. Ensure parents are expanded
            var parent = target.parentElement;
            while (parent) {
              if (parent.classList.contains('outline-children')) {
                // This is a UL container, make sure it is visible
                parent.classList.remove('d-none');
                // Fix chevron on the toggle button above
                var toggleBtn = parent.previousElementSibling.querySelector('.outline-toggle i');
                if (toggleBtn) {
                  toggleBtn.classList.remove('fa-chevron-right');
                  toggleBtn.classList.add('fa-chevron-down');
                }
              }
              parent = parent.parentElement;
              // Stop if we reach the root container
              if (parent && parent.id === 'outlineSidebar') break;
            }

            // 4. Scroll into view (if needed)
            target.scrollIntoView({behavior: 'smooth', block: 'nearest'});
          }
        })();
      ",
        target_id
      ))
    }
  })

  observeEvent(input$outlineGo, {
    req(input$outlineGo$line)
    session$sendCustomMessage(
      "aceGoTo",
      list(line = as.integer(input$outlineGo$line))
    )
  })

  #Name of active project
  getProjectNameById <- function(pid) {
    if (is.null(pid) || !nzchar(pid)) {
      return("")
    }
    projs <- loadProjects()
    if (!length(projs)) {
      return("")
    }
    for (p in projs) {
      if (is.list(p) && identical(p$id, pid)) return(p$name %||% "")
    }
    ""
  }
  `%||%` <- function(x, y) if (is.null(x)) y else x

  # Output the active project name based on activeProjectId
  output$activeProjectName <- renderText({
    projectId <- activeProjectId() # Get the active project ID from reactive value
    if (is.null(projectId)) {
      return("Fetching project...")
    } # Fallback text

    # Load the projects list and find the matching project
    projects <- loadProjects()
    projectName <- ""
    for (proj in projects) {
      if (proj$id == projectId) {
        projectName <- proj$name
        break
      }
    }

    # Return the project name or a fallback if not found
    if (nzchar(projectName)) projectName else "Unknown Project"
  })

  output$activeProjectId <- renderText({
    activeProject() %||% ""
  })

  # Add reactive for error log state
  errorLogOpen <- reactiveVal(FALSE)

  # Toggle error log
  observeEvent(input$railErrorLogBtn, {
    shinyjs::runjs("window.toggleErrorLog();")
  })

  # Handle go to line from error log
  observeEvent(input$errorLogGoTo, {
    req(input$errorLogGoTo$line)
    session$sendCustomMessage(
      "aceGoTo",
      list(line = as.integer(input$errorLogGoTo$line))
    )
  })

  # Persist logs & last file
  observeEvent(compileLog(), {
    val <- compileLog()
    uid <- isolate(user_session$user_info$user_id)
    if (!is.null(val) && !is.null(uid)) {
      cacheDir <- getUserAppCacheDir(uid)
      if (!is.null(cacheDir)) {
        writeLines(as.character(val), file.path(cacheDir, "compileLog.txt"))
      }
    }
  })
  observeEvent(dockerLog(), {
    val <- dockerLog()
    uid <- isolate(user_session$user_info$user_id)
    if (!is.null(val) && !is.null(uid)) {
      cacheDir <- getUserAppCacheDir(uid)
      if (!is.null(cacheDir)) {
        writeLines(as.character(val), file.path(cacheDir, "dockerLog.txt"))
      }
    }
  })
  observeEvent(currentFile(), {
    val <- currentFile()
    uid <- isolate(user_session$user_info$user_id)
    if (!is.null(val) && !is.null(uid)) {
      cacheDir <- getUserAppCacheDir(uid)
      if (!is.null(cacheDir)) {
        writeLines(as.character(val), file.path(cacheDir, "lastFile.txt"))
      }
    }
  })

  # Theme mirroring safety
  observeEvent(input$editorThemePanel, {
    req(input$editorThemePanel)
    updateAceEditor(session, "sourceEditor", theme = input$editorThemePanel)
    updateAceEditor(session, "dockerConsole", theme = input$editorThemePanel)

    uid <- isolate(user_session$user_info$user_id)
    if (!is.null(uid)) {
      cacheDir <- getUserAppCacheDir(uid)
      if (!is.null(cacheDir)) {
        writeLines(
          as.character(input$editorThemePanel),
          file.path(cacheDir, "theme.txt")
        )
      }
    }
  })

  # Presentation mode handler
  observeEvent(input$btnPresentationMode, {
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return()
    }
    uCompiledDir <- getUserCompiledDir(uid)
    pdfPath <- file.path(uCompiledDir, "output.pdf")

    if (!file.exists(pdfPath)) {
      showTablerAlert(
        "warning",
        "No PDF available",
        "Please compile your document first before opening presentation mode.",
        5000
      )
    } else {
      # Trigger JavaScript to open presentation mode
      # NOTE: openPresentationMode() in theme.js might need update or we pass URL via JS
      # Assuming theme.js reads from iframe or standard path.
      # Actually, presentation.html needs 'file' param.
      # Let's override the JS call to open window directly with correct URL
      ts <- as.numeric(Sys.time())
      pres_url <- paste0(
        "presentation.html?file=project/",
        uid,
        "/compiled/output.pdf&t=",
        ts
      )
      shinyjs::runjs(sprintf("window.open('%s', '_blank');", pres_url))
    }
  })

  # Open PDF in browser handler (with same validation)
  observeEvent(input$btnOpenPDF, {
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return()
    }
    uCompiledDir <- getUserCompiledDir(uid)
    pdfPath <- file.path(uCompiledDir, "output.pdf")

    if (!file.exists(pdfPath)) {
      showTablerAlert(
        "warning",
        "No PDF available",
        "Please compile your document first before opening in browser.",
        5000
      )
    } else {
      # Open PDF in new browser tab with cache-busting timestamp
      pdf_url <- paste0(
        "project/",
        uid,
        "/compiled/output.pdf?t=",
        as.numeric(Sys.time())
      )
      shinyjs::runjs(sprintf("window.open('%s', '_blank');", pdf_url))
      showTablerAlert(
        "info",
        "Opening PDF",
        "PDF opened in new browser tab.",
        5000
      )
    }
  })
