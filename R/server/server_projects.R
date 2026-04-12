  # ----------------------------- PROJECT MANAGEMENT -----------------------------

  projectChangeTrigger <- reactiveVal(0)

  userProfileTrigger <- reactiveVal(0)

  createdObservers <- reactiveVal(character(0))

  # Track the actual observer objects so we can destroy them
  file_observer_handles <- reactiveVal(list())

  # Function to destroy all current file observers
  clear_file_observers <- function() {
    # Wrap in isolate() to allow calling from non-reactive contexts (like session$onFlushed)
    isolate({
      handles <- file_observer_handles() # This read was causing the error

      for (obs in handles) {
        if (inherits(obs, "Observer")) {
          obs$destroy()
        }
      }

      # Reset the lists
      file_observer_handles(list())
      createdObservers(character(0))
    })
  }

  activeProjectId <- reactiveVal(NULL)
  projectDownloadTarget <- reactiveVal(NULL)

  getActiveProjectDir <- function() {
    projId <- activeProjectId()
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(projId) || is.null(uid)) {
      return(NULL)
    }
    file.path(getUserProjectDir(uid), projId)
  }

  # Persist active project to disk
  observeEvent(activeProjectId(), {
    projectId <- activeProjectId()
    if (!is.null(projectId) && nzchar(projectId)) {
      uid <- isolate(user_session$user_info$user_id)
      if (!is.null(uid)) {
        cacheDir <- getUserAppCacheDir(uid)
        if (!is.null(cacheDir)) {
          writeLines(projectId, file.path(cacheDir, "activeProject.txt"))
        }
      }
    }
  })

  observe({
    # Explicitly depend on activeProjectId
    projId <- activeProjectId()

    if (!is.null(projId) && nzchar(projId)) {
      uid <- isolate(user_session$user_info$user_id)
      if (is.null(uid)) {
        return()
      }
      pDir <- getUserProjectDir(uid)

      projDir <- file.path(pDir, projId)
    }
  })

  # Helper to filter out internal system folders
  getVisibleFiles <- function(projDir) {
    files <- list.files(projDir, recursive = TRUE, include.dirs = TRUE)
    # Exclude chat_files and compiled_cache and their contents
    files[!grepl("^(chat_files|compiled_cache|history)", files)]
  }

  # --- CACHE MANAGEMENT HELPERS ---

  # Syncs the temporary 'compiled' folder content BACK to the project's persistent cache
  saveCompiledToProjectCache <- function(projectId) {
    req(projectId)
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return()
    }

    pDir <- getUserProjectDir(uid)
    uCompiledDir <- getUserCompiledDir(uid)

    projCacheDir <- file.path(pDir, projectId, "compiled_cache")
    if (!dir.exists(projCacheDir)) {
      dir.create(projCacheDir, recursive = TRUE)
    }

    # List files in the user's compiled dir
    files <- list.files(uCompiledDir, full.names = TRUE)

    if (length(files) > 0) {
      file.copy(files, projCacheDir, overwrite = TRUE, recursive = TRUE)
    }
  }

  # Restores the project's persistent cache INTO the temporary 'compiled' folder
  restoreProjectCacheToCompiled <- function(projectId) {
    req(projectId)
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return(FALSE)
    }

    pDir <- getUserProjectDir(uid)
    uCompiledDir <- getUserCompiledDir(uid)

    # 1. Wipe the user compiled directory (cleanup previous project's mess)
    existing_files <- list.files(uCompiledDir, full.names = TRUE)
    if (length(existing_files) > 0) {
      unlink(existing_files, recursive = TRUE)
    }

    # 2. Check if project has a cache
    projCacheDir <- file.path(pDir, projectId, "compiled_cache")

    if (dir.exists(projCacheDir)) {
      # Copy cached files to the working compiled dir
      cache_files <- list.files(projCacheDir, full.names = TRUE)
      if (length(cache_files) > 0) {
        file.copy(cache_files, uCompiledDir, overwrite = TRUE, recursive = TRUE)
        return(TRUE) # Cache existed
      }
    }
    return(FALSE) # No cache
  }

  # Clears the project's specific cache
  clearProjectCache <- function(projectId) {
    req(projectId)
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return()
    }

    pDir <- getUserProjectDir(uid)
    projCacheDir <- file.path(pDir, projectId, "compiled_cache")
    if (dir.exists(projCacheDir)) {
      unlink(projCacheDir, recursive = TRUE)
    }
  }

  # Fixed loadProjects function
  loadProjects <- function() {
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return(list())
    }

    pDir <- getUserProjectDir(uid)
    if (is.null(pDir)) {
      return(list())
    }

    # Each user has their own projects.json inside their projects dir
    userProjectsFile <- file.path(pDir, ".projects.json")

    tryCatch(
      {
        # Check if file exists and has content
        if (
          !file.exists(userProjectsFile) || file.size(userProjectsFile) == 0
        ) {
          return(list())
        }

        # Read and parse JSON
        projects_json <- readLines(userProjectsFile, warn = FALSE)
        projects_json <- paste(projects_json, collapse = "\n")

        # Handle empty or invalid JSON
        if (nchar(trimws(projects_json)) == 0) {
          return(list())
        }

        projects <- jsonlite::fromJSON(projects_json, simplifyVector = FALSE)

        # Ensure we return a proper list
        if (!is.list(projects)) {
          return(list())
        }

        return(projects)
      },
      error = function(e) {
        # Suppress errors on login screen
        return(list())
      }
    )
  }

  # Fixed saveProjects function
  saveProjects <- function(projects) {
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return(FALSE)
    }

    pDir <- getUserProjectDir(uid)
    if (is.null(pDir)) {
      return(FALSE)
    }

    userProjectsFile <- file.path(pDir, ".projects.json")

    tryCatch(
      {
        # Ensure projects is a list
        if (!is.list(projects)) {
          projects <- as.list(projects)
        }

        # Convert to JSON with proper formatting
        projects_json <- jsonlite::toJSON(
          projects,
          auto_unbox = TRUE,
          pretty = TRUE
        )

        # Write to file
        writeLines(projects_json, userProjectsFile)
        return(TRUE)
      },
      error = function(e) {
        showTablerAlert(
          "danger",
          "Failed to save",
          paste("Error saving projects:", e$message),
          5000
        )
        return(FALSE)
      }
    )
  }

  updateProjectTimestamp <- function(projectId) {
    projects <- loadProjects()
    if (length(projects) > 0) {
      for (i in seq_along(projects)) {
        if (projects[[i]]$id == projectId) {
          projects[[i]]$lastEdited <- as.character(Sys.time())
          break
        }
      }
      saveProjects(projects)

      # SAFE: Only update reactive trigger if we're in a reactive context
      if (shiny::isRunning()) {
        isolate({
          projectChangeTrigger(projectChangeTrigger() + 1)
        })
      }
    }
  }

  updateProjectFileCount <- function(projectId) {
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return()
    }
    pDir <- getUserProjectDir(uid)

    projDir <- file.path(pDir, projectId)
    if (!dir.exists(projDir)) {
      return()
    }

    projects <- loadProjects()
    if (length(projects) > 0) {
      for (i in seq_along(projects)) {
        if (projects[[i]]$id == projectId) {
          # Get all files recursively
          projectFiles <- list.files(
            projDir,
            recursive = TRUE,
            all.files = FALSE,
            no.. = TRUE
          )

          # Filter out files in excluded subdirectories
          filteredFiles <- projectFiles[
            !grepl("^compiled_cache|history|chat_files", projectFiles)
          ]

          projects[[i]]$fileCount <- length(filteredFiles)
          projects[[i]]$lastEdited <- as.character(Sys.time())
          break
        }
      }
      saveProjects(projects)

      # SAFE: Only update reactive trigger if we're in a reactive context
      if (shiny::isRunning()) {
        isolate({
          projectChangeTrigger(projectChangeTrigger() + 1)
        })
      }
    }
  }

  # Fixed createNewProject function
  createNewProject <- function(
    name,
    description = "",
    initialFiles = NULL,
    template = "article"
  ) {
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return(FALSE)
    }
    pDir <- getUserProjectDir(uid)
    if (is.null(pDir)) {
      return(FALSE)
    }

    tryCatch(
      {
        projects <- loadProjects()
        #install.packages("uuid")
        library(uuid)
        newId <- uuid::UUIDgenerate()
        projDir <- file.path(pDir, newId)
        dir.create(projDir, recursive = TRUE)

        # Check if we have initial files or need to create a dummy .tex
        hasTexFile <- FALSE
        mainFile <- ""

        if (!is.null(initialFiles) && nrow(initialFiles) > 0) {
          # Copy initial files to project
          for (i in seq_len(nrow(initialFiles))) {
            destPath <- file.path(projDir, initialFiles$name[i])
            file.copy(initialFiles$datapath[i], destPath, overwrite = TRUE)

            # Check if any file is a .tex file
            if (tools::file_ext(initialFiles$name[i]) == "tex") {
              hasTexFile <- TRUE
              mainFile <- initialFiles$name[i]
            }
          }
        }

        # Create default .tex file if no .tex files were uploaded
        # Template Logic
        if (!hasTexFile) {
          defaultTexContent <- switch(
            template,
            "beamer" = paste(
              "\\documentclass{beamer}",
              "\\title{My Presentation}",
              "\\author{Author}",
              "\\date{\\today}",
              "\\begin{document}",
              "\\frame{\\titlepage}",
              "\\begin{frame}{Introduction}",
              "Hello World",
              "\\end{frame}",
              "\\end{document}",
              sep = "\n"
            ),
            "thesis" = paste(
              "\\documentclass[12pt]{report}",
              "\\title{My Thesis}",
              "\\author{Author}",
              "\\begin{document}",
              "\\maketitle",
              "\\chapter{Introduction}",
              "Content goes here.",
              "\\end{document}",
              sep = "\n"
            ),
            # Default Article
            paste(
              "\\documentclass{article}",
              "\\title{New Article}",
              "\\author{Author}",
              "\\begin{document}",
              "\\maketitle",
              "\\section{Intro}",
              "Start here.",
              "\\end{document}",
              sep = "\n"
            )
          )

          writeLines(
            defaultTexContent,
            file.path(
              projDir,
              paste0("main_", format(Sys.time(), "%Y%m%d"), ".tex")
            )
          )
        }

        # Get file count
        projectFiles <- list.files(projDir, recursive = TRUE)

        # Create new project object
        newProject <- list(
          id = newId,
          name = name,
          description = description,
          created = as.character(Sys.time()),
          lastEdited = as.character(Sys.time()),
          mainFile = mainFile,
          fileCount = length(projectFiles)
        )

        # Add to projects list
        if (length(projects) == 0) {
          projects <- list(newProject)
        } else {
          projects <- c(list(newProject), projects)
        }

        # Save projects
        success <- saveProjects(projects)

        # Trigger UI update
        projectChangeTrigger(projectChangeTrigger() + 1)

        return(newId)
      },
      error = function(e) {
        showTablerAlert(
          "danger",
          "Failed to load",
          paste("Error loading project:", e$message),
          5000
        )
        return(NULL)
      }
    )
  }

  deleteProject <- function(projectId) {
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return()
    }
    pDir <- getUserProjectDir(uid)

    projects <- loadProjects()
    projects <- projects[sapply(projects, function(x) x$id != projectId)]
    saveProjects(projects)

    # Delete project directory
    projDir <- file.path(pDir, projectId)
    if (dir.exists(projDir)) {
      unlink(projDir, recursive = TRUE)
    }

    # Trigger UI update
    projectChangeTrigger(projectChangeTrigger() + 1)
  }

  getProjectFiles <- function(projectId) {
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return(character(0))
    }
    pDir <- getUserProjectDir(uid)

    projDir <- file.path(pDir, projectId)
    if (dir.exists(projDir)) {
      list.files(projDir, recursive = TRUE, include.dirs = TRUE)
    } else {
      character(0)
    }
  }

  loadProjectToWorkspace <- function(projectId) {
    session$sendCustomMessage("togglePdfSpinner", TRUE)
    session$sendCustomMessage("toggleEditorSpinner", TRUE)
    shinyjs::runjs("setDashboardLoaderText('Syncing workspace...');")
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return(FALSE)
    }
    pDir <- getUserProjectDir(uid)

    projDir <- file.path(pDir, projectId)
    if (!dir.exists(projDir)) {
      return(FALSE)
    }

    # --- FIX: Clean up observers from previous project ---
    clear_file_observers()

    # Set active project FIRST
    activeProjectId(projectId)

    # Resource path "project_files" removed in favor of "project"

    # --- CHANGED: INTELLIGENT CACHE RESTORATION ---
    # Instead of just wiping, we restore this project's specific compiled files
    hasCache <- restoreProjectCacheToCompiled(projectId)

    if (hasCache) {
      # If we restored files, update the file lists
      rv_compiled(list.files(getUserCompiledDir(uid)))

      # REFRESH PDF VIEWER WITH 1 SECOND DELAY
      # This ensures the browser loads the new PDF that was just copied into place
      shinyjs::delay(1000, {
        session$sendCustomMessage('pdfUpdated', list(timestamp = Sys.time()))
        # Force re-render of PDF UI
        ts <- as.numeric(Sys.time())
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
        # --- AUTO-SYNC TO CURSOR AFTER CACHE LOAD ---
        shinyjs::runjs(
          "
          setTimeout(function() {
            try {
              var editor = ace.edit('sourceEditor');
              if (editor && window.Shiny) {
                var pos = editor.getCursorPosition();
                // pos.row is 0-indexed in JS, but SyncTeX expects 1-indexed lines
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
        # -------------------------------------------------
      })
    } else {
      # If no cache (new project), clear the view
      rv_compiled(character(0))
      output$pdfViewUI <- renderUI({
        div(
          style = "display: flex; align-items: center; justify-content: center; width: 100%; height: 100vh; padding: 2rem;",
          tags$img(
            src = "mudskipper_logo.svg",
            style = "max-width: 60%; max-height: 60%; opacity: 0.025;"
          )
        )
      })
    }

    # Update file list to show current project files
    rv_files(getVisibleFiles(projDir))

    # Update project timestamp
    later::later(function() updateProjectTimestamp(projectId), delay = 2)
    session$sendCustomMessage("togglePdfSpinner", FALSE)
    session$sendCustomMessage("toggleEditorSpinner", FALSE)

    return(TRUE)
  }

  # ----------------------------- REACTIVE VALUES FOR PROJECT MANAGEMENT -----------------------------
  showHomepage <- reactiveVal(TRUE) # Start with homepage visible
  showSettings <- reactiveVal(FALSE) # Track settings panel visibility
  activeProject <- reactiveVal(NULL) # Currently active project
  projectSort <- reactiveVal("lastEdited")

  # Observe URL parameters for direct project loading
  observe({
    query <- parseQueryString(session$clientData$url_search)
    if (!is.null(query$project)) {
      projectId <- query$project

      # Set both reactive values FIRST
      showHomepage(FALSE)
      activeProject(projectId)
      activeProjectId(projectId)

      # Then load the project workspace
      success <- loadProjectToWorkspace(projectId)

      if (success) {
        rv$editor_active <- TRUE
        # Load main file
        projects <- loadProjects()

        uid <- isolate(user_session$user_info$user_id)
        if (!is.null(uid)) {
          pDir <- getUserProjectDir(uid)
          projDir <- file.path(pDir, projectId)
        } else {
          projDir <- ""
        }

        mainFile <- NULL

        for (proj in projects) {
          if (
            proj$id == projectId &&
              !is.null(proj$mainFile) &&
              nzchar(proj$mainFile)
          ) {
            mainFile <- proj$mainFile
            break
          }
        }

        if (!is.null(mainFile) && file.exists(file.path(projDir, mainFile))) {
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

          # --- NEW: Retrieve saved cursor & scroll position ---
          savedRow <- 0
          savedCol <- 0
          # We can re-use the 'projects' list loaded earlier in this observer
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

          session$sendCustomMessage(
            'cursorRestore',
            list(
              file = mainFile,
              row = savedRow,
              column = savedCol
            )
          )
        }
      }
    }
  })

  # Output to control homepage visibility
  output$showHomepage <- reactive({
    showHomepage()
  })
  outputOptions(output, "showHomepage", suspendWhenHidden = FALSE)

  # Toggle settings overlay
  observeEvent(input$railSettingsPageBtn, {
    shinyjs::runjs("openSettingsOverlay();")
  })

  # ----------------------------- TAGGING SYSTEM LOGIC -----------------------------

  # Reactive value for the currently selected filter tag (NULL = show all)
  selectedTag <- reactiveVal(NULL)

  # Reactive value to track which project is currently being tagged (for the modal)
  taggingProjectId <- reactiveVal(NULL)

  # Reactive values for Global Tag Editing
  editingTagOldName <- reactiveVal(NULL)

  # HELPER: Robustly sanitize tags to List of Lists
  ensure_tags_list <- function(tags) {
    if (is.null(tags)) {
      return(list())
    }
    if (length(tags) == 0) {
      return(list())
    }
    if (is.character(tags)) {
      return(list())
    }

    # If jsonlite made it a DataFrame, convert back to list of lists
    if (is.data.frame(tags)) {
      if (nrow(tags) == 0) {
        return(list())
      }
      return(lapply(seq_len(nrow(tags)), function(i) {
        as.list(tags[i, , drop = FALSE])
      }))
    }

    # If it's a list...
    if (is.list(tags)) {
      # Check if it is a single flattened named list (has "name" directly)
      # Wrap it to ensure it is a list of lists
      if (!is.null(names(tags)) && "name" %in% names(tags)) {
        return(list(tags))
      }
      return(tags)
    }
    return(list())
  }

  # Observer: Handle Tag Filtering (Clicking a tag)
  observeEvent(input$filterTag, {
    clickedTag <- input$filterTag
    current <- selectedTag()
    if (!is.null(current) && current == clickedTag) {
      selectedTag(NULL)
    } else {
      selectedTag(clickedTag)
    }
  })

  # Observer: Remove Tag from Project (THE WORKING REFERENCE)
  observeEvent(input$removeTag, {
    req(input$removeTag$projectId, input$removeTag$tagName)
    pid <- input$removeTag$projectId
    tname <- input$removeTag$tagName

    projects <- loadProjects()
    updated <- FALSE

    for (i in seq_along(projects)) {
      if (projects[[i]]$id == pid) {
        projects[[i]]$tags <- ensure_tags_list(projects[[i]]$tags)

        if (length(projects[[i]]$tags) > 0) {
          # This works because Filter returns a clean sub-list
          new_tags <- Filter(function(t) t$name != tname, projects[[i]]$tags)

          if (length(new_tags) == 0) {
            new_tags <- list(list(name = "Uncategorized", color = "secondary"))
          }

          projects[[i]]$tags <- new_tags
          updated <- TRUE
        }
        break
      }
    }

    if (updated) {
      saveProjects(projects)
      projectChangeTrigger(projectChangeTrigger() + 1)
    }
  })

  # Observer: Open Create Tag Modal
  observeEvent(input$openTagModal, {
    pid <- input$openTagModal
    taggingProjectId(pid)
    shinyjs::runjs(
      "document.getElementById('createTagModal').style.display = 'flex';"
    )
    updateTextInput(session, "newTagName", value = "")
  })

  # Observer: Save New Tag (Manual) - SUPPORTS BULK
  observeEvent(input$saveNewTag, {
    req(taggingProjectId())
    req(input$newTagName)
    
    pid <- taggingProjectId() # This can now be a string OR a vector of strings
    name <- trimws(input$newTagName)
    color <- input$newTagColor %||% "blue"
    
    if (nchar(name) == 0) return()
    
    projects <- loadProjects()
    updated <- FALSE
    
    for (i in seq_along(projects)) {
      # USE %in% INSTEAD OF == TO HANDLE BULK ARRAYS
      if (projects[[i]]$id %in% pid) {
        projects[[i]]$tags <- ensure_tags_list(projects[[i]]$tags)
        projects[[i]]$tags <- Filter(
          function(t) t$name != "Uncategorized",
          projects[[i]]$tags
        )
        
        existing_names <- sapply(projects[[i]]$tags, function(t) t$name)
        if (!(name %in% existing_names)) {
          new_tag <- list(name = name, color = color)
          projects[[i]]$tags <- c(projects[[i]]$tags, list(new_tag))
          projects[[i]]$lastEdited <- as.character(Sys.time())
          updated <- TRUE
        }
        # DO NOT break here, we need to process all projects in the bulk array
      }
    }
    
    if (updated) {
      saveProjects(projects)
      projectChangeTrigger(projectChangeTrigger() + 1)
      shinyjs::runjs("document.getElementById('createTagModal').style.display = 'none';")
      
      # Clear checkboxes after successful bulk tag
      shinyjs::runjs("
        document.querySelectorAll('.project-select-cb').forEach(cb => cb.checked = false);
        if (typeof window.updateBulkActions === 'function') window.updateBulkActions();
      ")
    } else {
      showTablerAlert("warning", "Tag already exists", "This tag already exists on the selected project(s).", 5000)
    }
  })
  
  # Observer: Add Existing Tag - SUPPORTS BULK
  observeEvent(input$addExistingTag, {
    req(taggingProjectId())
    req(input$addExistingTag$name)
    
    pid <- taggingProjectId()
    name <- input$addExistingTag$name
    color <- input$addExistingTag$color
    
    projects <- loadProjects()
    updated <- FALSE
    
    for (i in seq_along(projects)) {
      if (projects[[i]]$id %in% pid) { # USE %in%
        projects[[i]]$tags <- ensure_tags_list(projects[[i]]$tags)
        projects[[i]]$tags <- Filter(
          function(t) t$name != "Uncategorized",
          projects[[i]]$tags
        )
        
        existing_names <- sapply(projects[[i]]$tags, function(t) t$name)
        if (!(name %in% existing_names)) {
          new_tag <- list(name = name, color = color)
          projects[[i]]$tags <- c(projects[[i]]$tags, list(new_tag))
          projects[[i]]$lastEdited <- as.character(Sys.time())
          updated <- TRUE
        }
      }
    }
    
    if (updated) {
      saveProjects(projects)
      projectChangeTrigger(projectChangeTrigger() + 1)
      shinyjs::runjs("document.getElementById('createTagModal').style.display = 'none';")
      
      # Clear checkboxes after successful bulk tag
      shinyjs::runjs("
        document.querySelectorAll('.project-select-cb').forEach(cb => cb.checked = false);
        if (typeof window.updateBulkActions === 'function') window.updateBulkActions();
      ")
    } else {
      showTablerAlert("warning", "Tag already exists", "This tag is already attached to the selected project(s).", 5000)
    }
  })

  # ---------------- GLOBAL TAG EDITING (STRICT LIST RECONSTRUCTION) ----------------

  # Observer: Open Edit Tag Modal
  observeEvent(input$openEditTagModal, {
    oldName <- input$openEditTagModal$name
    oldColor <- input$openEditTagModal$color

    editingTagOldName(oldName)

    updateTextInput(session, "editTagName", value = oldName)

    # Update the color input
    session$sendInputMessage("editTagColor", list(value = oldColor))

    shinyjs::runjs(sprintf(
      "
      var radios = document.getElementsByName('editTagColor');
      for(var i=0; i<radios.length; i++) {
        if(radios[i].value == '%s') radios[i].checked = true;
      }
      document.getElementById('editTagModal').style.display = 'flex';
    ",
      oldColor
    ))
  })

  # Observer: Save Global Tag Edit
  observeEvent(input$saveGlobalTagEdit, {
    req(editingTagOldName())
    req(input$editTagName)

    old_name <- editingTagOldName()
    new_name <- trimws(input$editTagName)
    new_color <- input$editTagColor %||% "blue" # Default to blue if null

    if (nchar(new_name) == 0) {
      return()
    }

    projects <- loadProjects()
    updated_any <- FALSE

    # Iterate ALL projects
    for (i in seq_along(projects)) {
      # 1. Sanitize input to guarantee we start with a list of lists
      current_tags <- ensure_tags_list(projects[[i]]$tags)

      if (length(current_tags) > 0) {
        # 2. CHECK if this project even has the tag (Optimization)
        has_target <- any(sapply(current_tags, function(t) {
          !is.null(t$name) && t$name == old_name
        }))

        if (has_target) {
          # 3. RECONSTRUCTION STRATEGY (Replicating Deletion Logic Idea)
          # Instead of modifying inside the list (which risks simplification),
          # we build a brand new list element by element.
          rebuilt_tags <- list()

          for (t in current_tags) {
            if (!is.null(t$name) && t$name == old_name) {
              # REPLACE: Create new list object
              rebuilt_tags[[length(rebuilt_tags) + 1]] <- list(
                name = new_name,
                color = new_color
              )
            } else {
              # KEEP: Copy existing list object
              rebuilt_tags[[length(rebuilt_tags) + 1]] <- t
            }
          }

          # 4. Assign the clean, rebuilt list back to the project
          projects[[i]]$tags <- rebuilt_tags
          updated_any <- TRUE
        }
      }
    }

    if (updated_any) {
      saveProjects(projects)
      projectChangeTrigger(projectChangeTrigger() + 1)
      shinyjs::runjs(
        "document.getElementById('editTagModal').style.display = 'none';"
      )

      # Update filter if needed
      if (!is.null(selectedTag()) && selectedTag() == old_name) {
        selectedTag(new_name)
      }
    } else {
      shinyjs::runjs(
        "document.getElementById('editTagModal').style.display = 'none';"
      )
    }
  })

  # Observer: Global Delete Tag
  observeEvent(input$deleteGlobalTag, {
    req(input$deleteGlobalTag$name)
    target_name <- input$deleteGlobalTag$name

    projects <- loadProjects()
    updated_any <- FALSE

    for (i in seq_along(projects)) {
      projects[[i]]$tags <- ensure_tags_list(projects[[i]]$tags)

      if (length(projects[[i]]$tags) > 0) {
        has_tag <- any(sapply(projects[[i]]$tags, function(t) {
          t$name == target_name
        }))

        if (has_tag) {
          new_tags <- Filter(
            function(t) t$name != target_name,
            projects[[i]]$tags
          )

          if (length(new_tags) == 0) {
            new_tags <- list(list(name = "Uncategorized", color = "secondary"))
          }

          projects[[i]]$tags <- new_tags
          updated_any <- TRUE
        }
      }
    }

    if (updated_any) {
      saveProjects(projects)
      projectChangeTrigger(projectChangeTrigger() + 1)
      if (!is.null(selectedTag()) && selectedTag() == target_name) {
        selectedTag(NULL)
      }
    }
  })

  # ----------------------------- TAG COUNTER UI -----------------------------
  output$projectTagsCounter <- renderUI({
    change_trigger <- projectChangeTrigger()
    filter_tag <- selectedTag()

    all_projects <- loadProjects()

    # Pre-process "Uncategorized" logic
    if (length(all_projects) > 0) {
      for (i in seq_along(all_projects)) {
        all_projects[[i]]$tags <- ensure_tags_list(all_projects[[i]]$tags)
        if (length(all_projects[[i]]$tags) == 0) {
          all_projects[[i]]$tags <- list(list(
            name = "Uncategorized",
            color = "secondary"
          ))
        }
      }
    }

    # Calculate Counts
    all_tags_list <- list()
    if (length(all_projects) > 0) {
      for (p in all_projects) {
        if (!is.null(p$tags) && length(p$tags) > 0) {
          for (t in p$tags) {
            if (!is.null(t$name)) {
              key <- paste0(t$name, "|", t$color)
              if (is.null(all_tags_list[[key]])) {
                all_tags_list[[key]] <- list(
                  name = t$name,
                  color = t$color,
                  count = 1
                )
              } else {
                all_tags_list[[key]]$count <- all_tags_list[[key]]$count + 1
              }
            }
          }
        }
      }
    }

    # --- Edit Tag Modal (Global) ---
    edit_tag_modal <- HTML(
      '
      <div id="editTagModal" style="position: fixed; top: 0; left: 0; right: 0; bottom: 0; width: 100%; height: 100%; background: rgba(24, 36, 51, 0.6); backdrop-filter: blur(4px); z-index: 2050; display: none; align-items: center; justify-content: center;">
        <div class="settings-dialog" style="max-width: 1000px; height: auto;">
          <div class="settings-header">
            <h3>Edit Tag</h3>
            <button type="button" class="btn-close" onclick="document.getElementById(\'editTagModal\').style.display=\'none\';" aria-label="Close"></button>
          </div>
          <div class="settings-body" style="height: auto; overflow: visible;">
            <div class="settings-content" style="padding: 2rem;">
              
              <div class="alert alert-info" role="alert">Changes will apply to all projects with this tag.</div>
              
              <div class="mb-3">
                <label class="form-label required">Tag Name</label>
                <input type="text" id="editTagName" class="form-control" maxlength="20">
              </div>
              
              <div class="mb-3">
                <label class="form-label required">Color</label>
                <div class="form-selectgroup">
                  <label class="form-selectgroup-item">
                    <input type="radio" name="editTagColor" value="blue" class="form-selectgroup-input" onchange="Shiny.setInputValue(\'editTagColor\', this.value)">
                    <span class="form-selectgroup-label"><span class="badge bg-blue"></span></span>
                  </label>
                  <label class="form-selectgroup-item">
                    <input type="radio" name="editTagColor" value="azure" class="form-selectgroup-input" onchange="Shiny.setInputValue(\'editTagColor\', this.value)">
                    <span class="form-selectgroup-label"><span class="badge bg-azure"></span></span>
                  </label>
                  <label class="form-selectgroup-item">
                    <input type="radio" name="editTagColor" value="indigo" class="form-selectgroup-input" onchange="Shiny.setInputValue(\'editTagColor\', this.value)">
                    <span class="form-selectgroup-label"><span class="badge bg-indigo"></span></span>
                  </label>
                  <label class="form-selectgroup-item">
                    <input type="radio" name="editTagColor" value="purple" class="form-selectgroup-input" onchange="Shiny.setInputValue(\'editTagColor\', this.value)">
                    <span class="form-selectgroup-label"><span class="badge bg-purple"></span></span>
                  </label>
                  <label class="form-selectgroup-item">
                    <input type="radio" name="editTagColor" value="pink" class="form-selectgroup-input" onchange="Shiny.setInputValue(\'editTagColor\', this.value)">
                    <span class="form-selectgroup-label"><span class="badge bg-pink"></span></span>
                  </label>
                  <label class="form-selectgroup-item">
                    <input type="radio" name="editTagColor" value="red" class="form-selectgroup-input" onchange="Shiny.setInputValue(\'editTagColor\', this.value)">
                    <span class="form-selectgroup-label"><span class="badge bg-red"></span></span>
                  </label>
                  <label class="form-selectgroup-item">
                    <input type="radio" name="editTagColor" value="orange" class="form-selectgroup-input" onchange="Shiny.setInputValue(\'editTagColor\', this.value)">
                    <span class="form-selectgroup-label"><span class="badge bg-orange"></span></span>
                  </label>
                  <label class="form-selectgroup-item">
                    <input type="radio" name="editTagColor" value="yellow" class="form-selectgroup-input" onchange="Shiny.setInputValue(\'editTagColor\', this.value)">
                    <span class="form-selectgroup-label"><span class="badge bg-yellow"></span></span>
                  </label>
                  <label class="form-selectgroup-item">
                    <input type="radio" name="editTagColor" value="lime" class="form-selectgroup-input" onchange="Shiny.setInputValue(\'editTagColor\', this.value)">
                    <span class="form-selectgroup-label"><span class="badge bg-lime"></span></span>
                  </label>
                  <label class="form-selectgroup-item">
                    <input type="radio" name="editTagColor" value="green" class="form-selectgroup-input" onchange="Shiny.setInputValue(\'editTagColor\', this.value)">
                    <span class="form-selectgroup-label"><span class="badge bg-green"></span></span>
                  </label>
                  <label class="form-selectgroup-item">
                    <input type="radio" name="editTagColor" value="teal" class="form-selectgroup-input" onchange="Shiny.setInputValue(\'editTagColor\', this.value)">
                    <span class="form-selectgroup-label"><span class="badge bg-teal"></span></span>
                  </label>
                  <label class="form-selectgroup-item">
                    <input type="radio" name="editTagColor" value="cyan" class="form-selectgroup-input" onchange="Shiny.setInputValue(\'editTagColor\', this.value)">
                    <span class="form-selectgroup-label"><span class="badge bg-cyan"></span></span>
                  </label>
                </div>
              </div>

              <div class="mt-4 pt-3 border-top text-end">
                <button type="button" class="btn me-2" onclick="document.getElementById(\'editTagModal\').style.display=\'none\';">Cancel</button>
                <button type="button" class="btn btn-primary"
                  onclick="
                    var name = document.getElementById(\'editTagName\').value.trim();
                    var colorElem = document.querySelector(\'input[name=\\\'editTagColor\\\']:checked\');
                    if(name === \'\') {
                      document.getElementById(\'editTagName\').classList.add(\'is-invalid\');
                      return;
                    }
                    document.getElementById(\'editTagName\').classList.remove(\'is-invalid\');
                    Shiny.setInputValue(\'editTagName\', name);
                    if(colorElem) Shiny.setInputValue(\'editTagColor\', colorElem.value);
                    Shiny.setInputValue(\'saveGlobalTagEdit\', Math.random(), {priority: \'event\'});
                  ">
                  Save Changes
                </button>
              </div>

            </div>
          </div>
        </div>
      </div>
    '
    )

    # Render HTML for Tags
    tags_html <- div(
      class = "d-flex flex-wrap gap-2 mb-3 align-items-center",
      if (length(all_tags_list) > 0) {
        lapply(all_tags_list, function(t) {
          is_active <- !is.null(filter_tag) && filter_tag == t$name
          opacity_style <- if (!is.null(filter_tag) && !is_active) {
            "opacity: 0.4;"
          } else {
            ""
          }
          border_style <- if (is_active) {
            "border: 1px solid var(--tblr-primary);"
          } else {
            "border: 1px solid transparent;"
          }

          js_name <- gsub("'", "\\\\'", t$name)

          kebab_html <- ""
          if (t$name != "Uncategorized") {
            kebab_html <- sprintf(
              '
                              <span class="dropdown ms-1" style="display: inline-flex; position: relative;">
                                <a href="#" class="text-muted" data-bs-toggle="dropdown" aria-haspopup="true" aria-expanded="false" onclick="event.stopPropagation();">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon"><circle cx="12" cy="12" r="1"></circle><circle cx="12" cy="5" r="1"></circle><circle cx="12" cy="19" r="1"></circle></svg>
                                </a>
                                <div class="dropdown-menu dropdown-menu-end" 
                                     style="background-color: var(--tblr-bg-surface, #ffffff); border: 1px solid var(--tblr-border-color, #e2e6ea); z-index: 10000 !important; position: absolute !important; right: 0px !important; left: auto !important; min-width: 140px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);">
                                  <a class="dropdown-item" href="#" onclick="event.stopPropagation(); Shiny.setInputValue(\'openEditTagModal\', {name: \'%s\', color: \'%s\'}, {priority: \'event\'})">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-inline me-1" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M4 20h4l10.5 -10.5a1.5 1.5 0 0 0 -4 -4l-10.5 10.5v4" /><line x1="13.5" y1="6.5" x2="17.5" y2="10.5" /></svg>
                                    Edit
                                  </a>
                                  <a class="dropdown-item text-danger" href="#" onclick="event.stopPropagation(); if(confirm(\'Delete tag %s from ALL projects?\')) { Shiny.setInputValue(\'deleteGlobalTag\', {name: \'%s\'}, {priority: \'event\'}); }">
                                    <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-inline me-1" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><line x1="4" y1="7" x2="20" y2="7" /><line x1="10" y1="11" x2="10" y2="17" /><line x1="14" y1="11" x2="14" y2="17" /><path d="M5 7l1 12a2 2 0 0 0 2 2h8a2 2 0 0 0 2 -2l1 -12" /><path d="M9 7v-3a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v3" /></svg>
                                    Delete
                                  </a>
                                </div>
                              </span>
                            ',
              js_name,
              t$color,
              js_name,
              js_name
            )
          }

          HTML(sprintf(
            '
                            <span class="tag" style="cursor: pointer; transition: all 0.2s; padding-right: 8px; overflow: visible; display: inline-flex; align-items: center; %s %s" onclick="Shiny.setInputValue(\'filterTag\', \'%s\', {priority: \'event\'})">
                              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor" class="text-%s" style="width: 16px; height: 16px; margin-right: 6px; flex-shrink: 0;">
                                <path d="M23.12,11.58,18.84,5.17A1.49,1.49,0,0,0,17.60,4.5H3.75A1.5,1.5,0,0,0,2.25,6V18a1.5,1.5,0,0,0,1.5,1.5H17.60a1.5,1.5,0,0,0,1.24-.67h0l4.28-6.41A0.75,0.75,0,0,0,23.12,11.58Z"></path>
                              </svg>
                              <span style="white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 100px;">%s</span>
                              <span class="badge tag-badge ms-1">%d</span>
                              %s
                            </span>
                          ',
            opacity_style,
            border_style,
            js_name,
            t$color,
            t$name,
            t$count,
            kebab_html
          ))
        })
      }
    )

    tagList(tags_html, edit_tag_modal)
  })

  # ----------------------------- UPDATED DASHBOARD -----------------------------

  output$projectsDashboard <- renderUI({
    # Hide loader whenever this UI is updated (handles all return paths)
    session$onFlushed(function() {
       shinyjs::runjs("var l = document.getElementById('dashboardLoader'); if(l) l.classList.remove('show');")
    }, once = TRUE)

    search_term <- input$projectSearch
    sort_by <- projectSort()
    change_trigger <- projectChangeTrigger()
    filter_tag <- selectedTag()
    
    # 1. Load raw projects and get the TRUE system total
    raw_all_projects <- loadProjects()
    total_projects_in_system <- length(raw_all_projects) 
    
    currentView <- projectDashboardState() # "active", "archived", or "trashed"
    
    # 2. Keep only projects that match the current view
    view_projects <- Filter(function(p) {
      status <- p$status %||% "active"
      status == currentView
    }, raw_all_projects)
    
    if (length(view_projects) > 0) {
      for (i in seq_along(view_projects)) {
        view_projects[[i]]$tags <- ensure_tags_list(view_projects[[i]]$tags)
        if (length(view_projects[[i]]$tags) == 0) {
          view_projects[[i]]$tags <- list(list(
            name = "Uncategorized",
            color = "secondary"
          ))
        }
      }
    }
    
    # --- EXISTING TAGS FOR MODAL ---
    existing_tags_html <- ""
    unique_tags <- list()
    if (length(view_projects) > 0) {
      for (p in view_projects) {
        if (!is.null(p$tags)) {
          for (t in p$tags) {
            if (
              !is.null(t$name) &&
              t$name != "Uncategorized" &&
              is.null(unique_tags[[t$name]])
            ) {
              unique_tags[[t$name]] <- t
            }
          }
        }
      }
    }
    
    if (length(unique_tags) > 0) {
      tag_names <- names(unique_tags)
      unique_tags <- unique_tags[order(tolower(tag_names))]
      
      rendered_existing <- lapply(unique_tags, function(t) {
        js_name <- gsub("'", "\\\\'", t$name)
        sprintf(
          '<span class="badge bg-%s text-white me-2 mb-2" style="cursor: pointer;" onclick="Shiny.setInputValue(\'addExistingTag\', {name: \'%s\', color: \'%s\'}, {priority: \'event\'})">%s</span>',
          t$color,
          js_name,
          t$color,
          t$name
        )
      })
      existing_tags_html <- paste(
        '<div class="mb-3"><label class="form-label">Quick add existing</label><div class="d-flex flex-wrap">',
        paste(rendered_existing, collapse = ""),
        '</div></div>'
      )
    }
    
    # --- CREATE TAG MODAL ---
    create_tag_modal <- HTML(paste0(
      '
      <div id="createTagModal" style="position: fixed; top: 0; left: 0; right: 0; bottom: 0; width: 100%; height: 100%; background: rgba(24, 36, 51, 0.6); backdrop-filter: blur(4px); z-index: 3000; display: none; align-items: center; justify-content: center;">
        <div class="settings-dialog" style="max-width: 1000px; height: auto;">
          <div class="settings-header">
            <h3>Add Tag</h3>
            <button type="button" class="btn-close" onclick="document.getElementById(\'createTagModal\').style.display=\'none\';" aria-label="Close"></button>
          </div>
          <div class="settings-body" style="height: auto; overflow: visible;">
            <div class="settings-content" style="padding: 2rem;">
              
              ',
      existing_tags_html,
      '
              
              <div class="hr-text">OR CREATE NEW</div>
              
              <div class="mb-3">
                <label class="form-label required">Tag Name</label>
                <input type="text" id="newTagName" class="form-control" placeholder="e.g. Urgent, Docs" maxlength="20">
              </div>
              
              <div class="mb-3">
                <label class="form-label required">Color</label>
                <div class="form-selectgroup">
                  <label class="form-selectgroup-item"><input type="radio" name="newTagColor" value="blue" class="form-selectgroup-input" checked><span class="form-selectgroup-label"><span class="badge bg-blue"></span></span></label>
                  <label class="form-selectgroup-item"><input type="radio" name="newTagColor" value="azure" class="form-selectgroup-input"><span class="form-selectgroup-label"><span class="badge bg-azure"></span></span></label>
                  <label class="form-selectgroup-item"><input type="radio" name="newTagColor" value="indigo" class="form-selectgroup-input"><span class="form-selectgroup-label"><span class="badge bg-indigo"></span></span></label>
                  <label class="form-selectgroup-item"><input type="radio" name="newTagColor" value="purple" class="form-selectgroup-input"><span class="form-selectgroup-label"><span class="badge bg-purple"></span></span></label>
                  <label class="form-selectgroup-item"><input type="radio" name="newTagColor" value="pink" class="form-selectgroup-input"><span class="form-selectgroup-label"><span class="badge bg-pink"></span></span></label>
                  <label class="form-selectgroup-item"><input type="radio" name="newTagColor" value="red" class="form-selectgroup-input"><span class="form-selectgroup-label"><span class="badge bg-red"></span></span></label>
                  <label class="form-selectgroup-item"><input type="radio" name="newTagColor" value="orange" class="form-selectgroup-input"><span class="form-selectgroup-label"><span class="badge bg-orange"></span></span></label>
                  <label class="form-selectgroup-item"><input type="radio" name="newTagColor" value="yellow" class="form-selectgroup-input"><span class="form-selectgroup-label"><span class="badge bg-yellow"></span></span></label>
                  <label class="form-selectgroup-item"><input type="radio" name="newTagColor" value="lime" class="form-selectgroup-input"><span class="form-selectgroup-label"><span class="badge bg-lime"></span></span></label>
                  <label class="form-selectgroup-item"><input type="radio" name="newTagColor" value="green" class="form-selectgroup-input"><span class="form-selectgroup-label"><span class="badge bg-green"></span></span></label>
                  <label class="form-selectgroup-item"><input type="radio" name="newTagColor" value="teal" class="form-selectgroup-input"><span class="form-selectgroup-label"><span class="badge bg-teal"></span></span></label>
                  <label class="form-selectgroup-item"><input type="radio" name="newTagColor" value="cyan" class="form-selectgroup-input"><span class="form-selectgroup-label"><span class="badge bg-cyan"></span></span></label>
                </div>
              </div>

              <div class="mt-4 pt-3 border-top text-end">
                <button type="button" class="btn" onclick="document.getElementById(\'createTagModal\').style.display=\'none\';">Cancel</button>
                <button type="button" class="btn btn-primary ms-2"
                  onclick="
                    var name = document.getElementById(\'newTagName\').value;
                    var color = document.querySelector(\'input[name=\\\'newTagColor\\\']:checked\').value;
                    if(name.trim() === \'\') {
                        document.getElementById(\'newTagName\').classList.add(\'is-invalid\');
                        return;
                    }
                    document.getElementById(\'newTagName\').classList.remove(\'is-invalid\');
                    Shiny.setInputValue(\'newTagName\', name);
                    Shiny.setInputValue(\'newTagColor\', color);
                    Shiny.setInputValue(\'saveNewTag\', Math.random(), {priority: \'event\'});
                  ">
                  Save Tag
                </button>
              </div>

            </div>
          </div>
        </div>
      </div>
    '
    ))
    
    # --- FILTERING ---
    filtered_projects <- view_projects
    
    if (!is.null(search_term) && nzchar(trimws(search_term))) {
      search_term_lower <- tolower(trimws(search_term))
      filtered_projects <- Filter(
        function(proj) {
          proj_name <- if (!is.null(proj$name)) tolower(proj$name) else ""
          proj_desc <- if (!is.null(proj$description)) {
            tolower(proj$description)
          } else {
            ""
          }
          grepl(search_term_lower, proj_name, fixed = TRUE) |
            grepl(search_term_lower, proj_desc, fixed = TRUE)
        },
        filtered_projects
      )
    }
    
    if (!is.null(filter_tag)) {
      filtered_projects <- Filter(
        function(p) {
          if (is.null(p$tags)) {
            return(FALSE)
          }
          any(sapply(p$tags, function(t) t$name == filter_tag))
        },
        filtered_projects
      )
    }
    
    
    # --- EMPTY STATES ---
    
    if (total_projects_in_system == 0) {
      # Absolute beginner: Show the Welcome screen
      return(
        div(
          class = "empty-state d-flex flex-column align-items-center justify-content-center h-100",
          ui_welcome_illustration(),
          HTML(
            "
            <button
              id=\"newProjectBtn\"
              type=\"button\"
              class=\" d-none d-sm-inline btn btn-1 btn-primary mt-4\"
              onclick=\"openCreateProjectOverlay('create-blank-tab')\"> 
               <svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\" class=\"icon icon-2\"> 
               <path d=\"M5 4h4l3 3h7a2 2 0 0 1 2 2v8a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-11a2 2 0 0 1 2 -2\" /> 
               </svg> 
               <span> New project </span>
            </button>
            "
          )
        )
      )
    }
    
    if (length(filtered_projects) == 0) {
      # Check if it's empty due to a search filter, or just an empty category
      is_search_active <- (!is.null(search_term) && nzchar(trimws(search_term))) || !is.null(filter_tag)
      
      if (is_search_active) {
        clear_tag_btn <- if (!is.null(filter_tag)) {
          js_tag <- gsub("'", "\\\\'", filter_tag)
          sprintf('<button class="btn btn-secondary mb-2" onclick="Shiny.setInputValue(\'filterTag\', \'%s\', {priority: \'event\'})">Clear Tag: %s</button>', js_tag, filter_tag)
        } else { "" }
        
        clear_search_btn <- if (!is.null(search_term) && nzchar(search_term)) {
          '<button class="btn btn-secondary mb-2" onclick="Shiny.setInputValue(\'clearSearch\', Date.now(), {priority:\'event\'})">Clear Search</button>'
        } else { "" }
        
        return(div(
          class = "projects-wrapper",
          div(
            class = "empty",
            ui_empty_illustration(),
            HTML('<p class="empty-title">No matches found</p>'),
            HTML('<p class="empty-subtitle text-secondary">Try adjusting your filters or search.</p>'),
            HTML(paste0('<div class="btn-list justify-content-center">', clear_tag_btn, clear_search_btn, '</div>'))
          ),
          create_tag_modal
        ))
        
      } else {
        # Category is just empty
        empty_title <- switch(currentView,
                              "active" = "NO ACTIVE PROJECTS",
                              "archived" = "NO ARCHIVED PROJECTS",
                              "trashed" = "TRASH IS EMPTY"
        )
        empty_subtitle <- switch(currentView,
                                 "active" = "You don't have any active projects right now. Create a new one!",
                                 "archived" = "You haven't archived any projects.",
                                 "trashed" = "There are no projects in the trash."
        )
        
        # Only offer a "Create New" button on the active tab
        new_btn_html <- if (currentView == "active") {
          "<button type='button' class='btn btn-primary mt-3' onclick=\"openCreateProjectOverlay('create-blank-tab')\">New project</button>"
        } else { "" }
        
        return(div(
          class = "projects-wrapper",
          div(
            class = "empty",
            ui_empty_illustration(),
            HTML(paste0('<p class="empty-title">', empty_title, '</p>')),
            HTML(paste0('<p class="empty-subtitle text-secondary">', empty_subtitle, '</p>')),
            HTML(new_btn_html)
          ),
          create_tag_modal
        ))
      }
    } 
    
    # --- SORTING ---
    if (length(filtered_projects) > 0) {
      sort_by <- if (is.null(sort_by)) "lastEdited" else sort_by
      filtered_projects <- switch(
        sort_by,
        "lastEdited" = filtered_projects[order(
          -sapply(filtered_projects, function(x) {
            if (!is.null(x$lastEdited)) {
              as.numeric(as.POSIXct(x$lastEdited))
            } else {
              0
            }
          })
        )],
        "name" = filtered_projects[order(tolower(sapply(
          filtered_projects,
          function(x) x$name
        )))],
        "created" = filtered_projects[order(
          -sapply(filtered_projects, function(x) {
            if (!is.null(x$created)) as.numeric(as.POSIXct(x$created)) else 0
          })
        )],
        "fileCount" = filtered_projects[order(
          -sapply(filtered_projects, function(x) {
            if (!is.null(x$fileCount)) as.numeric(x$fileCount) else 0
          })
        )],
        filtered_projects[order(
          -sapply(filtered_projects, function(x) {
            if (!is.null(x$lastEdited)) {
              as.numeric(as.POSIXct(x$lastEdited))
            } else {
              0
            }
          })
        )]
      )
    }

    # --- PAGINATION ---
    per_page <- 8L
    total_projects <- length(filtered_projects)
    total_pages <- ceiling(total_projects / per_page)
    current_page <- if (is.null(input$projectsPage)) {
      1L
    } else {
      as.integer(input$projectsPage)
    }
    if (is.na(current_page) || current_page < 1L) {
      current_page <- 1L
    }
    if (current_page > total_pages && total_pages >= 1L) {
      current_page <- total_pages
    }

    start_idx <- ((current_page - 1L) * per_page) + 1L
    end_idx <- min(current_page * per_page, total_projects)

    paged_projects <- filtered_projects[start_idx:end_idx]

    # --- RENDER CARDS ---
    # --- VIEW MODE ---
    view_mode <- input$dashboardViewMode %||% "grid"
    
    # --- INJECTED STYLES & SCRIPTS ---
    custom_table_styles <- tags$style(HTML("
      /* Custom subtle hover effect using the border color */
      .table-subtle-hover tbody tr:hover td { background-color: var(--tblr-border-color) !important; }
      
      /* Remove the thick header border from Tabler */
      .table-subtle-hover thead th { border-bottom: 1px solid var(--tblr-border-color) !important; }

      /* Flexible Tags that shrink text but keep color */
      .tags-nowrap-container { display: flex; flex-wrap: nowrap; gap: 4px; overflow: hidden; }
      .tag-flexible { display: inline-flex; align-items: center; max-width: 100%; min-width: 20px; flex-shrink: 1; margin: 0 !important; }
      .tag-text-shrink { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; min-width: 0; flex-shrink: 1; }
      .actions-cell { white-space: nowrap; }

      /* Bulk Actions Toolbar */
      #bulk-actions-container {
        transition: all 0.3s ease;
        background: var(--tblr-bg-surface);
        border: 1px solid var(--tblr-border-color);
        border-radius: var(--tblr-border-radius);
        padding: 0.5rem 1rem;
        margin-bottom: 1rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
      }
    "))
    
    # Scripts for view toggles and bulk checkbox tracking
    injected_scripts <- tags$script(HTML(sprintf("
      // Hide standard sort controls in table view
      (function() {
        var sortBtns = document.querySelectorAll('.btn-sort');
        if(sortBtns.length > 0) {
          var sortContainer = sortBtns[0].closest('.btn-group') || sortBtns[0].parentElement;
          if(sortContainer) sortContainer.style.display = '%s';
        }
      })();

      // Global function to track checkbox states
      window.updateBulkActions = function() {
        var checkboxes = document.querySelectorAll('.project-select-cb:checked');
        var ids = Array.from(checkboxes).map(cb => cb.value);
        var bulkContainer = document.getElementById('bulk-actions-container');
        var countLabel = document.getElementById('bulk-count-label');
        
        if (ids.length >= 2) {
          bulkContainer.classList.remove('d-none');
          if (countLabel) countLabel.innerText = ids.length + ' projects selected';
        } else {
          bulkContainer.classList.add('d-none');
        }
        
        // Send state to Shiny server
        if (window.Shiny) {
          Shiny.setInputValue('selectedProjects', ids);
        }
        
        // Handle 'Select All' visual state (Indeterminate vs Checked)
        var selectAllCb = document.getElementById('selectAllProjects');
        if (selectAllCb) {
          var allCheckboxes = document.querySelectorAll('.project-select-cb');
          selectAllCb.checked = (allCheckboxes.length > 0 && checkboxes.length === allCheckboxes.length);
          selectAllCb.indeterminate = (checkboxes.length > 0 && checkboxes.length < allCheckboxes.length);
        }
      };

      // Handle 'Select All' click
      window.toggleSelectAll = function(e) {
        var isChecked = e.target.checked;
        var checkboxes = document.querySelectorAll('.project-select-cb');
        checkboxes.forEach(cb => cb.checked = isChecked);
        window.updateBulkActions();
      };

      // Reset on render
      setTimeout(window.updateBulkActions, 100);

      // --- PROJECT SINGLETON TOOLTIP ENGINE ---
      (function() {
        var tooltip = document.querySelector('.ms-tooltip');
        if (!tooltip) {
          tooltip = document.createElement('div');
          tooltip.className = 'ms-tooltip';
          document.body.appendChild(tooltip);
        }
        
        var container = document.querySelector('.projects-wrapper');
        if (!container) return;
        
        container.addEventListener('mouseover', function(e) {
          var target = e.target.closest('[data-ms-tooltip]');
          if (target && target.dataset.msTooltip) {
            tooltip.textContent = target.dataset.msTooltip;
            tooltip.classList.add('show');
          }
        });
        
        container.addEventListener('mousemove', function(e) {
          if (tooltip.classList.contains('show')) {
            tooltip.style.left = e.clientX + 'px';
            tooltip.style.top = e.clientY + 'px';
          }
        });
        
        container.addEventListener('mouseout', function(e) {
          var target = e.target.closest('[data-ms-tooltip]');
          if (target) {
            tooltip.classList.remove('show');
          }
        });
      })();
    ", if (view_mode == "table") "none" else "")))
    
    # --- PAGER ---
    pager <- NULL
    if (total_pages > 1L) {
      prev_page <- max(1L, current_page - 1L)
      prev_disabled_str <- if (current_page == 1L) " disabled" else ""
      next_page <- min(total_pages, current_page + 1L)
      next_disabled_str <- if (current_page == total_pages) " disabled" else ""
      
      page_items <- lapply(seq_len(total_pages), function(p) {
        is_active <- (p == current_page)
        btn_class <- if (is_active) "btn btn-sm btn-outline-primary border-0 active" else "btn btn-sm btn-outline-secondary border-0"
        tags$li(class = "page-item", tags$button(type = "button", class = btn_class, onclick = sprintf("if (window.Shiny) Shiny.setInputValue('projectsPage', %d, {priority:'event'}); return false;", p), p))
      })
      
      pager <- tags$ul(
        class = "pagination d-flex flex-wrap justify-content-center align-items-center gap-2 mt-4",
        tags$li(class = paste0("page-item", prev_disabled_str), tags$button(type = "button", class = paste0("btn btn-sm btn-outline-secondary border-0", prev_disabled_str), onclick = sprintf("if (window.Shiny) Shiny.setInputValue('projectsPage', %d, {priority:'event'}); return false;", prev_page), HTML('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-1"><path d="M15 6l-6 6l6 6"></path></svg>'))),
        page_items,
        tags$li(class = paste0("page-item", next_disabled_str), tags$button(type = "button", class = paste0("btn btn-sm btn-outline-secondary border-0", next_disabled_str), onclick = sprintf("if (window.Shiny) Shiny.setInputValue('projectsPage', %d, {priority:'event'}); return false;", next_page), HTML('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-1"><path d="M9 6l6 6l-6 6"></path></svg>')))
      )
    }
    
    # --- RENDER ITEMS ---
    rendered_items <- lapply(paged_projects, function(proj) {
      if (!is.list(proj)) proj <- as.list(proj)
      
      safe_proj <- list(
        id = if (!is.null(proj$id)) proj$id else uuid::UUIDgenerate(),
        name = if (!is.null(proj$name)) proj$name else "Unknown",
        description = if (!is.null(proj$description)) proj$description else "",
        fileCount = if (!is.null(proj$fileCount)) proj$fileCount else 0,
        lastEdited = if (!is.null(proj$lastEdited)) proj$lastEdited else as.character(Sys.time()),
        tags = ensure_tags_list(proj$tags)
      )
      
      js_name <- gsub("'", "\\\\'", safe_proj$name)
      js_desc <- gsub("'", "\\\\'", safe_proj$description)
      js_desc <- gsub("\n", " ", js_desc)
      
      tags_html <- ""
      if (length(safe_proj$tags) > 0) {
        tags_rendered <- lapply(safe_proj$tags, function(t) {
          disp_name <- t$name
          js_tag_name <- gsub("'", "\\\\'", t$name)
          sprintf(
            '<span class="tag tag-flexible" style="cursor: pointer;" onclick="event.stopPropagation(); Shiny.setInputValue(\'filterTag\', \'%s\', {priority: \'event\'})">
              <span class="legend bg-%s flex-shrink-0"></span>
              <span class="tag-text-shrink">%s</span>
              <a href="#" class="btn-close flex-shrink-0 ms-1" onclick="event.stopPropagation(); Shiny.setInputValue(\'removeTag\', {projectId: \'%s\', tagName: \'%s\'}, {priority: \'event\'})"></a>
            </span>',
            js_tag_name, t$color, disp_name, safe_proj$id, js_tag_name
          )
        })
        tags_html <- paste(tags_rendered, collapse = "")
      }
      
      # Single-Item Action Buttons
      action_buttons <- if (currentView == "active") {
        paste0(
          '<a style="color:var(--text)!important; cursor:pointer;" data-ms-tooltip="Add Tag" onclick="event.stopPropagation(); Shiny.setInputValue(\'openTagModal\', \'', safe_proj$id, '\', {priority:\'event\'})"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon"><path d="M23.12,11.58,18.84,5.17A1.49,1.49,0,0,0,17.60,4.5H3.75A1.5,1.5,0,0,0,2.25,6V18a1.5,1.5,0,0,0,1.5,1.5H17.60a1.5,1.5,0,0,0,1.24-.67h0l4.28-6.41A0.75,0.75,0,0,0,23.12,11.58Z"></path></svg></a>',
          '<a style="color:var(--text)!important; cursor:pointer;" data-ms-tooltip="Archive" onclick="event.stopPropagation(); Shiny.setInputValue(\'archiveProject\', \'', safe_proj$id, '\', {priority:\'event\'})"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><rect x="3" y="4" width="18" height="4" rx="2" /><path d="M5 8v10a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-10" /><line x1="10" y1="12" x2="14" y2="12" /></svg></a> ',
          '<a style="color:var(--text)!important; cursor:pointer;" data-ms-tooltip="Trash" onclick="event.stopPropagation(); Shiny.setInputValue(\'trashProject\', \'', safe_proj$id, '\', {priority:\'event\'})"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg></a> ',
          '<a style="color:var(--text)!important; cursor:pointer;" data-ms-tooltip="Edit" onclick="event.stopPropagation(); openEditProjectOverlay(\'', safe_proj$id, '\', \'', js_name, '\', \'', js_desc, '\')"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg></a> ',
          '<a style="color:var(--text)!important; cursor:pointer;" id="download_', safe_proj$id, '" href="#" data-ms-tooltip="Download" onclick="event.preventDefault(); event.stopPropagation(); Shiny.setInputValue(\'downloadProject\', \'', safe_proj$id, '\', {priority: \'event\'});"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg></a>'
        )
      } else { 
        paste0(
          '<a style="color:var(--text)!important; cursor:pointer;" data-ms-tooltip="Restore" onclick="event.stopPropagation(); Shiny.setInputValue(\'restoreProject\', \'', safe_proj$id, '\', {priority:\'event\'})"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M9 11l-4 4l4 4m-4 -4h11a4 4 0 0 0 0 -8h-1" /></svg></a> ',
          '<a style="color:var(--tblr-danger)!important; cursor:pointer;" id="delete_', safe_proj$id, '" href="#" data-ms-tooltip="Delete Forever" onclick="event.preventDefault(); event.stopPropagation(); document.getElementById(\'deleteProjectModal_', safe_proj$id, '\').style.display = \'flex\';"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg></a>'
        )
      }
      
      card_onclick <- if (currentView == "active") {
        sprintf("setDashboardLoaderText('Opening project...'); document.getElementById('dashboardLoader').classList.add('show'); Shiny.setInputValue('loadProject', '%s', {priority: 'event'})", safe_proj$id)
      } else { "" }
      
      card_cursor <- if (currentView == "active") "cursor: pointer;" else "cursor: default;"
      
      delete_modal <- HTML(paste0(
        "<div id=\"deleteProjectModal_", safe_proj$id, "\" style=\"display:none; position: fixed; top: 0; left: 0; right: 0; bottom: 0; width: 100%; height: 100%; background: rgba(24, 36, 51, 0.6); backdrop-filter: blur(4px); z-index: 1060; align-items: center; justify-content: center;\">
            <div class=\"settings-dialog\" style=\"max-width: 1000px;\">
              <div class=\"settings-header\"><h3 class=\"text-danger\">Delete project</h3><button type=\"button\" class=\"btn-close\" onclick=\"document.getElementById('deleteProjectModal_", safe_proj$id, "').style.display='none';\"></button></div>
              <div class=\"settings-body\"><div class=\"settings-content\" style=\"padding: 2rem; text-align: center;\">
                  <div class=\"text-danger mb-3\"><svg xmlns=\"http://www.w3.org/2000/svg\" class=\"icon icon-lg\" width=\"48\" height=\"48\" viewBox=\"0 0 24 24\" stroke-width=\"2\" stroke=\"currentColor\" fill=\"none\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path stroke=\"none\" d=\"M0 0h24v24H0z\" fill=\"none\"/><path d=\"M12 9v2m0 4v.01\" /><path d=\"M5 19h14a2 2 0 0 0 1.84 -2.75l-7.1 -12.25a2 2 0 0 0 -3.5 0l-7.1 12.25a2 2 0 0 0 1.75 2.75\" /></svg></div>
                  <h3>Are you sure?</h3><div class=\"text-secondary\">Delete <strong>", safe_proj$name, "</strong>?</div>
                  <div class=\"mt-4 pt-3 border-top row g-2\"><div class=\"col\"><button type=\"button\" class=\"btn w-100\" onclick=\"document.getElementById('deleteProjectModal_", safe_proj$id, "').style.display='none';\">Cancel</button></div><div class=\"col\"><button type=\"button\" class=\"btn btn-danger w-100\" onclick=\"Shiny.setInputValue('deleteProjectForever', '", safe_proj$id, "', {priority: 'event'}); document.getElementById('deleteProjectModal_", safe_proj$id, "').style.display='none';\">Delete</button></div></div>
              </div></div>
            </div>
          </div>"
      ))
      
      # The Individual Checkbox applied to both Grid & Table
      select_checkbox <- tags$input(
        class = "form-check-input m-0 align-middle project-select-cb table-selectable-check", 
        type = "checkbox", 
        value = safe_proj$id, 
        onclick = "event.stopPropagation(); updateBulkActions();"
      )
      
      if (view_mode == "grid") {
        list(
          div(
            class = "project-card position-relative",
            style = card_cursor,
            `data-project-id` = safe_proj$id,
            onclick = card_onclick,
            
            # --- UPDATED: Flexbox header for perfect vertical centering ---
            div(class = "project-name d-flex align-items-center",
                # The checkbox wrapper (z-index ensures it's always clickable)
                div(class = "me-2", style = "z-index: 10; position: relative;", onclick = "event.stopPropagation();", select_checkbox),
                # The project name (truncates if it gets too long)
                span(class = "text-truncate", safe_proj$name)
            ),
            div(class = "project-description", if (nzchar(safe_proj$description)) safe_proj$description else "No description"),
            div(class = "project-tags mt-1 mb-1 px-3", style = "line-height: 1;", HTML(tags_html)),
            div(class = "project-meta",
                span(paste(safe_proj$fileCount, "files")),
                span(format(as.POSIXct(safe_proj$lastEdited), "%b %d, %Y %H:%M"))
            ),
            div(class = "project-actions", HTML(action_buttons))
          ),
          delete_modal
        )
      } else {
        # Table Row
        list(
          tags$tr(
            style = card_cursor,
            onclick = card_onclick,
            tags$td(class="w-1 pe-3", onclick = "event.stopPropagation();", select_checkbox),
            tags$td(class="sort-name text-truncate", style="max-width: 150px; font-weight: 500;", safe_proj$name),
            tags$td(class="sort-city text-muted text-truncate", style="max-width: 250px;", if (nzchar(safe_proj$description)) safe_proj$description else "No description"),
            tags$td(class="sort-status", 
                    tags$span(class=if(currentView=="active") "badge bg-success-lt" else "badge bg-danger-lt", tools::toTitleCase(currentView))
            ),
            tags$td(class="sort-date text-muted text-truncate", style="max-width: 120px;", format(as.POSIXct(safe_proj$lastEdited), "%b %d, %Y %H:%M")),
            tags$td(class="sort-tags py-1", div(class="tags-nowrap-container", style="max-width: 180px;", HTML(tags_html))),
            tags$td(class="sort-category text-muted text-truncate", style="max-width: 80px;", paste(safe_proj$fileCount, "files")),
            tags$td(class="text-end actions-cell", style="min-width: 150px;", onclick = "event.stopPropagation();", div(class="d-flex justify-content-end gap-2", HTML(action_buttons)))
          ),
          delete_modal
        )
      }
    })
    
    # --- BULK ACTIONS TOOLBAR ---
    bulk_actions_toolbar <- div(
      id = "bulk-actions-container",
      class = "d-none",
      span(id = "bulk-count-label", class = "fw-bold me-auto", "0 projects selected"),
      
      div(class = "d-flex align-items-center gap-3",
          # Download
          HTML('<a class = "rail-btn" style="color:var(--text)!important; cursor:pointer;" data-ms-tooltip="Download" onclick="Shiny.setInputValue(\'bulkActionTrigger\', \'download\', {priority: \'event\'})"><svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-1"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg></a>'),
          
          # Tag
          if(currentView == "active") {
            HTML('<a class = "rail-btn" style="color:var(--text)!important; cursor:pointer;" data-ms-tooltip="Tag" onclick="Shiny.setInputValue(\'bulkActionTrigger\', \'tag\', {priority: \'event\'})"><svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-1"><path d="M23.12,11.58,18.84,5.17A1.49,1.49,0,0,0,17.60,4.5H3.75A1.5,1.5,0,0,0,2.25,6V18a1.5,1.5,0,0,0,1.5,1.5H17.60a1.5,1.5,0,0,0,1.24-.67h0l4.28-6.41A0.75,0.75,0,0,0,23.12,11.58Z"></path></svg></a>')
          },
          
          # Archive
          if(currentView == "active") {
            HTML('<a class = "rail-btn" style="color:var(--text)!important; cursor:pointer;" data-ms-tooltip="Archive" onclick="Shiny.setInputValue(\'bulkActionTrigger\', \'archive\', {priority: \'event\'})"><svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-1"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><rect x="3" y="4" width="18" height="4" rx="2" /><path d="M5 8v10a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-10" /><line x1="10" y1="12" x2="14" y2="12" /></svg></a>')
          },
          
          # Restore
          if(currentView != "active") {
            HTML('<a class = "rail-btn" style="color:var(--text)!important; cursor:pointer;" data-ms-tooltip="Restore" onclick="Shiny.setInputValue(\'bulkActionTrigger\', \'restore\', {priority: \'event\'})"><svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-1"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M9 11l-4 4l4 4m-4 -4h11a4 4 0 0 0 0 -8h-1" /></svg></a>')
          },
          
          # Trash / Delete Forever
          if(currentView == "trashed") {
            HTML('<a class = "rail-btn" style="color:var(--tblr-danger)!important; cursor:pointer;" data-ms-tooltip="Delete Forever" onclick="Shiny.setInputValue(\'bulkActionTrigger\', \'trash\', {priority: \'event\'})"><svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-1"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg></a>')
          } else {
            HTML('<a class = "rail-btn" style="color:var(--text)!important; cursor:pointer;" data-ms-tooltip="Trash" onclick="Shiny.setInputValue(\'bulkActionTrigger\', \'trash\', {priority: \'event\'})"><svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-1"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg></a>')
          }
      )
    )
    
    # --- ASSEMBLE CONTENT ---
    content_ui <- if (view_mode == "grid") {
      div(class = "projects-grid", rendered_items)
    } else {
      # Table Layout
      div(class = "card",
          div(class = "table-responsive",
              tags$table(class = "table table-vcenter table-subtle-hover table-selectable card-table", style="table-layout: fixed; width: 100%;",
                         tags$thead(
                           tags$tr(
                             # The Select All Checkbox
                             tags$th(class = "w-1 pe-3", tags$input(class="form-check-input m-0 align-middle", type="checkbox", id="selectAllProjects", onclick="toggleSelectAll(event)")),
                             tags$th(style="width: 18%;", tags$button(class = "table-sort", onclick="Shiny.setInputValue('sortName', Math.random())", "Name")),
                             tags$th(style="width: 14%;", "Description"),
                             tags$th(style="width: 9%;", "Status"),
                             tags$th(style="width: 14%;", tags$button(class = "table-sort", onclick="Shiny.setInputValue('sortLastEdited', Math.random())", "Last Edited")),
                             tags$th(style="width: 20%;", "Tags"),
                             tags$th(style="width: 10%;", tags$button(class = "table-sort", onclick="Shiny.setInputValue('sortFileCount', Math.random())", "Files")),
                             tags$th(style="width: 15%; text-align: right;", "Actions")
                           )
                         ),
                         tags$tbody(class = "table-tbody", rendered_items)
              )
          )
      )
    }
    

    div(
      class = "projects-wrapper",
      style = "overflow: auto !important;",
      custom_table_styles,
      injected_scripts,
      bulk_actions_toolbar,  # Injected here above the content
      content_ui,
      create_tag_modal,
      if (!is.null(pager)) {
        div(class = "projects-pager", style = "padding-bottom: 5px !important;", pager)
      }
    )
  })

