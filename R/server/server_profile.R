  # ----------------------------- USER PROFILE MANAGEMENT -----------------------------
  # Load user profile
  loadUserProfile <- function() {
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return(list(
        username = "New User",
        email = "",
        userId = "",
        bio = "",
        institution = "",
        profilePicture = ""
      ))
    }

    con <- get_db_connection()
    if (is.null(con)) {
      # Log but otherwise return safe default
      message("Database connection failed in loadUserProfile")
      return(list(
        username = "Guest / Error",
        email = "",
        userId = uid,
        bio = "Database connection lost.",
        institution = "",
        profilePicture = ""
      ))
    }
    on.exit(poolReturn(con))

    tryCatch(
      {
        user <- dbGetQuery(
          con,
          "SELECT * FROM users WHERE user_id = $1",
          list(uid)
        )
        if (nrow(user) == 1) {
          list(
            userId = user$user_id,
            username = if (is.na(user$username) || user$username == "") {
              "New User"
            } else {
              user$username
            },
            email = user$email,
            institution = if (is.na(user$institution)) "" else user$institution,
            bio = if (is.na(user$bio)) "" else user$bio,
            profilePicture = if (is.na(user$profile_picture)) {
              ""
            } else {
              user$profile_picture
            },
            verified = FALSE,
            collaborators = 0,
            memberSince = as.character(Sys.time()),
            lastActive = as.character(Sys.time())
          )
        } else {
          list(
            userId = uid,
            username = "New User",
            email = "",
            institution = "",
            bio = "",
            profilePicture = ""
          )
        }
      },
      error = function(e) {
        list(
          userId = uid,
          username = "Error",
          email = "",
          institution = "",
          bio = "",
          profilePicture = ""
        )
      }
    )
  }

  # Save user profile
  saveUserProfile <- function(profile) {
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return(FALSE)
    }

    con <- get_db_connection()
    if (is.null(con)) {
      showTablerAlert(
        "danger",
        "Database Error",
        "Could not connect to database to save profile.",
        5000
      )
      return(FALSE)
    }
    on.exit(poolReturn(con))

    tryCatch(
      {
        dbExecute(
          con,
          "UPDATE users SET username = $1, institution = $2, bio = $3, profile_picture = $4 WHERE user_id = $5",
          list(
            profile$username,
            profile$institution,
            profile$bio,
            profile$profilePicture,
            uid
          )
        )
        showTablerAlert(
          "success",
          "Successfully saved",
          "Successfully saved user profile",
          5000
        )
        return(TRUE)
      },
      error = function(e) {
        showTablerAlert(
          "danger",
          "Error saving",
          paste("Error saving profile:", e$message),
          5000
        )
        return(FALSE)
      }
    )
  }

  # Update specific profile field
  updateProfileField <- function(field, value) {
    profile <- loadUserProfile()
    profile[[field]] <- value
    saveUserProfile(profile)
  }

  # Handle profile picture upload
  handleProfilePictureUpload <- function(uploadInfo) {
    tryCatch(
      {
        if (is.null(uploadInfo) || nrow(uploadInfo) == 0) {
          return(NULL)
        }

        # Create profile pictures directory if it doesn't exist
        profilePicsDir <- file.path("www", "profile_pictures")
        if (!dir.exists(profilePicsDir)) {
          dir.create(profilePicsDir, recursive = TRUE)
        }

        # Generate unique filename
        fileExt <- tools::file_ext(uploadInfo$name)
        # Generate unique UUID filename instead of timestamp
        newFileName <- paste0(uuid::UUIDgenerate(), ".", fileExt)
        destPath <- file.path(profilePicsDir, newFileName)

        # Copy uploaded file
        file.copy(uploadInfo$datapath, destPath, overwrite = TRUE)

        # Return relative path for use in HTML
        return(file.path("profile_pictures", newFileName))
      },
      error = function(e) {
        showTablerAlert(
          "danger",
          "Upload failed",
          paste("Error uploading profile picture:", e$message),
          5000
        )
        return(NULL)
      }
    )
  }

  # Clear search functionality
  observeEvent(input$clearSearch, {
    updateTextInput(session, "projectSearch", value = "")
  })

  # Render file input in the main modal
  output$fileUploadContainer <- renderUI({
    fileInput(
      "projectInitialFiles",
      NULL,
      multiple = TRUE,
      width = "100%",
      accept = c(
        ".tex",
        ".bib",
        ".bst",
        ".cls",
        ".cfg",
        ".sty",
        ".txt",
        ".rnw",
        ".dta",
        ".csv",
        ".xls",
        ".xlsx",
        ".doc",
        ".docx",
        ".ppt",
        ".pptx",
        ".rdata",
        ".rds",
        ".zip",
        ".tar",
        ".gz",
        ".7z",
        ".png",
        ".jpg",
        ".jpeg",
        ".gif",
        ".pdf",
        ".html",
        ".htm",
        ".js",
        ".css",
        ".xml",
        ".json",
        ".md",
        ".sql",
        ".py",
        ".c",
        ".cpp",
        ".java",
        ".sh",
        ".mp3",
        ".mp4",
        ".mov",
        ".avi",
        ".mkv",
        ".odt",
        ".ods",
        ".odp",
        ".rtf"
      )
    )
  })

  # Render file input in the secondary modal
  output$fileUploadContainerNew <- renderUI({
    fileInput(
      "projectInitialFilesNew",
      NULL,
      multiple = TRUE,
      width = "100%",
      accept = c(
        ".tex",
        ".bib",
        ".bst",
        ".cls",
        ".cfg",
        ".sty",
        ".txt",
        ".rnw",
        ".dta",
        ".csv",
        ".xls",
        ".xlsx",
        ".doc",
        ".docx",
        ".ppt",
        ".pptx",
        ".rdata",
        ".rds",
        ".zip",
        ".tar",
        ".gz",
        ".7z",
        ".png",
        ".jpg",
        ".jpeg",
        ".gif",
        ".pdf",
        ".html",
        ".htm",
        ".js",
        ".css",
        ".xml",
        ".json",
        ".md",
        ".sql",
        ".py",
        ".c",
        ".cpp",
        ".java",
        ".sh",
        ".mp3",
        ".mp4",
        ".mov",
        ".avi",
        ".mkv",
        ".odt",
        ".ods",
        ".odp",
        ".rtf"
      )
    )
  })

  # Upload new project modal trigger
  observeEvent(input$newProjectUploadBtn, {
    # Trigger modal display here
  })

  # Create new project modal trigger
  observeEvent(input$newProjectBtn, {
    # Trigger modal display here
  })

  # Unified Project Creation Handler (Blank & Upload)
  observeEvent(input$createProjectTrigger, {
    data <- input$createProjectTrigger

    # Capture the new template field (default to article if missing)
    template <- if (!is.null(data$template)) data$template else "article"

    req(data$name)

    name <- trimws(data$name)
    desc <- if (!is.null(data$desc)) trimws(data$desc) else ""
    type <- data$type

    initialFiles <- NULL

    # Pre-process uploaded files if any
    if (type == 'upload' && !is.null(data$files) && length(data$files) > 0) {
      # Convert list of lists to a format similar to Shiny's fileInput
      # createNewProject expects 'name' and 'datapath' columns

      filenames <- c()
      datapaths <- c()

      temp_dir <- tempdir()

      for (f in data$files) {
        # Decode base64
        dataURI <- f$data
        base64Data <- sub("^data:.*?;base64,", "", dataURI)
        rawData <- base64enc::base64decode(base64Data)

        # Save to temp
        safeName <- gsub("[^A-Za-z0-9._-]", "_", f$name)
        tPath <- file.path(temp_dir, safeName)
        writeBin(rawData, tPath)

        filenames <- c(filenames, f$name)
        datapaths <- c(datapaths, tPath)
      }

      initialFiles <- data.frame(
        name = filenames,
        datapath = datapaths,
        stringsAsFactors = FALSE
      )
    }

    # Create Project
    projectId <- createNewProject(
      name = trimws(data$name),
      description = data$desc,
      initialFiles = initialFiles,
      template = template
    )

    if (!is.null(projectId)) {
      showTablerAlert(
        "success",
        "Project created",
        paste("Project", name, "created successfully!"),
        5000
      )

      # Auto-load the new project
      shinyjs::delay(500, {
        shiny::updateQueryString(
          paste0("?project=", projectId),
          mode = "replace"
        )
        session$sendCustomMessage('loadProject', projectId)
      })
    } else {
      showTablerAlert("danger", "Failed to create", "Failed to create project.", 5000)
    }
  })

  observeEvent(input$resetFileInput_projectInitialFiles, {
    shinyjs::reset("projectInitialFiles")
    # Force update of the file input display
    shinyjs::runjs(
      "
    var inputs = document.querySelectorAll('input[data-shiny-name=\"projectInitialFiles\"]');
    inputs.forEach(function(input) {
      if (input.type === 'text') input.value = '';
    });
  "
    )
  })

  observeEvent(input$resetFileInput_projectInitialFilesNew, {
    shinyjs::reset("projectInitialFilesNew")
    # Force update of the file input display
    shinyjs::runjs(
      "
    var inputs = document.querySelectorAll('input[data-shiny-name=\"projectInitialFilesNew\"]');
    inputs.forEach(function(input) {
      if (input.type === 'text') input.value = '';
    });
  "
    )
  })

  # Load project into editor
  observeEvent(input$loadProject, {
    req(input$loadProject)

    # --- FIX: Force hide preview overlay to ensure editor is visible ---
    session$sendCustomMessage("hideFilePreview", list(path = NULL))
    # ------------------------------------------------------------------

    projectId <- input$loadProject
    success <- loadProjectToWorkspace(projectId)

    if (success) {
      rv$editor_active <- TRUE
      activeProject(projectId)
      activeProjectId(projectId) # Set both for consistency
      showHomepage(FALSE)

      # Load main .tex file if available
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
        if (proj$id == projectId && nzchar(proj$mainFile)) {
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

        # --- CRITICAL FIX: Set flag to prevent autosave from clearing file ---
        rv$fileJustLoaded <- TRUE
        later::later(function() {
          rv$fileJustLoaded <- FALSE
        }, 0.5)
        # ---------------------------------------------------------------------

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

        # Delay cursor restore to ensure editor is fully loaded
        later::later(
          function() {
            session$sendCustomMessage(
              'cursorRestore',
              list(
                file = mainFile,
                row = savedRow,
                column = savedCol
              )
            )
          },
          0.3
        )

        pushBibCitations(content, projDir)
        pushLabelKeys(content)
      } else {
        # Find any .tex file
        texFiles <- list.files(
          projDir,
          pattern = "\\.tex$",
          ignore.case = TRUE,
          recursive = TRUE
        )
        if (length(texFiles) > 0) {
          content <- paste(
            readLines(file.path(projDir, texFiles[1]), warn = FALSE),
            collapse = "\n"
          )
          updateAceEditor(session, "sourceEditor", value = content)
          currentFile(texFiles[1])
          updateStatus(texFiles[1])
          session$sendCustomMessage('cursorRestore', list(file = texFiles[1]))
        } else {
          updateAceEditor(session, "sourceEditor", value = "")
          currentFile("")
          updateStatus("Project loaded (no .tex files found)")
        }
      }
    } else {
      showTablerAlert("danger", "Failed to load", "Error loading project", 5000)
    }
  })

  # Trash Project
  observeEvent(input$trashProject, {
    req(input$trashProject)
    if(changeProjectStatus(input$trashProject, "trashed")) {
      showTablerAlert("info", "Project trashed", "Project moved to trash successfully.", 5000)
    }
  })
  
  # Archive Project
  observeEvent(input$archiveProject, {
    req(input$archiveProject)
    if(changeProjectStatus(input$archiveProject, "archived")) {
      showTablerAlert("info", "Project archived", "Project archived successfully.", 5000)
    }
  })
  
  # Restore Project (From Trash or Archive back to Active)
  observeEvent(input$restoreProject, {
    req(input$restoreProject)
    if(changeProjectStatus(input$restoreProject, "active")) {
      showTablerAlert("success", "Project restored", "Project restored successfully.", 5000)
    }
  })
  
  # OVERWRITE your existing deleteProject observer to only delete forever
  observeEvent(input$deleteProjectForever, {
    req(input$deleteProjectForever)
    projectId <- input$deleteProjectForever
    uid <- isolate(user_session$user_info$user_id)
    
    projects <- loadProjects()
    targetProj <- Filter(function(x) x$id == projectId, projects)
    
    if (length(targetProj) > 0) {
      status <- targetProj[[1]]$status %||% "active"
      baseDir <- getUserBaseDir(uid)
      paths <- list("active" = "projects", "trashed" = "trashed", "archived" = "archived")
      
      # Wipe physical directory
      projDir <- file.path(baseDir, paths[[status]], projectId)
      if (dir.exists(projDir)) {
        unlink(projDir, recursive = TRUE)
      }
      
      # Remove from JSON
      projects <- projects[sapply(projects, function(x) x$id != projectId)]
      saveProjects(projects)
      projectChangeTrigger(projectChangeTrigger() + 1)
      
      showTablerAlert("success", "Permanently deleted", "Project permanently deleted successfully.", 5000)
      shinyjs::runjs("document.body.classList.remove('modal-open'); document.querySelectorAll('.modal-backdrop').forEach(el => el.remove());")
    }
  })

  # Rename project
  observeEvent(input$renameProject, {
    req(input$renameProject)

    projectId <- input$renameProject$id
    newName <- input$renameProject$name
    newDesc <- input$renameProject$desc

    if (nzchar(trimws(newName))) {
      projects <- loadProjects()

      for (i in seq_along(projects)) {
        if (projects[[i]]$id == projectId) {
          projects[[i]]$name <- trimws(newName)
          projects[[i]]$description <- if (nzchar(trimws(newDesc))) {
            trimws(newDesc)
          } else {
            ""
          }
          projects[[i]]$lastEdited <- as.character(Sys.time())
          break
        }
      }

      saveProjects(projects)
      projectChangeTrigger(projectChangeTrigger() + 1)

      shinyjs::runjs(
        "document.body.classList.remove('modal-open'); document.querySelectorAll('.modal-backdrop').forEach(el => el.remove());"
      )
    } else {
      showTablerAlert(
        "warning",
        "No name",
        "Project name cannot be empty.",
        5000
      )
    }
  })

  # Global Project Download Handler (Handles Single & Bulk)
  output$global_project_download_link <- downloadHandler(
    filename = function() {
      targets <- projectDownloadTarget()
      
      # Fallback to active editor project if no target is explicitly set
      if (is.null(targets)) targets <- activeProjectId()
      req(targets)
      
      if (length(targets) > 1) {
        # Bulk Download Zip Name
        return(paste0("bulk_projects_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".zip"))
      } else {
        # Single Download Zip Name
        pId <- targets[1]
        projectName <- "project"
        projects <- loadProjects()
        for (proj in projects) {
          if (proj$id == pId) {
            projectName <- proj$name
            break
          }
        }
        safeName <- gsub("[^A-Za-z0-9_-]", "_", projectName)
        return(paste0(safeName, "_source_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".zip"))
      }
    },
    content = function(file) {
      targets <- projectDownloadTarget()
      if (is.null(targets)) targets <- activeProjectId()
      req(targets)
      
      uid <- isolate(user_session$user_info$user_id)
      if (is.null(uid)) stop("User not logged in")
      
      pDir <- getUserProjectDir(uid)
      projects <- loadProjects()
      
      if (length(targets) == 1) {
        # --- SINGLE PROJECT DOWNLOAD ---
        projDir <- file.path(pDir, targets[1])
        if (dir.exists(projDir)) {
          files <- list.files(projDir, full.names = FALSE, recursive = TRUE, include.dirs = FALSE)
          files <- files[!basename(files) %in% c(".", "..", ".DS_Store", "__MACOSX")]
          files <- files[!grepl("^(chat_files|compiled_cache|history)", files)]
          
          valid_files <- files[file.exists(file.path(projDir, files))]
          
          if (length(valid_files) > 0) {
            zip::zip(file, files = valid_files, root = projDir, mode = "cherry-pick")
          } else {
            zip::zip(file, files = character(0))
          }
        }
      } else {
        # --- BULK PROJECT DOWNLOAD (STAGED FOR PROPER FOLDER SEPARATION) ---
        
        # 1. Create a temporary staging directory
        temp_zip_dir <- tempfile(pattern = "bulk_zip_")
        dir.create(temp_zip_dir)
        
        # Ensure the staging directory is deleted after the function finishes (even if it crashes)
        on.exit(unlink(temp_zip_dir, recursive = TRUE), add = TRUE)
        
        used_folder_names <- character(0)
        
        for (pId in targets) {
          projDir <- file.path(pDir, pId)
          if (dir.exists(projDir)) {
            
            # Find the actual project name
            pName <- "Unnamed_Project"
            for (p in projects) {
              if (p$id == pId) {
                pName <- p$name
                break
              }
            }
            
            # Sanitize the project name so it's a valid folder name
            safe_name <- gsub("[^A-Za-z0-9_ -]", "_", pName)
            safe_name <- trimws(safe_name)
            if (safe_name == "") safe_name <- "Project"
            
            # Handle duplicates (e.g., if the user has two projects named "Draft")
            base_name <- safe_name
            counter <- 1
            while (safe_name %in% used_folder_names) {
              safe_name <- paste0(base_name, "_", counter)
              counter <- counter + 1
            }
            used_folder_names <- c(used_folder_names, safe_name)
            
            # Create the project's specific sub-folder in the staging area
            temp_proj_dir <- file.path(temp_zip_dir, safe_name)
            dir.create(temp_proj_dir, recursive = TRUE, showWarnings = FALSE)
            
            # Find valid files to copy
            pfiles <- list.files(projDir, full.names = FALSE, recursive = TRUE, include.dirs = FALSE)
            pfiles <- pfiles[!basename(pfiles) %in% c(".", "..", ".DS_Store", "__MACOSX")]
            pfiles <- pfiles[!grepl("^(chat_files|compiled_cache|history)", pfiles)]
            valid_pfiles <- pfiles[file.exists(file.path(projDir, pfiles))]
            
            # Copy each file into the staging directory, preserving its internal structure
            for (f in valid_pfiles) {
              src <- file.path(projDir, f)
              dst <- file.path(temp_proj_dir, f)
              dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
              file.copy(src, dst)
            }
          }
        }
        
        # 2. Zip the staging directory
        files_to_zip <- list.files(temp_zip_dir, full.names = FALSE, recursive = TRUE, include.dirs = FALSE)
        if (length(files_to_zip) > 0) {
          # Because we set root = temp_zip_dir, the zip will correctly use the project folders as the top level
          zip::zip(zipfile = file, files = files_to_zip, root = temp_zip_dir)
        } else {
          zip::zip(zipfile = file, files = character(0))
        }
      }
    },
    contentType = "application/zip"
  )

  # KEEP THIS: Crucial for the hidden link to work
  outputOptions(
    output,
    "global_project_download_link",
    suspendWhenHidden = FALSE
  )

  # Trigger single download
  observeEvent(input$downloadProject, {
    req(input$downloadProject)
    
    # Store the target ID for the download handler
    projectDownloadTarget(input$downloadProject)
    
    projects <- loadProjects()
    projectName <- ""
    for (proj in projects) {
      if (proj$id == input$downloadProject) {
        projectName <- proj$name
        break
      }
    }
    
    showTablerAlert("info", "Download started", paste("Downloading", projectName, "project..."), 5000)
    shinyjs::runjs("document.getElementById('global_project_download_link').click();")
  })
  
  # Bulk action handler
  observeEvent(input$bulkActionTrigger, {
    req(input$bulkActionTrigger)
    
    selected_ids <- input$selectedProjects
    if (is.null(selected_ids) || length(selected_ids) < 2) {
      showTablerAlert("warning", "Selection error", "Please select at least two projects.", 5000)
      return()
    }
    
    action <- input$bulkActionTrigger
    count <- length(selected_ids)
    
    if (action == "trash") {
      success_count <- sum(sapply(selected_ids, function(pid) changeProjectStatus(pid, "trashed")))
      showTablerAlert("info", "Projects trashed", paste("Moved", success_count, "projects to trash successfully."), 5000)
    } else if (action == "archive") {
      success_count <- sum(sapply(selected_ids, function(pid) changeProjectStatus(pid, "archived")))
      showTablerAlert("info", "Projects archived", paste("Archived", success_count, "projects successfully."), 5000)
    } else if (action == "restore") {
      success_count <- sum(sapply(selected_ids, function(pid) changeProjectStatus(pid, "active")))
      showTablerAlert("success", "Bulk restore", paste("Restored", success_count, "projects successfully."), 5000)
    } else if (action == "tag") {
      taggingProjectId(selected_ids) 
      shinyjs::runjs("document.getElementById('createTagModal').style.display = 'flex';")
      updateTextInput(session, "newTagName", value = "")
    } else if (action == "download") {
      # Store the ARRAY of targets for the download handler
      projectDownloadTarget(selected_ids)
      showTablerAlert("info", "Downloading projects", paste("Preparing to download", count, "projects..."), 5000)
      shinyjs::runjs("document.getElementById('global_project_download_link').click();")
    }
    
    # Deselect all checkboxes upon successful action
    if (action %in% c("trash", "archive", "restore", "download")) {
      shinyjs::runjs("
            document.querySelectorAll('.project-select-cb').forEach(cb => cb.checked = false);
            if (typeof window.updateBulkActions === 'function') window.updateBulkActions();
        ")
    }
  })
  
  
  # Navigation between homepage and editor
  observeEvent(input$backToHomepage, {
    rv$editor_active <- FALSE
    rv$block_comment_update <- TRUE

    # Update project timestamp
    if (!is.null(activeProject())) {
      updateProjectTimestamp(activeProject())
    }

    # --- FIX: Clean up observers ---
    clear_file_observers()
    # -------------------------------

    # Clear active project persistence
    uid <- isolate(user_session$user_info$user_id)
    if (!is.null(uid)) {
      cacheDir <- getUserAppCacheDir(uid)
      if (!is.null(cacheDir)) {
        apFile <- file.path(cacheDir, "activeProject.txt")
        if (file.exists(apFile)) {
          file.remove(apFile)
        }
      }
    }

    shinyjs::runjs(
      "var l = document.getElementById('dashboardLoader'); if(l) l.classList.remove('show');"
    )

    showHomepage(TRUE)
    activeProject(NULL)
    activeProjectId(NULL)
    rv_files(character(0)) # Clear file list
    session$sendCustomMessage("updateProjectURL", NULL)
  })

  # Make project statistics reactive to changes
  output$projectCount <- renderText({
    change_trigger <- projectChangeTrigger()
    projects <- loadProjects()
    if (length(projects) == 0) {
      return("0")
    }
    as.character(length(projects))
  })
  
  # --- DASHBOARD COUNTERS ---
  output$countActive <- renderText({
    change_trigger <- projectChangeTrigger()
    projects <- loadProjects()
    if (length(projects) == 0) return("0")
    as.character(sum(sapply(projects, function(p) (p$status %||% "active") == "active")))
  })
  
  output$countArchived <- renderText({
    change_trigger <- projectChangeTrigger()
    projects <- loadProjects()
    if (length(projects) == 0) return("0")
    as.character(sum(sapply(projects, function(p) (p$status %||% "active") == "archived")))
  })
  
  output$countTrashed <- renderText({
    change_trigger <- projectChangeTrigger()
    projects <- loadProjects()
    if (length(projects) == 0) return("0")
    as.character(sum(sapply(projects, function(p) (p$status %||% "active") == "trashed")))
  })
  
  # --- Dynamic Dashboard Title ---
  output$dashboardTitle <- renderText({
    currentView <- projectDashboardState() %||% "active"
    switch(currentView,
           "active" = "Your projects",
           "archived" = "Archived projects",
           "trashed" = "Trashed projects",
           "Your projects" # fallback
    )
  })
  
  # Force them to update even if the menu is hidden or momentarily out of view
  outputOptions(output, "dashboardTitle", suspendWhenHidden = FALSE)
  outputOptions(output, "countActive", suspendWhenHidden = FALSE)
  outputOptions(output, "countArchived", suspendWhenHidden = FALSE)
  outputOptions(output, "countTrashed", suspendWhenHidden = FALSE) 
  

  output$totalFiles <- renderText({
    change_trigger <- projectChangeTrigger()
    projects <- loadProjects()
    if (length(projects) == 0) {
      return("0")
    }

    total <- 0
    for (proj in projects) {
      if (!is.null(proj$fileCount)) {
        count <- tryCatch(
          {
            as.integer(proj$fileCount)
          },
          error = function(e) 0
        )
        total <- total + count
      }
    }
    as.character(total)
  })

  output$pctActive <- renderText({
    change_trigger <- projectChangeTrigger()
    projects <- loadProjects()
    if (length(projects) == 0) return("0%")
    active <- sum(sapply(projects, function(p) (p$status %||% "active") == "active"))
    total <- length(projects)
    sprintf("%.0f%%", (active / total) * 100)
  })

  output$activeProjectBar <- renderUI({
    change_trigger <- projectChangeTrigger()
    projects <- loadProjects()
    total <- length(projects)
    active <- if(total == 0) 0 else sum(sapply(projects, function(p) (p$status %||% "active") == "active"))
    pct <- if(total == 0) 0 else (active/total)*100
    
    tags$div(
      class = "progress",
      style = "height: 10px; border-radius: 50rem;",
      tags$div(
        class = "progress-bar bg-primary",
        style = sprintf("width: %d%%; border-radius: 50rem;", as.integer(pct)),
        role = "progressbar",
        aria_valuenow = as.integer(pct),
        aria_valuemin = "0",
        aria_valuemax = "100"
      )
    )
  })

  output$tagDistributionBar <- renderUI({
    change_trigger <- projectChangeTrigger()
    projects <- loadProjects()
    
    all_tags <- list()
    for (p in projects) {
      if (!is.null(p$tags)) {
        for (t in p$tags) {
          all_tags <- c(all_tags, list(t))
        }
      }
    }
    
    if (length(all_tags) == 0) {
      return(tags$div(class = "text-muted small", "No tags assigned yet."))
    }
    
    tag_counts <- table(sapply(all_tags, function(t) t$name))
    tag_colors <- list()
    for (t in all_tags) {
      tag_colors[[t$name]] <- t$color
    }
    
    tag_names <- names(tag_counts)
    # Sort by frequency
    tag_names <- tag_names[order(tag_counts, decreasing = TRUE)]
    total_tags <- length(all_tags)
    
    bars <- lapply(tag_names, function(name) {
      pct <- (tag_counts[[name]] / total_tags) * 100
      color <- tag_colors[[name]] %||% "blue"
      tags$div(
        class = sprintf("progress-bar bg-%s", color),
        style = sprintf("width: %f%%", pct)
      )
    })
    
    tags$div(
      class = "progress progress-stacked", 
      style = "height: 10px; border-radius: 50rem;",
      bars
    )
  })

  output$tagDistributionLegend <- renderUI({
    change_trigger <- projectChangeTrigger()
    projects <- loadProjects()
    
    all_tags <- list()
    for (p in projects) {
        if (!is.null(p$tags)) {
            for (t in p$tags) all_tags <- c(all_tags, list(t))
        }
    }
    if (length(all_tags) == 0) return(NULL)
    
    tag_counts <- table(sapply(all_tags, function(t) t$name))
    tag_colors <- list()
    for (t in all_tags) tag_colors[[t$name]] <- t$color
    tag_names <- names(tag_counts)
    tag_names <- tag_names[order(tag_counts, decreasing = TRUE)]
    total_tags <- length(all_tags)
    
    legend_items <- lapply(tag_names, function(name) {
      color <- tag_colors[[name]] %||% "blue"
      pct <- (tag_counts[[name]] / total_tags) * 100
      tags$div(
        class = "d-flex align-items-center me-3 mb-1",
        tags$span(class = sprintf("status-dot bg-%s me-2", color)),
        tags$span(class = "text-muted small", sprintf("%s (%.0f%%)", name, pct))
      )
    })
    
    tags$div(class = "d-flex flex-wrap mt-2", legend_items)
  })

  output$lastActivity <- renderText({
    change_trigger <- projectChangeTrigger()
    projects <- loadProjects()
    if (length(projects) == 0) {
      return("Never")
    }

    latest <- ""
    for (proj in projects) {
      if (!is.null(proj$lastEdited) && is.character(proj$lastEdited)) {
        if (proj$lastEdited > latest || latest == "") {
          latest <- proj$lastEdited
        }
      }
    }

    if (latest == "") {
      return("Never")
    }

    if (nchar(latest) >= 10) {
      return(as.character(format(Sys.time(), "%B %d, %Y at %H:%M:%S")))
    }

    "Recent"
  })

  # Sort button observers
  observeEvent(input$sortLastEdited, {
    projectSort("lastEdited")
  })

  observeEvent(input$sortName, {
    projectSort("name")
  })

  observeEvent(input$sortCreated, {
    projectSort("created")
  })

  observeEvent(input$sortFileCount, {
    projectSort("fileCount")
  })

  # Update button active states based on current sort
  observeEvent(projectSort(), {
    current_sort <- projectSort()

    # Remove active class from all sort buttons first
    shinyjs::runjs(
      "
    document.querySelectorAll('.btn-sort').forEach(btn => {
      btn.classList.remove('active');
    });
  "
    )

    # Add some delay to ensure DOM is updated, then add active class
    shinyjs::delay(100, {
      button_selector <- switch(
        current_sort,
        "lastEdited" = "#sortLastEdited",
        "name" = "#sortName",
        "created" = "#sortCreated",
        "fileCount" = "#sortFileCount"
      )

      if (!is.null(button_selector)) {
        shinyjs::runjs(sprintf(
          "
        var btn = document.querySelector('%s');
        if (btn) {
          btn.classList.add('active');
        }
      ",
          button_selector
        ))
      }
    })
  })

  # In your dynamic file observers section, modify the kebab menu handlers:
  # Dynamic file observers - only create once per file
  observeEvent(
    rv_files(),
    {
      items <- rv_files()
      projId <- activeProjectId()

      # Get list of files we've already created observers for
      existing <- createdObservers()

      # Find new files that need observers
      newFiles <- setdiff(items, existing)

      if (length(newFiles) > 0) {
        # Use lapply instead of a for loop.
        # This forces 'item' to be captured correctly for each specific file.
        new_handles_nested <- lapply(newFiles, function(item) {
          # List to collect observers for THIS specific file
          file_specific_observers <- list()

          safeId <- paste0(projId, "_", gsub("[^A-Za-z0-9]", "_", item))
          projDir <- getActiveProjectDir()

          if (!is.null(projDir)) {
            fullPath <- file.path(projDir, item)

            if (file.exists(fullPath)) {
              isDir <- file.info(fullPath)$isdir

              # ============ DOWNLOAD OBSERVER ============
              obs_dl <- observeEvent(
                input[[paste0("download_", safeId)]],
                {
                  if (isDir) {
                    # Folder Download Logic
                    zipName <- paste0(
                      safeId,
                      "_",
                      format(Sys.time(), "%Y%m%d_%H%M%S"),
                      ".zip"
                    )
                    zipPath <- file.path(projDir, zipName)

                    tryCatch(
                      {
                        files_in_folder <- list.files(
                          fullPath,
                          full.names = TRUE,
                          recursive = TRUE
                        )
                        if (length(files_in_folder) > 0) {
                          zip::zip(
                            zipPath,
                            files = files_in_folder,
                            root = fullPath,
                            mode = "cherry-pick"
                          )

                          uid <- isolate(user_session$user_info$user_id)
                          pid <- activeProjectId()
                          dlUrl <- file.path(
                            "project",
                            uid,
                            "projects",
                            pid,
                            zipName
                          )

                          shinyjs::runjs(sprintf(
                            "
                        var link = document.createElement('a');
                        link.href = '%s';
                        link.download = '%s';
                        document.body.appendChild(link);
                        link.click();
                        document.body.removeChild(link);
                      ",
                            dlUrl,
                            zipName
                          ))

                          showTablerAlert(
                            "success",
                            "Downloading folder",
                            "Folder download started",
                            5000
                          )

                          later::later(
                            function() {
                              if (file.exists(zipPath)) file.remove(zipPath)
                            },
                            5
                          )
                        }
                      },
                      error = function(e) {
                        showTablerAlert(
                          "danger",
                          "Error downloading folder",
                          paste("Download failed:", e$message),
                          5000
                        )
                      }
                    )
                  } else {
                    # Single File Download Logic
                    uid <- isolate(user_session$user_info$user_id)
                    pid <- activeProjectId()
                    dlUrl <- file.path("project", uid, "projects", pid, item)

                    # 'item' is now correctly frozen by lapply
                    shinyjs::runjs(sprintf(
                      "
                    var link = document.createElement('a');
                    link.href = '%s';
                    link.download = '%s';
                    document.body.appendChild(link);
                    link.click();
                    document.body.removeChild(link);
                  ",
                      dlUrl,
                      basename(item)
                    ))

                    showTablerAlert(
                      "success",
                      "Download started",
                      paste("Downloading", basename(item)),
                      5000
                    )
                  }
                },
                ignoreInit = TRUE,
                once = FALSE
              )

              file_specific_observers[[
                length(file_specific_observers) + 1
              ]] <- obs_dl

              # ============ RENAME TRIGGER OBSERVER ============
              obs_rn <- observeEvent(
                input[[paste0("rename_", safeId)]],
                {
                  session$sendCustomMessage(
                    "enableInlineRename",
                    list(path = item)
                  )
                },
                ignoreInit = TRUE,
                once = FALSE
              )

              file_specific_observers[[
                length(file_specific_observers) + 1
              ]] <- obs_rn

              # ============ CONFIRM RENAME OBSERVER ============
              obs_rn_confirm <- observeEvent(
                input[[paste0("confirmRename_", safeId)]],
                {
                  req(input[[paste0("confirmRename_", safeId)]]$newName)
                  newName <- trimws(
                    input[[paste0("confirmRename_", safeId)]]$newName
                  )

                  if (newName == "" || newName == basename(item)) {
                    return()
                  }

                  dirPart <- dirname(item)
                  newPath <- if (dirPart == ".") {
                    file.path(projDir, newName)
                  } else {
                    file.path(projDir, dirPart, newName)
                  }

                  if (file.exists(newPath)) {
                    showTablerAlert(
                      "warning",
                      "Name already exists",
                      "A file or folder with that name already exists in this project.",
                      5000
                    )
                  } else {
                    success <- file.rename(fullPath, newPath)
                    if (success) {
                      rv_files(getVisibleFiles(projDir))

                      if (!is.null(activeProjectId())) {
                        updateProjectFileCount(activeProjectId())
                      }

                      showTablerAlert(
                        "success",
                        "File renamed",
                        paste("File successfully renamed to", newName),
                        5000
                      )
                    } else {
                      showTablerAlert(
                        "danger",
                        "Error renaming file",
                        "Failed to rename file.",
                        5000
                      )
                    }
                  }
                },
                ignoreInit = TRUE,
                once = FALSE
              )

              file_specific_observers[[
                length(file_specific_observers) + 1
              ]] <- obs_rn_confirm

              # ============ DELETE TRIGGER OBSERVER ============
              obs_del <- observeEvent(
                input[[paste0("delete_", safeId)]],
                {
                  modalId <- paste0("deleteModal_", safeId)
                  itemType <- if (isDir) "folder" else "file"

                  modalHTML <- sprintf(
                    '
                <div class="modal modal-blur" id="%s" tabindex="-1" style="display: block;" aria-hidden="true" role="dialog">
                  <div class="modal-dialog modal-sm" role="document">
                    <div class="modal-content">
                      <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"
                        onclick="document.getElementById(\'%s\').remove(); document.body.classList.remove(\'modal-open\'); var backdrop = document.querySelector(\'.modal-backdrop\'); if(backdrop) backdrop.remove();"></button>
                      <div class="modal-status bg-danger"></div>
                      <div class="modal-body text-center py-4">
                        <svg xmlns="http://www.w3.org/2000/svg" class="icon mb-2 text-danger icon-lg" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
                          <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                          <path d="M12 9v2m0 4v.01"/>
                          <path d="M5 19h14a2 2 0 0 0 1.84 -2.75l-7.1 -12.25a2 2 0 0 0 -3.5 0l-7.1 12.25a2 2 0 0 0 1.75 2.75"/>
                        </svg>
                        <h3>Are you sure?</h3>
                        <div class="text-secondary">Do you really want to delete this %s <strong>%s</strong>? This cannot be undone.</div>
                      </div>
                      <div class="modal-footer">
                        <div class="w-100">
                          <div class="row">
                            <div class="col">
                              <button type="button" class="btn w-100" data-bs-dismiss="modal"
                                onclick="document.getElementById(\'%s\').remove(); document.body.classList.remove(\'modal-open\'); var backdrop = document.querySelector(\'.modal-backdrop\'); if(backdrop) backdrop.remove();">
                                Cancel
                              </button>
                            </div>
                            <div class="col">
                              <button type="button" class="btn btn-danger w-100"
                                onclick="
                                  Shiny.setInputValue(\'confirmDelete_%s\', Math.random(), {priority: \'event\'});
                                  document.getElementById(\'%s\').remove(); 
                                  document.body.classList.remove(\'modal-open\'); 
                                  var backdrop = document.querySelector(\'.modal-backdrop\'); 
                                  if(backdrop) backdrop.remove();
                                ">
                                Delete %s
                              </button>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                ',
                    modalId,
                    modalId,
                    itemType,
                    basename(item),
                    modalId,
                    safeId,
                    modalId,
                    itemType
                  )

                  shinyjs::runjs(sprintf(
                    "
                  var existing = document.getElementById('%s');
                  if (existing) existing.remove();
                  var backdrop = document.querySelector('.modal-backdrop');
                  if (backdrop) backdrop.remove();
                  document.body.insertAdjacentHTML('beforeend', %s);
                  document.body.classList.add('modal-open');
                ",
                    modalId,
                    jsonlite::toJSON(modalHTML, auto_unbox = TRUE)
                  ))
                },
                ignoreInit = TRUE,
                once = FALSE
              )

              file_specific_observers[[
                length(file_specific_observers) + 1
              ]] <- obs_del

              # ============ CONFIRM DELETE OBSERVER ============
              obs_del_confirm <- observeEvent(
                input[[paste0("confirmDelete_", safeId)]],
                {
                  if (file.exists(fullPath)) {
                    if (isDir) {
                      unlink(fullPath, recursive = TRUE)
                    } else {
                      file.remove(fullPath)
                    }

                    rv_files(getVisibleFiles(projDir))

                    if (!is.null(activeProjectId())) {
                      updateProjectFileCount(activeProjectId())
                    }

                    # Record activity
                    recordDailyActivity(activityType = "fileDelete", details = list(
                      projectId = activeProjectId(),
                      projectName = activeProject()$name,
                      file = basename(item)
                    ))

                    showTablerAlert(
                      "success",
                      "File deleted",
                      paste(basename(item), "has been deleted successfully."),
                      5000
                    )
                  }
                },
                ignoreInit = TRUE,
                once = FALSE
              )

              file_specific_observers[[
                length(file_specific_observers) + 1
              ]] <- obs_del_confirm
            } # end if file exists
          } # end if projDir not null

          return(file_specific_observers)
        })

        # Flatten the list of lists returned by lapply
        new_handles_list <- unlist(new_handles_nested, recursive = FALSE)

        # Clean any NULLs (files that didn't exist)
        new_handles_list <- new_handles_list[!sapply(new_handles_list, is.null)]

        # Add the new observers to our reactive list of handles
        current_handles <- file_observer_handles()
        file_observer_handles(c(current_handles, new_handles_list))

        # Update the list of created observers (names)
        createdObservers(c(existing, newFiles))
      }
    },
    ignoreInit = TRUE
  )

  # Clear observer tracking when project changes
  observeEvent(
    activeProjectId(),
    {
      createdObservers(character(0))
    },
    priority = 1000
  ) # High priority to run first

