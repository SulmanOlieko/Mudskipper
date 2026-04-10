# ----------------------------- BACKGROUND WORKER (ROBUST CHAIN) -----------------------------
compile_bg_task <- function(
    projDir,
    mainFile,
    compiledDir,
    compileMode = "normal",
    syntaxCheck = "none",
    errorHandling = "tryCompile"
) {

  sandbox <- NULL
  logFile <- file.path(compiledDir, "compile_job.log")
  
  streamLog <- function(msg) {
    ts <- format(Sys.time(), "%Y-%m-%d %H:%M:%OS3")
    cat(sprintf("[%s] %s\n", ts, msg), file = logFile, append = TRUE)
  }
  
  cleanup_sandbox <- function(dir) {
    if (!is.null(dir) && dir.exists(dir)) {
      unlink(dir, recursive = TRUE, force = TRUE)
    }
  }
  
  ensure_images_exist <- function(sandbox, mainFile) {
    texPath <- file.path(sandbox, mainFile)
    if (!file.exists(texPath)) return()
    tryCatch({
      all_tex <- list.files(sandbox, pattern = "\\.tex$",
                            recursive = TRUE, full.names = TRUE)
      content <- unlist(lapply(all_tex, function(f) {
        readLines(f, warn = FALSE, encoding = "UTF-8")
      }))
      pattern   <- "\\\\includegraphics(?:\\s*\\[.*?\\])?\\s*\\{(.*?)\\}"
      matches   <- gregexpr(pattern, content, perl = TRUE)
      extracted <- unlist(regmatches(content, matches))
      if (length(extracted) == 0) return()
      refs <- unique(sub(pattern, "\\1", extracted, perl = TRUE))
      exts <- c("", ".png", ".jpg", ".jpeg", ".pdf", ".eps")
      for (ref in refs) {
        exists      <- FALSE
        main_dir    <- dirname(file.path(sandbox, mainFile))
        search_bases <- unique(c(sandbox, main_dir))
        for (base in search_bases) {
          for (e in exts) {
            if (file.exists(file.path(base, paste0(ref, e)))) {
              exists <- TRUE; break
            }
          }
          if (exists) break
        }
        if (!exists) {
          all_files <- list.files(sandbox, recursive = TRUE)
          for (e in exts) {
            target    <- paste0(ref, e)
            match_idx <- which(tolower(all_files) == tolower(target))
            if (length(match_idx) > 0) {
              actual <- all_files[match_idx[1]]
              if (actual != target) {
                dir.create(dirname(file.path(sandbox, target)),
                           recursive = TRUE, showWarnings = FALSE)
                file.rename(file.path(sandbox, actual),
                            file.path(sandbox, target))
              }
              exists <- TRUE; break
            }
          }
        }
        if (!exists) {
          target_file      <- if (grepl("\\.[a-zA-Z]{3,4}$", ref)) ref else paste0(ref, ".png")
          full_target_path <- file.path(sandbox, target_file)
          dir.create(dirname(full_target_path), recursive = TRUE, showWarnings = FALSE)
          png_bytes <- as.raw(c(
            0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
            0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
            0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
            0xde, 0x00, 0x00, 0x00, 0x0c, 0x49, 0x44, 0x41,
            0x54, 0x08, 0xd7, 0x63, 0xf8, 0xcf, 0xc0, 0x00,
            0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xdd, 0x8d,
            0xb0, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e,
            0x44, 0xae, 0x42, 0x60, 0x82
          ))
          writeBin(png_bytes, full_target_path)
          streamLog(sprintf(">> Mocked missing image: %s", target_file))
        }
      }
    }, error = function(e) NULL)
  }
  
  result <- tryCatch({
    
    dir.create(compiledDir, showWarnings = FALSE, recursive = TRUE)
    if (file.exists(logFile)) cat("", file = logFile)
    
    streamLog(sprintf(
      "--- Worker Started: Mode=%s, Syntax=%s, Error=%s ---",
      compileMode, syntaxCheck, errorHandling
    ))
    
    sandbox <- file.path(compiledDir, "_sandbox")
    if (dir.exists(sandbox)) unlink(sandbox, recursive = TRUE, force = TRUE)
    dir.create(sandbox, showWarnings = FALSE, recursive = TRUE)
    sandbox <- normalizePath(sandbox, winslash = "/", mustWork = TRUE)
    
    projDir          <- normalizePath(projDir, winslash = "/")
    compiledDir_norm <- normalizePath(compiledDir, winslash = "/", mustWork = FALSE)
    
    exclude_dirs <- c(
      "compiled_cache", ".history", ".chat_files",
      ".git", ".svn", ".Rproj.user"
    )
    
    all_files  <- list.files(projDir, recursive = TRUE, full.names = TRUE)
    keep_files <- sapply(all_files, function(f) {
      f <- normalizePath(f, winslash = "/")
      if (startsWith(f, paste0(compiledDir_norm, "/"))) return(FALSE)
      rel_path        <- sub(paste0("^\\Q", projDir, "/\\E"), "", f, perl = TRUE)
      first_component <- strsplit(rel_path, "/")[[1]][1]
      !first_component %in% exclude_dirs
    })
    
    copied <- 0L
    for (src_path in all_files[keep_files]) {
      rel_path  <- sub(
        paste0("^\\Q", projDir, "/\\E"), "",
        normalizePath(src_path, winslash = "/"), perl = TRUE
      )
      dest_path <- file.path(sandbox, rel_path)
      dir.create(dirname(dest_path), recursive = TRUE, showWarnings = FALSE)
      file.copy(src_path, dest_path, overwrite = TRUE)
      copied <- copied + 1L
    }
    streamLog(sprintf(">> Copied %d file(s) into sandbox (full tree preserved).", copied))
    
    mainFile_abs <- file.path(sandbox, mainFile)
    if (!file.exists(mainFile_abs)) {
      stop(sprintf(
        "mainFile '%s' not found in sandbox after copy. Check that mainFile is a path relative to projDir.",
        mainFile
      ))
    }
    streamLog(sprintf(">> mainFile confirmed at: %s", mainFile_abs))
    
    junk <- list.files(
      sandbox,
      pattern    = "\\.(aux|toc|out|nav|snm|vrb|log|bbl|blg)$",
      full.names = TRUE,
      recursive  = TRUE
    )
    if (length(junk) > 0) unlink(junk)
    
    ensure_images_exist(sandbox, mainFile)
    
    raw            <- readLines(mainFile_abs, warn = FALSE, encoding = "UTF-8")
    detectedEngine <- "pdflatex"
    if (any(grepl("!T(?:e|E)X\\s+program\\s*=\\s*xelatex", raw, ignore.case = TRUE))) {
      detectedEngine <- "xelatex"
    } else if (any(grepl("!T(?:e|E)X\\s+program\\s*=\\s*lualatex", raw, ignore.case = TRUE))) {
      detectedEngine <- "lualatex"
    } else if (any(grepl("\\\\usepackage.*\\{fontspec\\}", raw))) {
      detectedEngine <- "xelatex"
    }
    streamLog(sprintf(">> Detected engine: %s", detectedEngine))
    
    content <- readLines(mainFile_abs, warn = FALSE, encoding = "UTF-8")
    doc_idx <- grep("\\\\documentclass", content)[1]
    if (!is.na(doc_idx)) {
      patches <- c()
      if (detectedEngine == "xelatex") {
        patches <- c(
          "\\PassOptionsToPackage{xetex}{geometry}",
          "\\PassOptionsToPackage{xetex}{hyperref}",
          "\\PassOptionsToPackage{xetex}{graphicx}",
          "\\PassOptionsToPackage{xetex}{beamerposter}"
        )
      }
      if (any(grepl("\\{beamer\\}", content[doc_idx]))) {
        patches <- c(patches,
                     "\\PassOptionsToPackage{bookmarks=true,pdfpagemode=UseOutlines}{hyperref}")
      }
      if (compileMode == "fast") {
        patches <- c(patches, "\\PassOptionsToPackage{draft}{graphicx}")
      }
      if (length(patches) > 0) {
        content <- if (doc_idx > 1) append(content, patches, after = doc_idx - 1) else c(patches, content)
        writeLines(content, mainFile_abs, useBytes = TRUE)
      }
    }
    
    user_id  <- suppressWarnings(system("id -u", intern = TRUE))
    if (length(user_id) == 0)  user_id  <- "1000"
    group_id <- suppressWarnings(system("id -g", intern = TRUE))
    if (length(group_id) == 0) group_id <- "1000"
    
    compile_cmd <- switch(detectedEngine,
                          "xelatex"  = "xelatex",
                          "lualatex" = "lualatex",
                          "pdflatex"
    )
    
    base_flags <- "-interaction=nonstopmode -file-line-error"
    chain_sep  <- if (errorHandling == "stopFirst") " && " else " ; "
    if (errorHandling == "stopFirst") base_flags <- paste(base_flags, "-halt-on-error")
    
    mainFile_dir  <- dirname(mainFile)   # e.g. "sections" or "."
    mainFile_base <- basename(mainFile)  # e.g. "main.tex"
    
    output_dir_flag <- if (mainFile_dir == ".") {
      ""
    } else {
      paste0("-output-directory=", shQuote(mainFile_dir))
    }
    
    steps <- list()
    
    if (syntaxCheck == "before") {
      steps[[length(steps) + 1]] <- paste(
        compile_cmd,
        "-interaction=nonstopmode -file-line-error -halt-on-error -no-pdf",
        output_dir_flag, shQuote(mainFile)
      )
      steps[[length(steps) + 1]] <- "&&"
    }
    
    if (compileMode == "fast") {
      steps[[length(steps) + 1]] <- paste(
        compile_cmd, base_flags, "-synctex=1",
        output_dir_flag, shQuote(mainFile)
      )
    } else {
      # Step A: Draft pass
      steps[[length(steps) + 1]] <- paste(
        compile_cmd, base_flags,
        output_dir_flag, shQuote(mainFile)
      )
      
      # Step B: BibTeX — find all .bib files recursively, expose via BIBINPUTS
      bib_files <- list.files(sandbox, pattern = "\\.bib$",
                              recursive = TRUE, full.names = TRUE)
      if (length(bib_files) > 0) {
        
        # Unique dirs holding .bib files, as /workdir-relative Docker paths
        bib_dirs     <- unique(dirname(bib_files))
        bib_dirs_rel <- sub(paste0("^\\Q", sandbox, "\\E/?"), "", bib_dirs, perl = TRUE)
        bib_dirs_rel[bib_dirs_rel == ""] <- "."
        bibinputs <- paste(
          c(paste0("/workdir/", bib_dirs_rel), "/workdir"),
          collapse = ":"
        )
        
        aux_base <- sub("\\.tex$", "", mainFile_base)  # stem only, no path
        
        if (length(steps) > 0 && steps[[length(steps)]] != "&&") {
          steps[[length(steps) + 1]] <- chain_sep
        }
        
        # cd into mainFile_dir so bibtex finds the .aux by stem alone,
        # then return to /workdir for subsequent LaTeX passes
        bibtex_cmd <- if (mainFile_dir == ".") {
          paste0(
            "BIBINPUTS=", shQuote(bibinputs), " ",
            "[ -f ", shQuote(paste0(aux_base, ".aux")), " ] && ",
            "bibtex ", shQuote(aux_base)
          )
        } else {
          paste0(
            "cd ", shQuote(mainFile_dir), " && ",
            "BIBINPUTS=", shQuote(bibinputs), " ",
            "[ -f ", shQuote(paste0(aux_base, ".aux")), " ] && ",
            "bibtex ", shQuote(aux_base), " && ",
            "cd /workdir"
          )
        }
        
        steps[[length(steps) + 1]] <- bibtex_cmd
        streamLog(sprintf(">> BibTeX BIBINPUTS: %s", bibinputs))
      }
      
      # Step C: Resolution pass
      if (length(steps) > 0 && steps[[length(steps)]] != "&&") {
        steps[[length(steps) + 1]] <- chain_sep
      }
      steps[[length(steps) + 1]] <- paste(
        compile_cmd, base_flags,
        output_dir_flag, shQuote(mainFile)
      )
      
      # Step D: Final pass
      if (length(steps) > 0 && steps[[length(steps)]] != "&&") {
        steps[[length(steps) + 1]] <- chain_sep
      }
      steps[[length(steps) + 1]] <- paste(
        compile_cmd, base_flags, "-synctex=1",
        output_dir_flag, shQuote(mainFile)
      )
    }
    
    cmd_chain <- paste(unlist(steps), collapse = "")
    
    docker_args <- c(
      "run", "--rm",
      "-v", paste0(sandbox, ":/workdir"),
      "-w", "/workdir",
      "-u", paste0(user_id, ":", group_id),
      "-e", "HOME=/workdir",
      "-e", "FONTCONFIG_PATH=/workdir/.fontconfig",
      "texlive/texlive:latest",
      "sh", "-c", cmd_chain
    )
    
    streamLog(sprintf(">> Engine: %s | Mode: %s | ErrorHandling: %s",
                      detectedEngine, compileMode, errorHandling))
    streamLog(">> Executing Chain...")
    
    res <- processx::run(
      "docker",
      args            = docker_args,
      wd              = sandbox,
      stdout          = logFile,
      stderr          = logFile,
      error_on_status = FALSE,
      timeout         = 900
    )
    
    exit_status  <- res$status
    expected_pdf <- file.path(sandbox, mainFile_dir,
                              sub("\\.tex$", ".pdf", mainFile_base))
    pdfSrc       <- file.path(sandbox, "output.pdf")
    
    if (file.exists(expected_pdf) && !file.exists(pdfSrc)) {
      file.rename(expected_pdf, pdfSrc)
    }
    
    if (!file.exists(pdfSrc) && detectedEngine == "xelatex") {
      xdvSrc <- file.path(sandbox, mainFile_dir,
                          sub("\\.tex$", ".xdv", mainFile_base))
      if (file.exists(xdvSrc)) {
        streamLog(">> Attempting XDV->PDF recovery...")
        processx::run(
          "docker",
          args = c(
            "run", "--rm",
            "-v", paste0(sandbox, ":/workdir"),
            "-w", "/workdir",
            "-u", paste0(user_id, ":", group_id),
            "texlive/texlive:latest",
            "xdvipdfmx", "-o", "output.pdf",
            file.path(mainFile_dir, sub("\\.tex$", ".xdv", mainFile_base))
          ),
          error_on_status = FALSE
        )
        if (file.exists(file.path(sandbox, "output.pdf"))) {
          pdfSrc <- file.path(sandbox, "output.pdf")
        }
      }
    }
    
    if (file.exists(pdfSrc)) {
      file.copy(pdfSrc, file.path(compiledDir, "output.pdf"), overwrite = TRUE)
      streamLog(">> PDF Exported.")
      synctexSrc <- file.path(sandbox, mainFile_dir,
                              sub("\\.tex$", ".synctex.gz", mainFile_base))
      if (file.exists(synctexSrc)) {
        file.copy(synctexSrc, file.path(compiledDir, "output.synctex.gz"),
                  overwrite = TRUE)
      }
      cleanup_sandbox(sandbox)
      return(list(success = TRUE, message = "Compilation successful."))
      
    } else {
      candidate_log <- file.path(sandbox, mainFile_dir,
                                 sub("\\.tex$", ".log", mainFile_base))
      fallback_log  <- file.path(sandbox, "output.log")
      log_to_copy   <- if (file.exists(candidate_log)) candidate_log else fallback_log
      if (file.exists(log_to_copy)) {
        file.copy(log_to_copy, file.path(compiledDir, "error.log"), overwrite = TRUE)
      }
      cleanup_sandbox(sandbox)
      msg <- if (exit_status != 0) {
        paste("Compilation failed (Exit Code", exit_status, ")")
      } else {
        "No PDF produced."
      }
      return(list(success = FALSE, message = msg))
    }
    
  }, error = function(e) {
    streamLog(sprintf("CRITICAL WORKER ERROR: %s", conditionMessage(e)))
    cleanup_sandbox(sandbox)
    return(list(success = FALSE, message = conditionMessage(e)))
  })
  
  return(result)
}
# =================== HELPER: LATEX LOG PARSER (UPDATED) ===================
parse_tex_log <- function(log_path) {
  if (!file.exists(log_path)) {
    return(list())
  }

  # Read the log file safe for binary/garbage characters
  lines <- readLines(log_path, warn = FALSE)
  # Sanitize encoding (Critical for log parsing stability)
  lines <- iconv(lines, to = "UTF-8", sub = "byte")

  annotations <- list()

  for (i in seq_along(lines)) {
    line <- lines[i]

    # --- 1. PRIORITY: Check for "-file-line-error" format ---
    # Matches: "./filename.tex:123: Message"
    # We use a robust regex that captures: (path):(line):(message)
    if (grepl("^.*?:[0-9]+: ", line)) {
      match <- regexec("^.*?:([0-9]+): (.*)$", line)
      parts <- regmatches(line, match)[[1]]

      if (length(parts) == 3) {
        line_num <- as.numeric(parts[2])
        msg <- parts[3]

        # Determine type: Downgrade "Warning" or "Info" texts to warning type
        type <- "error"
        if (
          grepl("Warning", msg, ignore.case = TRUE) ||
            grepl("Info", msg, ignore.case = TRUE)
        ) {
          type <- "warning"
        }

        annotations[[length(annotations) + 1]] <- list(
          row = max(0, line_num - 1), # Ace is 0-indexed
          column = 0,
          text = trimws(msg),
          type = type
        )
        # If we matched this format, skip the rest for this line
        next
      }
    }

    # --- 2. Traditional LaTeX Errors ("! Error") ---
    if (grepl("^! ", line)) {
      msg <- sub("^! ", "", line)
      line_num <- 0

      # Look ahead 1-5 lines for "l.123" pattern
      for (j in 1:5) {
        if (i + j <= length(lines)) {
          next_line <- lines[i + j]
          if (grepl("^l\\.[0-9]+", next_line)) {
            line_num <- as.numeric(sub("^l\\.([0-9]+).*", "\\1", next_line))
            break
          }
        }
      }

      annotations[[length(annotations) + 1]] <- list(
        row = max(0, line_num - 1),
        column = 0,
        text = msg,
        type = "error"
      )
    } else if (grepl("LaTeX Warning:", line)) {
      # --- 3. LaTeX Warnings ---
      if (grepl("input line [0-9]+", line)) {
        # Warning with line number
        line_num <- as.numeric(sub(".*input line ([0-9]+).*", "\\1", line))
        msg <- sub("LaTeX Warning: (.*) on input line.*", "\\1", line)

        annotations[[length(annotations) + 1]] <- list(
          row = max(0, line_num - 1),
          column = 0,
          text = trimws(msg),
          type = "warning"
        )
      } else {
        # Global warning (no line number)
        msg <- sub("LaTeX Warning: ", "", line)
        annotations[[length(annotations) + 1]] <- list(
          row = 0,
          column = 0,
          text = trimws(msg),
          type = "warning"
        )
      }
    } else if (grepl("(Overfull|Underfull) \\\\(hbox|vbox)", line)) {
      # --- 4. Bad Boxes (Overfull/Underfull) ---
      # Regex to grab the first number after "line" or "lines"
      line_num <- 0
      lines_match <- regmatches(line, regexpr("lines? ([0-9]+)", line))

      if (length(lines_match) > 0) {
        line_num <- as.numeric(sub("lines? ", "", lines_match))
      }

      is_over <- grepl("Overfull", line)
      # Overfull = warning (orange), Underfull = info (blue)
      type <- if (is_over) "warning" else "info"

      annotations[[length(annotations) + 1]] <- list(
        row = max(0, line_num - 1),
        column = 0,
        text = line,
        type = type
      )
    } else if (grepl("File `.*' not found", line)) {
      # --- 5. Critical Missing Files (Fallback) ---
      fname <- sub(".*File `(.*?)' not found.*", "\\1", line)
      annotations[[length(annotations) + 1]] <- list(
        row = 0,
        column = 0,
        text = paste("Missing file:", fname),
        type = "error"
      )
    }
  }

  return(annotations)
}

#-------------------------------SESSION ADDRESS-----------------------
# --- ROBUST IP DETECTION ---
# Check proxy headers first, then direct address
get_ip <- function(req) {
  if (is.null(req)) return("Unknown")
  
  # 1. Check X-Forwarded-For (Standard proxy header)
  if (!is.null(req$HTTP_X_FORWARDED_FOR)) {
    return(strsplit(req$HTTP_X_FORWARDED_FOR, ",")[[1]][1])
  }
  # 2. Check X-Real-IP (Nginx specific)
  if (!is.null(req$HTTP_X_REAL_IP)) {
    return(req$HTTP_X_REAL_IP)
  }
  # 3. Fallback to Remote Address
  if (!is.null(req$REMOTE_ADDR)) {
    return(req$REMOTE_ADDR)
  }
  return("Unknown")
}

