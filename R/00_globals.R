# =============================================================================
# 00_globals.R
# Libraries, global options, and shared constants.
# Sourced first by app.R so every other module can rely on these symbols.
# =============================================================================

# ----------------------------- LIBRARIES ------------------------------------
library(shiny)
library(shinyAce)
library(processx)
library(later)
library(jsonlite)
library(shinyjs)
library(magrittr)
library(base64enc)
library(DBI)
library(RSQLite)
library(sodium)
library(blastula)  # Required for emails
library(jose)      # Required for decoding ID tokens
library(callr)
library(digest)
library(httr2)
library(promises)
library(future)
library(mailR)
library(dotenv)
load_dot_env()

# ----------------------------- OPTIONS --------------------------------------
options(shiny.maxRequestSize = 100 * 1024^2)

# ----------------------------- CONSTANTS ------------------------------------

# File extensions that should be treated as plain-text and opened in the editor
text_extensions <- c(
  # LaTeX & Typesetting (High Confidence)
  "tex",
  "bib",
  "bst",
  "cls",
  "cfg",
  "sty",
  "rnw",
  "tikz",
  "dtx",
  "ins",
  "ltx",
  "clo",
  "def",
  "toc",
  "ind",
  "idx",
  "nav",
  "snm",

  # Documentation & Lightweight Markup
  "txt",
  "md",
  "markdown",
  "rmd",
  "qmd",
  "rst",
  "adoc",
  "asciidoc",
  "org",
  "norg",

  # Standard Programming (Source Code Only)
  "r",
  "py",
  "c",
  "cpp",
  "h",
  "hpp",
  "java",
  "js",
  "ts",
  "css",
  "scss",
  "html",
  "xml",
  "json",
  "sql",
  "lua",
  "jl",
  "m",

  # Data & Config (Non-Executable)
  "csv",
  "tsv",
  "yaml",
  "yml",
  "ini",
  "toml",
  "jsonl",
  "dat",
  "bibtool",

  # Build & Project Metadata (Plain Text)
  "gitignore",
  "editorconfig",
  "makefile",
  "latexmkrc",
  "dot",
  "mermaid"
)
