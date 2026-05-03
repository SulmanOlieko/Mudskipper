  # --- SERVER SIDE REVIEW & COMMENTS LOGIC ---

  # commentUpdate <- reactiveVal(0) # Moved to top
  reviewPaneVisible <- reactiveVal(FALSE)

  # Optimized Load/Save with Validations
  loadComments <- function(projId, filePath) {
    uid <- isolate(user_session$user_info$user_id)
    if (
      is.null(uid) || is.null(projId) || is.null(filePath) || filePath == ""
    ) {
      return(list())
    }

    # Sanitize path for storage
    safeProj <- gsub("[^a-zA-Z0-9]", "_", projId)
    safePath <- gsub("[^a-zA-Z0-9]", "_", basename(filePath))

    cDir <- getUserCommentsDir(uid)
    if (is.null(cDir)) {
      return(list())
    }

    f <- file.path(cDir, paste0(".", safeProj, "_", safePath, ".json"))

    if (file.exists(f)) {
      tryCatch(
        {
          res <- jsonlite::fromJSON(f, simplifyVector = FALSE)
          # VALIDATION: Ensure res is a list and ONLY contains lists (comments)
          if (!is.list(res)) {
            return(list())
          }
          # Filter out any atomic vectors (corrupted entries) to prevent $ operator error
          res <- Filter(function(x) is.list(x) || is.environment(x), res)
          return(res)
        },
        error = function(e) list()
      )
    } else {
      list()
    }
  }

  # Recursive function to find parent ID and add reply
  add_reply_recursive <- function(nodes, parentId, newReply) {
    lapply(nodes, function(node) {
      # Check if this node is the parent (either a Comment or a Reply)
      if (node$id == parentId) {
        if (is.null(node$replies)) {
          node$replies <- list()
        }
        node$replies <- c(node$replies, list(newReply))
      } else {
        # If this node has children, search them recursively
        if (!is.null(node$replies) && length(node$replies) > 0) {
          node$replies <- add_reply_recursive(node$replies, parentId, newReply)
        }
      }
      node
    })
  }

  # Recursive function to delete a reply
  delete_reply_recursive <- function(nodes, targetId) {
    # First, filter out the target reply at this level
    nodes <- Filter(function(node) node$id != targetId, nodes)

    # Then recursively process any children
    lapply(nodes, function(node) {
      if (!is.null(node$replies) && length(node$replies) > 0) {
        node$replies <- delete_reply_recursive(node$replies, targetId)
      }
      node
    })
  }

  # Recursive function to set edit mode for a reply
  edit_reply_recursive <- function(nodes, targetId, isEditing = TRUE) {
    lapply(nodes, function(node) {
      if (node$id == targetId) {
        node$isEditing <- isEditing
      } else if (!is.null(node$replies) && length(node$replies) > 0) {
        node$replies <- edit_reply_recursive(node$replies, targetId, isEditing)
      }
      node
    })
  }

  # Recursive function to save edited reply content
  save_reply_recursive <- function(nodes, targetId, content) {
    lapply(nodes, function(node) {
      if (node$id == targetId) {
        node$content <- content
        node$isEditing <- FALSE
        # Edit time removed
      } else if (!is.null(node$replies) && length(node$replies) > 0) {
        node$replies <- save_reply_recursive(node$replies, targetId, content)
      }
      node
    })
  }

  saveComments <- function(projId, filePath, comments) {
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid) || is.null(projId) || is.null(filePath)) {
      return()
    }

    safeProj <- gsub("[^a-zA-Z0-9]", "_", projId)
    safePath <- gsub("[^a-zA-Z0-9]", "_", basename(filePath))

    cDir <- getUserCommentsDir(uid)
    if (is.null(cDir)) {
      return()
    }

    f <- file.path(cDir, paste0(".", safeProj, "_", safePath, ".json"))

    # Ensure atomic write to prevent corruption
    jsonlite::write_json(comments, f, auto_unbox = TRUE, pretty = TRUE)
  }

  # 2. Toggle Pane
  observeEvent(input$toggleReviewPane, {
    current <- reviewPaneVisible()
    # If explicit TRUE/FALSE sent from JS, use it, else toggle
    val <- input$toggleReviewPane
    newState <- if (is.logical(val)) val else !current

    reviewPaneVisible(newState)
  })

  # 3. Add Comment (Fixed for Instant Rendering)
  observeEvent(input$addCommentTrigger, {
    req(input$addCommentTrigger)
    data <- input$addCommentTrigger
    user <- loadUserProfile()

    newC <- list(
      id = paste0("c_", as.numeric(Sys.time()), "_", sample(100:999, 1)),
      author = user$username,
      avatar = user$profilePicture,
      timestamp = format(Sys.time(), "%b %d, %H:%M"),
      selectedText = data$text,
      # Ensure integers for Ace
      startRow = as.integer(data$startRow),
      startCol = as.integer(data$startCol),
      endRow = as.integer(data$endRow),
      endCol = as.integer(data$endCol),
      content = "",
      replies = list(),
      resolved = FALSE,
      isEditing = TRUE
    )

    # Save to disk
    cmts <- loadComments(activeProjectId(), currentFile())
    cmts <- c(cmts, list(newC))
    saveComments(activeProjectId(), currentFile(), cmts)

    # 2. Update Sidebar UI
    # --- SMART OPEN LOGIC ---
    # Only toggle the pane if R thinks it is currently CLOSED
    if (!isTRUE(reviewPaneVisible())) {
      reviewPaneVisible(TRUE)
      session$sendCustomMessage("toggleReviewPane", TRUE)
    }
    # ------------------------
    commentUpdate(commentUpdate() + 1)

    # 1. CRITICAL FIX: Push the visual marker to Ace IMMEDIATELY
    session$sendCustomMessage(
      "renderCommentMarkers",
      list(
        comments = cmts,
        force = TRUE
      )
    )

    # 3. Scroll to card
    shinyjs::delay(300, {
      shinyjs::runjs(sprintf(
        "
      var card = document.getElementById('card-%s');
      if(card) {
        card.scrollIntoView({behavior: 'smooth', block: 'center'});
        card.classList.add('active-comment');
        var txt = document.getElementById('txt-%s');
        if(txt) { txt.focus(); txt.select(); }
      }
    ",
        newC$id,
        newC$id
      ))
    })
  })

  # 4. Handle Actions
  observeEvent(input$saveCommentContent, {
    req(input$saveCommentContent$commentId)
    cId <- input$saveCommentContent$commentId
    val <- input$saveCommentContent$commentContent

    cmts <- loadComments(activeProjectId(), currentFile())
    cmts <- lapply(cmts, function(c) {
      if (c$id == cId) {
        c$content <- val
        c$isEditing <- FALSE
        # Edit time removed
      }
      c
    })
    saveComments(activeProjectId(), currentFile(), cmts)
    commentUpdate(commentUpdate() + 1)
  })

  # Cancel comment edit (new or existing)
  observeEvent(input$cancelCommentEdit, {
    cId <- input$cancelCommentEdit
    cmts <- loadComments(activeProjectId(), currentFile())

    # Find the comment
    targetComment <- NULL
    for (c in cmts) {
      if (c$id == cId) {
        targetComment <- c
        break
      }
    }

    if (!is.null(targetComment)) {
      # If it's a new comment with empty content, delete it
      if (targetComment$content == "" && isTRUE(targetComment$isEditing)) {
        cmts <- Filter(function(c) c$id != cId, cmts)
      } else {
        # Otherwise just cancel edit mode
        cmts <- lapply(cmts, function(c) {
          if (c$id == cId) {
            c$isEditing <- FALSE
          }
          c
        })
      }
      saveComments(activeProjectId(), currentFile(), cmts)
      commentUpdate(commentUpdate() + 1)
    }
  })

  observeEvent(input$editCommentTrigger, {
    cId <- input$editCommentTrigger
    cmts <- loadComments(activeProjectId(), currentFile())
    cmts <- lapply(cmts, function(c) {
      if (c$id == cId) {
        c$isEditing <- TRUE
      }
      c
    })
    saveComments(activeProjectId(), currentFile(), cmts)
    commentUpdate(commentUpdate() + 1)
  })

  observeEvent(input$deleteComment, {
    cId <- input$deleteComment
    cmts <- loadComments(activeProjectId(), currentFile())
    cmts <- Filter(function(c) c$id != cId, cmts)
    saveComments(activeProjectId(), currentFile(), cmts)
    commentUpdate(commentUpdate() + 1)
  })

  observeEvent(input$postReply, {
    # replyParentId can be a Comment ID OR a Reply ID
    pId <- input$postReply$replyParentId
    txt <- input$postReply$replyContent
    user <- loadUserProfile()

    # Create the reply
    reply <- list(
      id = paste0("r_", as.numeric(Sys.time()), "_", sample(100:999, 1)),
      author = user$username,
      avatar = user$profilePicture,
      timestamp = format(Sys.time(), "%H:%M"),
      content = txt,
      replies = list(), # Replies can have sub-replies
      isEditing = FALSE
      # editedAt removed
    )

    cmts <- loadComments(activeProjectId(), currentFile())

    # Use recursive helper to insert reply at correct depth
    cmts <- add_reply_recursive(cmts, pId, reply)

    saveComments(activeProjectId(), currentFile(), cmts)
    commentUpdate(commentUpdate() + 1)
  })

  # Cancel reply posting
  observeEvent(input$cancelReply, {
    # replyParentId can be a Comment ID OR a Reply ID
    pId <- input$cancelReply$replyParentId

    # Use JavaScript to hide the reply box and clear content
    shinyjs::runjs(sprintf(
      "
    var replyBox = document.getElementById('reply-box-%s');
    var replyInput = document.getElementById('reply-input-%s');
    var replyArea = document.getElementById('reply-area-%s');
    var replyVal = document.getElementById('reply-val-%s');
    
    if (replyBox) {
      replyBox.classList.add('d-none');
      if (replyInput) replyInput.value = '';
    }
    if (replyArea) {
      replyArea.classList.remove('show');
      if (replyVal) replyVal.value = '';
    }
  ",
      pId,
      pId,
      pId,
      pId
    ))
  })

  # Resolve
  observeEvent(input$resolveComment, {
    cId <- input$resolveComment
    cmts <- loadComments(activeProjectId(), currentFile())
    cmts <- lapply(cmts, function(c) {
      if (c$id == cId) {
        c$resolved <- !c$resolved
        # Edit time removed
      }
      c
    })
    saveComments(activeProjectId(), currentFile(), cmts)
    commentUpdate(commentUpdate() + 1)
  })

  # 5. Render Stream

  # Delete Reply Handler - UPDATED to handle nested replies
  observeEvent(input$deleteReply, {
    req(input$deleteReply$commentId, input$deleteReply$replyId)
    cId <- input$deleteReply$commentId
    rId <- input$deleteReply$replyId

    cmts <- loadComments(activeProjectId(), currentFile())

    # Find the comment and recursively delete the reply
    cmts <- lapply(cmts, function(comment) {
      if (comment$id == cId) {
        # Use recursive function to delete reply
        comment$replies <- delete_reply_recursive(comment$replies, rId)
      }
      comment
    })

    saveComments(activeProjectId(), currentFile(), cmts)
    commentUpdate(commentUpdate() + 1)
  })

  # --- Reply Editing Handlers ---

  # Trigger Edit Mode for a Reply - UPDATED to handle nested replies
  observeEvent(input$editReplyTrigger, {
    req(input$editReplyTrigger$commentId, input$editReplyTrigger$replyId)
    cId <- input$editReplyTrigger$commentId
    rId <- input$editReplyTrigger$replyId

    cmts <- loadComments(activeProjectId(), currentFile())

    # Find the comment and recursively set edit mode
    cmts <- lapply(cmts, function(comment) {
      if (comment$id == cId) {
        comment$replies <- edit_reply_recursive(comment$replies, rId, TRUE)
      }
      comment
    })

    saveComments(activeProjectId(), currentFile(), cmts)
    commentUpdate(commentUpdate() + 1)
  })

  # Save Edited Reply - UPDATED to handle nested replies
  observeEvent(input$saveReplyContent, {
    req(input$saveReplyContent$commentId, input$saveReplyContent$replyId)
    cId <- input$saveReplyContent$commentId
    rId <- input$saveReplyContent$replyId
    val <- input$saveReplyContent$content

    cmts <- loadComments(activeProjectId(), currentFile())

    # Find the comment and recursively save the reply
    cmts <- lapply(cmts, function(comment) {
      if (comment$id == cId) {
        comment$replies <- save_reply_recursive(comment$replies, rId, val)
      }
      comment
    })

    saveComments(activeProjectId(), currentFile(), cmts)
    commentUpdate(commentUpdate() + 1)
  })

  # Cancel reply editing
  observeEvent(input$cancelReplyEdit, {
    req(input$cancelReplyEdit$commentId, input$cancelReplyEdit$replyId)
    cId <- input$cancelReplyEdit$commentId
    rId <- input$cancelReplyEdit$replyId

    cmts <- loadComments(activeProjectId(), currentFile())

    # Find the comment and recursively cancel edit mode
    cmts <- lapply(cmts, function(comment) {
      if (comment$id == cId) {
        comment$replies <- edit_reply_recursive(comment$replies, rId, FALSE)
      }
      comment
    })

    saveComments(activeProjectId(), currentFile(), cmts)
    commentUpdate(commentUpdate() + 1)
  })

  # Reply to a Reply (Focuses the reply box for that specific reply)
  observeEvent(input$replyToReplyTrigger, {
    req(
      input$replyToReplyTrigger$commentId,
      input$replyToReplyTrigger$replyId,
      input$replyToReplyTrigger$author
    )
    cId <- input$replyToReplyTrigger$commentId
    rId <- input$replyToReplyTrigger$replyId
    author <- input$replyToReplyTrigger$author

    # Run JS to open the specific reply box for the nested reply
    shinyjs::runjs(sprintf(
      "
    var replyBox = document.getElementById('reply-box-%s');
    var replyInput = document.getElementById('reply-input-%s');
    if(replyBox && replyInput) {
      replyBox.classList.remove('d-none');
      replyInput.value = '@%s ';
      replyInput.focus();
      replyBox.scrollIntoView({behavior: 'smooth', block: 'center'});
    }
  ",
      rId,
      rId,
      author
    ))
  })

  # --- REVIEW FILTER LOGIC ---
  reviewFilter <- reactiveVal("active") # Default to active view

  observeEvent(input$reviewFilter, {
    reviewFilter(input$reviewFilter)
  })

  # --- RENDER STREAM (Updated) ---
  output$commentStream <- renderUI({
    trigger <- commentUpdate()
    filterState <- reviewFilter()

    projId <- activeProjectId()
    currFile <- currentFile()

    if (is.null(projId) || is.null(currFile)) {
      return(NULL)
    }

    # Load all comments
    all_cmts <- loadComments(projId, currFile)

    # NOTE: We do NOT send markers here anymore.
    # That is handled by the dedicated observer to separate data logic from UI logic.

    # Filter list for Sidebar Display
    display_cmts <- list()
    empty_msg <- ""

    if (filterState == "active") {
      # Show only Unresolved
      display_cmts <- Filter(function(c) !isTRUE(c$resolved), all_cmts)
      empty_msg <- "No active comments."
    } else {
      # Show only Resolved
      display_cmts <- Filter(function(c) isTRUE(c$resolved), all_cmts)
      empty_msg <- "No resolved comments."
    }

    # Sort by row position
    if (length(display_cmts) > 0) {
      display_cmts <- display_cmts[order(sapply(display_cmts, function(x) {
        x$startRow
      }))]
    }

    if (length(display_cmts) == 0) {
      return(
        tagList(
          div(
            class = "text-center text-muted mt-4",
            style = "font-size:0.9rem;",
            empty_msg
          ),
          div(
            class = "empty",
            ui_empty_illustration(),
            HTML(
              '
                   <p class="empty-title">NO COMMENTS FOUND</p>
                   <p class="empty-subtitle text-secondary">There are no comments in this file.</p>
          '
            )
          )
        )
      )
    }

    currentUser <- loadUserProfile()

    # --- RECURSIVE REPLY RENDERER (Cleaned of editedAt logic) ---
    render_replies_recursive <- function(replies, isResolved, commentId) {
      if (length(replies) == 0) {
        return(NULL)
      }

      lapply(replies, function(r) {
        rAvatar <- if (!is.null(r$avatar) && nzchar(r$avatar)) {
          r$avatar
        } else {
          "https://via.placeholder.com/32"
        }
        rIsMine <- (r$author == currentUser$username)
        canEditReply <- rIsMine && !isResolved

        div(
          class = "nested-reply-container reply-item",
          id = paste0("reply-", r$id),
          div(
            class = "reply-header",
            style = "display:flex; justify-content:space-between; align-items:center; margin-bottom:4px; min-height:20px;",
            div(
              style = "display:flex; gap:8px; align-items:center; font-weight:600; font-size:0.8rem;",
              tags$img(
                src = rAvatar,
                class = "avatar avatar-xs rounded-circle",
                style = "width:18px;height:18px; box-shadow: 0 0 0 2px var(--tblr-bg-surface-secondary);"
              ),
              r$author
            ),
            div(
              style = "display:flex; gap:8px; align-items:center; position:relative;",
              span(
                style = "color:var(--tblr-secondary);font-weight:normal;font-size:0.7rem;",
                r$timestamp
              ),
              div(
                class = "dropdown",
                style = "position:static;",
                tags$a(
                  class = "text-muted",
                  href = "javascript:void(0);",
                  `data-bs-toggle` = "dropdown",
                  onclick = "event.stopPropagation()",
                  tags$i(class = "fa-solid fa-ellipsis-vertical")
                ),
                div(
                  class = "dropdown-menu dropdown-menu-end",
                  if (!isResolved) {
                    tags$a(
                      class = "dropdown-item",
                      onclick = sprintf(
                        "event.stopPropagation(); Shiny.setInputValue('replyToReplyTrigger', {commentId: '%s', replyId: '%s', author: '%s'}, {priority:'event'})",
                        commentId,
                        r$id,
                        r$author
                      ),
                      "Reply"
                    )
                  },
                  if (canEditReply) {
                    tags$a(
                      class = "dropdown-item",
                      onclick = sprintf(
                        "event.stopPropagation(); Shiny.setInputValue('editReplyTrigger', {commentId: '%s', replyId: '%s'}, {priority:'event'})",
                        commentId,
                        r$id
                      ),
                      "Edit"
                    )
                  },
                  tags$a(
                    class = "dropdown-item text-danger",
                    onclick = sprintf(
                      "event.stopPropagation(); if(confirm('Delete reply?')) Shiny.setInputValue('deleteReply', {commentId: '%s', replyId: '%s'}, {priority:'event'})",
                      commentId,
                      r$id
                    ),
                    "Delete"
                  )
                )
              )
            )
          ),
          if (isTRUE(r$isEditing)) {
            div(
              onclick = "event.stopPropagation()",
              class = "mt-1",
              tags$textarea(
                id = paste0("reply-edit-", r$id),
                class = "reply-textarea",
                rows = 1,
                r$content
              ),
              div(
                class = "text-end mt-2 d-flex gap-2 justify-content-end",
                tags$button(
                  "Cancel",
                  class = "btn btn-sm btn-xs btn-secondary",
                  onclick = sprintf(
                    "Shiny.setInputValue('cancelReplyEdit', {commentId: '%s', replyId: '%s'}, {priority:'event'})",
                    commentId,
                    r$id
                  )
                ),
                tags$button(
                  "Save",
                  class = "btn btn-sm btn-xs btn-primary",
                  onclick = sprintf(
                    "Shiny.setInputValue('saveReplyContent', {commentId: '%s', replyId: '%s', content: document.getElementById('reply-edit-%s').value}, {priority:'event'})",
                    commentId,
                    r$id,
                    r$id
                  )
                )
              )
            )
          } else {
            div(
              style = "padding-left:26px; color:var(--tblr-body-color);",
              r$content
            )
          },
          if (!isResolved) {
            div(
              id = paste0("reply-box-", r$id),
              class = "d-none mt-2 ps-4",
              onclick = "event.stopPropagation();",
              tags$textarea(
                id = paste0("reply-input-", r$id),
                class = "reply-textarea",
                rows = 1,
                placeholder = "Write a reply..."
              ),
              div(
                class = "text-end mt-1 d-flex gap-2 justify-content-end",
                tags$button(
                  "Cancel",
                  class = "btn btn-sm btn-xs btn-secondary",
                  onclick = sprintf(
                    "event.stopPropagation(); Shiny.setInputValue('cancelReply', {replyParentId: '%s'}, {priority:'event'}); this.parentElement.parentElement.classList.add('d-none'); document.getElementById('reply-input-%s').value = '';",
                    r$id,
                    r$id
                  )
                ),
                tags$button(
                  "Post",
                  class = "btn btn-sm btn-xs btn-primary",
                  onclick = sprintf(
                    "Shiny.setInputValue('postReply', {replyParentId: '%s', replyContent: document.getElementById('reply-input-%s').value}, {priority:'event'})",
                    r$id,
                    r$id
                  )
                )
              )
            )
          },
          if (!is.null(r$replies) && length(r$replies) > 0) {
            render_replies_recursive(r$replies, isResolved, commentId)
          }
        )
      })
    }

    # --- RENDER MAIN LIST (Cleaned of editedAt logic) ---
    lapply(display_cmts, function(c) {
      isResolved <- isTRUE(c$resolved)

      # Logic: If resolved, card is NOT active/clickable for jump
      cardClass <- paste0(
        "comment-card",
        if (isResolved) " resolved" else "",
        if (isTRUE(c$isEditing)) " editing" else ""
      )

      # Logic: Only generate onclick jump if NOT resolved
      cardOnClick <- if (isResolved) {
        "" # No action on click
      } else {
        sprintf("jumpToCode('%s')", c$id)
      }

      div(
        class = cardClass,
        id = paste0("card-", c$id),
        onclick = cardOnClick, # Apply logic here

        # Header
        div(
          class = "comment-header",
          div(
            class = "comment-user",
            tags$img(
              src = if (!is.null(c$avatar) && nzchar(c$avatar)) {
                c$avatar
              } else {
                "https://via.placeholder.com/32"
              },
              class = "avatar avatar-xs rounded-circle"
            ),
            span(c$author)
          ),
          div(
            class = "comment-meta",
            c$timestamp,
            div(
              class = "dropdown",
              style = "position:static;",
              tags$a(
                class = "text-muted",
                href = "javascript:void(0);",
                `data-bs-toggle` = "dropdown",
                onclick = "event.stopPropagation()",
                tags$i(class = "fa-solid fa-ellipsis-vertical")
              ),
              div(
                class = "dropdown-menu dropdown-menu-end",
                if (c$author == currentUser$username && !isResolved) {
                  tags$a(
                    class = "dropdown-item",
                    onclick = sprintf(
                      "event.stopPropagation(); Shiny.setInputValue('editCommentTrigger', '%s', {priority:'event'})",
                      c$id
                    ),
                    "Edit"
                  )
                },
                tags$a(
                  class = "dropdown-item text-danger",
                  onclick = sprintf(
                    "event.stopPropagation(); Shiny.setInputValue('deleteComment', '%s', {priority:'event'})",
                    c$id
                  ),
                  "Delete"
                ),
                if (isResolved) {
                  tags$a(
                    class = "dropdown-item",
                    onclick = sprintf(
                      "event.stopPropagation(); Shiny.setInputValue('resolveComment', '%s', {priority:'event'})",
                      c$id
                    ),
                    "Re-open"
                  )
                }
              )
            )
          )
        ),

        # Body
        if (isTRUE(c$isEditing)) {
          div(
            onclick = "event.stopPropagation()",
            tags$textarea(
              id = paste0("txt-", c$id),
              class = "reply-textarea",
              rows = 1,
              c$content
            ),
            div(
              class = "d-flex gap-2 mt-2",
              tags$button(
                "Cancel",
                class = "btn btn-sm btn-secondary",
                onclick = sprintf(
                  "Shiny.setInputValue('cancelCommentEdit', '%s', {priority:'event'})",
                  c$id
                )
              ),
              tags$button(
                "Save",
                class = "btn btn-sm btn-primary",
                onclick = sprintf(
                  "Shiny.setInputValue('saveCommentContent', {commentId: '%s', commentContent: document.getElementById('txt-%s').value}, {priority:'event'})",
                  c$id,
                  c$id
                )
              )
            )
          )
        } else {
          div(class = "comment-body", c$content)
        },

        # Replies
        if (length(c$replies) > 0) {
          div(
            class = "reply-thread",
            render_replies_recursive(c$replies, isResolved, c$id)
          )
        },

        # Footer Actions (Only for Active comments)
        if (!isResolved && !isTRUE(c$isEditing)) {
          div(
            class = "comment-actions",
            tags$button(
              class = "cmd-btn",
              onclick = sprintf(
                "event.stopPropagation(); document.getElementById('reply-area-%s').classList.toggle('show'); document.getElementById('reply-val-%s').focus();",
                c$id,
                c$id
              ),
              icon("reply"),
              " Reply"
            ),
            tags$button(
              class = "cmd-btn resolve",
              onclick = sprintf(
                "event.stopPropagation(); Shiny.setInputValue('resolveComment', '%s', {priority:'event'})",
                c$id
              ),
              icon("check"),
              " Resolve"
            )
          )
        },

        # Main Reply Box
        if (!isResolved) {
          div(
            id = paste0("reply-area-", c$id),
            class = "reply-input-area",
            onclick = "event.stopPropagation()",
            tags$textarea(
              id = paste0("reply-val-", c$id),
              class = "reply-textarea",
              rows = 1,
              placeholder = "Reply to main comment..."
            ),
            div(
              class = "d-flex gap-2 justify-content-end mt-2",
              tags$button(
                class = "btn btn-sm btn-secondary",
                onclick = sprintf(
                  "event.stopPropagation(); Shiny.setInputValue('cancelReply', {replyParentId: '%s'}, {priority:'event'}); document.getElementById('reply-area-%s').classList.remove('show'); document.getElementById('reply-val-%s').value = '';",
                  c$id,
                  c$id,
                  c$id
                ),
                "Cancel"
              ),
              tags$button(
                class = "btn btn-sm btn-primary",
                onclick = sprintf(
                  "Shiny.setInputValue('postReply', {replyParentId: '%s', replyContent: document.getElementById('reply-val-%s').value}, {priority:'event'})",
                  c$id,
                  c$id
                ),
                "Post"
              )
            )
          )
        }
      )
    })
  })

  # Ensure comments/highlights render even if pane is initially closed
  outputOptions(output, "commentStream", suspendWhenHidden = FALSE)

  # --- 6. COORDINATE SYNC (PERSISTENCE FIX) ---
  observeEvent(
    input$updateCommentCoordinates,
    {
      # 1. STATE CHECK (The Fix)
      # If the editor is not effectively active, IGNORE this update completely.
      # We do NOT reset this flag here. It stays FALSE until a project is loaded.
      if (isFALSE(rv$editor_active)) {
        return()
      }

      # 2. LEGACY FLAG CHECK (Optional, keep if you use it elsewhere)
      if (isTRUE(rv$block_comment_update)) {
        rv$block_comment_update <- FALSE
        return()
      }

      raw_input <- input$updateCommentCoordinates

      # 3. GARBAGE DATA CHECK (Double safety)
      # When editor hides, Ace often sends "[]" or empty strings.
      if (
        !is.null(raw_input) && is.character(raw_input) && length(raw_input) == 1
      ) {
        if (raw_input == "[]" || raw_input == "") return()
      }

      cat(
        "DEBUG: raw_input type =",
        class(raw_input),
        "| length =",
        length(raw_input),
        "\n"
      )
      if (length(raw_input) > 0) {
        cat("DEBUG: first element preview:", substr(raw_input[1], 1, 80), "\n")
      }

      # ONLY accept if it's a single JSON string
      if (!is.character(raw_input) || length(raw_input) != 1) {
        return()
      }

      json_str <- trimws(raw_input[1])
      if (nchar(json_str) == 0 || json_str == "[]") {
        return()
      }

      # Parse JSON
      updates <- tryCatch(
        {
          jsonlite::fromJSON(json_str, simplifyVector = FALSE)
        },
        error = function(e) {
          return(NULL)
        }
      )

      if (is.null(updates) || length(updates) == 0) {
        return()
      }

      # Ensure it's a list (even if single obj)
      if (!is.list(updates)) {
        updates <- list(updates)
      }

      projId <- activeProjectId()
      filePath <- currentFile()
      if (is.null(projId) || is.null(filePath)) {
        return()
      }

      cmts <- loadComments(projId, filePath)
      data_changed <- FALSE

      for (u in updates) {
        # Safety: only process if u is list/df and has 'id'
        if (!is.list(u) || is.null(u$id)) {
          next
        }

        for (i in seq_along(cmts)) {
          if (
            is.list(cmts[[i]]) && !is.null(cmts[[i]]$id) && cmts[[i]]$id == u$id
          ) {
            # Explicit integer coercion
            cmts[[i]]$startRow <- as.integer(u$startRow)
            cmts[[i]]$startCol <- as.integer(u$startCol)
            cmts[[i]]$endRow <- as.integer(u$endRow)
            cmts[[i]]$endCol <- as.integer(u$endCol)
            data_changed <- TRUE
            cat(
              "💾 Updated comment",
              u$id,
              "→ R[",
              u$startRow,
              ",",
              u$startCol,
              "]-[",
              u$endRow,
              ",",
              u$endCol,
              "]\n"
            )
            break
          }
        }
      }

      if (data_changed) {
        saveComments(projId, filePath, cmts)
        cat(
          "✅ Synced",
          length(updates),
          "comment(s) to disk for",
          filePath,
          "\n"
        )
      } else {
        cat("ℹ️  No coordinate changes needed\n")
      }
    },
    ignoreInit = TRUE
  )

  # --- CRITICAL: Render Markers on File Load or Editor Ready ---
  observeEvent(
    {
      list(currentFile(), input$aceEditorReady, input$toggleReviewPane)
    },
    {
      req(activeProjectId(), currentFile())

      # Load data
      cmts <- loadComments(activeProjectId(), currentFile())

      # Send to JS with Force=TRUE to ensure anchors are reset to disk state on file load
      session$sendCustomMessage(
        "renderCommentMarkers",
        list(
          comments = cmts,
          force = TRUE
        )
      )

      # Trigger sidebar refresh without full reload
      commentUpdate(commentUpdate() + 1)
    }
  )

  # ---------------- REWORKED SYNCTEX LOGIC ----------------
  observeEvent(input$syncTexClick, {
    req(input$syncTexClick)

    # 1. Capture Inputs
    click_page <- input$syncTexClick$page
    click_x <- input$syncTexClick$x
    click_y <- input$syncTexClick$y
    select_text <- input$syncTexClick$selectText

    # 2. Validation: Ensure Synctex file exists
    uid <- isolate(user_session$user_info$user_id)
    if (is.null(uid)) {
      return()
    } # Should not happen if authenticated

    uCompiledDir <- getUserCompiledDir(uid)
    synctex_file <- file.path(uCompiledDir, "output.synctex.gz")

    if (!file.exists(synctex_file)) {
      showTablerAlert(
        "warning",
        "SyncTeX unavailable",
        "Please compile with SyncTeX enabled first.",
        5000
      )
      return()
    }

    # 3. Run Synctex in Docker
    tryCatch(
      {
        res <- processx::run(
          "docker",
          args = c(
            "run",
            "--rm",
            "-v",
            paste0(normalizePath(uCompiledDir, winslash = "/"), ":/compiled"),
            "-w",
            "/compiled",
            "texlive/texlive",
            "synctex",
            "edit",
            "-o",
            paste0(click_page, ":", click_x, ":", click_y, ":output.pdf")
          ),
          error_on_status = FALSE
        )

        output_str <- res$stdout

        # 4. Parse Output Robustly
        lines <- unlist(strsplit(output_str, "\n"))
          input_line <- grep("^Input:", lines, value = TRUE)
          line_num_line <- grep("^Line:", lines, value = TRUE)
          col_num_line <- grep("^Column:", lines, value = TRUE)

          if (length(input_line) > 0 && length(line_num_line) > 0) {
            # Extract raw values
            raw_file <- sub("^Input:", "", input_line[1])
            raw_line <- sub("^Line:", "", line_num_line[1])
            raw_column <- if (length(col_num_line) > 0) sub("^Column:", "", col_num_line[1]) else "0"

            # Clean path (remove ./ prefix if present)
            detected_file <- trimws(sub("^\\./", "", raw_file))
            target_line <- as.integer(trimws(raw_line))
            target_column <- as.integer(trimws(raw_column))

          if (nzchar(detected_file) && !is.na(target_line) && target_line > 0) {
            # 5. Path Resolution Strategy
            projDir <- getActiveProjectDir()

            # Get all project files
            all_files <- list.files(projDir, recursive = TRUE)

            # --- CRITICAL FIX: Strictly Exclude compiled_cache from resolution ---
            # This ensures we NEVER match the temporary backup files
            all_files <- all_files[!grepl("^compiled_cache/|/\\.", all_files)]
            # ---------------------------------------------------------------------

            # Check direct match first
            final_rel_path <- NULL

            if (detected_file %in% all_files) {
              final_rel_path <- detected_file
            } else {
              # Fallback: Match by basename (e.g. if Docker path is absolute or different)
              matches <- grep(
                paste0(basename(detected_file), "$"),
                all_files,
                value = TRUE
              )
              if (length(matches) > 0) {
                # Pick the shortest match (usually the one in root) to avoid confusion
                matches <- matches[order(nchar(matches))]
                final_rel_path <- matches[1]
              }
            }

            if (!is.null(final_rel_path)) {
              # Force close any active file preview (fallback to editor) ---
              # We pass final_rel_path so the sidebar highlights the correct file immediately
              session$sendCustomMessage(
                "hideFilePreview",
                list(path = final_rel_path)
              )

              # 6. Execute Jump
              if (currentFile() != final_rel_path) {
                # Load file via JS trigger (handles editor mode, content, etc.)
                shinyjs::runjs(sprintf(
                  "if(window.Shiny) Shiny.setInputValue('fileClick', {path: '%s', isEditable: true, gotoLine: %d, gotoColumn: %d, selectText: '%s', context: 'synctex', nonce: Math.random()}, {priority: 'event'});",
                  final_rel_path,
                  target_line - 1,
                  target_column,
                  gsub("'", "\\\\'", select_text)
                ))
              } else {
                session$sendCustomMessage(
                  'aceGoTo',
                  list(
                    line = target_line - 1,
                    column = target_column,
                    selectText = select_text
                  )
                )
              }
            } else {}
          }
        }
      },
      error = function(e) {}
    )
  })

  # ---------------- FORWARD SEARCH (Editor -> PDF) ----------------
  observeEvent(input$editorSyncClick, {
    req(input$editorSyncClick)

    # 1. Collapse the Docker Console (maximize PDF height)
    # 2. Open the PDF Pane if it's currently hidden (maximize PDF visibility)
    shinyjs::runjs(
      "
      // 1. Vertical Split: Collapse Console
      if (window.consolePane) {
        window.consolePane.collapse();
      }
      
      // 2. Horizontal Split: Open PDF Sidebar if hidden
      if (typeof mainSplit !== 'undefined') {
        var sizes = mainSplit.getSizes();
        // If PDF pane (index 2) is less than 1% width, it's closed. Toggle it open.
        if (sizes[2] < 1) {
           window.togglePDF();
        }
      }
    "
    )
    # --------------------------------

    line <- as.integer(input$editorSyncClick$line)
    col <- as.integer(input$editorSyncClick$column)
    fileRelPath <- currentFile()

    if (is.null(fileRelPath) || fileRelPath == "") {
      return()
    }

    # Docker needs to see the file exactly as it was compiled.

    tryCatch(
      {
        uid <- isolate(user_session$user_info$user_id)
        if (is.null(uid)) {
          stop("User not logged in")
        }
        uCompiledDir <- getUserCompiledDir(uid)

        res <- processx::run(
          "docker",
          args = c(
            "run",
            "--rm",
            "-v",
            paste0(normalizePath(uCompiledDir, winslash = "/"), ":/compiled"),
            "-w",
            "/compiled",
            "texlive/texlive",
            "synctex",
            "view",
            # Pass column number explicitly: line:column:file
            "-i",
            paste0(line, ":", col, ":", fileRelPath),
            "-o",
            "output.pdf"
          ),
          error_on_status = FALSE
        )

        output_str <- res$stdout

        # Parse Result
        page_match <- regmatches(
          output_str,
          regexec("Page:([0-9]+)", output_str)
        )[[1]]
        x_match <- regmatches(
          output_str,
          regexec("x:([0-9\\.]+)", output_str)
        )[[1]]
        y_match <- regmatches(
          output_str,
          regexec("y:([0-9\\.]+)", output_str)
        )[[1]]

        if (length(page_match) > 1) {
          target_page <- as.numeric(page_match[2])
          target_x <- as.numeric(x_match[2])
          target_y <- as.numeric(y_match[2])

          # Send to Viewer
          session$sendCustomMessage(
            "syncPdfView",
            list(
              page = target_page,
              x = target_x,
              y = target_y
            )
          )
        } else {}
      },
      error = function(e) {}
    )
  })

