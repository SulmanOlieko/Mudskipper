  # ----------------------------- CHAT HELPERS -----------------------------
  
  # PERFORMANCE CACHE: Avoid reading last snapshot from disk every save (1s)
  lastSavedHistoryCache <- list()

  # Securely load chat data for a project
  loadProjectChat <- function(projId) {
    req(projId)

    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return(list(meta = list(), participants = list(), messages = list()))
    }

    pDir <- getUserProjectDir(uid)
    if (is.null(pDir)) {
      return(list(meta = list(), participants = list(), messages = list()))
    }

    chatFile <- file.path(pDir, projId, ".chat_files", ".chat.json")

    if (!file.exists(chatFile)) {
      return(list(
        meta = list(created = as.character(Sys.time())),
        participants = list(),
        messages = list()
      ))
    }
    tryCatch(
      {
        jsonlite::fromJSON(chatFile, simplifyVector = FALSE)
      },
      error = function(e) {
        list(meta = list(), participants = list(), messages = list())
      }
    )
  }

  # Save chat data with basic file locking to prevent overwrite conflicts
  saveProjectChat <- function(projId, chatData) {
    req(projId)

    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return(FALSE)
    }
    pDir <- getUserProjectDir(uid)
    if (is.null(pDir)) {
      return(FALSE)
    }

    chatFile <- file.path(pDir, projId, ".chat_files", ".chat.json")

    # Ensure directory exists
    if (!dir.exists(dirname(chatFile))) {
      dir.create(dirname(chatFile), recursive = TRUE)
    }

    lockFile <- paste0(chatFile, ".lock")
    i <- 0
    while (file.exists(lockFile) && i < 10) {
      Sys.sleep(0.1)
      i <- i + 1
    }
    file.create(lockFile)
    on.exit(unlink(lockFile))
    tryCatch(
      {
        jsonlite::write_json(
          chatData,
          chatFile,
          auto_unbox = TRUE,
          pretty = TRUE
        )
        return(TRUE)
      },
      error = function(e) return(FALSE)
    )
  }

  # Save uploaded chat files to a project-specific directory
  saveChatAttachments <- function(projId, files) {
    req(files)

    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return(list())
    }
    pDir <- getUserProjectDir(uid)

    # Create directory: projects/{projId}/chat_files
    uploadDir <- file.path(pDir, projId, ".chat_files")
    if (!dir.exists(uploadDir)) {
      dir.create(uploadDir, recursive = TRUE)
    }

    savedPaths <- list()

    for (i in seq_len(nrow(files))) {
      # Generate unique name to prevent overwrites
      ext <- tools::file_ext(files$name[i])
      newFileName <- paste0(format(Sys.time(), "%Y%m%d%H%M%S_"), i, ".", ext)
      destPath <- file.path(uploadDir, newFileName)

      file.copy(files$datapath[i], destPath)

      # Store relative path for portability
      savedPaths[[i]] <- list(
        name = files$name[i],
        path = file.path(".chat_files", newFileName), # Relative to project root
        type = files$type[i],
        size = files$size[i]
      )
    }
    return(savedPaths)
  }

  # ==============================================================================
  #                               CHAT SERVER LOGIC
  # ==============================================================================

  # 1. Reactive State -----------------------------------------------------------
  chatPaneVisible <- reactiveVal(FALSE)
  lastChatReadTime <- reactiveVal(as.numeric(Sys.time()))

  # Holds temporary state for file uploads and editing
  chatState <- reactiveValues(
    pendingAttachments = NULL, # Dataframe of files waiting to be sent
    editingMsgId = NULL # ID of the message currently being edited (NULL = normal mode)
  )

  # 2. Toggle Chat Pane Visibility ----------------------------------------------
  observeEvent(input$toggleChatPane, {
    val <- input$toggleChatPane
    newState <- if (is.logical(val)) val else !chatPaneVisible()
    chatPaneVisible(newState)

    if (newState) {
      lastChatReadTime(as.numeric(Sys.time()))
    } else {}
  })

  # 3. Data Polling (Real-time updates) -----------------------------------------
  chatDataReactive <- reactive({
    projId <- activeProjectId()
    if (is.null(projId)) {
      return(NULL)
    }

    # Poll file every 3 seconds
    invalidateLater(3000, session)

    loadProjectChat(projId)
  })

  # 4. Attachment Handling ------------------------------------------------------
  # A. Capture Uploads
  observeEvent(input$chatFileUpload, {
    files <- input$chatFileUpload
    req(files)

    # Validation: Max 3 files, Max 5MB each
    if (nrow(files) > 3) {
      showTablerAlert("error", "Too many attachments", "Maximum 3 files allowed per message.", 5000)
      return()
    }
    if (any(files$size > 5 * 1024 * 1024)) {
      showTablerAlert("error", "Too big attachments", "All files must be under 5MB.", 5000)
      return()
    }

    chatState$pendingAttachments <- files
  })

  # B. Remove a pending attachment
  observeEvent(input$removeAttachment, {
    idx <- input$removeAttachment
    files <- chatState$pendingAttachments
    if (!is.null(files) && idx <= nrow(files)) {
      chatState$pendingAttachments <- files[-idx, , drop = FALSE]
      if (nrow(chatState$pendingAttachments) == 0) {
        chatState$pendingAttachments <- NULL
      }
    }
  })

  # C. Render Preview Area (Above input box)
  output$chatAttachmentPreview <- renderUI({
    files <- chatState$pendingAttachments
    # Extra safety: Ensure it is actually a dataframe with rows
    if (is.null(files) || !is.data.frame(files) || nrow(files) == 0) {
      return(NULL)
    }

    div(
      class = "d-flex gap-2 mb-2 flex-wrap",
      lapply(1:nrow(files), function(i) {
        tags$span(
          class = "badge bg-blue-lt",
          files$name[i],
          tags$span(
            class = "ms-2 cursor-pointer",
            style = "cursor:pointer;",
            "×",
            onclick = sprintf(
              "Shiny.setInputValue('removeAttachment', %d, {priority:'event'})",
              i
            )
          )
        )
      })
    )
  })

  # 5. Message Actions (Edit / Delete) ------------------------------------------
  observeEvent(input$msgAction, {
    action <- input$msgAction$action
    msgId <- input$msgAction$id
    projId <- activeProjectId()
    user <- loadUserProfile()

    data <- loadProjectChat(projId)

    # Find message index
    idx <- which(sapply(data$messages, function(x) x$id == msgId))
    if (length(idx) == 0) {
      return()
    }

    msg <- data$messages[[idx]]

    # Security: Only owner can modify
    if (msg$senderId != user$userId) {
      showTablerAlert("warning", "Cannot edit", "You cannot modify this message.", 5000)
      return()
    }

    if (action == "delete") {
      # --- DELETE LOGIC ---
      data$messages[[idx]]$isDeleted <- TRUE
      data$messages[[idx]]$content <- "This message was deleted."
      data$messages[[idx]]$attachments <- list() # Clear files
      saveProjectChat(projId, data)
    } else if (action == "edit") {
      # --- EDIT SETUP ---
      chatState$editingMsgId <- msgId

      # Populate input with existing text
      updateTextAreaInput(
        session,
        "chatInputMsg",
        value = msg$content,
        placeholder = "Editing... (Press Enter to update)"
      )

      # Focus input
      shinyjs::runjs("document.getElementById('chatInputMsg').focus();")
    }
  })

  # 6. Sending Messages (New & Edit Commit) -------------------------------------
  # Listens to both the UI button and the JS 'Enter' key trigger
  observeEvent(
    {
      input$btnSendChat
      input$triggerSendChat
    },
    {
      txt <- input$chatInputMsg
      files <- chatState$pendingAttachments
      projId <- activeProjectId()
      user <- loadUserProfile()

      # Basic Validation
      hasText <- !is.null(txt) && nzchar(trimws(txt))
      hasFiles <- !is.null(files) && is.data.frame(files) && nrow(files) > 0

      # Allow empty text ONLY if we have files (for new messages)
      if (!hasText && !hasFiles) {
        return()
      }

      data <- loadProjectChat(projId)

      # --- BRANCH A: EDIT EXISTING MESSAGE ---
      if (!is.null(chatState$editingMsgId)) {
        idx <- which(sapply(data$messages, function(x) {
          x$id == chatState$editingMsgId
        }))

        if (length(idx) > 0) {
          if (!hasText) {
            # If user clears text during edit, treat as cancel or warn?
            # Here we assume text is required for edit.
            showTablerAlert("warning", "Empty message", "Message cannot be empty.", 5000)
            return()
          }

          data$messages[[idx]]$content <- trimws(txt)
          data$messages[[idx]]$isEdited <- TRUE
          saveProjectChat(projId, data)
        }

        # Reset Edit Mode
        chatState$editingMsgId <- NULL
        updateTextAreaInput(
          session,
          "chatInputMsg",
          value = "",
          placeholder = "Type a message..."
        )
      } else {
        # --- BRANCH B: SEND NEW MESSAGE ---

        # 1. Process Attachments
        savedFiles <- list()
        if (hasFiles) {
          savedFiles <- saveChatAttachments(projId, files)
        }

        # 2. Construct Message
        newMsg <- list(
          id = paste0("msg_", as.numeric(Sys.time())),
          senderId = user$userId,
          senderName = user$username,
          senderAvatar = user$profilePicture,
          content = if (hasText) trimws(txt) else "",
          attachments = savedFiles,
          timestamp = as.character(Sys.time()),
          status = "delivered",
          readBy = list(user$userId),
          isEdited = FALSE,
          isDeleted = FALSE
        )

        data$messages <- c(data$messages, list(newMsg))
        saveProjectChat(projId, data)

        # 3. Cleanup
        updateTextAreaInput(session, "chatInputMsg", value = "")
        chatState$pendingAttachments <- NULL
        shinyjs::reset("chatFileUpload") # Clear file input

        # 4. Analytics
        recordDailyActivity("chat", list(projectId = projId))
      }
    },
    ignoreInit = TRUE
  )

  # 7. Typing Indicators --------------------------------------------------------
  observeEvent(input$userTyping, {
    req(activeProjectId())
    user <- loadUserProfile()

    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return()
    }
    pDir <- getUserProjectDir(uid)
    if (is.null(pDir)) {
      return()
    }

    # Define path
    typingFile <- file.path(pDir, activeProjectId(), ".chat_files", "typing.txt")

    # FIX: Ensure directory exists before writing
    dir.create(dirname(typingFile), recursive = TRUE, showWarnings = FALSE)

    # Write lock file
    writeLines(
      paste(user$userId, as.numeric(Sys.time()), sep = "|"),
      typingFile
    )
  })

  # 8. Render Message Stream (Fixed Links & Navigation)
  # ----------------------------- CHAT COLOR LOGIC -----------------------------
  # Default to Blue Light
  chatColor <- reactiveVal("teal-lt")

  observeEvent(input$setChatColor, {
    chatColor(input$setChatColor)
  })

  # -------------------------- UPDATED MESSAGE STREAM --------------------------
  output$chatMessageStream <- renderUI({
    data <- chatDataReactive()

    if (is.null(data) || length(data$messages) == 0) {
      return(div(
        class = "text-center text-muted mt-5",
        div(
          class = "empty",
          ui_empty_illustration(),
          HTML(
            '
                     <p class="empty-title">NO MESSAGES FOUND</p>
                     <p class="empty-subtitle text-secondary">Start the conversation!</p>
              '
          )
        )
      ))
    }

    currentUser <- loadUserProfile()
    searchQuery <- tolower(trimws(input$chatSearch %||% ""))
    projId <- activeProjectId()

    # Get current selected color
    myColorClass <- paste0("bg-", chatColor())

    msgs_html <- lapply(data$messages, function(msg) {
      # Search Filter
      if (
        nzchar(searchQuery) &&
          !grepl(searchQuery, tolower(msg$content), fixed = TRUE)
      ) {
        return(NULL)
      }

      isMe <- (msg$senderId == currentUser$userId)

      # 1. Handle Deleted
      if (isTRUE(msg$isDeleted)) {
        rowClass <- if (isMe) "flex-row-reverse" else "flex-row"
        return(div(
          class = paste("d-flex mb-3", rowClass),
          div(
            class = "chat-avatar mx-2",
            tags$span(
              class = "avatar rounded-circle",
              style = paste0("background-image: url(", msg$senderAvatar, ")")
            )
          ),
          div(
            class = "p-2 rounded bg-secondary-lt text-muted fst-italic",
            "Message deleted"
          )
        ))
      }

      # 2. Attachments
      attHtml <- ""
      if (!is.null(msg$attachments) && length(msg$attachments) > 0) {
        attList <- lapply(msg$attachments, function(f) {
          isImg <- grepl("image", f$type)
          fPath <- file.path("storage", projId, f$path)
          if (isImg) {
            sprintf(
              '<a href="javascript:void(0);" onclick="window.open(\'%s\'); return false;" class="d-block mt-2"><img src="%s" class="rounded border shadow-sm" style="max-height: 150px; max-width: 100%%;"></a>',
              fPath,
              fPath
            )
          } else {
            sprintf(
              '<a href="%s" target="_blank" class="d-flex align-items-center text-decoration-underline"><span class="text-truncate" style="max-width:150px;">%s</span> 
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="icon icon-1"
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <path d="M19 18a3.5 3.5 0 0 0 0 -7h-1a5 4.5 0 0 0 -11 -2a4.6 4.4 0 0 0 -2.1 8.4" />
              <path d="M12 13l0 9" />
              <path d="M9 19l3 3l3 -3" />
            </svg></a>',
              fPath,
              f$name
            )
          }
        })
        attHtml <- paste(unlist(attList), collapse = "")
      }

      # 3. Message Styling
      rowClass <- if (isMe) "flex-row-reverse" else "flex-row"

      bubbleClass <- if (isMe) {
        paste(myColorClass, "border text-muted border-transparent")
      } else {
        "border text-muted border-transparent"
      }

      # Standard Chat Radius: Square off the corner near the avatar
      radiusStyle <- if (isMe) {
        "border-radius: 12px 0 12px 12px;"
      } else {
        "border-radius: 0 12px 12px 12px;"
      }

      # 4. Kebab Menu
      actionMenu <- ""
      if (isMe) {
        # FIXED: href="javascript:void(0);" to prevent navigation
        actionMenu <- sprintf(
          '
          <div class="dropdown" style="position: absolute; top: 0; %s: -20px; opacity: 0; transition: opacity 0.2s;">
            <a href="javascript:void(0);" class="text-muted" data-bs-toggle="dropdown"><i class="fa-solid fa-ellipsis-vertical"></i></a>
            <div class="dropdown-menu dropdown-menu-end">
              <a class="dropdown-item" href="javascript:void(0);" onclick="Shiny.setInputValue(\'msgAction\', {action:\'edit\', id:\'%s\'}, {priority:\'event\'})">Edit</a>
              <a class="dropdown-item text-danger" href="javascript:void(0);" onclick="Shiny.setInputValue(\'msgAction\', {action:\'delete\', id:\'%s\'}, {priority:\'event\'})">Delete</a>
            </div>
          </div>
        ',
          if (isMe) "left" else "right",
          msg$id,
          msg$id
        )
      }

      # 5. Metadata (Name + Time + Status)
      ts <- tryCatch(
        format(as.POSIXct(msg$timestamp), "%H:%M"),
        error = function(e) ""
      )
      editedTag <- if (isTRUE(msg$isEdited)) {
        '<span class="ms-1 fst-italic text-muted" style="font-size: 0.75em;">(edited)</span>'
      } else {
        ""
      }

      statusIcon <- ""
      if (isMe) {
        color <- if (msg$status == "read") "text-blue" else "text-muted"
        icon <- if (msg$status == "read") "fa-check-double" else "fa-check"
        statusIcon <- sprintf(
          '<i class="fa-solid %s %s ms-1" style="font-size: 10px;"></i>',
          icon,
          color
        )
      }

      metaHeader <- if (isMe) {
        sprintf(
          '<div class="d-flex align-items-center mb-1 small text-muted" style="gap:6px; flex-direction: row-reverse;"><span>%s</span></div>',
          msg$senderName
        )
      } else {
        sprintf(
          '<div class="d-flex align-items-center mb-1 small text-muted" style="gap:6px;"><span>%s</span></div>',
          msg$senderName
        )
      }

      # 6. Assemble
      div(
        class = paste("d-flex mb-3 message-group", rowClass),
        div(
          class = "chat-avatar mx-2",
          tags$span(
            class = "avatar rounded-circle",
            style = paste0("background-image: url(", msg$senderAvatar, ")")
          )
        ),
        div(
          style = "max-width: 80%; position: relative;",
          HTML(metaHeader),
          HTML(actionMenu),
          div(
            class = paste("p-2", bubbleClass),
            style = radiusStyle,
            div(
              style = "word-wrap: break-word; font-size: 0.95rem; line-height: 1.4;",
              msg$content
            ),
            HTML(attHtml),
            div(
              class = "d-flex justify-content-end align-items-center mt-1",
              style = "font-size: 0.7rem; opacity: 0.7;",
              HTML(editedTag),
              span(class = "ms-1", ts),
              HTML(statusIcon)
            )
          )
        )
      )
    })

    tagList(msgs_html)
  })

  # 9. Read Receipts (Fixed: Safety against NA values)
  observe({
    # Use isTRUE to safely handle cases where chatPaneVisible might be unstable
    req(isTRUE(chatPaneVisible()))

    data <- chatDataReactive()
    currentUser <- loadUserProfile()
    projId <- activeProjectId()

    # Safety checks: ensure data and user exist
    if (is.null(data) || length(data$messages) == 0) {
      return()
    }
    if (
      is.null(currentUser) ||
        is.null(currentUser$userId) ||
        is.na(currentUser$userId)
    ) {
      return()
    }

    modified <- FALSE

    data$messages <- lapply(data$messages, function(msg) {
      # Safety: If message data is corrupt/missing senderId, skip logic
      if (is.null(msg$senderId) || is.na(msg$senderId)) {
        return(msg)
      }

      # 1. Am I the sender? (Safe comparison)
      isSender <- identical(
        as.character(msg$senderId),
        as.character(currentUser$userId)
      )

      # 2. Have I read it? (Safe check)
      hasRead <- isTRUE(currentUser$userId %in% msg$readBy)

      # Only mark read if I am NOT the sender and I have NOT read it yet
      if (!isSender && !hasRead) {
        msg$readBy <- c(msg$readBy, currentUser$userId)
        msg$status <- "read"
        modified <<- TRUE
      }
      msg
    })

    if (modified) {
      saveProjectChat(projId, data)
    }
  })

  # =================== HISTORY HELPERS (FINAL & FIXED) ===================
  library(digest) # Ensure this is loaded
  historyUpdateCounter <- reactiveVal(0)

  # 1. Get History Directory for a specific file
  getHistoryDir <- function(projId, filePath) {
    if (is.null(projId) || is.null(filePath)) {
      return(NULL)
    }

    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return(NULL)
    }
    pDir <- getUserProjectDir(uid)
    if (is.null(pDir)) {
      return(NULL)
    }

    # Create a unique folder name: "filename_HASH"
    safeName <- gsub("[^a-zA-Z0-9]", "_", basename(filePath))
    pathHash <- digest::digest(filePath, algo = "crc32")
    folderName <- paste0(safeName, "_", pathHash)

    histDir <- file.path(pDir, projId, ".history", folderName)
    if (!dir.exists(histDir)) {
      dir.create(histDir, recursive = TRUE)
    }
    return(histDir)
  }

  # 2. Save a Snapshot (Calculates Tags: Add/Edit/Delete)
  saveHistorySnapshot <- function(projId, filePath, content) {
    # Skip empty content
    if (is.null(content) || trimws(content) == "") {
      return()
    }

    histDir <- getHistoryDir(projId, filePath)
    if (is.null(histDir)) {
      return()
    }

    manifestFile <- file.path(histDir, "manifest.json")

    # Load existing manifest
    manifest <- if (file.exists(manifestFile)) {
      tryCatch(
        jsonlite::fromJSON(manifestFile, simplifyVector = FALSE),
        error = function(e) list()
      )
    } else {
      list()
    }

    # --- PERFORMANCE: Check against the IN-MEMORY CACHE first (Super Fast) ---
    cacheKey <- paste0(projId, "::", filePath)
    if (!is.null(lastSavedHistoryCache[[cacheKey]])) {
      if (lastSavedHistoryCache[[cacheKey]] == content) {
        return() # No change since last memory save
      }
    }

    # --- FALLBACK: Check against the latest snapshot on disk ---
    if (length(manifest) > 0) {
      lastEntry <- manifest[[1]]
      lastSnapFile <- file.path(histDir, paste0(lastEntry$id, ".txt"))
      if (file.exists(lastSnapFile)) {
        lastContent <- tryCatch({
          paste(readLines(lastSnapFile, warn = FALSE), collapse = "\n")
        }, error = function(e) "")
        
        # Update cache for next time
        lastSavedHistoryCache[[cacheKey]] <<- lastContent 
        
        if (lastContent == content) return() # No change
      }
    }

    # --- DETERMINE TYPE (Add, Delete, Edit) ---
    actionType <- "edit" # Default
    if (length(manifest) == 0) {
      actionType <- "add"
    } else if (trimws(content) == "") {
      actionType <- "delete"
    }

    # Create new snapshot
    user <- loadUserProfile()
    snapId <- uuid::UUIDgenerate()
    timestamp <- as.numeric(Sys.time())

    newEntry <- list(
      id = snapId,
      timestamp = timestamp,
      user = user$username,
      file = basename(filePath),
      type = actionType
    )

    # Save content file
    writeLines(content, file.path(histDir, paste0(snapId, ".txt")))
    
    # Update cache for next time
    lastSavedHistoryCache[[cacheKey]] <<- content

    # Update manifest (Prepend new entry)
    manifest <- c(list(newEntry), manifest)

    # Limit history depth
    if (length(manifest) > 50) {
      oldest <- manifest[[length(manifest)]]
      unlink(file.path(histDir, paste0(oldest$id, ".txt")))
      manifest <- manifest[1:50]
    }

    jsonlite::write_json(
      manifest,
      manifestFile,
      auto_unbox = TRUE,
      pretty = TRUE
    )
    
    # Force UI Refresh
    historyUpdateCounter(historyUpdateCounter() + 1)
  }

  # 3. Load History Manifest
  loadHistoryManifest <- function(projId, filePath) {
    histDir <- getHistoryDir(projId, filePath)
    if (is.null(histDir)) {
      return(list())
    }

    manifestFile <- file.path(histDir, "manifest.json")
    if (file.exists(manifestFile)) {
      tryCatch(
        jsonlite::fromJSON(manifestFile, simplifyVector = FALSE),
        error = function(e) list()
      )
    } else {
      list()
    }
  }

  ensureFileHistoryExists <- function(projId, filePath) {
    req(projId, filePath)
    manifest <- loadHistoryManifest(projId, filePath)
    if (length(manifest) == 0) {
      projDir <- getActiveProjectDir()
      fullPath <- file.path(projDir, filePath)
      
      # Check if file is editable (don't read binary files)
      isEditable <- tolower(tools::file_ext(filePath)) %in% c("tex", "bib", "bst", "cls", "sty", "txt", "md", "rnw", "r", "rprofile", "rds", "rdata")
      # Note: rdata and rds are binary but we usually shouldn't try to read them as text history
      
      if (file.exists(fullPath) && isEditable) {
        content <- tryCatch({
          paste(readLines(fullPath, warn = FALSE), collapse = "\n")
        }, error = function(e) "")
        if (nzchar(content)) {
          saveHistorySnapshot(projId, filePath, content)
        }
      }
    }
  }

  # 4. Get Snapshot Content
  getHistorySnapshotContent <- function(projId, filePath, snapId) {
    histDir <- getHistoryDir(projId, filePath)
    snapFile <- file.path(histDir, paste0(snapId, ".txt"))
    if (file.exists(snapFile)) {
      paste(readLines(snapFile, warn = FALSE), collapse = "\n")
    } else {
      ""
    }
  }

  # =================== HISTORY UI HANDLERS ===================
  
  # Sync historyActiveFile whenever currentFile changes to ensure the History pane
  # is always ready with the correct context.
  observeEvent(currentFile(), {
    req(currentFile())
    # If the user switches files in the main editor, update the history target
    # unless they already have a specific history file selected.
    # Actually, we should probably follow the editor's active file by default.
    historyActiveFile(currentFile())
  })

  # 1. Render History Sidebar
  observeEvent(input$openHistoryBtn, {
    req(activeProjectId(), currentFile())
    projId <- activeProjectId()
    # Set history active file — ALWAYS sync with currentFile to avoid empty state
    filePath <- currentFile()
    historyActiveFile(filePath)

    # Auto-init if needed (only for editable files)
    isEditable <- isTRUE(input$fileClick$isEditable) # fileClick is usually the last click
    # Alternative: check extension
    editableExts <- c("tex", "bib", "bst", "cls", "sty", "txt", "md", "rnw", "r", "rprofile")
    isEditable <- tolower(tools::file_ext(filePath)) %in% editableExts

    if (isEditable) {
      ensureFileHistoryExists(projId, filePath)
    }

    session$sendCustomMessage("toggleHistoryView", TRUE)

    # Initial load of the latest version if exists
    manifest <- loadHistoryManifest(projId, filePath)
    if (length(manifest) > 0) {
      latestId <- manifest[[1]]$id
      shinyjs::delay(200, {
        shinyjs::runjs(sprintf("loadHistoryItem('%s')", latestId))
      })
    }
  })

  # 1.a Render History Sidebar (Versions)
  output$historySidebarContent <- renderUI({
    # Bind to our counter for instant reactivity
    historyUpdateCounter()
    # Bind to currentFile to refresh instantly when switching files in the editor
    currentFile() 
    
    # Start Spinner
    session$sendCustomMessage("toggleHistoryVersionsSpinner", TRUE)

    req(activeProjectId())
    
    # Fallback: ensure historyActiveFile is populated
    activePath <- historyActiveFile()
    if (is.null(activePath) || activePath == "") {
      activePath <- currentFile()
      if (!is.null(activePath) && nzchar(activePath)) historyActiveFile(activePath)
    }
    req(activePath)
    
    manifest <- loadHistoryManifest(activeProjectId(), activePath)

    if (length(manifest) == 0) {
      # Stop Spinner
      session$onFlushed(function() {
        session$sendCustomMessage("toggleHistoryVersionsSpinner", FALSE)
      }, once = TRUE)

      return(div(
        class = "text-muted text-center p-3",
        "No history recorded yet."
      ))
    }

    # Sort: Newest first
    manifest <- manifest[order(
      sapply(manifest, function(x) x$timestamp),
      decreasing = TRUE
    )]

    # Generate Cards
    card_list <- lapply(seq_along(manifest), function(i) {
      entry <- manifest[[i]]
      date_str <- format(
        as.POSIXct(entry$timestamp, origin = "1970-01-01"),
        "%b %d · %I:%M %p"
      )

      # Tag Logic
      eType <- if (!is.null(entry$type)) entry$type else "edit"
      tag_class <- switch(
        eType,
        "add" = "tag-added",
        "delete" = "tag-deleted",
        "edit" = "tag-edited",
        "text-secondary"
      )
      tag_label <- toupper(eType)

      active_class <- if (i == 1) " active" else ""

      # UI Card
      div(
        class = paste0("history-card", active_class),
        id = paste0("card-", entry$id),
        onclick = sprintf("loadHistoryItem('%s')", entry$id),

        div(
          class = "d-flex justify-content-between align-items-start",
          span(class = paste("history-tag", tag_class), tag_label),
          # Kebab Dropdown (Fixed Positioning)
          div(
            class = "dropdown",
            style = "position: relative;", # <--- Keeps menu near button
            onclick = "event.stopPropagation();",

            tags$a(
              href = "javascript:void(0);",
              class = "text-muted",
              `data-bs-toggle` = "dropdown",
              `data-bs-display` = "static", # <--- Prevents flying away
              icon("ellipsis-vertical")
            ),

            div(
              class = "dropdown-menu dropdown-menu-end",
              # Restore Action
              tags$a(
                class = "dropdown-item",
                href = "javascript:void(0);",
                onclick = sprintf("restoreVersion('%s')", entry$id),
                HTML(
                  '<svg
                                      xmlns="http://www.w3.org/2000/svg"
                                      class="icon icon-1"
                                      width="24"
                                      height="24"
                                      viewBox="0 0 24 24"
                                      fill="none"
                                      stroke="currentColor"
                                      stroke-width="2"
                                      stroke-linecap="round"
                                      stroke-linejoin="round">
                                      <path d="M12 8l0 4l2 2"></path>
                                      <path d="M3.05 11a9 9 0 1 1 .5 4m-.5 5v-5h5"></path>
                                    </svg>'
                ),
                " Restore this version"
              ),

              # Download Action (Triggers hidden handler)
              tags$a(
                class = "dropdown-item",
                href = "javascript:void(0);",
                onclick = sprintf(
                  "Shiny.setInputValue('history_dl_id', '%s', {priority: 'event'}); document.getElementById('history_dl_btn').click();",
                  entry$id
                ),
                HTML(
                  '<svg
                                      xmlns="http://www.w3.org/2000/svg"
                                      class="icon icon-1"
                                      width="24"
                                      height="24"
                                      viewBox="0 0 24 24"
                                      fill="none"
                                      stroke="currentColor"
                                      stroke-width="2"
                                      stroke-linecap="round"
                                      stroke-linejoin="round"
                                    >
                                      <path d="M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2 -2v-2" />
                                      <path d="M7 11l5 5l5 -5" />
                                      <path d="M12 4l0 12" />
                                    </svg>
                                    '
                ),
                " Download this version"
              )
            )
          )
        ),

        div(
          class = "mt-2",
          div(
            style = "font-weight: 600; font-size: 0.9rem;",
            if (nzchar(entry$user)) entry$user else "Unknown User"
          ),
          div(class = "text-muted small", date_str)
        )
      )
    })

    # Stop Spinner
    session$onFlushed(function() {
      session$sendCustomMessage("toggleHistoryVersionsSpinner", FALSE)
    }, once = TRUE)

    div(card_list)
  })

  # 1.b Render History File List
  output$historyFileList <- renderUI({
    # Bind to currentFile to highlight the active file correctly in the tree
    currentFile()

    # Start Spinner
    session$sendCustomMessage("toggleHistoryFilesSpinner", TRUE)

    req(activeProjectId())
    
    # Fallback: ensure historyActiveFile is populated
    activePath <- historyActiveFile()
    if (is.null(activePath) || activePath == "") {
      activePath <- currentFile()
      if (!is.null(activePath) && nzchar(activePath)) historyActiveFile(activePath)
    }
    
    res <- renderFileTreeUI(
      projDir = getActiveProjectDir(),
      activePath = activePath,
      clickInputId = "historyFileClick",
      projId = activeProjectId(),
      readOnly = TRUE
    )

    # Stop Spinner
    session$onFlushed(function() {
      session$sendCustomMessage("toggleHistoryFilesSpinner", FALSE)
    }, once = TRUE)

    return(res)
  })

  # 1c. Render History Navbar Info (SYNCED WITH EDITOR)
  output$historyNavbarInfo <- renderUI({
    projId <- activeProjectId()
    filePath <- historyActiveFile()
    
    if (is.null(projId)) return(NULL)
    
    # Mirror logic from editor navbar
    projects <- loadProjects()
    projectName <- "Unknown Project"
    for (proj in projects) {
      if (proj$id == projId) {
        projectName <- proj$name
        break
      }
    }
    
    # Construct breadcrumb-style HTML
    tagList(
      div(
        style = "display: flex; align-items: center; gap: 10px; font-size: 0.9rem;",
        span(
          class = "file-on-editor",
          tags$i(class = "fa-regular fa-folder", style = "color: var(--tblr-primary); opacity: 1;")
        ),
        span(class = "fw-bold", style = "color: var(--tblr-body-color);", projectName),
        span(
          style = "opacity: 0.5; color: var(--tblr-body-color);",
          tags$i(class = "fa-solid fa-chevron-right", style = "font-size: 0.7em;")
        ),
        if (!is.null(filePath) && nzchar(filePath)) {
          tagList(
            span(
              class = "file-on-editor",
              tags$i(class = "fa-regular fa-file-lines", style = "color: var(--tblr-primary); opacity: 1;")
            ),
            span(style = "color: var(--tblr-body-color);", filePath)
          )
        } else {
          span(style = "color: var(--tblr-secondary); font-style: italic;", "No file selected")
        }
      )
    )
  })

  # 1d. History File Selection
  observeEvent(input$historyFileClick, {
    req(input$historyFileClick$path)
    
    # Check if file is editable before proceeding (Prevents binary/encoding crashes)
    isEditable <- isTRUE(input$historyFileClick$isEditable)
    if (!isEditable) {
       return()
    }
    
    filePath <- input$historyFileClick$path
    projId <- activeProjectId()

    # Step A: Update state
    historyActiveFile(filePath)

    # Step B: Auto-Initialize if none exists
    ensureFileHistoryExists(projId, filePath)

    # Step C: Load the latest version
    manifest <- loadHistoryManifest(projId, filePath)
    if (length(manifest) > 0) {
      shinyjs::runjs(sprintf("loadHistoryItem('%s')", manifest[[1]]$id))
    }
  })

  # 2. History Selection (With Diff Fix)
  observeEvent(input$history_selected_id, {
    req(input$history_selected_id)
    snapId <- input$history_selected_id

    manifest <- loadHistoryManifest(activeProjectId(), historyActiveFile())
    currEntry <- Find(function(x) x$id == snapId, manifest)
    req(currEntry)

    currContent <- getHistorySnapshotContent(
      activeProjectId(),
      historyActiveFile(),
      snapId
    )

    # Find previous content for Diff
    idx <- which(sapply(manifest, function(x) x$id == snapId))
    prevContent <- ""
    if (length(idx) > 0 && idx < length(manifest)) {
      prevId <- manifest[[idx + 1]]$id
      prevContent <- getHistorySnapshotContent(
        activeProjectId(),
        historyActiveFile(),
        prevId
      )
    }

    session$sendCustomMessage(
      "historyContentReady",
      list(
        content = currContent,
        previous = prevContent, # Needed for Green/Red diff
        diffMode = TRUE,
        meta = list(
          id = currEntry$id,
          user = currEntry$user,
          timestamp = currEntry$timestamp,
          file = historyActiveFile(),
          projectName = getProjectNameById(activeProjectId())
        )
      )
    )
  })

  # 3. Restore Handler
  observeEvent(input$history_restore_id, {
    req(input$history_restore_id)
    snapId <- input$history_restore_id
    content <- getHistorySnapshotContent(
      activeProjectId(),
      historyActiveFile(),
      snapId
    )

    if (nzchar(content)) {
      fullPath <- file.path(getActiveProjectDir(), historyActiveFile())
      writeLines(content, fullPath)
      
      # If the restored file is the one currently in the main editor, update it
      if (identical(historyActiveFile(), currentFile())) {
        updateAceEditor(session, "sourceEditor", value = content)
        
        # Also update the Visual Editor via the bridge
        session$sendCustomMessage("cmdSafeLoadFile", list(
          content = content,
          mode = getAceModeFromExtension(historyActiveFile())
        ))
        
        # Flag to prevent autosave loop immediately after restore
        rv$fileJustLoaded <- TRUE
        later::later(function() {
          shiny::withReactiveDomain(session, {
            rv$fileJustLoaded <- FALSE
          })
        }, 1.0)
      }

      saveHistorySnapshot(activeProjectId(), historyActiveFile(), content)
      showTablerAlert(
        "success",
        "File restored",
        "File restored successfully.",
        5000
      )
      session$sendCustomMessage("toggleHistoryView", FALSE)
    }
  })

  output$history_dl_btn <- downloadHandler(
    filename = function() {
      req(input$history_dl_id)
      # E.g. "myfile_v_12345.txt"
      snapId <- input$history_dl_id
      paste0(
        tools::file_path_sans_ext(historyActiveFile()),
        "_",
        snapId,
        ".",
        tools::file_ext(historyActiveFile())
      )
    },
    content = function(file) {
      req(input$history_dl_id)
      snapId <- input$history_dl_id
      content <- getHistorySnapshotContent(
        activeProjectId(),
        historyActiveFile(),
        snapId
      )
      writeLines(content, file)
    }
  )

  # 4. Close Button
  observeEvent(input$closeHistoryBtn, {
    session$sendCustomMessage("toggleHistoryView", FALSE)
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

  # ============ AI Assistant Server Logic ============ #
  # Enable background processing
  plan(multisession)

  # --- Server Logic ---

  # Helper: Chat Directory
  CHAT_DIR <- ".chat_sessions"
  if (!dir.exists(CHAT_DIR)) {
    dir.create(CHAT_DIR)
  }

  # Helper: Cleanup Old Sessions (30 Days)
  cleanup_old_sessions <- function() {
    files <- list.files(CHAT_DIR, pattern = "\\.json$", full.names = TRUE)
    if (length(files) == 0) {
      return()
    }

    # Calculate age
    now <- Sys.time()
    cutoff <- now - (30 * 24 * 60 * 60) # 30 days in seconds

    for (f in files) {
      info <- file.info(f)
      if (!is.na(info$mtime) && info$mtime < cutoff) {
        unlink(f) # Delete file
      }
    }
  }

  # Helper: Save Session
  save_chat_session <- function(session_id, history) {
    if (is.null(session_id)) {
      return()
    }
    file_path <- file.path(CHAT_DIR, paste0(session_id, ".json"))

    # Create a title from the first user message if possible
    title <- "New Chat"
    first_user_msg <- Find(function(x) x$role == "user", history)
    if (!is.null(first_user_msg)) {
      title <- substr(first_user_msg$text, 1, 30)
      if (nchar(first_user_msg$text) > 30) title <- paste0(title, "...")
    }

    write_json(
      list(
        id = session_id,
        timestamp = Sys.time(),
        title = title,
        history = history
      ),
      file_path,
      auto_unbox = TRUE
    )
  }

  # Chat State
  rv_chat <- reactiveValues(
    session_id = uuid::UUIDgenerate(),
    history = list(),
    typing = FALSE,
    trigger_scroll = 0,
    refresh_history = 0 # <--- ADD THIS (Trigger for updating the list)
  )

  # Expose typing state
  output$is_ai_typing <- reactive({
    rv_chat$typing
  })
  outputOptions(output, "is_ai_typing", suspendWhenHidden = FALSE)

  # --- 1. History & Session Management ---

  # Toggle Sidebar
  observeEvent(input$ai_toggle_history, {
    shinyjs::runjs(
      "document.getElementById('aiHistorySidebar').classList.toggle('show');"
    )
  })

  # New Chat
  observeEvent(input$ai_new_chat, {
    rv_chat$session_id <- uuid::UUIDgenerate()
    rv_chat$history <- list()
    shinyjs::runjs(
      "document.getElementById('aiHistorySidebar').classList.remove('show');"
    )
  })

  # Load Chat (Dynamic Observer for history items)
  observeEvent(input$load_session_id, {
    req(input$load_session_id)
    file_path <- file.path(CHAT_DIR, paste0(input$load_session_id, ".json"))

    if (file.exists(file_path)) {
      saved_data <- read_json(file_path, simplifyVector = FALSE)
      rv_chat$session_id <- saved_data$id
      rv_chat$history <- saved_data$history
      shinyjs::runjs(
        "document.getElementById('aiHistorySidebar').classList.remove('show');"
      )
      shinyjs::runjs("beautifyChat();") # Re-apply highlighting
    }
  })

  # Render History List (Hover-to-Delete Version)
  output$chat_history_list <- renderUI({
    # Trigger cleanup and refresh logic
    cleanup_old_sessions()
    rv_chat$history
    rv_chat$refresh_history

    files <- list.files(CHAT_DIR, pattern = "\\.json$", full.names = TRUE)
    if (length(files) == 0) {
      return(div(class = "p-3 text-muted italic", "No history yet."))
    }

    # Read metadata
    sessions <- lapply(files, function(f) {
      tryCatch(
        {
          d <- jsonlite::fromJSON(f, simplifyVector = FALSE)
          list(id = d$id, title = d$title, timestamp = d$timestamp)
        },
        error = function(e) NULL
      )
    })

    sessions <- Filter(Negate(is.null), sessions)
    sessions <- sessions[order(
      sapply(sessions, function(x) x$timestamp),
      decreasing = TRUE
    )]

    div(
      class = "list-group list-group-flush",
      lapply(sessions, function(s) {
        is_active <- identical(s$id, rv_chat$session_id)
        active_cls <- if (is_active) "active" else ""

        # Item Container
        div(
          class = paste("history-item-container", active_cls),
          onclick = sprintf(
            "Shiny.setInputValue('load_session_id', '%s', {priority: 'event'})",
            s$id
          ),

          # 1. Content (Title + Date)
          div(
            class = "history-content",
            div(class = "history-title", title = s$title, s$title),
            div(
              class = "history-date",
              format(as.POSIXct(s$timestamp), "%b %d")
            )
          ),

          # 2. Delete Button (Hidden until hover)
          div(
            class = "history-delete-wrapper",
            tags$button(
              class = "btn btn-icon btn-ghost-danger btn-sm",
              type = "button",
              title = "Delete Chat",
              # STOP PROPAGATION ensures we don't 'load' the chat while deleting it
              onclick = sprintf(
                "event.stopPropagation(); if(confirm('Delete this chat?')) { Shiny.setInputValue('delete_session', '%s', {priority: 'event'}); }",
                s$id
              ),
              icon("trash")
            )
          )
        )
      })
    )
  })

  # Delete Handler
  observeEvent(input$delete_session, {
    req(input$delete_session)
    file_to_del <- file.path(CHAT_DIR, paste0(input$delete_session, ".json"))

    if (file.exists(file_to_del)) {
      unlink(file_to_del)

      # If we deleted the ACTIVE session, start a new one
      if (identical(rv_chat$session_id, input$delete_session)) {
        rv_chat$session_id <- uuid::UUIDgenerate()
        rv_chat$history <- list()
      }

      # Trigger the UI refresh SAFELY
      rv_chat$refresh_history <- rv_chat$refresh_history + 1
    }
  })

  # --- 2. Handle Send (Updated for Context & Persistence) ---
  observeEvent(input$ai_send, {
    req(input$gemini_prompt)
    user_text <- input$gemini_prompt

    # Update UI: Add User Message
    new_history <- c(
      rv_chat$history,
      list(list(role = "user", text = user_text))
    )
    rv_chat$history <- new_history

    # Save immediately (User message)
    save_chat_session(rv_chat$session_id, rv_chat$history)

    updateTextAreaInput(session, "gemini_prompt", value = "")
    rv_chat$typing <- TRUE

    # Get Key
    api_key <- Sys.getenv("GEMINI_API_KEY")

    # Capture current state for the future block
    current_history <- new_history
    current_sess_id <- rv_chat$session_id

    # Async API Call
    future::future({
      library(httr2)
      library(jsonlite)

      if (api_key == "") {
        stop("GEMINI_API_KEY is missing. Check .Renviron.")
      }

      # --- CONTEXT MEMORY: Build Payload from History ---
      # Map 'user'/'model' roles correctly for Gemini API
      # Note: Gemini expects 'user' and 'model' roles.
      formatted_contents <- lapply(current_history, function(msg) {
        list(
          role = msg$role,
          parts = list(list(text = msg$text))
        )
      })

      payload <- list(contents = formatted_contents)

      resp <- request(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent"
      ) %>%
        req_headers("x-goog-api-key" = api_key) %>%
        req_headers("Content-Type" = "application/json") %>%
        req_body_json(payload) %>%
        req_perform()

      resp_json <- resp %>% resp_body_json()

      if (!is.null(resp_json$candidates[[1]]$content$parts[[1]]$text)) {
        return(resp_json$candidates[[1]]$content$parts[[1]]$text)
      } else {
        stop("AI API returned an empty response.")
      }
    }) %...>%
      (function(ai_response) {
        # SUCCESS
        # Update History
        updated_history <- c(
          current_history,
          list(list(role = "model", text = ai_response))
        )
        rv_chat$history <- updated_history

        # Save (AI Message)
        save_chat_session(current_sess_id, updated_history)

        rv_chat$typing <- FALSE

        # Trigger JS Beautifier
        shinyjs::runjs("beautifyChat();")
      }) %...!%
      (function(err) {
        # ERROR HANDLER
        rv_chat$typing <- FALSE
        msg <- err$message
        if (grepl("404", msg)) {
          msg <- "AI model not found (404)."
        } else if (grepl("403", msg)) {
          msg <- "Access Denied (403). Check API Key."
        }

        showNotification(paste("AI Error:", msg), type = "error")
      })

    NULL
  })

  # Render Chat Messages (Strictly your original logic + Scroll update)
  output$chat_ui <- renderUI({
    req(length(rv_chat$history) > 0)

    # Ensure we scroll to bottom on re-render
    shinyjs::runjs(
      "setTimeout(function(){ var c = document.getElementById('chat-scroll-container'); c.scrollTop = c.scrollHeight; }, 100);"
    )

    lapply(seq_along(rv_chat$history), function(i) {
      msg <- rv_chat$history[[i]]
      is_user <- msg$role == "user"

      if (is_user) {
        # USER MESSAGE - No profile pic
        div(
          class = "d-flex justify-content-end mb-3",
          div(
            class = "card bg-primary text-white p-3 fade-in user-message",
            style = "max-width: 85%; border-radius: 12px 12px 2px 12px; font-size: 0.95rem;",
            div(style = "white-space: pre-wrap;", msg$text)
          )
        )
      } else {
        # AI MESSAGE
        div(
          class = "d-flex justify-content-start mb-3 fade-in",
          div(
            HTML(
              '<span class="avatar avatar-sm rounded-circle me-2 ai-avatar-glow"></span>'
            )
          ),
          div(
            class = "card p-3 ai-message-card",
            style = "max-width: 90%; background: var(--tblr-bg-surface-secondary); border: 1px solid var(--tblr-border-color); border-radius: 2px 12px 12px 12px; font-size: 0.95rem;",
            HTML(markdown::markdownToHTML(
              text = msg$text,
              fragment.only = TRUE
            ))
          )
        )
      }
    })
  })

  # --- Dynamic Layout Handler ---
  observe({
    # Check if history is empty
    is_empty <- length(rv_chat$history) == 0

    if (is_empty) {
      # Add class to center the input
      shinyjs::addClass(id = "aiPane", class = "chat-empty")
    } else {
      # Remove class to move input to bottom
      shinyjs::removeClass(id = "aiPane", class = "chat-empty")
    }
  })
  # ============ AI Assistant Server Logic ============ #
  # Enable background processing
  plan(multisession)

  # --- Server Logic ---

  # Helper: Chat Directory
  CHAT_DIR <- ".chat_sessions"
  if (!dir.exists(CHAT_DIR)) {
    dir.create(CHAT_DIR)
  }

  # Helper: Cleanup Old Sessions (30 Days)
  cleanup_old_sessions <- function() {
    files <- list.files(CHAT_DIR, pattern = "\\.json$", full.names = TRUE)
    if (length(files) == 0) {
      return()
    }

    # Calculate age
    now <- Sys.time()
    cutoff <- now - (30 * 24 * 60 * 60) # 30 days in seconds

    for (f in files) {
      info <- file.info(f)
      if (!is.na(info$mtime) && info$mtime < cutoff) {
        unlink(f) # Delete file
      }
    }
  }

  # Helper: Save Session
  save_chat_session <- function(session_id, history) {
    if (is.null(session_id)) {
      return()
    }
    file_path <- file.path(CHAT_DIR, paste0(session_id, ".json"))

    # Create a title from the first user message if possible
    title <- "New Chat"
    first_user_msg <- Find(function(x) x$role == "user", history)
    if (!is.null(first_user_msg)) {
      title <- substr(first_user_msg$text, 1, 30)
      if (nchar(first_user_msg$text) > 30) title <- paste0(title, "...")
    }

    write_json(
      list(
        id = session_id,
        timestamp = Sys.time(),
        title = title,
        history = history
      ),
      file_path,
      auto_unbox = TRUE
    )
  }

  # Chat State
  rv_chat <- reactiveValues(
    session_id = uuid::UUIDgenerate(),
    history = list(),
    typing = FALSE,
    trigger_scroll = 0,
    refresh_history = 0 # <--- ADD THIS (Trigger for updating the list)
  )

  # Expose typing state
  output$is_ai_typing <- reactive({
    rv_chat$typing
  })
  outputOptions(output, "is_ai_typing", suspendWhenHidden = FALSE)

  # --- 1. History & Session Management ---

  # Toggle Sidebar
  observeEvent(input$ai_toggle_history, {
    shinyjs::runjs(
      "document.getElementById('aiHistorySidebar').classList.toggle('show');"
    )
  })

  # New Chat
  observeEvent(input$ai_new_chat, {
    rv_chat$session_id <- uuid::UUIDgenerate()
    rv_chat$history <- list()
    shinyjs::runjs(
      "document.getElementById('aiHistorySidebar').classList.remove('show');"
    )
  })

  # Load Chat (Dynamic Observer for history items)
  observeEvent(input$load_session_id, {
    req(input$load_session_id)
    file_path <- file.path(CHAT_DIR, paste0(input$load_session_id, ".json"))

    if (file.exists(file_path)) {
      saved_data <- read_json(file_path, simplifyVector = FALSE)
      rv_chat$session_id <- saved_data$id
      rv_chat$history <- saved_data$history
      shinyjs::runjs(
        "document.getElementById('aiHistorySidebar').classList.remove('show');"
      )
      shinyjs::runjs("beautifyChat();") # Re-apply highlighting
    }
  })

  # Render History List (Hover-to-Delete Version)
  output$chat_history_list <- renderUI({
    # Trigger cleanup and refresh logic
    cleanup_old_sessions()
    rv_chat$history
    rv_chat$refresh_history

    files <- list.files(CHAT_DIR, pattern = "\\.json$", full.names = TRUE)
    if (length(files) == 0) {
      return(div(class = "p-3 text-muted italic", "No history yet."))
    }

    # Read metadata
    sessions <- lapply(files, function(f) {
      tryCatch(
        {
          d <- jsonlite::fromJSON(f, simplifyVector = FALSE)
          list(id = d$id, title = d$title, timestamp = d$timestamp)
        },
        error = function(e) NULL
      )
    })

    sessions <- Filter(Negate(is.null), sessions)
    sessions <- sessions[order(
      sapply(sessions, function(x) x$timestamp),
      decreasing = TRUE
    )]

    div(
      class = "list-group list-group-flush",
      lapply(sessions, function(s) {
        is_active <- identical(s$id, rv_chat$session_id)
        active_cls <- if (is_active) "active" else ""

        # Item Container
        div(
          class = paste("history-item-container", active_cls),
          onclick = sprintf(
            "Shiny.setInputValue('load_session_id', '%s', {priority: 'event'})",
            s$id
          ),

          # 1. Content (Title + Date)
          div(
            class = "history-content",
            div(class = "history-title", title = s$title, s$title),
            div(
              class = "history-date",
              format(as.POSIXct(s$timestamp), "%b %d")
            )
          ),

          # 2. Delete Button (Hidden until hover)
          div(
            class = "history-delete-wrapper",
            tags$button(
              class = "btn btn-icon btn-ghost-danger btn-sm",
              type = "button",
              title = "Delete Chat",
              # STOP PROPAGATION ensures we don't 'load' the chat while deleting it
              onclick = sprintf(
                "event.stopPropagation(); if(confirm('Delete this chat?')) { Shiny.setInputValue('delete_session', '%s', {priority: 'event'}); }",
                s$id
              ),
              icon("trash")
            )
          )
        )
      })
    )
  })

  # Delete Handler
  observeEvent(input$delete_session, {
    req(input$delete_session)
    file_to_del <- file.path(CHAT_DIR, paste0(input$delete_session, ".json"))

    if (file.exists(file_to_del)) {
      unlink(file_to_del)

      # If we deleted the ACTIVE session, start a new one
      if (identical(rv_chat$session_id, input$delete_session)) {
        rv_chat$session_id <- uuid::UUIDgenerate()
        rv_chat$history <- list()
      }

      # Trigger the UI refresh SAFELY
      rv_chat$refresh_history <- rv_chat$refresh_history + 1
    }
  })

  # --- 2. Handle Send (Updated for Context & Persistence) ---
  observeEvent(input$ai_send, {
    req(input$gemini_prompt)
    user_text <- input$gemini_prompt

    # Update UI: Add User Message
    new_history <- c(
      rv_chat$history,
      list(list(role = "user", text = user_text))
    )
    rv_chat$history <- new_history

    # Save immediately (User message)
    save_chat_session(rv_chat$session_id, rv_chat$history)

    updateTextAreaInput(session, "gemini_prompt", value = "")
    rv_chat$typing <- TRUE

    # Get Key
    api_key <- Sys.getenv("GEMINI_API_KEY")

    # Capture current state for the future block
    current_history <- new_history
    current_sess_id <- rv_chat$session_id

    # Async API Call
    future::future({
      library(httr2)
      library(jsonlite)

      if (api_key == "") {
        stop("GEMINI_API_KEY is missing. Check .Renviron.")
      }

      # --- CONTEXT MEMORY: Build Payload from History ---
      # Map 'user'/'model' roles correctly for Gemini API
      # Note: Gemini expects 'user' and 'model' roles.
      formatted_contents <- lapply(current_history, function(msg) {
        list(
          role = msg$role,
          parts = list(list(text = msg$text))
        )
      })

      payload <- list(contents = formatted_contents)

      resp <- request(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent"
      ) %>%
        req_headers("x-goog-api-key" = api_key) %>%
        req_headers("Content-Type" = "application/json") %>%
        req_body_json(payload) %>%
        req_perform()

      resp_json <- resp %>% resp_body_json()

      if (!is.null(resp_json$candidates[[1]]$content$parts[[1]]$text)) {
        return(resp_json$candidates[[1]]$content$parts[[1]]$text)
      } else {
        stop("AI API returned an empty response.")
      }
    }) %...>%
      (function(ai_response) {
        # SUCCESS
        # Update History
        updated_history <- c(
          current_history,
          list(list(role = "model", text = ai_response))
        )
        rv_chat$history <- updated_history

        # Save (AI Message)
        save_chat_session(current_sess_id, updated_history)

        rv_chat$typing <- FALSE

        # Trigger JS Beautifier
        shinyjs::runjs("beautifyChat();")
      }) %...!%
      (function(err) {
        # ERROR HANDLER
        rv_chat$typing <- FALSE
        msg <- err$message
        if (grepl("404", msg)) {
          msg <- "AI model not found (404)."
        } else if (grepl("403", msg)) {
          msg <- "Access Denied (403). Check API Key."
        }

        showNotification(paste("AI Error:", msg), type = "error")
      })

    NULL
  })

  # Render Chat Messages (Strictly your original logic + Scroll update)
  output$chat_ui <- renderUI({
    req(length(rv_chat$history) > 0)

    # Ensure we scroll to bottom on re-render
    shinyjs::runjs(
      "setTimeout(function(){ var c = document.getElementById('chat-scroll-container'); c.scrollTop = c.scrollHeight; }, 100);"
    )

    lapply(seq_along(rv_chat$history), function(i) {
      msg <- rv_chat$history[[i]]
      is_user <- msg$role == "user"

      if (is_user) {
        # USER MESSAGE - No profile pic
        div(
          class = "d-flex justify-content-end mb-3",
          div(
            class = "card bg-primary text-white p-3 fade-in user-message",
            style = "max-width: 85%; border-radius: 12px 12px 2px 12px; font-size: 0.95rem;",
            div(style = "white-space: pre-wrap;", msg$text)
          )
        )
      } else {
        # AI MESSAGE
        div(
          class = "d-flex justify-content-start mb-3 fade-in",
          div(
            HTML(
              '<span class="avatar avatar-sm rounded-circle me-2 ai-avatar-glow"></span>'
            )
          ),
          div(
            class = "card p-3 ai-message-card",
            style = "max-width: 90%; background: var(--tblr-bg-surface-secondary); border: 1px solid var(--tblr-border-color); border-radius: 2px 12px 12px 12px; font-size: 0.95rem;",
            HTML(markdown::markdownToHTML(
              text = msg$text,
              fragment.only = TRUE
            ))
          )
        )
      }
    })
  })

  # --- Dynamic Layout Handler ---
  observe({
    # Check if history is empty
    is_empty <- length(rv_chat$history) == 0

    if (is_empty) {
      # Add class to center the input
      shinyjs::addClass(id = "aiPane", class = "chat-empty")
    } else {
      # Remove class to move input to bottom
      shinyjs::removeClass(id = "aiPane", class = "chat-empty")
    }
  })
