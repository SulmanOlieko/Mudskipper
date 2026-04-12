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
    
    streamLog("[STATUS] Syncing")
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
      steps[[length(steps) + 1]] <- "echo '[STATUS] Pass #1' ; "
      steps[[length(steps) + 1]] <- paste(
        compile_cmd, base_flags, "-synctex=1",
        output_dir_flag, shQuote(mainFile)
      )
    } else {
      # Step A: Draft pass
      steps[[length(steps) + 1]] <- "echo '[STATUS] Pass #1' ; "
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
        
        steps[[length(steps) + 1]] <- "echo '[STATUS] Pass #2' ; "
        steps[[length(steps) + 1]] <- bibtex_cmd
        streamLog(sprintf(">> BibTeX BIBINPUTS: %s", bibinputs))
      }
      
      # Step C: Resolution pass
      if (length(steps) > 0 && steps[[length(steps)]] != "&&") {
        steps[[length(steps) + 1]] <- chain_sep
      }
      steps[[length(steps) + 1]] <- "echo '[STATUS] Pass #3' ; "
      steps[[length(steps) + 1]] <- paste(
        compile_cmd, base_flags,
        output_dir_flag, shQuote(mainFile)
      )
      
      # Step D: Final pass
      if (length(steps) > 0 && steps[[length(steps)]] != "&&") {
        steps[[length(steps) + 1]] <- chain_sep
      }
      steps[[length(steps) + 1]] <- "echo '[STATUS] Pass #4' ; "
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
    
    # Attempt to copy the log file out regardless of success
    candidate_log <- file.path(sandbox, mainFile_dir,
                               sub("\\.tex$", ".log", mainFile_base))
    fallback_log  <- file.path(sandbox, "output.log")
    log_to_copy   <- if (file.exists(candidate_log)) candidate_log else fallback_log
    
    if (file.exists(log_to_copy)) {
      # For success, save as output.log so server can parse warnings
      file.copy(log_to_copy, file.path(compiledDir, "output.log"), overwrite = TRUE)
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
      if (file.exists(log_to_copy)) {
        # Keep error.log copy for backwards compatibility with error state UI
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

  # 1. PRIORITY: Check for "-file-line-error" format
  idx1 <- grep("^.*?:[0-9]+: ", lines)
  for (i in seq_along(idx1)) {
    line <- lines[idx1[i]]
    match <- regexec("^.*?:([0-9]+): (.*)$", line)
    parts <- regmatches(line, match)[[1]]
    if (length(parts) == 3) {
      msg <- parts[3]
      type <- "error"
      if (grepl("Warning|Info", msg, ignore.case = TRUE)) type <- "warning"
      annotations[[length(annotations) + 1]] <- list(row = max(0, as.numeric(parts[2]) - 1), column = 0, text = trimws(msg), type = type)
    }
  }

  # 2. Traditional LaTeX Errors ("! Error")
  idx2 <- grep("^! ", lines)
  for (i in seq_along(idx2)) {
    line_idx <- idx2[i]
    if (line_idx %in% idx1) next # Skip if already processed
    msg <- sub("^! ", "", lines[line_idx])
    line_num <- 0
    # Search next 5 lines
    for (j in 1:6) {
      if (line_idx + j <= length(lines)) {
        if (grepl("^l\\.[0-9]+", lines[line_idx + j])) {
          line_num <- as.numeric(sub("^l\\.([0-9]+).*", "\\1", lines[line_idx + j]))
          break
        }
      }
    }
    annotations[[length(annotations) + 1]] <- list(row = max(0, line_num - 1), column = 0, text = msg, type = "error")
  }

  # 3. LaTeX Warnings
  idx3 <- grep("LaTeX Warning:", lines)
  for (i in seq_along(idx3)) {
    line <- lines[idx3[i]]
    if (grepl("input line [0-9]+", line)) {
      line_num <- as.numeric(sub(".*input line ([0-9]+).*", "\\1", line))
      msg <- sub("LaTeX Warning: (.*) on input line.*", "\\1", line)
      annotations[[length(annotations) + 1]] <- list(row = max(0, line_num - 1), column = 0, text = trimws(msg), type = "warning")
    } else {
      msg <- sub("LaTeX Warning: ", "", line)
      annotations[[length(annotations) + 1]] <- list(row = 0, column = 0, text = trimws(msg), type = "warning")
    }
  }

  # 3.5 Package Warnings
  idx35 <- grep("Package [A-Za-z0-9_-]+ Warning:", lines, ignore.case = TRUE)
  for (i in seq_along(idx35)) {
    line_idx <- idx35[i]
    line <- lines[line_idx]
    pkg <- sub("Package ([A-Za-z0-9_-]+) Warning:.*", "\\1", line, ignore.case = TRUE)
    msg <- sub(paste0("Package ", pkg, " Warning: "), "", line, ignore.case = TRUE)
    line_num <- 0
    for (j in 1:4) {
      if (line_idx + j <= length(lines)) {
        next_line <- lines[line_idx + j]
        if (grepl("on input line [0-9]+", next_line) || grepl("on line [0-9]+", next_line)) {
          line_num <- as.numeric(sub(".*line ([0-9]+).*", "\\1", next_line))
          break
        } else if (nzchar(trimws(next_line))) {
          msg <- paste(msg, trimws(next_line))
        }
      }
    }
    annotations[[length(annotations) + 1]] <- list(row = max(0, line_num - 1), column = 0, text = trimws(paste0("[", pkg, "] ", msg)), type = "warning")
  }

  # 4. Bad Boxes
  idx4 <- grep("(Overfull|Underfull) \\\\(hbox|vbox)", lines)
  for (i in seq_along(idx4)) {
    line <- lines[idx4[i]]
    line_num <- 0
    lines_match <- regmatches(line, regexpr("lines? ([0-9]+)", line))
    if (length(lines_match) > 0) {
      line_num <- as.numeric(sub("lines? ", "", lines_match))
    }
    is_over <- grepl("Overfull", line)
    type <- if (is_over) "warning" else "info"
    annotations[[length(annotations) + 1]] <- list(row = max(0, line_num - 1), column = 0, text = line, type = type)
  }

  # 5. Missing Files
  idx5 <- grep("File `.*' not found", lines)
  for (i in seq_along(idx5)) {
    fname <- sub(".*File `(.*?)' not found.*", "\\1", lines[idx5[i]])
    annotations[[length(annotations) + 1]] <- list(row = 0, column = 0, text = paste("Missing file:", fname), type = "error")
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

# =================== HELPER: CHKTEX LINTER ===================
run_chktex <- function(projDir, fileRelPath) {
  # Run chktex via Docker
  cmd <- c(
    "run", "--rm",
    "-v", paste0(projDir, ":/workdir"),
    "-w", "/workdir",
    "texlive/texlive:latest",
    "chktex", "-q", "-v0", "-I0", "-f", "%l:%c:%d:%k:%n:%m\n", fileRelPath
  )
  
  res <- tryCatch({
    processx::run("docker", cmd, error_on_status = FALSE, timeout = 10)
  }, error = function(e) { NULL })
  
  if (is.null(res)) return(list())
  
  # Parse output
  # Format: "line:column:length:type:code:message"
  # e.g., "12:5:3:Warning:1:Command terminated with space."
  lines <- strsplit(res$stdout, "\n")[[1]]
  annotations <- list()
  for (line in lines) {
    if (!nzchar(trimws(line))) next
    parts <- strsplit(line, ":")[[1]]
    if (length(parts) >= 6) {
      row <- as.numeric(parts[1]) - 1
      col <- as.numeric(parts[2]) - 1
      len <- as.numeric(parts[3])
      msg_type <- tolower(parts[4])
      code <- parts[5]
      msg <- paste(parts[6:length(parts)], collapse = ":")
      
      annotations[[length(annotations) + 1]] <- list(
        row = max(0, row),
        column = max(0, col),
        text = trimws(msg),
        type = "warning"
      )
    }
  }
  return(annotations)
}
