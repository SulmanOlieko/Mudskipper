# ------------------------------- UI -----------------------------------
app_ui <- fluidPage(
  # Main app content wrapped in container
  tags$div(
    id = "app-content",
    style = "padding: 0 !important; margin: 0 !important;",
    HTML(
      '
    <!-- Alert System Container -->
      <div id="alertContainer"
        class="alert-container"
        style="position: fixed; top: 80px; right: 20px; z-index: 1060; width: 400px; max-width: 90vw;">
      </div>
  '
    ),

    # --- UPDATED: Safer hiding method ---
    tags$div(
      style = "position: absolute; width: 0; height: 0; overflow: hidden;",
      downloadLink("global_project_download_link", ""),
      downloadLink("history_dl_btn", ""),
      downloadLink("pdf_download_link", "")
    ),

    # --- WORD COUNT OVERLAY ---
    div(
      id = "wordCountOverlay",
      div(
        class = "settings-dialog",
        style = "max-width: 1000px;",
        div(
          class = "settings-header",
          h3("Word count"),
          tags$button(
            type = "button",
            class = "btn-close",
            onclick = "closeWordCountOverlay()",
            `aria-label` = "Close"
          )
        ),
        div(
          class = "settings-body",
          style = "height: auto; overflow-y: auto;",
          div(
            class = "settings-content",
            style = "padding: 1.5rem;",

            # Summary Big Numbers
            div(
              class = "row text-center mb-4",
              div(
                class = "col-6 border-end",
                div(class = "text-secondary small text-uppercase", "Words"),
                div(
                  class = "text-secondary display-6 fw-bold",
                  id = "wc-total-words",
                  "0"
                )
              ),
              div(
                class = "col-6",
                div(
                  class = "text-secondary small text-uppercase",
                  "Characters"
                ),
                div(
                  class = "text-secondary display-6 fw-bold",
                  id = "wc-total-chars",
                  "0"
                )
              )
            ),

            # Detailed Table
            div(
              class = "table-responsive",
              tags$table(
                class = "table table-vcenter",
                tags$thead(
                  tags$tr(
                    class = "text-secondary text-uppercase",
                    tags$th(class = "text-secondary text-start", style = "border-bottom: 1px solid var(--tblr-border-color) !important;", "Element"),
                    tags$th(class = "text-secondary text-end", style = "border-bottom: 1px solid var(--tblr-border-color) !important;", "Words"),
                    tags$th(class = "text-secondary text-end", style = "border-bottom: 1px solid var(--tblr-border-color) !important;", "Characters")
                  )
                ),
                tags$tbody(
                  tags$tr(
                    class = "border-top",
                    tags$td("Main text"),
                    tags$td(
                      class = "text-secondary text-end",
                      id = "wc-main-words",
                      "0"
                    ),
                    tags$td(
                      class = "text-secondary text-end",
                      id = "wc-main-chars",
                      "0"
                    )
                  ),
                  tags$tr(
                    class = "border-top",
                    tags$td(HTML(
                      'Headers <span class="text-secondary ms-1" style="font-size:0.8em" id="wc-headers-count">(0)</span>'
                    )),
                    tags$td(
                      class = "text-secondary text-end",
                      id = "wc-headers-words",
                      "0"
                    ),
                    tags$td(
                      class = "text-secondary text-end",
                      id = "wc-headers-chars",
                      "0"
                    )
                  ),
                  tags$tr(
                    class = "border-top",
                    tags$td("Abstract"),
                    tags$td(
                      class = "text-secondary text-end",
                      id = "wc-abstract-words",
                      "0"
                    ),
                    tags$td(
                      class = "text-secondary text-end",
                      id = "wc-abstract-chars",
                      "0"
                    )
                  ),
                  tags$tr(
                    class = "border-top",
                    tags$td("Captions"),
                    tags$td(
                      class = "text-secondary text-end",
                      id = "wc-captions-words",
                      "0"
                    ),
                    tags$td(
                      class = "text-secondary text-end",
                      id = "wc-captions-chars",
                      "0"
                    )
                  ),
                  tags$tr(
                    class = "border-top",
                    tags$td("Footnotes"),
                    tags$td(
                      class = "text-secondary text-end",
                      id = "wc-footnotes-words",
                      "0"
                    ),
                    tags$td(
                      class = "text-secondary text-end",
                      id = "wc-footnotes-chars",
                      "0"
                    )
                  ),
                  tags$tr(
                    class = "border-top",
                    tags$td("Other"),
                    tags$td(
                      class = "text-secondary text-end",
                      id = "wc-other-words",
                      "0"
                    ),
                    tags$td(
                      class = "text-secondary text-end",
                      id = "wc-other-chars",
                      "0"
                    )
                  )
                )
              )
            ),

            # Math Stats
            div(
              class = "mt-3 pt-3 border-top d-flex justify-content-between text-secondary small",
              HTML(
                '<span>Inline math: <strong id="wc-math-inline" class="text-secondary text-body">0</strong></span>'
              ),
              HTML(
                '<span>Display math: <strong id="wc-math-display" class="text-secondary text-body">0</strong></span>'
              )
            )
          )
        )
      )
    ),
    tags$style(HTML(
      "
      #wordCountOverlay {
        position: fixed; top: 0; left: 0; right: 0; bottom: 0;
        width: 100%; height: 100%;
        background: rgba(0, 0, 0, 0.5);
        z-index: 1060;
        display: none; opacity: 0; transition: opacity 0.3s ease;
        align-items: center; justify-content: center;
      }
      #wordCountOverlay.show { display: flex; opacity: 1; }
    "
    )),
    HTML(
      '
     <!-- --- TABLE BUILDER --- -->
<div id="tableOverlay">
  <div class="settings-dialog" style="max-width: 1000px;">

    <!-- Header -->
    <div class="settings-header">
      <h3>Visual Table Builder</h3>

        <!-- --- TOOLBAR --- -->
        <nav class="nav nav-segmented nav-2" role="tablist">

          <!-- Bold -->
          <button
            class="nav-link"
            role="tab"
            data-bs-toggle="tab"
            aria-selected="false"
            tabindex="-1"
            onclick="formatCell(\'bold\')">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"
                 viewBox="0 0 24 24" fill="none" stroke="currentColor"
                 stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                 class="icon nav-link-icon icon-2">
              <path d="M7 5h6a3.5 3.5 0 0 1 0 7h-6z"></path>
              <path d="M13 12h1a3.5 3.5 0 0 1 0 7h-7v-7"></path>
            </svg>
          </button>

          <!-- Italic -->
          <button
            class="nav-link"
            role="tab"
            data-bs-toggle="tab"
            aria-selected="false"
            tabindex="-1"
            onclick="formatCell(\'italic\')">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"
                 viewBox="0 0 24 24" fill="none" stroke="currentColor"
                 stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                 class="icon nav-link-icon icon-2">
              <path d="M11 5l6 0"></path>
              <path d="M7 19l6 0"></path>
              <path d="M14 5l-4 14"></path>
            </svg>
          </button>

          <!-- Color picker -->
          <button
            class="nav-link"
            aria-selected="false"
            tabindex="-1">

            <input
              type="color"
              id="cellTextColor"
              value="#000000"
              class="form-control form-control-color"
              title="Text Color"
              oninput="formatCell(\'foreColor\', this.value)">
          </button>

          <!-- Clear grid -->
          <button
            class="nav-link"
            role="tab"
            data-bs-toggle="tab"
            aria-selected="false"
            aria-disabled="true"
            tabindex="-1"
            onclick="clearGrid()">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"
                 viewBox="0 0 24 24" fill="none" stroke="currentColor"
                 stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                 class="icon nav-link-icon icon-2">
              <path d="M4 7l16 0" />
              <path d="M10 11l0 6" />
              <path d="M14 11l0 6" />
              <path d="M5 7l1 12a2 2 0 0 0 2 2h8a2 2 0 0 0 2 -2l1 -12" />
              <path d="M9 7v-3a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v3" />
            </svg>
          </button>

          <!-- Insert table -->
          <button
            class="nav-link"
            role="tab"
            data-bs-toggle="tab"
            aria-selected="false"
            tabindex="-1"
            onclick="insertGeneratedTable()">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"
                 viewBox="0 0 24 24" fill="none" stroke="currentColor"
                 stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                 class="icon nav-link-icon icon-2">
              <path d="M12 5l0 14" />
              <path d="M5 12l14 0" />
            </svg>
          </button>
        </nav>

      <button
        type="button"
        class="btn-close"
        onclick="closeTableOverlay()"
        aria-label="Close">
      </button>
    </div>

    <!-- Body -->
    <div class="settings-body">
      <div
        class="settings-content"
        style="padding: 1.5rem; display: flex; flex-direction: column; align-items: center;"
      >

        <!-- --- GRID AREA --- -->
        <div class="builder-container">

          <div class="table-wrapper">
            <table id="visualTableGrid" class="visual-table"></table>
          </div>

          <!-- Column controls -->
          <div class="col-controls">
            <button
              class="btn btn-action" role="button"
              onclick="modifyGrid(\'add\', \'col\')">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"
                 viewBox="0 0 24 24" fill="none" stroke="currentColor"
                 stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                 class="icon nav-link-icon icon-2">
              <path d="M14 4h4a1 1 0 0 1 1 1v14a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1v-14a1 1 0 0 1 1 -1z" />
              <path d="M5 12l4 0" />
              <path d="M7 10l0 4" />
            </svg>
            </button>
            <button
              class="btn btn-action" role="button"
              onclick="modifyGrid(\'rem\', \'col\')">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"
                 viewBox="0 0 24 24" fill="none" stroke="currentColor"
                 stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                 class="icon nav-link-icon icon-2">
              <path d="M6 4h4a1 1 0 0 1 1 1v14a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1v-14a1 1 0 0 1 1 -1z" />
              <path d="M16 10l4 4" />
              <path d="M16 14l4 -4" />
            </svg>
            </button>
          </div>

          <!-- Row controls -->
          <div class="row-controls">
            <button
              class="btn btn-action" role="button"
              onclick="modifyGrid(\'add\', \'row\')">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"
                 viewBox="0 0 24 24" fill="none" stroke="currentColor"
                 stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                 class="icon nav-link-icon icon-2">
              <path d="M4 18v-4a1 1 0 0 1 1 -1h14a1 1 0 0 1 1 1v4a1 1 0 0 1 -1 1h-14a1 1 0 0 1 -1 -1z" />
              <path d="M12 9v-4" />
              <path d="M10 7l4 0" />
            </svg>
            </button>
            <button
              class="btn btn-action" role="button"
              onclick="modifyGrid(\'rem\', \'row\')">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"
                 viewBox="0 0 24 24" fill="none" stroke="currentColor"
                 stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                 class="icon nav-link-icon icon-2">
              <path d="M20 6v4a1 1 0 0 1 -1 1h-14a1 1 0 0 1 -1 -1v-4a1 1 0 0 1 1 -1h14a1 1 0 0 1 1 1z" />
              <path d="M10 16l4 4" />
              <path d="M10 20l4 -4" />
            </svg>
            </button>
          </div>

        </div>
        <!-- --- END GRID AREA --- -->

      </div>
    </div>

  </div>
</div>

     '
    ),

    # --- CITATION MANAGER OVERLAY ---
    div(
      id = "citationOverlay",
      div(
        class = "settings-dialog",
        style = "max-width: 1000px;",
        div(
          class = "settings-header",
          h3("Citation Manager"),
          tags$button(
            type = "button",
            class = "btn-close",
            onclick = "closeCitationOverlay()",
            `aria-label` = "Close"
          )
        ),
        div(
          class = "settings-body",
          style = "height: auto; overflow-y: auto;",
          div(
            class = "settings-content",
            style = "padding: 2rem;",
            h2(class = "mb-4", "Import reference from DOI"),

            # --- [NEW] File Selector Dropdown ---
            # This renders the dropdown dynamically based on files in the directory
            uiOutput("bibTargetSelector"),

            # Search Input Group
            div(
              class = "input-group mb-3",
              tags$input(
                type = "text",
                class = "form-control",
                id = "citationSearchInput",
                placeholder = "Paste Title or DOI (e.g., 10.1080/09670874... or https://doi.org/10.1080/09670874...)"
              ),
              tags$button(
                class = "btn btn-sm btn-primary",
                type = "button",
                id = "btnSearchCitation",
                onclick = "searchCitation()",
                "Search"
              )
            ),

            # Results Area (unchanged)
            div(
              id = "citationPreviewArea",
              class = "card mb-3",
              style = "display:none; border: 1px solid var(--tblr-border-color);",
              div(class = "card-header", h3(class = "card-title", "Preview")),
              div(
                class = "card-body",
                tags$pre(
                  id = "bibtexPreview",
                  style = "background: var(--tblr-bg-surface-secondary); color: var(--tblr-body-color); padding: 10px; border-radius: 4px; font-size: 0.8em; white-space: pre-wrap; border: 1px solid var(--tblr-border-color);"
                )
              ),
              div(
                class = "card-footer text-end",
                tags$button(
                  class = "btn btn-sm btn-primary",
                  onclick = "appendCitationToBib()",
                  "Append to bibliography"
                )
              )
            )
          )
        )
      )
    ),

    # --- FIGURE OVERLAY ---
    div(
      id = "figureOverlay",
      div(
        class = "settings-dialog",
        style = "max-width: 1000px;",
        div(
          class = "settings-header",
          h3("Insert Figure"),
          tags$button(
            type = "button",
            class = "btn-close",
            onclick = "closeFigureOverlay()",
            `aria-label` = "Close"
          )
        ),
        div(
          class = "settings-body",
          # --- Left Navigation ---
          div(
            class = "settings-nav",
            div(
              class = "nav flex-column nav-pills",
              role = "tablist",
              HTML(
                '
                        <a class="nav-link active" href="#fig-upload-tab" role="tab" onclick="switchFigureTab(event, \'fig-upload-tab\')">
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
                            stroke-linejoin="round">
                            <path d="M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2 -2v-2" />
                            <path d="M7 9l5 -5l5 5" />
                            <path d="M12 4l0 12" />
                          </svg>
                          Upload from computer
                        </a>
                        <a class="nav-link" href="#fig-project-tab" role="tab" onclick="switchFigureTab(event, \'fig-project-tab\')">
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
                            stroke-linejoin="round">
                            <path d="M12 6m-8 0a8 3 0 1 0 16 0a8 3 0 1 0 -16 0" />
                            <path d="M4 6v6a8 3 0 0 0 16 0v-6" />
                            <path d="M4 12v6a8 3 0 0 0 16 0v-6" />
                          </svg>
                          From project files
                        </a>
                        <a class="nav-link" href="#fig-other-tab" role="tab" onclick="switchFigureTab(event, \'fig-other-tab\')">
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
                            stroke-linejoin="round">
                            <path d="M4 6c0 1.657 3.582 3 8 3s8 -1.343 8 -3s-3.582 -3 -8 -3s-8 1.343 -8 3" />
                            <path d="M4 6v6c0 1.657 3.582 3 8 3c1.075 0 2.1 -.08 3.037 -.224" />
                            <path d="M20 12v-6" />
                            <path d="M4 12v6c0 1.657 3.582 3 8 3c.166 0 .331 -.002 .495 -.006" />
                            <path d="M16 19h6" />
                            <path d="M19 16v6" />
                          </svg>
                          From another project
                        </a>
                        <a class="nav-link" href="#fig-url-tab" role="tab" onclick="switchFigureTab(event, \'fig-url-tab\')">
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
                            stroke-linejoin="round">
                            <path d="M9 15l6 -6" />
                            <path d="M11 6l.463 -.536a5 5 0 0 1 7.072 0a4.993 4.993 0 0 1 -.001 7.072" />
                            <path d="M12.603 18.534a5.07 5.07 0 0 1 -7.127 0a4.972 4.972 0 0 1 0 -7.071l.524 -.463" />
                            <path d="M16 19h6" />
                            <path d="M19 16v6" />
                          </svg>
                          From URL
                        </a>
                      '
              )
            )
          ),
          # --- Right Content Area ---
          div(
            class = "settings-content",
            div(
              class = "tab-content",

              # TAB 1: Upload from computer
              div(
                class = "tab-pane show active",
                id = "fig-upload-tab",
                role = "tabpanel",
                h2(class = "mb-4", "Upload Image"),
                # Dropzone
                tags$form(
                  class = "dropzone",
                  id = "dropzone-figure",
                  action = ".",
                  autocomplete = "off",
                  novalidate = NA,
                  div(
                    class = "fallback",
                    fileInput("fig_upload_fallback", "Upload", multiple = FALSE)
                  ),
                  div(
                    class = "dz-message",
                    h3(
                      class = "dropzone-msg-title",
                      "Drop image here or click to upload"
                    ),
                    span(class = "dropzone-msg-desc", "Supports PNG, JPG, PDF")
                  )
                ),
                tags$br(),
                # Inputs
                textInput(
                  "fig_upload_name",
                  "Save as filename",
                  placeholder = "image.png"
                ),
                textAreaInput(
                  "fig_upload_caption",
                  "Caption",
                  placeholder = "Enter caption...",
                  rows = 2
                ),
                textInput(
                  "fig_upload_label",
                  "Label",
                  placeholder = "fig:label"
                ),

                # Width Group
                tags$label(class = "form-label", "Width"),
                div(
                  class = "btn-group w-100",
                  role = "group",
                  tags$input(
                    type = "radio",
                    class = "btn-check",
                    name = "fig_upload_width",
                    id = "u_w25",
                    value = "0.25",
                    autocomplete = "off"
                  ),
                  tags$label(
                    class = "btn btn-outline-secondary",
                    `for` = "u_w25",
                    "1/4"
                  ),
                  tags$input(
                    type = "radio",
                    class = "btn-check",
                    name = "fig_upload_width",
                    id = "u_w50",
                    value = "0.5",
                    autocomplete = "off"
                  ),
                  tags$label(
                    class = "btn btn-outline-secondary",
                    `for` = "u_w50",
                    "1/2"
                  ),
                  tags$input(
                    type = "radio",
                    class = "btn-check",
                    name = "fig_upload_width",
                    id = "u_w75",
                    value = "0.75",
                    autocomplete = "off",
                    checked = NA
                  ),
                  tags$label(
                    class = "btn btn-outline-secondary",
                    `for` = "u_w75",
                    "3/4"
                  ),
                  tags$input(
                    type = "radio",
                    class = "btn-check",
                    name = "fig_upload_width",
                    id = "u_w100",
                    value = "1.0",
                    autocomplete = "off"
                  ),
                  tags$label(
                    class = "btn btn-outline-secondary",
                    `for` = "u_w100",
                    "1"
                  )
                ),
                tags$script(HTML(
                  "
                                $(document).on('change', 'input[name=\"fig_upload_width\"]', function() {
                                  Shiny.setInputValue('fig_upload_width', this.value);
                                });
                              "
                )),
                # Footer
                div(
                  class = "mt-4 pt-3 border-top text-end",
                  tags$button(
                    type = "button",
                    class = "btn",
                    onclick = "closeFigureOverlay()",
                    "Cancel"
                  ),
                  # CHANGED: Replaced tags$button with actionButton
                  actionButton(
                    "btnInsertFigUpload",
                    "Insert",
                    class = "btn btn-primary ms-2"
                  )
                )
              ),

              # TAB 2: From Project Files
              div(
                class = "tab-pane",
                id = "fig-project-tab",
                role = "tabpanel",
                h2(class = "mb-4", "Select from Project"),
                uiOutput("figProjFileSelectUI"), # Dynamic Select
                tags$br(),
                textInput(
                  "fig_proj_name",
                  "Filename (in project)",
                  placeholder = "Selected file...",
                  width = "100%"
                ) %>%
                  disabled(),
                textAreaInput(
                  "fig_proj_caption",
                  "Caption",
                  placeholder = "Enter caption...",
                  rows = 2
                ),
                textInput("fig_proj_label", "Label", placeholder = "fig:label"),
                tags$label(class = "form-label", "Width"),
                div(
                  class = "btn-group w-100",
                  role = "group",
                  tags$input(
                    type = "radio",
                    class = "btn-check",
                    name = "fig_proj_width",
                    id = "p_w25",
                    value = "0.25",
                    autocomplete = "off"
                  ),
                  tags$label(
                    class = "btn btn-outline-secondary",
                    `for` = "p_w25",
                    "1/4"
                  ),
                  tags$input(
                    type = "radio",
                    class = "btn-check",
                    name = "fig_proj_width",
                    id = "p_w50",
                    value = "0.5",
                    autocomplete = "off"
                  ),
                  tags$label(
                    class = "btn btn-outline-secondary",
                    `for` = "p_w50",
                    "1/2"
                  ),
                  tags$input(
                    type = "radio",
                    class = "btn-check",
                    name = "fig_proj_width",
                    id = "p_w75",
                    value = "0.75",
                    autocomplete = "off",
                    checked = NA
                  ),
                  tags$label(
                    class = "btn btn-outline-secondary",
                    `for` = "p_w75",
                    "3/4"
                  ),
                  tags$input(
                    type = "radio",
                    class = "btn-check",
                    name = "fig_proj_width",
                    id = "p_w100",
                    value = "1.0",
                    autocomplete = "off"
                  ),
                  tags$label(
                    class = "btn btn-outline-secondary",
                    `for` = "p_w100",
                    "1"
                  )
                ),
                tags$script(HTML(
                  "
                                $(document).on('change', 'input[name=\"fig_proj_width\"]', function() {
                                  Shiny.setInputValue('fig_proj_width', this.value);
                                });
                              "
                )),
                div(
                  class = "mt-4 pt-3 border-top text-end",
                  tags$button(
                    type = "button",
                    class = "btn",
                    onclick = "closeFigureOverlay()",
                    "Cancel"
                  ),
                  # CHANGED: Replaced tags$button with actionButton
                  actionButton(
                    "btnInsertFigProj",
                    "Insert",
                    class = "btn btn-primary ms-2"
                  )
                )
              ),

              # TAB 3: From Another Project
              div(
                class = "tab-pane",
                id = "fig-other-tab",
                role = "tabpanel",
                h2(class = "mb-4", "Import from Another Project"),
                uiOutput("figOtherProjSelectUI"), # Select Project
                uiOutput("figOtherFileSelectUI"), # Select File
                tags$br(),
                textInput("fig_other_name", "Save as filename") %>%
                  disabled(),
                textAreaInput(
                  "fig_other_caption",
                  "Caption",
                  placeholder = "Enter caption...",
                  rows = 2
                ),
                textInput(
                  "fig_other_label",
                  "Label",
                  placeholder = "fig:label"
                ),
                tags$label(class = "form-label", "Width"),
                div(
                  class = "btn-group w-100",
                  role = "group",
                  tags$input(
                    type = "radio",
                    class = "btn-check",
                    name = "fig_other_width",
                    id = "o_w25",
                    value = "0.25",
                    autocomplete = "off"
                  ),
                  tags$label(
                    class = "btn btn-outline-secondary",
                    `for` = "o_w25",
                    "1/4"
                  ),
                  tags$input(
                    type = "radio",
                    class = "btn-check",
                    name = "fig_other_width",
                    id = "o_w50",
                    value = "0.5",
                    autocomplete = "off"
                  ),
                  tags$label(
                    class = "btn btn-outline-secondary",
                    `for` = "o_w50",
                    "1/2"
                  ),
                  tags$input(
                    type = "radio",
                    class = "btn-check",
                    name = "fig_other_width",
                    id = "o_w75",
                    value = "0.75",
                    autocomplete = "off",
                    checked = NA
                  ),
                  tags$label(
                    class = "btn btn-outline-secondary",
                    `for` = "o_w75",
                    "3/4"
                  ),
                  tags$input(
                    type = "radio",
                    class = "btn-check",
                    name = "fig_other_width",
                    id = "o_w100",
                    value = "1.0",
                    autocomplete = "off"
                  ),
                  tags$label(
                    class = "btn btn-outline-secondary",
                    `for` = "o_w100",
                    "1"
                  )
                ),
                tags$script(HTML(
                  "
                                $(document).on('change', 'input[name=\"fig_other_width\"]', function() {
                                  Shiny.setInputValue('fig_other_width', this.value);
                                });
                              "
                )),
                div(
                  class = "mt-4 pt-3 border-top text-end",
                  tags$button(
                    type = "button",
                    class = "btn",
                    onclick = "closeFigureOverlay()",
                    "Cancel"
                  ),
                  # CHANGED: Replaced tags$button with actionButton
                  actionButton(
                    "btnInsertFigOther",
                    "Insert",
                    class = "btn btn-primary ms-2"
                  )
                )
              ),

              # TAB 4: From URL
              div(
                class = "tab-pane",
                id = "fig-url-tab",
                role = "tabpanel",
                h2(class = "mb-4", "Link from Web"),
                textAreaInput(
                  "fig_url_link",
                  "Figure URL",
                  placeholder = "https://example.com/image.png",
                  rows = 1
                ),
                textInput("fig_url_name", "Save as filename") %>%
                  disabled(),
                textAreaInput(
                  "fig_url_caption",
                  "Caption",
                  placeholder = "Enter caption...",
                  rows = 2
                ),
                textInput("fig_url_label", "Label", placeholder = "fig:label"),
                tags$label(class = "form-label", "Width"),
                div(
                  class = "btn-group w-100",
                  role = "group",
                  tags$input(
                    type = "radio",
                    class = "btn-check",
                    name = "fig_url_width",
                    id = "u_url25",
                    value = "0.25",
                    autocomplete = "off"
                  ),
                  tags$label(
                    class = "btn btn-outline-secondary",
                    `for` = "u_url25",
                    "1/4"
                  ),
                  tags$input(
                    type = "radio",
                    class = "btn-check",
                    name = "fig_url_width",
                    id = "u_url50",
                    value = "0.5",
                    autocomplete = "off"
                  ),
                  tags$label(
                    class = "btn btn-outline-secondary",
                    `for` = "u_url50",
                    "1/2"
                  ),
                  tags$input(
                    type = "radio",
                    class = "btn-check",
                    name = "fig_url_width",
                    id = "u_url75",
                    value = "0.75",
                    autocomplete = "off",
                    checked = NA
                  ),
                  tags$label(
                    class = "btn btn-outline-secondary",
                    `for` = "u_url75",
                    "3/4"
                  ),
                  tags$input(
                    type = "radio",
                    class = "btn-check",
                    name = "fig_url_width",
                    id = "u_url100",
                    value = "1.0",
                    autocomplete = "off"
                  ),
                  tags$label(
                    class = "btn btn-outline-secondary",
                    `for` = "u_url100",
                    "1"
                  )
                ),
                tags$script(HTML(
                  "
                                $(document).on('change', 'input[name=\"fig_url_width\"]', function() {
                                  Shiny.setInputValue('fig_url_width', this.value);
                                });
                              "
                )),
                div(
                  class = "mt-4 pt-3 border-top text-end",
                  tags$button(
                    type = "button",
                    class = "btn",
                    onclick = "closeFigureOverlay()",
                    "Cancel"
                  ),
                  # CHANGED: Replaced tags$button with actionButton
                  actionButton(
                    "btnInsertFigUrl",
                    "Insert",
                    class = "btn btn-primary ms-2"
                  )
                )
              )
            )
          )
        )
      )
    ),
    HTML(
      '

 <! --- HISTORY OVERLAY (Fixed Layout) --->
  <div id="historyOverlay">
  <header class="navbar navbar-expand-sm d-print-none border-bottom">
    <div class="container-fluid">

      <div class="navbar-nav flex-row align-items-center gap-2">
        <div class="nav-item">
          <button
            id="closeHistoryBtn"
            class="btn btn-sm"
            onclick="Shiny.setInputValue(\'closeHistoryBtn\', Math.random(), {priority: \'event\'})"
            title="Back to Editor"
            data-bs-toggle="tooltip">
            <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M5 12l14 0" />
              <path d="M5 12l6 6" />
              <path d="M5 12l6 -6" />
            </svg>
            Back to Editor
          </button>
        </div>
      </div>

      <div class="navbar-nav flex-row mx-auto">
        <div id="historyNavbarInfo" class="nav-item shiny-html-output" style="color: var(--tblr-body-color);">
           </div>
      </div>

      <div class="navbar-nav flex-row order-md-last">
        <div class="nav-item">
          <button
            class="btn btn-primary btn-sm"
            onclick="if(window.HistoryManager && window.HistoryManager.currentVersionId) Shiny.setInputValue(\'history_restore_id\', window.HistoryManager.currentVersionId, {priority:\'event\'});">
            <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M12 8l0 4l2 2"></path>
              <path d="M3.05 11a9 9 0 1 1 .5 4m-.5 5v-5h5"></path>
            </svg>
            Restore this version
          </button>
        </div>
      </div>

    </div>
  </header>

  <div
    class="page-wrapper"
    style="height: calc(103vh - 56px); overflow: hidden; background: var(--tblr-body-bg); padding: 0;">

    <div
      class="card h-100"
      style="display: flex; flex-direction: column; overflow: hidden; background-color: var(--tblr-body-bg); border-radius: 0 !important;">

      <div id="historyContainer" class="d-flex h-100">

        <!-- Left Column: File Tree -->
        <div
          id="historyFileTreeSidebar"
          class="border-end bg-body d-flex flex-column"
          style="overflow: hidden; background-color: var(--tblr-body-bg) !important;">

          <div class="pane-header"
               style="height: 38px; min-height: 38px; padding: 0 10px; display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid var(--tblr-border-color); cursor: pointer;"
               onclick="var body = document.getElementById(\'historyFileList\'); var icon = this.querySelector(\'.chevron-icon\'); if(body.style.display === \'none\') { body.style.display = \'block\'; icon.classList.replace(\'fa-chevron-right\', \'fa-chevron-down\'); } else { body.style.display = \'none\'; icon.classList.replace(\'fa-chevron-down\', \'fa-chevron-right\'); }">
             <strong style="font-size:14px; font-weight:600; text-transform: uppercase;">Project Files</strong>
             <i class="fa-solid fa-chevron-down chevron-icon" style="font-size: 0.8rem; color: var(--tblr-secondary);"></i>
          </div>

          <div id="historyFileTreeBody" class="flex-fill position-relative" style="overflow-y: auto;">
             <div id="historyFilesSpinner" style="display:none;">
                <div class="spinner-border" role="status"></div>
             </div>
             <div id="historyFileList" class="shiny-html-output" style="padding: 10px;"></div>
          </div>
        </div>
      '
    ),
    div(
      id = "historyEditorContainer",
      class = "flex-fill position-relative border-0",
      div(
        class = "flex-fill position-relative border-bottom",
        style = "width: 100%; height: 30px;",
        div(
          style = "height: 30px; min-height: 30px; padding: 0 10px; display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid var(--tblr-border-color); container-type: inline-size;",
          # LEFT: Date
          tags$span(
            id = "historyViewDate",
            class = "status-item-text",
            style = "font-weight: 500;"
          ),
          # RIGHT: Change Count
          tags$span(id = "historyChangeCount", class = "badge bg-primary-lt")
        )
      ),
      div(
        style = "height: 100%; width: 100%;",
        aceEditor(
          "historyEditor",
          value = "Select a version to view...",
          mode = "text",
          readOnly = TRUE,
          height = "100%",
          fontSize = 12,
          wordWrap = TRUE,
          showPrintMargin = FALSE,
          tabSize = 4,
          useSoftTabs = TRUE,
          showInvisibles = FALSE
        )
      )
    ),
    HTML(
      '
        <!-- Right Column: Versions -->
        <div
          id="historySidebar"
          class="border-start bg-body d-flex flex-column"
          style="overflow: hidden; background-color: var(--tblr-body-bg) !important;">

          <div class="pane-header"
               style="height: 38px; min-height: 38px; padding: 0 10px; display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid var(--tblr-border-color); cursor: pointer;"
               onclick="var body = document.getElementById(\'historySidebarContent\'); var icon = this.querySelector(\'.chevron-icon\'); if(body.style.display === \'none\') { body.style.display = \'block\'; icon.classList.replace(\'fa-chevron-right\', \'fa-chevron-down\'); } else { body.style.display = \'none\'; icon.classList.replace(\'fa-chevron-down\', \'fa-chevron-right\'); }">
             <strong style="font-size:14px; font-weight:600; text-transform: uppercase;">Version History</strong>
             <i class="fa-solid fa-chevron-down chevron-icon" style="font-size: 0.8rem; color: var(--tblr-secondary);"></i>
          </div>

          <div id="historyVersionsBody" class="flex-fill position-relative" style="overflow-y: auto;">
             <div id="historyVersionsSpinner" style="display:none;">
                <div class="spinner-border" role="status"></div>
             </div>
             <div id="historySidebarContent" class="shiny-html-output" style="padding: 10px;"></div>
          </div>
        </div>

      </div>
    </div>
  </div>

</div>

<div id="copyProjectOverlay">
      <div class="settings-dialog" style="max-width: 1000px; height: auto; max-height: auto;">
        <div class="settings-header">
          <h3>Copy project</h3>
          <button type="button" class="btn-close" onclick="closeCopyProjectOverlay()" aria-label="Close"></button>
        </div>
        <div class="settings-body" style="height: auto; overflow: visible;">
          <div class="settings-content" style="padding: 2rem;">
            <div class="mb-3">
              <label class="form-label required">New name</label>
              <input type="text" class="form-control" id="copyProjectNameInput" placeholder="Project Copy" />
            </div>
            <div class="mt-4 pt-3 border-top text-end">
              <button type="button" class="btn" onclick="closeCopyProjectOverlay()">Cancel</button>
              <button type="button" class="btn btn-primary ms-2" id="btnCopyProjectConfirm">Copy</button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <style>
      #copyProjectOverlay {
        position: fixed; top: 0; left: 0; right: 0; bottom: 0;
        width: 100%; height: 100%;
        background: rgba(0, 0, 0, 0.5);
        z-index: 1060;
        display: none; opacity: 0; transition: opacity 0.3s ease;
        align-items: center; justify-content: center; /* Center vertically */
      }
      #copyProjectOverlay.show { display: flex; opacity: 1; }
    </style>

<div id="settingsOverlay">
      <div class="settings-dialog" style="max-width: 1000px;">
        <div class="settings-header">
          <h3>Settings</h3>
          <button type="button" class="btn-close" onclick="closeSettingsOverlay()" aria-label="Close"></button>
        </div>
        <div class="settings-body">
          <div class="settings-nav">
            <div class="nav flex-column nav-pills" role="tablist">
              <a class="nav-link active" href="#settings-theme-tab" role="tab" onclick="switchSettingsTab(event, \'settings-theme-tab\')">
                <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1 text-muted" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M7 7m0 2.667a2.667 2.667 0 0 1 2.667 -2.667h8.666a2.667 2.667 0 0 1 2.667 2.667v8.666a2.667 2.667 0 0 1 -2.667 2.667h-8.666a2.667 2.667 0 0 1 -2.667 -2.667z"/><path d="M4.012 16.737a2.005 2.005 0 0 1 -1.012 -1.737v-10c0 -1.1 .9 -2 2 -2h10c.75 0 1.158 .385 1.5 1"/></svg>
                Theme
              </a>
              <a class="nav-link" href="#settings-editor-tab" role="tab" onclick="switchSettingsTab(event, \'settings-editor-tab\')">
                <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1 text-muted" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path d="M7 8l-4 4l4 4" /><path d="M17 8l4 4l-4 4" /><path d="M14 4l-4 16" /></svg>
                Editor
              </a>
              <a class="nav-link" href="#settings-shortcuts-tab" role="tab" onclick="switchSettingsTab(event, \'settings-shortcuts-tab\')">
                <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1 text-muted" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><rect x="2" y="6" width="20" height="12" rx="2"/><line x1="6" y1="10" x2="6" y2="10"/><line x1="10" y1="10" x2="10" y2="10"/><line x1="14" y1="10" x2="14" y2="10"/><line x1="18" y1="10" x2="18" y2="10"/><line x1="6" y1="14" x2="6" y2="14.01"/><line x1="18" y1="14" x2="18" y2="14.01"/><line x1="10" y1="14" x2="14" y2="14"/></svg>
                Shortcuts
              </a>
              <a class="nav-link" href="#settings-sessions-tab" role="tab" onclick="switchSettingsTab(event, \'settings-sessions-tab\')">
                <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1 text-muted" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M3 5a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v14a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-14z" /><path d="M3 10h18" /><path d="M7 15h.01" /><path d="M11 15h2" /></svg>
                Sessions
              </a>
            </div>
          </div>
          <div class="settings-content">
            <div class="tab-content">
              <div class="tab-pane show active" id="settings-theme-tab" role="tabpanel">
                <h2 class="mb-4">Theme Settings</h2>
                <form id="settingsOverlayForm">
                  <div class="mb-4">
                    <label class="form-label">Color mode</label>
                    <p class="form-hint mb-2">Choose a color mode.</p>
                    <div class="form-selectgroup">
                      <label class="form-selectgroup-item">
                        <input type="radio" name="theme" value="light" class="form-selectgroup-input" />
                        <span class="form-selectgroup-label">
                          <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none" /><circle cx="12" cy="12" r="4" /><path d="M3 12h1m8 -9v1m8 8h1m-9 8v1m-6.4 -15.4l.7 .7m12.1 -.7l-.7 .7m0 11.4l.7 .7m-12.1 -.7l-.7 .7" /></svg>
                        </span>
                      </label>
                      <label class="form-selectgroup-item">
                        <input type="radio" name="theme" value="dark" class="form-selectgroup-input" checked />
                        <span class="form-selectgroup-label">
                          <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M12 3c.132 0 .263 0 .393 0a7.5 7.5 0 0 0 7.92 12.446a9 9 0 1 1 -8.313 -12.454z" /></svg>
                        </span>
                      </label>
                    </div>
                  </div>

                  <div class="mb-4">
                    <label class="form-label">Font family</label>
                    <p class="form-hint mb-2">Choose a font family.</p>
                    <div class="form-selectgroup">
                      <label class="form-selectgroup-item"><input type="radio" name="theme-font" value="sans-serif" class="form-selectgroup-input" checked /><span class="form-selectgroup-label">Sans-serif</span></label>
                      <label class="form-selectgroup-item"><input type="radio" name="theme-font" value="serif" class="form-selectgroup-input" /><span class="form-selectgroup-label">Serif</span></label>
                      <label class="form-selectgroup-item"><input type="radio" name="theme-font" value="monospace" class="form-selectgroup-input" /><span class="form-selectgroup-label">Monospace</span></label>
                      <label class="form-selectgroup-item"><input type="radio" name="theme-font" value="comic" class="form-selectgroup-input" /><span class="form-selectgroup-label">Comic</span></label>
                      <label class="form-selectgroup-item"><input type="radio" name="theme-font" value="instrument-serif" class="form-selectgroup-input" /><span class="form-selectgroup-label" style="font-family: \'Instrument Serif\', serif;">Instrument Serif</span></label>
                      <label class="form-selectgroup-item"><input type="radio" name="theme-font" value="fira-code" class="form-selectgroup-input" /><span class="form-selectgroup-label" style="font-family: \'Fira Code\', monospace;">Fira Code</span></label>
                      <label class="form-selectgroup-item"><input type="radio" name="theme-font" value="roboto" class="form-selectgroup-input" /><span class="form-selectgroup-label" style="font-family: \'Roboto\', sans-serif;">Roboto</span></label>
                      <label class="form-selectgroup-item"><input type="radio" name="theme-font" value="nexa" class="form-selectgroup-input" /><span class="form-selectgroup-label" style="font-family: \'Nexa\', sans-serif;">Nexa</span></label>
                      <label class="form-selectgroup-item"><input type="radio" name="theme-font" value="proxima-nova" class="form-selectgroup-input" /><span class="form-selectgroup-label" style="font-family: \'Proxima Nova\', sans-serif;">Proxima Nova</span></label>
                    </div>
                  </div>

                  <div class="mb-4">
                    <label class="form-label">Color scheme</label>
                    <p class="form-hint mb-2">Choose a color scheme.</p>
                    <div class="row g-2">
                      <div class="col-6 col-sm-4 col-md-3 col-lg-2"><label class="form-colorinput"><input name="theme-primary" type="radio" value="blue" class="form-colorinput-input" /><span class="form-colorinput-color bg-blue"></span></label></div>
                      <div class="col-6 col-sm-4 col-md-3 col-lg-2"><label class="form-colorinput"><input name="theme-primary" type="radio" value="azure" class="form-colorinput-input" /><span class="form-colorinput-color bg-azure"></span></label></div>
                      <div class="col-6 col-sm-4 col-md-3 col-lg-2"><label class="form-colorinput"><input name="theme-primary" type="radio" value="indigo" class="form-colorinput-input" /><span class="form-colorinput-color bg-indigo"></span></label></div>
                      <div class="col-6 col-sm-4 col-md-3 col-lg-2"><label class="form-colorinput"><input name="theme-primary" type="radio" value="purple" class="form-colorinput-input" /><span class="form-colorinput-color bg-purple"></span></label></div>
                      <div class="col-6 col-sm-4 col-md-3 col-lg-2"><label class="form-colorinput"><input name="theme-primary" type="radio" value="pink" class="form-colorinput-input" /><span class="form-colorinput-color bg-pink"></span></label></div>
                      <div class="col-6 col-sm-4 col-md-3 col-lg-2"><label class="form-colorinput"><input name="theme-primary" type="radio" value="red" class="form-colorinput-input" /><span class="form-colorinput-color bg-red"></span></label></div>
                      <div class="col-6 col-sm-4 col-md-3 col-lg-2"><label class="form-colorinput"><input name="theme-primary" type="radio" value="orange" class="form-colorinput-input" /><span class="form-colorinput-color bg-orange"></span></label></div>
                      <div class="col-6 col-sm-4 col-md-3 col-lg-2"><label class="form-colorinput"><input name="theme-primary" type="radio" value="yellow" class="form-colorinput-input" /><span class="form-colorinput-color bg-yellow"></span></label></div>
                      <div class="col-6 col-sm-4 col-md-3 col-lg-2"><label class="form-colorinput"><input name="theme-primary" type="radio" value="lime" class="form-colorinput-input" /><span class="form-colorinput-color bg-lime"></span></label></div>
                      <div class="col-6 col-sm-4 col-md-3 col-lg-2"><label class="form-colorinput"><input name="theme-primary" type="radio" value="green" class="form-colorinput-input" checked /><span class="form-colorinput-color bg-green"></span></label></div>
                      <div class="col-6 col-sm-4 col-md-3 col-lg-2"><label class="form-colorinput"><input name="theme-primary" type="radio" value="teal" class="form-colorinput-input" /><span class="form-colorinput-color bg-teal"></span></label></div>
                      <div class="col-6 col-sm-4 col-md-3 col-lg-2"><label class="form-colorinput"><input name="theme-primary" type="radio" value="cyan" class="form-colorinput-input" /><span class="form-colorinput-color bg-cyan"></span></label></div>
                    </div>
                  </div>

                  <div class="mb-4">
                    <label class="form-label">Theme base</label>
                    <p class="form-hint mb-2">Choose a gray shade.</p>
                    <div class="form-selectgroup">
                      <label class="form-selectgroup-item"><input type="radio" name="theme-base" value="slate" class="form-selectgroup-input" /><span class="form-selectgroup-label">Slate</span></label>
                      <label class="form-selectgroup-item"><input type="radio" name="theme-base" value="gray" class="form-selectgroup-input" /><span class="form-selectgroup-label">Gray</span></label>
                      <label class="form-selectgroup-item"><input type="radio" name="theme-base" value="zinc" class="form-selectgroup-input" checked /><span class="form-selectgroup-label">Zinc</span></label>
                      <label class="form-selectgroup-item"><input type="radio" name="theme-base" value="neutral" class="form-selectgroup-input" /><span class="form-selectgroup-label">Neutral</span></label>
                      <label class="form-selectgroup-item"><input type="radio" name="theme-base" value="stone" class="form-selectgroup-input" /><span class="form-selectgroup-label">Stone</span></label>
                      <label class="form-selectgroup-item"><input type="radio" name="theme-base" value="black" class="form-selectgroup-input" /><span class="form-selectgroup-label">Black</span></label>
                    </div>
                  </div>

                  <div class="mb-4">
                    <label class="form-label">Corner radius</label>
                    <p class="form-hint mb-2">Choose a border radius factor.</p>
                    <div class="form-selectgroup">
                      <label class="form-selectgroup-item"><input type="radio" name="theme-radius" value="0" class="form-selectgroup-input"/><span class="form-selectgroup-label">0</span></label>
                      <label class="form-selectgroup-item"><input type="radio" name="theme-radius" value="0.5" class="form-selectgroup-input" /><span class="form-selectgroup-label">0.5</span></label>
                      <label class="form-selectgroup-item"><input type="radio" name="theme-radius" value="1" class="form-selectgroup-input" checked /><span class="form-selectgroup-label">1</span></label>
                      <label class="form-selectgroup-item"><input type="radio" name="theme-radius" value="1.5" class="form-selectgroup-input" /><span class="form-selectgroup-label">1.5</span></label>
                      <label class="form-selectgroup-item"><input type="radio" name="theme-radius" value="2" class="form-selectgroup-input" /><span class="form-selectgroup-label">2</span></label>
                    </div>
                  </div>

                  <div class="d-flex gap-2 mt-4">
                    <button type="reset" class="btn w-100" id="reset-settings-overlay" value="reset">
                      <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon me-2"><path d="M19.95 11a8 8 0 1 0 -.5 4m.5 5v-5h-5" /></svg>
                      Reset changes
                    </button>
                  </div>
                </form>
              </div>

              <div class="tab-pane" id="settings-editor-tab" role="tabpanel">
                <h2 class="mb-4">Editor settings</h2>
                <div style="max-width: 600px;">
                  <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px;">
                     <h4 class="mb-0">Editor theme</h4>
                     <div style="flex-shrink: 0;">
                        <select id="editorThemePanel" class="form-select" style="shadow: none; font-size: 12px; padding: 2px 6px; height: auto; min-height: 24px; width: 180px; border: 1px solid #ced4da;">
                            <option value="ambiance">Ambiance</option>
                            <option value="chaos">Chaos</option>
                            <option value="chrome">Chrome</option>
                            <option value="clouds">Clouds</option>
                            <option value="clouds_midnight">Clouds midnight</option>
                            <option value="cobalt">Cobalt</option>
                            <option value="crimson_editor">Crimson editor</option>
                            <option value="dawn">Dawn</option>
                            <option value="dracula">Dracula</option>
                            <option value="dreamweaver">Dreamweaver</option>
                            <option value="eclipse">Eclipse</option>
                            <option value="github">Github</option>
                            <option value="gob">Gob</option>
                            <option value="gruvbox">Gruvbox</option>
                            <option value="idle_fingers" selected>Idle fingers</option>
                            <option value="iplastic">Iplastic</option>
                            <option value="katzenmilch">Katzenmilch</option>
                            <option value="kr_theme">Kr theme</option>
                            <option value="kuroir">Kuroir</option>
                            <option value="merbivore_soft">Merbivore soft</option>
                            <option value="merbivore">Merbivore</option>
                            <option value="mono_industrial">Mono industrial</option>
                            <option value="monokai">Monokai</option>
                            <option value="pastel_on_dark">Pastel on dark</option>
                            <option value="solarized_dark">Solarized dark</option>
                            <option value="solarized_light">Solarized light</option>
                            <option value="sqlserver">Sqlserver</option>
                            <option value="terminal">Terminal</option>
                            <option value="textmate">Textmate</option>
                            <option value="tomorrow">Tomorrow</option>
                            <option value="twilight">Twilight</option>
                            <option value="vibrant_ink">Vibrant ink</option>
                            <option value="xcode">Xcode</option>
                        </select>
                     </div>
                  </div>
                  <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px;">
                    <h4 class="mb-0">Font family</h4>
                    <div style="flex-shrink: 0;">
                       <select id="editorFontFamilyPanel" class="form-select" style="shadow: none; font-size: 12px; padding: 2px 6px; height: auto; min-height: 24px; width: 180px; border: 1px solid #ced4da;">
                           <option value="\'Fira Code\', monospace" selected>Fira Code</option>
                           <option value="\'Consolas\', monospace">Consolas</option>
                           <option value="\'Monaco\', monospace">Monaco</option>
                           <option value="\'JetBrains Mono\', monospace">JetBrains Mono</option>
                           <option value="\'Source Code Pro\', monospace">Source Code Pro</option>
                           <option value="\'Ubuntu Mono\', monospace">Ubuntu Mono</option>
                           <option value="\'Menlo\', monospace">Menlo</option>
                           <option value="\'Inconsolata\', monospace">Inconsolata</option>
                           <option value="monospace">Monospace</option>
                       </select>
                    </div>
                  </div>
                  <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px;">
                     <h4 class="mb-0">Font size</h4>
                     <div style="flex-shrink: 0;">
                        <select id="editorFontSizePanel" class="form-select" style="shadow: none; font-size: 12px; padding: 2px 6px; height: auto; min-height: 24px; width: 180px; border: 1px solid #ced4da;">
                            <option value="10">10</option>
                            <option value="12" selected>12</option>
                            <option value="14">14</option>
                            <option value="16">16</option>
                            <option value="18">18</option>
                            <option value="20">20</option>
                            <option value="22">22</option>
                            <option value="24">24</option>
                        </select>
                     </div>
                  </div>
                  <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px;">
                    <div style="display: flex; flex-direction: column;">
                        <h4 class="mb-0">Sticky Context</h4>
                        <small class="text-muted" style="font-size: 0.75rem; margin-top: 4px;">Pin parent scopes to top while scrolling</small>
                    </div>
                    <div class="form-check form-switch" style="margin: 0; padding-left: 2.5em;">
                        <input class="form-check-input" type="checkbox" id="enableStickyScrollPanel" checked style="width: 40px; height: 20px; cursor: pointer; float: none; margin-left: -2.5em;">
                    </div>
                  </div>
                  <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px;">
                    <div style="display: flex; flex-direction: column;">
                        <h4 class="mb-0">Minimap</h4>
                        <small class="text-muted" style="font-size: 0.75rem; margin-top: 4px;">Enable minimap</small>
                    </div>
                    <div class="form-check form-switch" style="margin: 0; padding-left: 2.5em;">
                        <input class="form-check-input" type="checkbox" id="enableMinimapPanel" checked style="width: 40px; height: 20px; cursor: pointer; float: none; margin-left: -2.5em;">
                    </div>
                  </div>
                  <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px;">
                    <div style="display: flex; flex-direction: column;">
                        <h4 class="mb-0">Math Preview</h4>
                        <small class="text-muted" style="font-size: 0.75rem; margin-top: 4px;">Render LaTeX equations near cursor</small>
                    </div>
                    <div class="form-check form-switch" style="margin: 0; padding-left: 2.5em;">
                        <input class="form-check-input" type="checkbox" id="enableMathPreviewPanel" checked style="width: 40px; height: 20px; cursor: pointer; float: none; margin-left: -2.5em;">
                    </div>
                  </div>
                  <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px;">
                    <div style="display: flex; flex-direction: column;">
                       <h4 class="mb-0">Spellcheck Language</h4>
                       <small class="text-muted" style="font-size: 0.75rem; margin-top: 4px;">Check language spelling and apply suggestions.</small>
                    </div>
                    <div style="flex-shrink: 0;">
                       <select id="editorSpellLangPanel" class="form-select" style="shadow: none; font-size: 12px; padding: 2px 6px; height: auto; min-height: 24px; width: 180px; border: 1px solid #ced4da;">
                           <option value="en_GB" selected>English (UK)</option>
                       </select>
                    </div>
                  </div>
                  <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; border-top: 1px solid var(--tblr-border-color); padding-top: 20px;">
                    <div style="display: flex; flex-direction: column;">
                       <h4 class="mb-0">Auto-lock timer</h4>
                       <small class="text-muted" style="font-size: 0.75rem; margin-top: 4px;">Lock screen after inactivity</small>
                    </div>
                    <div style="flex-shrink: 0;">
                       <select id="autolockTimePanel" class="form-select" style="shadow: none; font-size: 12px; padding: 2px 6px; height: auto; min-height: 24px; width: 180px; border: 1px solid #ced4da;">
                           <option value="0" selected>Never</option>
                           <option value="60000">1 minute</option>
                           <option value="180000">3 minutes</option>
                           <option value="300000">5 minutes</option>
                           <option value="900000">15 minutes</option>
                           <option value="1800000">30 minutes</option>
                           <option value="3600000">1 hour</option>
                       </select>
                    </div>
                  </div>
                </div>
              </div>

              <div class="tab-pane" id="settings-shortcuts-tab" role="tabpanel">
                <h2 class="mb-4">Keyboard shortcuts</h2>
                <div class="table-responsive">
                  <table class="table table-vcenter">
                    <thead>
                      <tr><th>Action</th><th>Shortcut</th></tr>
                    </thead>
                    <tbody>
                      <tr><td>Go to projects</td><td><kbd>Ctrl/⌘</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd></td></tr>
                      <tr><td>Compile document</td><td><kbd>Ctrl/⌘</kbd> + <kbd>S</kbd></td></tr>
                      <tr><td>Find/Replace</td><td><kbd>Ctrl/⌘</kbd> + <kbd>F</kbd></td></tr>
                      <tr><td>Navigate to Line</td><td><kbd>Ctrl/⌘</kbd> + <kbd>L</kbd></td></tr>
                      <tr><td>Select all</td><td><kbd>Ctrl/⌘</kbd> + <kbd>A</kbd></td></tr>
                      <tr><td>Copy selection</td><td><kbd>Ctrl/⌘</kbd> + <kbd>C</kbd></td></tr>
                      <tr><td>Cut selection</td><td><kbd>Ctrl/⌘</kbd> + <kbd>X</kbd></td></tr>
                      <tr><td>Paste</td><td><kbd>Ctrl/⌘</kbd> + <kbd>V</kbd></td></tr>
                      <tr><td>Undo</td><td><kbd>Ctrl/⌘</kbd> + <kbd>Z</kbd></td></tr>
                      <tr><td>Redo</td><td><kbd>Ctrl/⌘</kbd> + <kbd>Y</kbd></td></tr>
                      <tr><td>Delete line</td><td><kbd>Ctrl/⌘</kbd> + <kbd>D</kbd></td></tr>
                      <tr><td>Next match</td><td><kbd>Ctrl/⌘</kbd> + <kbd>G</kbd></td></tr>
                      <tr><td>Quit app</td><td><kbd>Ctrl/⌘</kbd> + <kbd>Q</kbd> or <kbd>Ctrl/⌘</kbd> + <kbd>W</kbd></td></tr>
                      <tr><td>Reload page</td><td><kbd>Ctrl/⌘</kbd> + <kbd>R</kbd></td></tr>
                      <tr><td>Exit find/replace</td><td><kbd>Esc</kbd></td></tr>
                    </tbody>
                  </table>
                </div>
              </div>

              <div class="tab-pane" id="settings-sessions-tab" role="tabpanel">
                <h2 class="mb-4">Your Sessions</h2>
                <div id="sessionsListContainer">
                  <div class="text-center text-muted p-3">Loading sessions...</div>
                </div>
              </div>

            </div>
          </div>
        </div>
      </div>
    </div>

    <div id="addFilesOverlay">
      <div class="settings-dialog" style="max-width: 1000px;">
        <div class="settings-header">
          <h3>Add files and folders</h3>
          <button type="button" class="btn-close" onclick="closeAddFilesOverlay()" aria-label="Close"></button>
        </div>
        <div class="settings-body">
          <div class="settings-nav">
            <div class="nav flex-column nav-pills" role="tablist">
              <a class="nav-link active" href="#add-file-tab" role="tab" onclick="switchAddFilesTab(event, \'add-file-tab\')">
                <i class="fa-solid fa-file-circle-plus"></i>&nbsp;
                New file
              </a>

              <a class="nav-link" href="#add-folder-tab" role="tab" onclick="switchAddFilesTab(event, \'add-folder-tab\')">
                <i class="fa-solid fa-folder-plus"></i>&nbsp;
                New folder
              </a>

              <a class="nav-link" href="#upload-tab" role="tab" onclick="switchAddFilesTab(event, \'upload-tab\')">
                <i class="fa-solid fa-upload"></i>&nbsp;
                Upload files
              </a>
            </div>
          </div>

          <div class="settings-content">
            <div class="tab-content">

              <div class="tab-pane show active" id="add-file-tab" role="tabpanel">
              <h2 class="mb-4">File name</h2>
                <div class="mb-3">
                  <label class="form-label required">Input file name</label>
                  <input type="text" class="form-control" id="newFileNameInput" value="fileName.tex" placeholder="fileName.tex" />
                  <div class="form-text text-muted">e.g., main.tex, references.bib, notes.txt</div>
                </div>

                  <div class="mt-4 pt-3 border-top text-end">
                    <button type="button" class="btn" onclick="closeAddFilesOverlay()">Cancel</button>
                    <button type="button" class="btn btn-primary" id="createNewFileBtn">Create</button>
                  </div>
              </div>

              <div class="tab-pane" id="add-folder-tab" role="tabpanel">
              <h2 class="mb-4">Folder name</h2>
                <div class="mb-3">
                  <label class="form-label required">Input folder name</label>
                  <input type="text" class="form-control" id="newFolderNameInput" placeholder="folder name" />
                </div>

                 <div class="mt-4 pt-3 border-top text-end">
                    <button type="button" class="btn" onclick="closeAddFilesOverlay()">Cancel</button>
                    <button type="button" class="btn btn-primary" id="createNewFolderBtn">Create</button>
                  </div>
              </div>

              <div class="tab-pane" id="upload-tab" role="tabpanel">
              <h2 class="mb-4">Upload</h2>
                <form class="dropzone" id="dropzone-upload" action="." autocomplete="off" novalidate>
                  <div class="fallback">
                    <input name="file" type="file" multiple />
                  </div>
                  <div class="dz-message">
                    <h3 class="dropzone-msg-title">Drop files here or click to upload</h3>
                    <span class="dropzone-msg-desc">Upload .tex, .bib, images, PDFs, and other project files</span>
                  </div>
                </form>

                  <div class="mt-4 pt-3 border-top text-end">
                    <button type="button" class="btn" onclick="closeAddFilesOverlay()">Cancel</button>
                    <button type="button" class="btn btn-primary" id="processUploadBtn">Upload</button>
                  </div>

              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <style>
      #addFilesOverlay {
        position: fixed;
        top: 0; left: 0; right: 0; bottom: 0;
        width: 100%; height: 100%;
        background: rgba(0, 0, 0, 0.5);
        z-index: 1060;
        display: none;
        opacity: 0;
        transition: opacity 0.3s ease;
        align-items: flex-start;
        justify-content: center;
      }
      #addFilesOverlay.show {
        display: flex;
        opacity: 1;
      }
      #addFilesOverlay .tab-pane { display: none; }
      #addFilesOverlay .tab-pane.active { display: block; }
    </style>

    <div id="createProjectOverlay">
      <div class="settings-dialog" style="max-width: 1000px;">
        <div class="settings-header">
          <h3>Start a new project</h3>
          <button type="button" class="btn-close" onclick="closeCreateProjectOverlay()" aria-label="Close"></button>
        </div>
        <div class="settings-body">
          <div class="settings-nav">
            <div class="nav flex-column nav-pills" role="tablist">
              <a class="nav-link active" href="#create-blank-tab" role="tab" onclick="switchCreateProjectTab(event, \'create-blank-tab\')">
                <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="24"
                    height="24"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  >
                    <path d="M12 19h-7a2 2 0 0 1 -2 -2v-11a2 2 0 0 1 2 -2h4l3 3h7a2 2 0 0 1 2 2v3.5" />
                    <path d="M16 19h6" />
                    <path d="M19 16v6" />
                  </svg>
                  &nbsp;
                Blank project
              </a>

              <a class="nav-link" href="#create-upload-tab" role="tab" onclick="switchCreateProjectTab(event, \'create-upload-tab\')">
                <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="24"
                    height="24"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round">
                    <path d="M12 19h-7a2 2 0 0 1 -2 -2v-11a2 2 0 0 1 2 -2h4l3 3h7a2 2 0 0 1 2 2v3.5" />
                    <path d="M19 22v-6" />
                    <path d="M22 19l-3 -3l-3 3" />
                  </svg>
                  &nbsp;
                Upload project
              </a>

              <a class="nav-link" href="#create-zip-tab" role="tab" onclick="switchCreateProjectTab(event, \'create-zip-tab\')">
                <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2 -2v-2" />
                  <path d="M7 9l5 -5l5 5" />
                  <path d="M12 4l0 12" />
                </svg>
                &nbsp; Import project
              </a>
            </div>
          </div>

          <div class="settings-content">
            <div class="tab-content">

              <div class="tab-pane show active" id="create-blank-tab" role="tabpanel">
                <h2 class="mb-4">Start from a template</h2>
                <div class="mb-3">
                  <label class="form-label required">Project name</label>
                  <input type="text" class="form-control" id="newProjectName" placeholder="Project name" />
                </div>
                <div class="mb-3">
                  <label class="form-label">Description</label>
                  <textarea class="form-control" id="newProjectDesc" rows="3" placeholder="Description..."></textarea>
                </div>
                <div class="mb-3">
                  <label class="form-label">Template</label>
                  <select class="form-select" id="newProjectTemplate">
                    <option value="article">Article</option>
                    <option value="beamer">Presentation (Beamer)</option>
                    <option value="thesis">Thesis / Report</option>
                  </select>
                </div>
                <div class="mt-4 pt-3 border-top text-end">
                  <button type="button" class="btn" onclick="closeCreateProjectOverlay()">Cancel</button>
                   <button type="button" class="btn btn-primary" id="btnCreateBlank">Create</button>
                </div>
              </div>

              <div class="tab-pane" id="create-upload-tab" role="tabpanel">
                <h2 class="mb-4">Upload a project</h2>
                <div class="mb-3">
                  <label class="form-label required">Project name</label>
                  <input type="text" class="form-control" id="uploadProjectName" placeholder="Project name" />
                </div>
                <div class="mb-3">
                  <label class="form-label">Description</label>
                  <textarea class="form-control" id="uploadProjectDesc" rows="2" placeholder="Description..."></textarea>
                </div>

                <label class="form-label">Upload project files</label>
                <form class="dropzone" id="dropzone-project" action="." autocomplete="off" novalidate>
                  <div class="fallback">
                    <input name="file" type="file" multiple />
                  </div>
                  <div class="dz-message">
                    <h3 class="dropzone-msg-title">Drop project files here</h3>
                    <span class="dropzone-msg-desc">Upload .tex, .bib, images, etc.</span>
                  </div>
                </form>

                <div class="mt-4 pt-3 border-top text-end">
                  <button type="button" class="btn" onclick="closeCreateProjectOverlay()">Cancel</button>
                   <button type="button" class="btn btn-primary" id="btnCreateFromUpload">Upload</button>
                </div>
              </div>

              <div class="tab-pane" id="create-zip-tab" role="tabpanel">
                <h2 class="mb-4">Import Compressed Project</h2>
                <div class="mb-3">
                  <label class="form-label">Project Name (Optional)</label>
                  <input type="text" class="form-control" id="importZipName" placeholder="Leave empty to use compressed filename">
                  <small class="form-hint">The contents of the zip file will be extracted into the new project folder.</small>
                </div>

                <div class="mb-3">
                  <label class="form-label required">Select compressed file</label>
                  <form class="dropzone" id="dropzone-import-zip" action="." autocomplete="off" style="border: 2px dashed var(--tblr-border-color); background: var(--tblr-bg-surface-secondary);">
                    <div class="dz-message">
                      <h3 class="dropzone-msg-title">Drop a compressed file here</h3>
                      <span class="dropzone-msg-desc">Or click to select</span>
                    </div>
                  </form>
                </div>

                <div class="mt-4 pt-3 border-top text-end">
                  <button type="button" class="btn me-2" onclick="closeCreateProjectOverlay()">Cancel</button>
                  <button type="button" class="btn btn-primary" id="btnImportZip">Import Project</button>
                </div>
              </div>


            </div>
          </div>
        </div>
      </div>
    </div>

    <div id="editProjectOverlay">
      <div class="settings-dialog" style="max-width: 1000px;">
        <div class="settings-header">
          <h3>Edit project</h3>
          <button type="button" class="btn-close" onclick="closeEditProjectOverlay()" aria-label="Close"></button>
        </div>
        <div class="settings-body">
          <div class="settings-nav">
            <div class="nav flex-column nav-pills" role="tablist">
              <a class="nav-link active" href="#edit-general-tab" role="tab">
                <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
                  <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                  <path d="M10.325 4.317c.426 -1.756 2.924 -1.756 3.35 0a1.724 1.724 0 0 0 2.573 1.066c1.543 -.94 3.31 .826 2.37 2.37a1.724 1.724 0 0 0 1.065 2.572c1.756 .426 1.756 2.924 0 3.35a1.724 1.724 0 0 0 -1.066 2.573c.94 1.543 -.826 3.31 -2.37 2.37a1.724 1.724 0 0 0 -2.572 1.065c-.426 1.756 -2.924 1.756 -3.35 0a1.724 1.724 0 0 0 -2.573 -1.066c-1.543 .94 -3.31 -.826 -2.37 -2.37a1.724 1.724 0 0 0 -1.065 -2.572c-1.756 -.426 -1.756 -2.924 0 -3.35a1.724 1.724 0 0 0 1.066 -2.573c-.94 -1.543 .826 -3.31 2.37 -2.37c1 .608 2.296 .07 2.572 -1.065z" />
                  <circle cx="12" cy="12" r="3" />
                </svg>
                Edit project metadata
              </a>
            </div>
          </div>

          <div class="settings-content">
            <div class="tab-content">
              <div class="tab-pane show active" id="edit-general-tab" role="tabpanel">
                <h2 class="mb-4">Project settings</h2>
                <input type="hidden" id="editProjectId" />

                <div class="mb-3">
                  <label class="form-label">Project name</label>
                  <input type="text" class="form-control" id="editProjectName" />
                </div>
                <div class="mb-3">
                  <label class="form-label">Description</label>
                  <textarea class="form-control" id="editProjectDesc" rows="3"></textarea>
                </div>

                <div class="mt-4 pt-3 border-top text-end">
                  <button type="button" class="btn" onclick="closeEditProjectOverlay()">Cancel</button>
                  <button type="button" class="btn btn-primary" id="btnSaveProjectEdit">Save</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <style>
      #createProjectOverlay, #editProjectOverlay {
        position: fixed;
        top: 0; left: 0; right: 0; bottom: 0;
        width: 100%; height: 100%;
        background: rgba(0, 0, 0, 0.5);
        z-index: 1060;
        display: none;
        opacity: 0;
        transition: opacity 0.3s ease;
        align-items: flex-start;
        justify-content: center;
      }
      #createProjectOverlay.show, #editProjectOverlay.show {
        display: flex;
        opacity: 1;
      }
      #createProjectOverlay .tab-pane { display: none; }
      #createProjectOverlay .tab-pane.active { display: block; }
    </style>

    <div id="editProfileOverlay">
      <div class="settings-dialog" style="max-width: 1000px;">
        <div class="settings-header">
          <h3>Edit profile</h3>
          <button type="button" class="btn-close" onclick="closeEditProfileOverlay()" aria-label="Close"></button>
        </div>
        <div class="settings-body">
          <div class="settings-nav">
            <div class="nav flex-column nav-pills" role="tablist">
              <a class="nav-link active" href="#profile-general-tab" role="tab" onclick="switchEditProfileTab(event, \'profile-general-tab\')">
                <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
                  <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                  <path d="M8 7a4 4 0 1 0 8 0a4 4 0 0 0 -8 0" />
                  <path d="M6 21v-2a4 4 0 0 1 4 -4h4a4 4 0 0 1 4 4v2" />
                </svg>
                General info
              </a>

              <a class="nav-link" href="#profile-avatar-tab" role="tab" onclick="switchEditProfileTab(event, \'profile-avatar-tab\')">
                <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
                  <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                  <path d="M12 12m-9 0a9 9 0 1 0 18 0a9 9 0 1 0 -18 0" />
                  <path d="M12 10m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0" />
                  <path d="M6.168 18.849a4 4 0 0 1 3.832 -2.849h4a4 4 0 0 1 3.834 2.855" />
                </svg>
                Profile picture
              </a>
            </div>
          </div>

          <div class="settings-content">
            <div class="tab-content">

              <div class="tab-pane show active" id="profile-general-tab" role="tabpanel">
                <h2 class="mb-4">Personal information</h2>
                <div class="mb-3">
                  <label class="form-label">Username</label>
                  <input type="text" class="form-control" id="editProfileUsername" placeholder="Enter your name" />
                </div>
                <div class="mb-3">
                  <label class="form-label">Email</label>
                  <input type="email" class="form-control" id="editProfileEmail" placeholder="Enter your email" />
                </div>
                <div class="mb-3">
                  <label class="form-label">Institution / Title</label>
                  <input type="text" class="form-control" id="editProfileInstitution" placeholder="e.g., Researcher, University Name" />
                </div>
                <div class="mb-3">
                  <label class="form-label">Bio</label>
                  <textarea class="form-control" id="editProfileBio" rows="4" placeholder="Tell us about yourself..."></textarea>
                </div>
              </div>

              <div class="tab-pane" id="profile-avatar-tab" role="tabpanel">
                <h2 class="mb-4">Change profile picture</h2>

                <form class="dropzone" id="dropzone-profile" action="." autocomplete="off" novalidate>
                  <div class="fallback">
                    <input name="file" type="file" />
                  </div>
                  <div class="dz-message">
                    <h3 class="dropzone-msg-title">Drop image here</h3>
                    <span class="dropzone-msg-desc">Supports PNG, JPG, GIF (Max 2MB)</span>
                  </div>
                </form>
              </div>

              <div class="mt-4 pt-3 border-top text-end">
                 <button type="button" class="btn" onclick="closeEditProfileOverlay()">Cancel</button>
                 <button type="button" class="btn btn-primary ms-2" id="saveProfileChangesBtn">Save</button>
              </div>

            </div>
          </div>
        </div>
      </div>
    </div>

    <style>
      #editProfileOverlay {
        position: fixed;
        top: 0; left: 0; right: 0; bottom: 0;
        width: 100%; height: 100%;
        background: rgba(0, 0, 0, 0.5);
        z-index: 1060;
        display: none;
        opacity: 0;
        transition: opacity 0.3s ease;
        align-items: flex-start;
        justify-content: center;
      }
      #editProfileOverlay.show {
        display: flex;
        opacity: 1;
      }
      #editProfileOverlay .tab-pane { display: none; }
      #editProfileOverlay .tab-pane.active { display: block; }

      /* Circular preview for profile dropzone */
      #dropzone-profile {
        max-width: 400px;
        margin: 0 auto;
        border-radius: var(--tblr-border-radius);
      }
      #dropzone-profile .dz-preview .dz-image {
        border-radius: 50%;
      }
    </style>
    '
    ),
    tags$head(
      shinyjs::useShinyjs(),
      tags$script(src = "theme.js", defer = NA),
      tags$link(rel = "stylesheet", href = "theme.css"),
      tags$script(src = "split.min.js"),
      tags$link(rel = "manifest", href = "manifest.json"),
      tags$script(src = "https://unpkg.com/split.js/dist/split.min.js"),
      tags$script(
        src = "https://cdn.jsdelivr.net/npm/@tabler/core@1.4.0/dist/js/tabler.min.js"
      ),
      tags$link(
        href = "https://cdn.jsdelivr.net/npm/@tabler/core@1.4.0/dist/css/tabler.min.css",
        rel = "stylesheet"
      ),
      tags$link(
        href = "https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/tabler-icons.min.css",
        rel = "stylesheet"
      ),
      tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
      tags$link(
        rel = "preconnect",
        href = "https://fonts.gstatic.com",
        crossorigin = "anonymous"
      ),
      tags$link(
        href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap",
        rel = "stylesheet"
      ),
      tags$script(src = "eqneditor.api.min.js", crossorigin = "anonymous"),

      # 1. Syntax Highlighting (Atom One Dark)
      tags$link(
        rel = "stylesheet",
        href = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-dark.min.css"
      ),
      tags$script(
        src = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"
      ),

      # --- ADD THIS LINE HERE ---
      tags$script(src = "cookie_handler.js"),
      # --------------------------

      # 1. Devicon (For official language logos: R, Python, Latex, etc.)
      tags$link(
        rel = "stylesheet",
        href = "https://cdn.jsdelivr.net/gh/devicons/devicon@latest/devicon.min.css"
      ),

      # 2. FontAwesome 6 (For generic UI: Folders, PDF, Zip)
      tags$link(
        rel = "stylesheet",
        href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css"
      ),

      # --- Add KaTeX for Equation Preview ---
      tags$link(
        rel = "stylesheet",
        href = "https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css"
      ),
      tags$script(
        src = "https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"
      ),
      # tags$script(src = "https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/contrib/auto-render.min.js"),

      tags$script(
        src = "https://cdnjs.cloudflare.com/ajax/libs/diff_match_patch/20121119/diff_match_patch.js"
      ),
      tags$script(
        src = "https://cdn.jsdelivr.net/npm/typo-js@1.0.3/typo.min.js"
      ),
      tags$link(
        href = "https://cdn.jsdelivr.net/npm/dropzone@5.9.3/dist/min/dropzone.min.css",
        rel = "stylesheet"
      ),
      tags$script(
        src = "https://cdn.jsdelivr.net/npm/dropzone@5.9.3/dist/min/dropzone.min.js"
      ),
      tags$script(
        src = "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"
      ),
      tags$script(HTML(
        "
        if (typeof pdfjsLib !== 'undefined') {
          pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';
        }
"
      )),

      # Service worker register + Preloader removal logic
      tags$script(HTML(
        "
      if ('serviceWorker' in navigator) {
        window.addEventListener('load', function() {
          navigator.serviceWorker.register('sw.js').catch(function(e){
            console.error('SW registration failed', e);
          });
        });
      }

      // =================== PRELOADER REMOVAL LOGIC ===================
      (function() {
        let preloaderRemoved = false;

        // Function to hide preloader (can only run once)
        function hidePreloader(reason) {
          if (preloaderRemoved) return;
          preloaderRemoved = true;

          const preloader = document.getElementById('app-preloader');
          const appContent = document.getElementById('app-content');

          if (preloader) {
            preloader.classList.add('fade-out');
            setTimeout(function() {
              preloader.remove();
            }, 500);
          }

          if (appContent) {
            appContent.classList.add('visible');
          }

        }

        // FORCE REMOVAL AFTER 7 SECONDS
        setTimeout(function() {
          hidePreloader('7-second force timeout');
        }, 6000);

        // Try to remove if Shiny connects
        $(document).on('shiny:connected', function() {
          setTimeout(function() {
            hidePreloader('Shiny connected');
          }, 6000);
        });

        // Optional: Try to remove when resources load
        window.addEventListener('load', function() {
          setTimeout(function() {
            hidePreloader('Resources loaded');
          }, 6000);
        });
      })();


    "
      )),
      tags$script(HTML(
        "
  window.onload = function () {
    // 1. Create a hidden dummy textarea
    if (!document.getElementById('hiddenEqInput')) {
      var hiddenInput = document.createElement('textarea');
      hiddenInput.id = 'hiddenEqInput';

      // Use the HTML 'hidden' attribute as requested
      hiddenInput.setAttribute('hidden', '');

      // SAFETY NET: Move it off-screen.
      // This prevents the library from making it visible if it overrides the 'hidden' attribute.
      hiddenInput.style.position = 'absolute';
      hiddenInput.style.left = '-9999px';
      hiddenInput.style.top = '0';
      hiddenInput.style.opacity = '0';

      document.body.appendChild(hiddenInput);
    }

    // 2. Link EqEditor to this hidden input
    var eqInterface = EqEditor.TextArea.link('hiddenEqInput');

    // 3. HIJACK the 'insert' method
    // This intercepts the LaTeX code from the toolbar and sends it to Ace instead
    eqInterface.insert = function(latex) {
      var editor = ace.edit('sourceEditor');
      if(editor) {
        editor.insert(latex);
        editor.focus();
      }
    };

    // 4. Initialize the Toolbar
    EqEditor.Toolbar.link('toolbar').addTextArea(eqInterface);
  }

  // sanity check
  if (typeof Split !== 'function') {
    console.error('Split.js failed to load.');
  }
"
      )),

      # ======================= THEME ===========================
      tags$style(HTML(
        "

/* Hide verified badge when class is not present */
.page-subtitle .text-success:not(.verified) {
  display: none !important;
}

#history button {
    background-color: transparent;
    border: 0;
    filter: invert(1) hue-rotate(180deg);
}

/* =============================== Layout =============================== */
#mainArea{
  height:94vh;
  display:flex;
  flex-wrap: nowrap; /* Prevent wrapping */
  width: 100%;       /* Ensure full width context */
  overflow:hidden;
  background:var(--tblr-body-bg)!important;
}

#utilityRail{
  width:38px;
  min-width:38px;
  background: var(--tblr-body-bg);
  border-right:1px solid var(--tblr-border-color);
  display:flex;
  flex-direction:column;
  align-items:center;
  padding:10px 6px;
}

#fileSidebar, #editorArea, #pdfPreview {
  height: 100%;
  color: var(--tblr-body-color)!important;

  /* PREVENT PANES FROM SHRINKING AUTOMATICALLY (Browser logic) */
  flex-shrink: 0 !important;
  flex-grow: 0 !important;

  /* FORCE PANES TO ACCEPT 0 WIDTH (Fixes gutters getting pushed off screen) */
  min-width: 0 !important;
  overflow: hidden !important;
}
#editorArea{
  border-right:0px solid var(--bs-border-color)!important;
}

#pdfViewUI.placeholder-active {
  height: auto;
  overflow: hidden;
}

#pdfPreview{
  display:flex;
  flex-direction:column;
}

/* === Move settings button to the bottom of the utility rail === */
#utilityRail {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  height: 100%;
}

#utilityRail .settings-button {
  margin-top: auto;
}

/* =============================== Sidebar =============================== */
#fileSidebar{
  border-right:1px solid var(--bs-border-color)!important;
  overflow:hidden;
}
#fileSidebar.collapsed{
  width:0!important;
  min-width:0!important;
  display:none!important;
}

#filesPane, #outlinePane{
  height:100%;
  display:flex;
  flex-direction:column;
  overflow:hidden;
}

#filesPane .pane-body {
  flex: 1;
  overflow-y: auto;
}

#filesPane .pane-body.collapsed {
  max-height: 0 !important;
  opacity: 0;
  overflow: hidden;
  padding: 0 !important;
}

#filesPaneChevron.rotated {
  transform: rotate(-90deg);
}

.btn-icon:hover {
  color: var(--bs-primary) !important;
  transform: scale(1.1);
}

#outlinePane .pane-body {
  flex: 1;
  overflow-y: auto;
}

#outlinePane .pane-body.collapsed {
  max-height: 0 !important;
  opacity: 0;
  overflow: hidden;
  padding: 0 !important;
}

#outlinePaneChevron.rotated {
  transform: rotate(-90deg);
}

/* ============================== Ace editor ============================== */
.ace_editor{
  border:1px solid var(--bs-border-color)!important;
  border-radius: 0px;
  box-shadow: none;
}
#editorSplit{
  height:calc(100% - 40px);
}

/* ============================== Ace Editor Scrollbar Visibility ============================== */
.ace_scrollbar {
  /* Firefox Support */
  scrollbar-color: var(--tblr-secondary) var(--tblr-bg-surface-secondary);
  scrollbar-width: thin;
}

/* Webkit (Chrome, Edge, Safari) Main Dimensions */
.ace_scrollbar::-webkit-scrollbar {
  width: 14px;  /* Width of the vertical rail */
  height: 14px; /* Height of the horizontal rail */
}

/* THE RAIL (TRACK) - Now styled to be visible */
.ace_scrollbar::-webkit-scrollbar-track {
  /* Use a secondary background color to distinguish the rail from the editor */
  background: var(--tblr-bg-surface-secondary, #f1f5f9) !important;
  border-left: 1px solid var(--tblr-secondary) !important; /* Border separates rail from code */
}

/* THE THUMB (HANDLE) */
.ace_scrollbar::-webkit-scrollbar-thumb {
  background-color: var(--tblr-secondary-color, #9ca3af) !important;
  border-radius: 10px;
  border: 3px solid transparent; /* Creates padding so thumb sits 'inside' the rail */
  background-clip: content-box;
}

/* Hover State */
.ace_scrollbar::-webkit-scrollbar-thumb:hover {
  background-color: var(--tblr-primary, #007bff) !important;
}

/* Corner where vertical and horizontal bars meet */
.ace_scrollbar::-webkit-scrollbar-corner {
  background: var(--tblr-bg-surface-secondary, #f1f5f9) !important;
}
/* ============================== Custom Ace Annotations ============================== */

.ace_gutter-cell.ace_error,
.ace_gutter-cell.ace_warning,
.ace_gutter-cell.ace_info {
  background-image: none !important;
  background-position: 0 !important;
}

.ace_gutter-cell.ace_error::before,
.ace_gutter-cell.ace_warning::before,
.ace_gutter-cell.ace_info::before {
  content: '';
  display: inline-block;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  margin-right: 8px;
  margin-left: -16px;
  vertical-align: middle;
}

.ace_gutter-cell.ace_error::before {
  background-color: #d63939;
  border: 1px solid #d6336c;
}

.ace_gutter-cell.ace_warning::before {
  background-color: #f59f00;
  border: 1px solid #f76707;
}

.ace_gutter-cell.ace_info::before {
  background-color: #4299e1;
  border: 1px solid #4263eb;
}

.ace_tooltip {
  display: none !important;
  visibility: hidden !important;
  opacity: 0 !important;
  pointer-events: none !important;
  border-radius: var(--tblr-border-radius) !important;
}

#custom-ace-tooltip {
  color: var(--tblr-body-color) !important;
}

.ace_error-marker {
  position: absolute;
  border-bottom: 2px dotted #d63939 !important;
  background: rgba(214, 57, 57, 0.05) !important;
  z-index: 1050 !important;
}

.ace_warning-marker {
  position: absolute;
  border-bottom: 2px dotted #f76707 !important;
  background: rgba(247, 103, 7, 0.05) !important;
  z-index: 1050 !important;
}

.ace_info-marker {
  position: absolute;
  border-bottom: 2px dotted #0054a6 !important;
  background: rgba(0, 84, 166, 0.05) !important;
  z-index: 1050 !important;
}

.ace_gutter-cell:hover {
  cursor: pointer;
}

/* =============================== PDF area =============================== */
#pdfPreview .pdf-header{
  padding:10px;
  background:var(--bs-light);
  border-bottom:1px solid var(--bs-border-color);
  color:var(--bs-body-color);
  display:flex;
  align-items:center;
  justify-content:space-between;
  /* Prevent header from shrinking/growing unexpectedly */
  flex: 0 0 38px;
}

/* ================================ Banners =============================== */
.banner{
  position:fixed;
  left:0;
  right:0;
  bottom: -1px;
  z-index:1052;
  background:var(--tblr-orange);
  color:var(--tblr-white);
  border: none;
  padding:1px 1px;
  border-radius: 0px;
  align-items: center;
  justify-content: center;
  text-align: center;

}

  justify-content: center;
  text-align: center;
}
.hidden{
  display:none!important;
}


/* ============================= Settings Overlay ============================ */
#settingsOverlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.5);
  z-index: 1060;
  display: none;
  opacity: 0;
  transition: opacity 0.3s ease;
  align-items: flex-start;
  justify-content: center;
}

#settingsOverlay.show {
  display: flex;
  opacity: 1;
}

.settings-dialog {
  background: var(--tblr-body-bg);
  border-radius: var(--tblr-border-radius);
  box-shadow: 0 0.5rem 2rem rgba(0, 0, 0, 0.175);
  width: 90%;
  max-width: 1000px;
  max-height: 85vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;

  margin: 5vh auto;
}

.settings-header {
  padding: 1.5rem;
  border-bottom: 1px solid var(--tblr-border-color);
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-shrink: 0;
}

.settings-header h3 {
  margin: 0;
}

.settings-body {
  display: flex;
  height: calc(85vh - 80px);
  overflow: hidden;
  flex: 1;
}

.settings-nav {
  width: 200px;
  min-width: 200px;
  border-right: 1px solid var(--tblr-border-color);
  padding: 1rem;
  overflow-y: auto;
  background: var(--tblr-bg-surface);
}

.settings-content {
  flex: 1;
  padding: 2rem;
  overflow-y: auto;
  background: var(--tblr-body-bg);
}

.settings-nav .nav-link {
  color: var(--tblr-body-color);
  padding: 0.5rem 1rem;
  border-radius: var(--tblr-border-radius);
  display: flex;
  align-items: center;
  margin-bottom: 0.25rem;
  text-decoration: none;
  transition: all 0.2s;
  cursor: pointer;
}

.settings-nav .nav-link:hover {
  background: var(--tblr-hover-bg);
}

.settings-nav .nav-link.active {
  background: var(--tblr-primary);
  color: var(--tblr-primary-fg);
}

.settings-nav .nav-link .icon {
  margin-right: 0.5rem;
}

/* Ensure tab content is visible */
.settings-content .tab-content {
  width: 100%;
}

.settings-content .tab-pane {
  display: none;
}

.settings-content .tab-pane.active {
  display: block;
}

/* ============================ Kebab & menu ============================ */
.kebab-wrap{
  position:relative;
  flex:0 0 auto;
}
.kebab-btn{
  width:0px;
  height:0px;
  display:flex;
  align-items:center;
  justify-content:center;
  background-color:inherit;
  cursor:pointer;
  font-weight:700;
  line-height:1;
  color:inherit;
  border:none !important;
}
.kebab-btn:hover{
  background-color:none !important;
  border:none !important;
}

.context-menu{
  position:fixed;
  min-width:14rem;
  z-index:1000;
  background-color: var(--tblr-body-bg) !important;
  border:1px solid var(--tblr-border-color) !important;
  border-radius: var(--tblr-border-radius);
  display:none;
  padding:.5rem 0;
  color: inherit;
  font-size:.875rem;
}
.context-menu.open{
  display:block;
}
.context-menu .menu-item{
  display:flex;
  align-items:center;
  padding:.25rem 1rem;
  color:inherit;
  text-decoration:none;
  cursor:pointer;
  line-height:1.71429;
  margin:0;
}
.context-menu .menu-item:hover{
  background-color: var(--tblr-border-color) !important;
  color:inherit;
  border-left: 4px solid var(--tblr-primary) !important;
}


/* --- PDF fills panel; console is split + collapsible --- */
#pdfPreview{
  display:flex;
  flex-direction:column;
}
#pdfContainer{
  flex:1 1 auto;
  overflow:hidden;
}

/* Console container cooperates with Split.js; header stays 36px */
#dockerConsoleContainer{
  overflow:hidden;
  border-top:1px solid var(--bs-border-color);
}
#dockerConsoleContainer .pdf-header{
  min-height:36px;
}
#dockerConsoleContainer .ace_editor{
  height:calc(100% - 36px) !important;
}

/* Collapsed state keeps only header visible (when not using Split sizing) */
#dockerConsoleContainer.collapsed{
  height:36px !important;
}
#dockerConsoleContainer.collapsed .ace_editor{
  height:0 !important;
  opacity:0;
  pointer-events:none;
}
/* ========================= PROJECT CARDS (Code Block Skin - Final) ========================= */

.projects-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.project-card {
  /* --- CUSTOM VARIABLES --- */
  --grad-start: #ef476f;
  --grad-end: var(--tblr-primary);
  --grad: linear-gradient(90deg, var(--grad-start), var(--grad-end));
  --muted: var(--tblr-secondary-color);

  /* --- THEME INTEGRATION --- */
  background: var(--tblr-bg-surface);
  color: var(--tblr-body-color);
  border: 1px solid var(--tblr-border-color);
  border-radius: var(--tblr-border-radius);

  /* --- LAYOUT & ANIMATION --- */
  position: relative;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  height: 100%;
  transition: transform 0.3s ease, box-shadow 0.3s ease, border-color 0.3s ease;
  cursor: pointer;
  padding: 0;
  box-sizing: border-box;
  box-shadow: var(--tblr-shadow-card, 0 4px 6px rgba(0, 0, 0, 0.05));
}

/* --- TOP GRADIENT BAR (Restored Hover Logic) --- */
.project-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 4px;
  background-image: var(--grad);
  transform: scaleX(0);
  transform-origin: center;
  transition: transform 0.35s ease;
  pointer-events: none;
  z-index: 20; /* Higher than header */
}

.project-card:hover::before {
  transform: scaleX(1);
}

/* --- HEADER (Full Width Project Name) --- */
.project-card .project-name {
  position: relative;
  width: 100%;
  height: 36px;
  border-bottom: 1px solid var(--tblr-border-color);
  padding: 0 12px;
  margin: 0;
  z-index: 10;
  box-sizing: border-box;

  /* Typography */
  font-family: 'Fira Code', monospace;
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--tblr-primary);
  text-transform: uppercase;
  letter-spacing: 0.5px;

  /* The Fix: Line-height handles the vertical centering for the first line */
  line-height: 36px;

  /* Truncation / Clamping */
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
  word-break: break-all; /* Prevents overflow before ellipsis kicks in */
}

/* --- BODY (Description) --- */
.project-card .project-description {
  font-family: 'Fira Code', monospace;
  font-size: 0.875rem;
  line-height: 1.5;
  padding: 1rem;
  margin-bottom: 5px;
  flex-grow: 1;
  color: inherit;

  /* Truncation */
  display: -webkit-box;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
  word-break: break-word;
  min-height: 50px;
}

/* --- FOOTER (Meta) --- */
.project-card .project-meta {
  display: flex;
  justify-content: space-between;
  font-size: 0.8em;
  color: var(--muted);
  margin-top: auto;
  padding: 12px 1rem;
  position: relative;
  background: rgba(0, 0, 0, 0.02);
}

.project-card .project-meta::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 2px;
  background-image: var(--grad);
  opacity: 0.8;
}

/* --- ACTIONS (Vertical & Right-Aligned) --- */
.project-actions {
  position: absolute;
  top: 5px; /* Moves below the 36px header */
  right: 8px;
  opacity: 0;
  transition: opacity 0.18s ease, transform 0.18s ease;
  display: flex;
  flex-direction: column; /* Restored Vertical */
  align-items: flex-end;
  gap: 2px;
  max-height: 95%;
  z-index: 15;
  pointer-events: none;
  transform: translateY(-1px);
}

.project-card:hover .project-actions,
.project-card.active .project-actions {
  opacity: 1;
  transform: translateY(0);
  pointer-events: auto;
}

.project-actions > * {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 4px;
  background: var(--tblr-bg-surface-secondary);
  border: 1px solid var(--tblr-border-color);
  border-radius: var(--tblr-border-radius);
  cursor: pointer;
  color: var(--tblr-body-color);
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

/* --- CARD HOVER EFFECTS --- */
.project-card:hover {
  border-color: var(--tblr-primary);
  transform: translateY(-1px);
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

[data-bs-theme='dark'] .project-card:hover {
  border-color: var(--tblr-primary);
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.project-card.active {
  border-color: var(--tblr-primary);
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

/* --- MODERN CUSTOM TOOLTIP (Shared) --- */
.ms-tooltip {
   position: fixed;
   pointer-events: none;
   /* Light mode: Dark background, White text */
   background: var(--tblr-gray-900);
   color: var(--tblr-gray-50);
   border: 1px solid var(--tblr-border-color);
   border-radius: var(--tblr-border-radius);
   padding: .25rem .5rem;
   font-family: var(--tblr-font-sans-serif);
   font-size: .76562rem;
   font-weight: 400;
   line-height: 1.71429;
   box-shadow: var(--tblr-shadow-card);
   z-index: 100000;
   opacity: 0;
   transform: translate(-50%, -100%) translateY(-10px);
   transition: opacity 0.1s ease, transform 0.1s ease;
   white-space: nowrap;
}
/* Dark mode: Light background, Dark text */
[data-bs-theme='dark'] .ms-tooltip {
   background: var(--tblr-gray-100);
   color: var(--tblr-gray-900);
}
.ms-tooltip.show {
   opacity: 1;
   transform: translate(-50%, -100%) translateY(-15px);
}

/* Empty State */
.empty-state {
  text-align: center;
  padding: 80px 20px;
  color: var(--muted);
}

.empty-state i {
  font-size: 4rem;
  margin-bottom: 20px;
  opacity: 0.5;
}

.empty-state h3 {
  margin-bottom: 10px;
  color: var(--text);
}
/* 1. Position the Container in the Top-Middle */
.alert-container {
  position: fixed;
  top: 20px !important;
  right: auto !important;
  left: 50% !important;
  transform: translateX(-50%) !important;
  z-index: 9060;
  display: flex;
  flex-direction: column;
  align-items: center;
  pointer-events: none;
}

/* 2. Update Alert Item Styles to target .toast */
.alert-container .toast {
  margin-bottom: 10px;
  animation: slideInDown 0.3s ease-out forwards !important;
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  pointer-events: auto;
  opacity: 1 !important; /* Override Bootstrap's hidden state */
}

/* 3. Update Removing Animation for .toast */
.toast.removing {
  animation: slideOutUp 0.3s ease-in forwards !important;
}

/* 4. Define Keyframes (Vertical instead of Horizontal) */
@keyframes slideInDown {
  from {
    transform: translateY(-100%);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

@keyframes slideOutUp {
  from {
    transform: translateY(0);
    opacity: 1;
  }
  to {
    transform: translateY(-100%);
    opacity: 0;
  }
}

/* ============================== Integrated File Preview (Panel Mode) ============================== */
#filePreviewOverlay {
  display: none;
  flex-direction: column;
  width: 100%;
  height: 100%; /* Fill the #editorArea container completely */
  background: var(--tblr-body-bg);
  overflow: hidden;
  box-sizing: border-box; /* Crucial for preventing layout shifts */
  color: var(--tblr-body-color);
}

#filePreviewDialog {
  display: flex;
  flex-direction: column;
  width: 100%;
  height: 100%;
  background: inherit;
  box-sizing: border-box;
}

#filePreviewHeader {
  padding: 0 16px;
  border-bottom: 1px solid var(--tblr-border-color);
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-shrink: 0; /* Never shrink the header */
  background: var(--tblr-body-bg);
  height: 40px; /* Fixed height to match editor toolbar if possible */
  box-sizing: border-box;
}

#filePreviewBody {
  flex: 1; /* Take remaining space */
  overflow: auto; /* Scroll internally */
  padding: 20px;
  display: flex;
  justify-content: center;
  align-items: flex-start;
  background: var(--tblr-body-bg);
  box-sizing: border-box;
  min-width: 0; /* Allow shrinking in flex container */
}

/* Image styling */
#filePreviewBody img {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
  box-shadow: 0 0 10px rgba(0,0,0,0.1);
}

/* PDF Object styling */
#filePreviewBody object {
  width: 100%;
  height: 100%;
  display: block;
  border: none;
}

/* Text styling */
#filePreviewBody pre {
  width: 100%;
  background: #282c34 !important;
  color: #abb2bf !important;
  padding: 0;
  border-radius: var(--tblr-border-radius);
  position: relative;
  margin: 12px 0;
  border: 1px solid rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

/* ============================== Dropzone Styling ============================== */
.dropzone {
  min-height: 300px;
  border: 2px dashed var(--tblr-border-color);
  background: var(--bs-body-bg);
  border-radius: var(--tblr-border-radius);
  padding: 2rem;
  transition: all 0.3s ease;
}

.dropzone:hover {
  border-color: var(--tblr-primary);
  background: var(--tblr-primary-bg-subtle);
}

.dropzone .dz-message {
  text-align: center;
  margin: 2rem 0;
  color: var(--bs-body-color);
}

.dropzone-msg-title {
  font-size: 1.2rem;
  font-weight: 600;
  margin-bottom: 0.5rem;
  color: var(--bs-body-color);
}

.dropzone-msg-desc {
  color: var(--bs-secondary-color);
  font-size: 0.875rem;
}

.dropzone .dz-preview {
  margin: 1rem;
}

.dropzone .dz-preview .dz-image {
  border-radius: var(--tblr-border-radius);
  overflow: hidden;
}

.dropzone .dz-preview .dz-details {
  background: var(--tblr-bg-surface);
  padding: 0.5rem;
  border-radius: var(--tblr-border-radius);
}

.dropzone .dz-preview .dz-filename {
  color: var(--bs-body-color);
}

.dropzone .dz-preview .dz-size {
  color: var(--bs-secondary-color);
}

.dropzone .dz-preview.dz-success .dz-success-mark,
.dropzone .dz-preview.dz-error .dz-error-mark {
  opacity: 1;
}

/* Close sidebar button */
#closeSidebarBtn {
  opacity: 0.7;
  font-size: 1.1rem;
}

#closeSidebarBtn:hover {
  opacity: 1;
  color: var(--bs-danger) !important;
  transform: scale(1.1);
}

#closeSidebarBtn:focus {
  outline: 2px solid var(--tblr-primary);
  outline-offset: 2px;
}

#closeSidebarBtn:active {
  transform: scale(0.95);
}

/* ============================== Error Log Console ============================== */
#errorLogConsole {
  display: none;
  height: 100%;
  flex-direction: column;
  background-color: var(--tblr-body-bg);
  color: var(--tblr-body-color);

}

#errorLogConsole.active {
  display: flex;
}

.error-log-header {
  padding: 10px 12px;
  padding-bottom: 0;
  display: flex;
  justify-content: space-between;
  align-items: center;
  min-height: 40px;
  background: var(--tblr-border-color);
}

.error-log-header h5 {
  margin: 0;
  font-size: 0.875rem;
  font-weight: 600;
  letter-spacing: 0.01em;
  padding-bottom: 0;
}

.error-log-tabs {
  display: flex;
  gap: 4px;
  padding: 6px 12px 0;
  background: var(--tblr-border-color);
}

.error-log-tab {
  padding: 8px 16px;
  cursor: pointer;
  font-size: 0.875rem;
  font-weight: 500;
  transition: all 0.2s ease;
  color: var(--tblr-secondary-color);
  display: flex;
  align-items: center;
  gap: 8px;
  background: var(--tblr-border-color);
}

.error-log-tab:hover {
  background: var(--tblr-border-color);
  color: var(--tblr-body-color);
}

.error-log-tab.active {
  color: var(--tblr-body-color);
  background: var(--tblr-body-bg);
}

.error-log-tab .count {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 20px;
  height: 20px;
  padding: 0 6px;
  border-radius: 10px;
  font-size: 0.75rem;
  font-weight: 600;
  line-height: 1;
  white-space: nowrap;
}

/* Errors */
.error-log-tab.tab-errors .count {
  background-color: var(--tblr-red-lt);
  color: var(--tblr-red);
}

/* Warnings */
.error-log-tab.tab-warnings .count {
  background-color: var(--tblr-orange-lt);
  color: var(--tblr-orange);
}

/* Info */
.error-log-tab.tab-info .count {
  background-color: var(--tblr-blue-lt);
  color: var(--tblr-blue);
}

/* All */
.error-log-tab.tab-all .count {
  background-color: var(--tblr-gray-200);
  color: var(--tblr-gray-800);
}

/* Tone down badge when tab is active */
.error-log-tab.active .count {
  opacity: 0.85;
}


.error-log-body {
  flex: 1;
  overflow-y: auto;
  padding: 12px;
  background-color: var(--tblr-body-bg);
}

.error-log-item {
  padding: 12px;
  margin-bottom: 8px;
  border-radius: var(--tblr-border-radius);
  cursor: pointer;
  transition: all 0.2s ease;
  border-left: 3px solid;

}

.error-log-item:hover {
  transform: translateX(-2px);
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.error-log-item.error {
  background: var(--tblr-red-lt);
  border-left-color: var(--tblr-red);
  color: var(--tblr-red-fg);
}

.error-log-item.warning {
  background: var(--tblr-orange-lt);
  border-left-color: var(--tblr-orange);
  color: var(--tblr-orange-fg);
}

.error-log-item.info {
  background: var(--tblr-blue-lt);
  border-left-color: var(--tblr-blue);
  color: var(--tblr-blue-fg);
}

.error-log-item-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
}

.error-log-type {
  display: flex;
  align-items: center;
  gap: 6px;
  font-weight: 600;
  font-size: 0.875rem;
}

.error-log-item.error .error-log-type {
  color: var(--tblr-red);
}

.error-log-item.warning .error-log-type {
  color: var(--tblr-orange);
}

.error-log-item.info .error-log-type {
  color: var(--tblr-blue);
}

.error-log-line {
  font-size: 0.75rem;
  padding: 2px 8px;
  border-radius: var(--tblr-border-radius);
  background: var(--tblr-body-bg);
  font-family: monospace;
}

.error-log-item.error .error-log-line {
  color: var(--tblr-red);
  background: rgba(var(--tblr-red-rgb), 0.1);
}

.error-log-item.warning .error-log-line {
  color: var(--tblr-orange);
  background: rgba(var(--tblr-orange-rgb), 0.1);
}

.error-log-item.info .error-log-line {
  color: var(--tblr-blue);
  background: rgba(var(--tblr-blue-rgb), 0.1);
}

.error-log-message {
  font-size: 0.875rem;
  line-height: 1.4;
}

.error-log-item.error .error-log-message {
 color: var(--tblr-secondary-color);
}

.error-log-item.warning .error-log-message {
  color: var(--tblr-secondary-color);
}

.error-log-item.info .error-log-message {
  color: var(--tblr-secondary-color);
}

.error-log-empty {
  text-align: center;
  padding: 40px 20px;
  color: var(--tblr-secondary-color);
}

.error-log-empty i {
  font-size: 3rem;
  margin-bottom: 16px;
  opacity: 0.5;
  color: var(--tblr-green);
}

.error-log-body::-webkit-scrollbar {
  width: 6px;
}

.error-log-body::-webkit-scrollbar-thumb {
  background-color: var(--tblr-secondary-color);
  border-radius: var(--tblr-border-radius);
}

.error-log-body::-webkit-scrollbar-thumb:hover {
  background-color: var(--tblr-primary);
}


/* Console container with tabs for switching between console and error log */
#dockerConsoleContainer {
  overflow: hidden;
  border-top: 1px solid var(--tblr-border-color);
  display: flex;
  flex-direction: column;
}

#dockerConsoleContainer .console-tabs {
  display: flex;
  border-bottom: 1px solid var(--tblr-border-color);
  min-height: 36px;
}

#dockerConsoleContainer .console-tab {
  padding: 8px 16px;
  cursor: pointer;
  font-size: 0.875rem;
  font-weight: 500;
  border-bottom: 2px solid transparent;
  transition: all 0.2s ease;
  color: var(--tblr-secondary-color);
  display: flex;
  align-items: center;
  gap: 8px;
}

#dockerConsoleContainer .console-tab:hover {
  background: var(--tblr-border-color);
  color: var(--tblr-body-color);
}

#dockerConsoleContainer .console-tab.active {
  color: var(--tblr-primary);
  border-bottom-color: var(--tblr-primary);
  background: var(--tblr-body-bg);
}

#dockerConsoleContainer .console-content {
  flex: 1;
  overflow: hidden;
  position: relative;
}

#dockerConsoleContainer .ace_editor {
  display: none;
  height: 100% !important;
}

#dockerConsoleContainer .ace_editor.active {
  display: block;
}

/* Collapsed state */
#dockerConsoleContainer.collapsed {
  height: 36px !important;
}

#dockerConsoleContainer.collapsed .console-content,
#dockerConsoleContainer.collapsed .ace_editor,
#dockerConsoleContainer.collapsed #errorLogConsole {
  height: 0 !important;
  opacity: 0;
  pointer-events: none;
}


.page-body,
.page-wrapper,
.container-xl,
.container-fluid {
  padding-top: 0 !important;
  margin-top: 0 !important;
  padding-left: 0 !important;
  padding-right: 0 !important;
}

body {
  padding-left: 0 !important;
  padding-right: 0 !important;
}

:root{
 --nav-height:30px;
}

.navbar {
  margin-bottom: 0 !important;
  padding-top: 0.1rem !important;
  padding-bottom: 0.1rem !important;
  min-height: 0 !important;
  border-radius: 0 !important;
}

.navbar .avatar,
.navbar .avatar-sm {
  width: calc(var(--nav-height) - 2px) !important;
  height: calc(var(--nav-height) - 2px) !important;
  min-width: 0 !important;
  display: inline-block !important;
}

.navbar .container,
.navbar .container-fluid {
  height: var(--nav-height) !important;
  padding-top: 0 !important;
  padding-bottom: 0 !important;
  margin-top: 0 !important;
  margin-bottom: 0 !important;
}

.navbar > * {
  align-self: center !important;
  max-height: var(--nav-height) !important;
}

/* Header Status Bar Styles - NEW SPLIT HEADER CSS */
.navbar-status-group {
  display: flex;
  align-items: center;
  gap: 5px;
  white-space: nowrap;
  overflow: hidden;
}

.nav-divider {
  width: 1px;
  height: 20px;
  background-color: var(--tblr-border-color);
  margin: 5px 5px;
  flex-shrink: 0;
  min-height: 20px;
  align-self: center;
}

.status-item-text {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  display: block;
}

/* Limits for the two sections */
.status-section-citation {
  min-width: 40px;
  max-width: 200px;
}

.status-section-context {
  min-width: 200px;
  max-width: 1000;
}

#activeProjectName, #statusBar, #citationCount {
  display: block;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

#activeProjectName { max-width: 150px; }
#statusBar { max-width: 500px; }

/* hide radio buttons on form */
.dropdown-item input[type='radio'] {
      display: none;
}
.dropdown-item .tick-icon {
  opacity: 0;
  transition: opacity 0.2s ease;
  margin-right: 0.5em;
}
.dropdown-item input[type='radio']:checked + .tick-icon {
  opacity: 1;
}

/* Inline Rename Input Styling */
  .rename-input {
    border: 2px solid var(--tblr-primary);
    padding: 1px 4px;
    font-size: inherit;
    font-family: inherit;
    border-radius: var(--tblr-border-radius);
    background: var(--tblr-bg-surface);
    color: var(--tblr-body-color);
    outline: none;
    width: 100%;
    min-width: 60px;
    height: 24px;
  }

/* 1. Make the Pane Bodies relative so absolute positioning works inside them */
#filesPaneBody,
#outlinePaneBody {
  position: relative !important;
  min-height: 200px; /* Ensure there is height to center within */
}

/* 2. Position the Spinner Wrapper exactly in the center */
#filesSpinner,
#outlineSpinner,
#editorSpinner,
#historyFilesSpinner,
#historyVersionsSpinner {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  z-index: 100;
  margin-left: 0 !important;
}

/* 3. Style the Spinner Animation */
#filesSpinner .spinner-border,
#outlineSpinner .spinner-border,
#editorSpinner .spinner-border,
#historyFilesSpinner .spinner-border,
#historyVersionsSpinner .spinner-border {
  width: 3rem;  /* Make them slightly larger for better visibility */
  height: 3rem;
  animation: spinner-border 0.75s linear infinite;
  color: var(--tblr-primary);
}

@keyframes spinner-border {
  to { transform: rotate(360deg); }
}


/* ================================= Gutters =============================== */
.gutter.gutter-horizontal{
  cursor:col-resize;
  background:var(--tblr-border-color);
  box-shadow:inset 0 -1px 0 var(--tblr-border-color), inset 0 1px 0 var(--tblr-border-color);
}
.gutter.gutter-horizontal:hover{
  background:var(--tblr-border-color);
}
.gutter.gutter-vertical{
  cursor:row-resize;
  background:var(--tblr-border-color);
  box-shadow:inset 0 -1px 0 var(--tblr-border-color), inset 0 1px 0 var(--tblr-border-color);
}
.gutter.gutter-vertical:hover{
  background:var(--tblr-border-color);
}

/* --- GUTTER STYLES --- */
.gutter.gutter-horizontal {
    cursor: col-resize;
    background: var(--tblr-border-color);
    position: relative;
    z-index: 4;

    /* Center content (the button) */
    display: flex !important;
    align-items: center;
    justify-content: center;

    /* Allow button to be wider than the gutter without being clipped */
    overflow: visible !important;

    /* Layout strictness */
    flex-shrink: 0 !important;
    flex-grow: 0 !important;
    width: 8px !important;
    min-width: 8px !important;
}

/* The Chevron Button */
.gutter-collapse-btn {
    /* Absolute centering relative to the gutter */
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);

    /* Rectangle Dimensions */
    width: 8px;
    height: 48px;

    /* Visual Style */
    background: var(--tblr-secondary);
    color: white;
    border-radius: 0px;

    /* Flex to center the chevron icon inside the button */
    display: flex;
    align-items: center;
    justify-content: center;

    cursor: pointer;
    font-size: 10px;
    transition: all 0.2s ease;
    pointer-events: auto;
}

.gutter-collapse-btn:hover {
    background: var(--tblr-primary);
}

/* Override previous specific left/right positioning to ensure they stay centered */
.gutter.gutter-horizontal:nth-of-type(2) .gutter-collapse-btn,
.gutter.gutter-horizontal:nth-of-type(4) .gutter-collapse-btn {
    left: 50%;
    right: auto;
    border-radius: 0px;
}

/* Force Hide Class */
.pane-collapsed {
    width: 0 !important;
    min-width: 0 !important;
    flex: 0 0 0 !important;
    padding: 0 !important;
    margin: 0 !important;
    border: none !important;
    overflow: hidden !important;
    opacity: 0 !important;
    pointer-events: none !important;
}

/* =================== PDF Invert (Dark Mode) =================== */
/* 1. Invert the container to make the white pages dark */
#pdfContainer.inverted {
  filter: invert(1) hue-rotate(180deg);
}

#pdfContainer.inverted object,
#pdfContainer.inverted embed,
#pdfContainer.inverted iframe {
  background-color: transparent !important;
}

/* Remove number input spinner buttons */
#pdfPageInput::-webkit-outer-spin-button,
#pdfPageInput::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
}

#pdfPageInput[type=number] {
  -moz-appearance: textfield;
}

/* =================== NAVBAR BADGES (LABELS & CITATIONS) =================== */
.nav-badge-container {
  position: relative;
  display: inline-flex !important;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  cursor: pointer;
}

.nav-badge-counter {
  position: absolute;
  top: 0;
  right: 0;
  min-width: 16px;
  height: 16px;
  padding: 0 4px;
  border-radius: 8px;
  background-color: #2fb344 !important; /* Always Green */
  color: #ffffff !important;            /* Always White */
  font-size: 9px;
  font-weight: 700;
  line-height: 16px;
  text-align: center;
  display: none; /* Hidden by default */
  z-index: 10;
  pointer-events: none;
  box-shadow: 0 1px 2px rgba(0,0,0,0.2);
}

.nav-badge-counter.show {
  display: inline-block;
}


/* Only hide badge if we are explicitly looking at the errors */
#railErrorLogBtn.hide-badge .nav-badge-counter {
  display: none !important;
  opacity: 0;
  pointer-events: none;
}

/* =================== FILE SEARCH STYLES =================== */
.search-result-group {
  margin-bottom: 12px;
  border: 1px solid var(--tblr-border-color);
  border-radius: var(--tblr-border-radius);
  overflow: hidden;
  background: var(--tblr-bg-surface);
  width: 98%;
  margin-left: auto;
  margin-right: auto;
  justify-content: center;
  min-height: 50px;
}

.search-result-file {
  padding: 6px 8px;
  background: var(--tblr-bg-surface-secondary);
  border-bottom: 1px solid var(--tblr-border-color);
  font-weight: 600;
  font-size: 0.85rem;
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
}

.search-result-file:hover {
  color: var(--tblr-primary);
}

.search-result-snippet {
  padding: 4px 8px;
  font-family: var(--tblr-font-monospace);
  font-size: 0.75rem;
  color: var(--tblr-secondary-color);
  cursor: pointer;
  border-bottom: 1px solid var(--tblr-border-color-light);
  display: flex;
  gap: 8px;
}

.search-result-snippet:last-child {
  border-bottom: none;
}

.search-result-snippet:hover {
  background: var(--tblr-primary-bg-subtle);
  color: var(--tblr-body-color);
}

.snippet-line-num {
  color: var(--tblr-gray-500);
  min-width: 24px;
  text-align: right;
  user-select: none;
}

.snippet-content {
  white-space: pre-wrap;
  word-break: break-all;
}

.search-highlight {
  background-color: rgba(255, 229, 100, 0.4);
  color: var(--tblr-body-color);
  font-weight: 700;
  border-radius: var(--tblr-border-radius);
  padding: 0 1px;
}

[data-bs-theme='dark'] .search-highlight {
  background-color: rgba(255, 215, 0, 0.25);
  color: #fff;
}


/* =================== REVIEW PANE & COMMENTS (FINAL) =================== */
#reviewPane {
  z-index: 20;
  border-right: 1px solid var(--tblr-border-color);
  backdrop-filter: blur(10px);
  display: flex;
  flex-direction: column;
}

/* Base Card Style */
.comment-card {
  background: var(--tblr-bg-surface);
  border: 1px solid var(--tblr-border-color);
  border-radius: var(--tblr-border-radius);
  padding: 12px;
  margin-bottom: 12px;
  transition: all 0.2s ease;
  position: relative;
  border-left: 3px solid var(--tblr-primary);
  min-width: 250px;
}

.comment-card:hover {
  border-color: var(--tblr-border-color-dark);
}

.comment-card.resolved {
  opacity: 0.6;
  border-left-color: var(--tblr-success);
  background: var(--tblr-bg-surface-secondary);
}

.comment-card.active-comment {
  border-color: var(--tblr-primary);
  background-color: var(--tblr-primary-bg-subtle) !important;
}

/* Ace Markers (RESTORED) */
.ace_comment_highlight {
  position: absolute;
  background-color: rgba(255, 229, 100, 0.25);
  border-bottom: 2px dotted rgba(241, 196, 15, 0.7);
  z-index: 2;
  transition: all 0.2s ease;
}

[data-bs-theme='dark'] .ace_comment_highlight {
  background-color: rgba(255, 215, 0, 0.2);
  border-bottom-color: rgba(255, 215, 0, 0.6);
}

.ace_active_comment_highlight {
  position: absolute;
  background-color: rgba(255, 229, 100, 0.6) !important;
  border-bottom: 2px dotted #f1c40f !important;
  z-index: 3;
}

[data-bs-theme='dark'] .ace_active_comment_highlight {
  background-color: rgba(255, 215, 0, 0.35) !important;
  border-bottom-color: rgba(255, 215, 0, 0.8) !important;
}

/* Header & Avatar */
.comment-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 8px;
}

.comment-user {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 600;
  font-size: 0.85rem;
  z-index: 2;
  position: relative;
  white-space: nowrap;
  text-overflow: ellipsis;
  width: 100%;
}

.comment-meta {
  font-size: 0.7rem;
  color: var(--tblr-secondary);
  display: flex;
  align-items: center;
  gap: 6px;
  white-space: nowrap;
  text-overflow: ellipsis;
}

/* Content Body */
.comment-body {
  font-size: 0.85rem;
  line-height: 1.5;
  color: var(--tblr-body-color);
  white-space: pre-wrap;
  margin-bottom: 8px;
  padding-left: 2px;
  margin-left: 26px;
}

/* Actions Bar */
.comment-actions {
  display: flex;
  gap: 10px;
  padding-top: 6px;
  border-top: 1px solid var(--tblr-border-color-light);
}

.cmd-btn {
  background: none;
  border: none;
  font-size: 0.75rem;
  color: var(--tblr-secondary);
  font-weight: 600;
  padding: 2px 6px;
  border-radius: var(--tblr-border-radius);
  transition: all 0.2s;
}
.cmd-btn:hover { background: var(--tblr-bg-surface-secondary); color: var(--tblr-primary); }
.cmd-btn.resolve:hover { color: var(--tblr-success); }

/* =================== NESTED THREAD LINES =================== */

.reply-thread {
  margin-top: 8px;
  position: relative;
}

.reply-item {
  position: relative;
  margin-top: 8px;
  background: var(--tblr-bg-surface-secondary);
  border: 1px solid var(--tblr-border-color-light);
  border-radius: var(--tblr-border-radius);
  padding: 8px 10px;
}

/* Indentation for Nested Replies */
.nested-reply-container {
  margin-left: 26px; /* Indent child */
}

/* THE CURVED GUIDE LINE */
.nested-reply-container::before {
  content: '';
  position: absolute;
  top: -24px;       /* Reach up to parent */
  left: -17px;      /* Align with parent avatar center */
  width: 15px;      /* Width of the horizontal part of 'L' */
  height: 40px;     /* Height of the vertical part of 'L' */
  border-left: 1px solid var(--tblr-secondary-color);
  border-bottom: 1px solid var(--tblr-secondary-color);
  border-bottom-left-radius: 12px; /* The Curve */
  pointer-events: none;
  z-index: 0;
}

/* Fix z-index so avatars sit ON TOP of the guide lines */
.reply-item .comment-user {
  position: relative;
  z-index: 1;
  position: relative;
  white-space: nowrap;
  text-overflow: ellipsis;
  width: 100%;
}

/* Reply Input Areas */
.reply-textarea {
  width: 100%;
  border: 1px solid var(--tblr-border-color);
  border-radius: var(--tblr-border-radius);
  padding: 6px;
  font-size: 0.85rem;
  resize: none;
  background: var(--tblr-bg-surface);
  color: var(--tblr-body-color);
}
.reply-textarea:focus {
  outline: none;
  border-color: var(--tblr-primary);
}

.reply-input-area { display: none; margin-top: 8px; }
.reply-input-area.show { display: block; animation: fadeIn 0.2s ease; }

/* Floating Tooltip */
.comment-tooltip {
  position: absolute;
  z-index: 1000;
  background: var(--tblr-body-bg);
  border-radius: var(--tblr-border-radius);
  padding: 2px;
  animation: fadeIn 0.2s ease;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}
.comment-tooltip button {
  background: transparent;
  border: none;
  color: var(--tblr-body-color);
  padding: 4px 10px;
  cursor: pointer;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.85rem;
}
.comment-tooltip button:hover {
  color: var(--tblr-primary);
}

/* =================== REVIEW PANE FOOTER TABS =================== */
.review-footer {
  display: flex;
  height: 40px;
  min-height: 40px;
  border-top: 1px solid var(--tblr-border-color);
  background: var(--tblr-bg-surface);
  flex-shrink: 0; /* Prevent shrinking */
}

.review-tab {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--tblr-secondary);
  transition: all 0.2s ease;
  border-top: 2px solid transparent;
  user-select: none;
}

.review-tab:hover {
  background: var(--tblr-bg-surface-secondary);
  color: var(--tblr-body-color);
}

.review-tab.active {
  color: var(--tblr-primary);
  border-top-color: var(--tblr-primary);
  background: var(--tblr-primary-bg-subtle);
}


/* Dropdown positioning fixes */

.reply-header .dropdown {
  position: static !important;
}

.reply-header .dropdown-menu {
  position: absolute !important;
  right: 0;
  top: 100%;
  z-index: 1000;
}

/* Ensure dropdown doesn't break out of reply card */
.reply-item {
  position: relative;
  overflow: visible !important;
}

/* Make sure dropdown toggle has proper cursor */
.dropdown-toggle {
  cursor: pointer;
}

/* Fix for nested dropdowns */
.nested-reply-container .dropdown-menu {
  transform: translate(0, 0) !important;
}

/* Spell Error Marker */
.misspelled {
  position: absolute;
  z-index: 2000 !important;
  border-bottom: 2px dotted #d63939; /* Red underline */
}

/* Spellcheck Suggestion Box */
#spell-suggestions {
  display: none;
  position: fixed;
  z-index: 10000;
  background: var(--tblr-bg-surface, #fff);
  border: 1px solid var(--tblr-border-color, #ccc);
  border-radius: var(--tblr-border-radius);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  min-width: 150px;
  max-height: 200px;
  overflow-y: auto;
  font-family: inherit;
  font-size: 0.75rem;
}

.suggestion-item {
  padding: 6px 8px;
  cursor: pointer;
  color: var(--tblr-body-color);
  transition: background 0.1s ease;
  border-left: 3px solid transparent;
}

.suggestion-item:hover {
  background-color: var(--tblr-primary-bg-subtle);
  color: var(--tblr-primary);
  border-left-color: var(--tblr-primary);
}

.suggestion-header {
  padding: 4px 12px;
  font-size: 0.75rem;
  color: #888;
  background: var(--tblr-bg-surface-secondary, #f8f9fa);
  pointer-events: none;
}


/* =================== PREMIUM AUTOCOMPLETE STYLING =================== */
.autocomplete-popup {
  position: fixed;
  z-index: 10000; /* High z-index to sit above editor */
  background: var(--tblr-bg-surface, #fff);
  border: 1px solid var(--tblr-border-color, #ccc);
  border-radius: var(--tblr-border-radius);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  min-width: 150px;
  max-height: 200px;
  overflow-y: auto;
  font-family: inherit;
  font-size: 0.75rem;
  display: flex;
  flex-direction: column;
}

.autocomplete-header {
  padding: 6px 8px;
  font-size: 0.7rem;
  font-weight: 600;
  text-transform: uppercase;
  color: var(--tblr-secondary);
  background: var(--tblr-bg-surface-secondary, #f8f9fa);
  border-bottom: 1px solid var(--tblr-border-color-light);
  pointer-events: none;
  flex-shrink: 0; /* Keeps header visible */
  letter-spacing: 0.5px;
}

.autocomplete-item {
  padding: 6px 8px;
  cursor: pointer;
  color: var(--tblr-body-color);
  transition: background 0.1s ease;
  border-left: 3px solid transparent; /* Indicator strip */
}

/* Hover & Active State */
.autocomplete-item:hover, .autocomplete-item.active {
  background-color: var(--tblr-primary-bg-subtle);
  color: var(--tblr-primary);
  border-left-color: var(--tblr-primary);
}



/* =================== CHAT PANE STYLES =================== */
#chatContent::-webkit-scrollbar {
  width: 6px;
}
#chatContent::-webkit-scrollbar-thumb {
  background-color: var(--tblr-border-color);
  border-radius: 4px;
}

.badge-blink {
  animation: blink-animation 1s steps(5, start) infinite;
}
@keyframes blink-animation {
  to { visibility: hidden; }
}

/* Tabler Card Adjustments for Chat */
.chat-avatar .avatar {
  width: 32px;
  height: 32px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

/* Enter key support for textarea */
#chatInputMsg {
  border: 1px solid var(--tblr-border-color);
}
#chatInputMsg:focus {
  border-color: var(--tblr-primary);
  box-shadow: 0 0 0 2px var(--tblr-primary-bg-subtle);
}


/* Show action menu on hover */
.message-group:hover .dropdown {
  opacity: 1 !important;
}

/* Floating Button Animation */
#chatScrollBtn {
  transition: transform 0.2s;
}
#chatScrollBtn:active {
  transform: scale(0.95);
}

/* Emoji Grid */
.emoji-btn {
  font-size: 1.2rem;
  width: 36px;
  height: 36px;
}



/* --- HISTORY MODE CSS --- */
#historyOverlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 103vh;
  background: var(--tblr-body-bg);
  z-index: 2000;
  display: none;
  flex-direction: column;
}

#historyOverlay.show {
  display: flex;
}

/* Sidebar Cards */
.history-card {
  background: var(--tblr-bg-surface-secondary);
  border: 1px solid var(--tblr-border-color);
  border-radius: var(--tblr-border-radius);
  padding: 12px;
  margin-bottom: 10px;
  cursor: pointer;
  border-left: 4px solid var(--tblr-primary);
  transition: all 0.2s ease;
}

.history-card:hover {
  border-color: var(--tblr-border-color-dark);
}

.history-card.active {
  background-color: var(--tblr-bg-surface) !important;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
  border-color: var(--tblr-primary-bg-subtle);
  border-left-color: var(--tblr-primary) !important; /* Blue Strip */
}

/* History Tags */
.history-tag {
  font-size: 9px;
  text-transform: uppercase;
  font-weight: 700;
  padding: 2px 6px;
  border-radius: 4px;
  letter-spacing: 0.5px;
}

.tag-added { color: #2fb344; background: rgba(47, 179, 68, 0.1); }
.tag-edited { color: #4299e1; background: rgba(66, 153, 225, 0.1); }
.tag-deleted { color: #d63939; background: rgba(214, 57, 57, 0.1); }

/* Ace Highlights */
.history-marker-added {
    background-color: rgba(46, 164, 79, 0.2);
    position: absolute;
    z-index: 20;
    border-bottom: 2px solid #2ea44f;
}

.history-marker-deleted {
    background-color: rgba(209, 36, 47, 0.4);
    position: absolute;
    z-index: 20;
    width: 3px !important;
}

/* Message Pane for Non-Editable Files */
.history-message-pane {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: var(--tblr-secondary);
  background: var(--tblr-bg-surface-secondary);
  text-align: center;
}

/* Custom Floating Tooltip for History */
#historyTooltip {
  position: fixed;
  display: none;
  z-index: 2100;
  background: var(--tblr-gray-800);
  color: white;
  padding: 6px 12px;
  border-radius: 4px;
  font-size: 12px;
  pointer-events: none;
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  max-width: 250px;
  line-height: 1.4;
}



/* Sets the main text font size */
#inputLatex {
  font-size: 12px !important;
  background: var(--tblr-border-color) !important;
}

/* Simulates the placeholder */
#inputLatex:empty::before {
  content: attr(placeholder);
  color: var(--tblr-body-color); /* Standard gray placeholder color */
  font-size: 12px; /* Matches input size */
  pointer-events: none; /* Allows clicking through the text to focus the div */
  display: block; /* Ensures it renders correctly */
}

/* Blinking Mic Icon Animation */
.icon-blink {
  animation: icon-pulse 1.5s infinite ease-in-out;
}

@keyframes icon-pulse {
  0% { opacity: 1; }
  50% { opacity: 0.4; } /* Fades to 40% opacity */
  100% { opacity: 1; }
}



/* --- Nested Dropdown Support for Bootstrap 5 --- */
.dropdown-menu .dropend {
  position: relative;
}
.dropdown-menu .dropend .dropdown-toggle {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
}
.dropdown-menu .dropend .dropdown-toggle::after {
  transform: rotate(-135deg); /* Point right */
  margin-left: auto;
}

/* --- History Gutters --- */
#historyContainer .gutter.gutter-horizontal {
    cursor: col-resize;
    background: var(--tblr-border-color);
    position: relative;
    z-index: 10;
    display: flex !important;
    align-items: center;
    justify-content: center;
    overflow: visible !important;
    flex-shrink: 0 !important;
    flex-grow: 0 !important;
    width: 6px !important;
    min-width: 6px !important;
}

#historyContainer .gutter.gutter-horizontal:hover {
    background: var(--tblr-primary);
    opacity: 0.5;
}

.dropdown-menu .dropend:hover > .dropdown-menu {
  display: block;
  top: 0;
  left: 100%;
  margin-top: -5px;
}

/* --- UPDATED: Editor Area Layout (Flex Column) --- */
#editorArea {
  border-right: 0px solid var(--bs-border-color)!important;
  display: flex !important;
  flex-direction: column !important;
  overflow: hidden !important;
  position: relative !important;
}

/* Force Ace Editor to fill remaining space */
#editorArea #sourceEditor {
  flex: 1 1 auto !important;
  height: 100% !important;
}

#symbolPalette {
  display: none;
  position: absolute !important;
  bottom: 0;
  left: 0;
  width: 100%;
  height: 200px;
  background: var(--tblr-border-color);
  border-top: 4px solid var(--tblr-border-color);
  z-index: 10;
  flex-direction: column;
  box-shadow: 0 -4px 10px rgba(0,0,0,0.1);
}

#symbolPalette.show {
  display: flex;
}

.symbol-btn {
  font-family: 'Times New Roman', serif;
  font-size: 1.2rem;
  width: 40px;
  height: 40px;
  margin: 2px;
  background: var(--tblr-bg-surface-secondary);
  border: 0;
  border-radius: var(--tblr-border-radius);
  color: var(--tblr-body-color);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s;
}

.symbol-btn {
  font-size: 1.7rem;
}

#symbolPalette .tab-content {
  display: flex;
  gap: 4px;
  padding: 10px;
  overflow-y: auto;
  max-height: 150px;
  margin-top: -1px;
  background: var(--tblr-border-color);
}

#symbolPalette .nav-tabs {
  flex-wrap: nowrap;
  overflow-x: auto;
  white-space: nowrap;
  overflow-y: hidden;
  border-radius: 0 !important;
  background: var(--tblr-bg-surface-secondary);
  color: var(--tblr-body-color);
  border-bottom: none;
}

#symbolPalette .nav-tabs .nav-link {
  padding: 5px 10px;
  font-size: 0.85rem;
  border: none;
  background: transparent;
}

#symbolPalette .nav-tabs .nav-link.active {
  padding: 5px 10px;
  font-size: 0.85rem;
  border-bottom-color: var(--tblr-border-color);
  background: var(--tblr-border-color);
  border-radius: 0 !important;
}



/* ================= FIGURE OVERLAY (Exact Match to Settings) ================= */
#figureOverlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.5); /* Dimmed background */
  z-index: 1060;                  /* High z-index to sit on top */
  display: none;                  /* HIDDEN BY DEFAULT */
  opacity: 0;
  transition: opacity 0.3s ease;
  align-items: center;            /* Center Vertically */
  justify-content: center;        /* Center Horizontally */
}
#figureOverlay.show {
  display: flex !important;       /* Flex when active */
  opacity: 1;
}
/* Specific sizing for this overlay to look good */
#figureOverlay .settings-dialog {
  width: 900px;
  max-width: 1000px;
  height: 80vh;
  margin: 0; /* Remove top margin used by settingsOverlay */
}
/* Ensure the dropzone fits well */
#figureOverlay .dropzone {
  min-height: 200px;
  border: 2px dashed var(--tblr-border-color);
  background: var(--tblr-bg-surface-secondary);
}
/* Fixed footer alignment */
#figureOverlay .settings-content .tab-pane .mt-4.pt-3 {
  margin-left: -1.5rem;
  margin-right: -1.5rem;
  padding-left: 1.5rem;
  padding-right: 1.5rem;
}

/* Fix for greyed dropdowns in figure overlay */
#figureOverlay .form-select {
  background: var(--tblr-body-bg) !important;
  color: var(--tblr-body-color) !important;
  border-color: var(--tblr-border-color) !important;
  opacity: 1 !important;
}
#figureOverlay .form-select:disabled,
#figureOverlay .form-select[readonly] {
  background-color: var(--tblr-body-bg) !important;
  opacity: 1 !important;
  color: var(--tblr-body-color) !important;
}
#figureOverlay .form-select:hover {
  border-color: var(--tblr-primary) !important;
}
#figureOverlay .form-select:focus {
  border-color: var(--tblr-primary) !important;
  box-shadow: 0 0 0 0.2rem var(--tblr-primary-fg-subtle) !important;
}


/* 1. Main Container: Exact size of the icon */
.nav-brand-toggle {
  position: absolute !important;
  left: 5px !important;
  margin: 0 !important;
}

/* 2. Layers: Absolute positioning forces exact overlap */
.brand-layer {
 position: absolute;
 left: 0 !important;
 top: 0 !important;
 width: 100%;
 height: 100%;
 display: flex;
 align-items: center;
 justify-content: center;
 transition: all 0.35s cubic-bezier(0.25, 0.8, 0.25, 1);
}

/* 3. Default State (Mudskipper Logo) */
.brand-default {
 opacity: 1;
 transform: translateY(0) scale(1);
}

/* 4. Hover State (Projects Icon) */
.brand-hover {
 opacity: 0;
 transform: translateY(8px) scale(0.95);
 pointer-events: none;
}

/* 5. Hover Triggers */
.nav-brand-toggle:hover .brand-default {
 opacity: 0;
 transform: translateY(-8px) scale(0.95);
}
.nav-brand-toggle:hover .brand-hover {
 opacity: 1;
 transform: translateY(0) scale(1);
}

/* 6. Circular Background: Matches Logo Size (34px) exactly */
.project-icon-circle {
 width: 34px;
 height: 34px;
 min-width: 34px;
 background-color: rgba(32, 107, 196, 0.1);
 border-radius: 50%;
 display: flex;
 align-items: center;
 justify-content: center;
 color: var(--tblr-primary, #206bc4);
}

/* =================== EQUATION PREVIEW POPUP =================== */
#math-preview-popup {
  display: none;
  position: fixed;
  z-index: 10000;
  background: var(--tblr-bg-surface, #fff);
  color: var(--tblr-body-color);
  border: 1px solid var(--tblr-border-color, #ccc);
  border-radius: var(--tblr-border-radius);
  border-left: 4px solid var(--tblr-primary);
  padding: 5px 5px;
  padding-top: 2px;
  padding-bottom: 2px;
  box-shadow: 0 10px 25px rgba(0,0,0,0.2);
  font-size: 14px;
  pointer-events: none;
  transform: translateY(10px);
  transition: opacity 0.2s, transform 0.2s;
  opacity: 0;
  max-width: 700px;
  overflow-x: auto;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-rendering: geometricPrecision;
}

#math-preview-popup.visible {
  display: block;
  opacity: 1;
  transform: translateY(0);
}

#math-preview-popup .katex,
#math-preview-popup .katex * {
  font-weight: 400;
  transform: translateZ(0);
  backface-visibility: hidden;
}


.navbar {
  padding-left: 0 !important;
}

.navbar > .container,
.navbar > .container-fluid {
  padding-left: 0 !important;
}

/* ================= CITATION MANAGER OVERLAY ================= */
#citationOverlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.5);
  z-index: 1060;
  display: none;
  opacity: 0;
  transition: opacity 0.3s ease;
  align-items: center;
  justify-content: center;
}

#citationOverlay.show {
  display: flex !important;
  opacity: 1;
}



/* =========Table Builder Overlay=============*/
#tableOverlay {
  position: fixed; top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(0, 0, 0, 0.5); z-index: 1060;
  display: none; align-items: center; justify-content: center;
  opacity: 0; transition: opacity 0.3s ease;
}
#tableOverlay.show { display: flex !important; opacity: 1; }

#visualTableGrid td {
  min-width: 100px;
  border: 1px solid var(--tblr-border-color);
  padding: 8px;
  background: var(--tblr-bg-surface);
}
#visualTableGrid td:focus {
  outline: 2px solid var(--tblr-primary);
  background: var(--tblr-bg-surface-secondary);
}

/* Wrapper & Layout */
.builder-container {
  display: grid;
  grid-template-columns: auto 40px;
  grid-template-rows: auto 40px;
  gap: 10px;
  justify-content: center;
}

.table-wrapper {
  grid-column: 1; grid-row: 1;
  overflow: auto;
  max-width: 800px; max-height: 500px;
  padding: 20px; /* Space for outer borders */
  background: var(--tblr-bg-surface);
  border: 1px solid var(--tblr-border-color);
}

/* The Table */
.visual-table {
  border-collapse: separate; /* Required for custom border rendering */
  border-spacing: 0;
}

.visual-table td {
  position: relative;
  min-width: 80px; height: 40px;
  padding: 8px;
  outline: none;
  border: 1px solid transparent; /* Hidden by default, toggled via classes */
  /* Dashed guide lines (visual aid only) */
  background-image:
    linear-gradient(to right, #e2e2e2 1px, transparent 1px),
    linear-gradient(to bottom, #e2e2e2 1px, transparent 1px);
  background-size: 100% 100%; /* Only show on edges */
  background-repeat: no-repeat;
}

/* Real Borders (Toggled by JS) */
.visual-table td.b-top { border-top: 2px solid #000 !important; }
.visual-table td.b-bottom { border-bottom: 2px solid #000 !important; }
.visual-table td.b-left { border-left: 2px solid #000 !important; }
.visual-table td.b-right { border-right: 2px solid #000 !important; }

/* Interactive Hover States */
.visual-table td:hover {
  background-color: rgba(0,0,0,0.02);
}
.visual-table td:focus {
  background-color: var(--tblr-bg-surface-secondary);
}

/* Border Hit Zones (Pseudo-cursor feedback) */
.visual-table td { cursor: text; }
.visual-table td.hover-top { cursor: row-resize; box-shadow: inset 0 2px 0 var(--tblr-primary); }
.visual-table td.hover-bottom { cursor: row-resize; box-shadow: inset 0 -2px 0 var(--tblr-primary); }
.visual-table td.hover-left { cursor: col-resize; box-shadow: inset 2px 0 0 var(--tblr-primary); }
.visual-table td.hover-right { cursor: col-resize; box-shadow: inset -2px 0 0 var(--tblr-primary); }

/* Controls */
.col-controls, .row-controls { display: flex; gap: 5px; justify-content: center; }
.col-controls { flex-direction: column; grid-column: 2; grid-row: 1; }
.row-controls { flex-direction: row; grid-column: 1; grid-row: 2; }



/* ============= AI Assistant Styles ============= */

/* === Header Improvements === */
.pane-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.25rem 1.5rem;
  border-bottom: 1px solid var(--tblr-border-color);
  background: var(--tblr-bg-surface);
  height: 65px;
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
}

/* AI Avatar with Glow Effect */
.ai-avatar-glow {
  background-image: url('mudskipper_logo.svg');
  background-size: cover;
  box-shadow: 0 2px 12px rgba(var(--tblr-primary-rgb), 0.15), 0 0 0 3px rgba(var(--tblr-primary-rgb), 0.08);
  transition: all 0.3s ease;
}

.ai-avatar-glow:hover {
  box-shadow: 0 4px 16px rgba(var(--tblr-primary-rgb), 0.25), 0 0 0 3px rgba(var(--tblr-primary-rgb), 0.12);
  transform: translateY(-1px);
}


/* === Smooth Animations === */
.fade-in {
  animation: fadeIn 0.5s cubic-bezier(0.4, 0, 0.2, 1);
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(12px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* === Message Cards === */
.ai-pane .card {
  font-size: 11px;
  line-height: 1.6;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.04);
  transition: all 0.2s ease;
}

.ai-pane .card:hover {
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
}

.ai-pane .card p:last-child {
  margin-bottom: 0;
}

/* User Messages */
.user-message {
  background: var(--tblr-primary);
  color: white;
  border-radius: 12px 12px 4px 12px;
  padding: 0.875rem 1.125rem;
  box-shadow: 0 2px 8px rgba(var(--tblr-primary-rgb), 0.2);
}

/* AI Messages */
.ai-message-card {
  background: var(--tblr-bg-surface-secondary);
  border-radius: 12px 12px 12px 4px;
  padding: 0.875rem 1.125rem;
}

/* AI Avatar in Messages */
.ai-pane .avatar {
  width: 36px;
  height: 36px;
  min-width: 36px;
  background-image: url('mudskipper_logo.svg');
  background-size: cover;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
}

/* === Code Block Container (Do Not Touch) === */
.ai-pane pre {
  background: #282c34 !important;
  color: #abb2bf !important;
  padding: 0;
  border-radius: var(--tblr-border-radius);
  position: relative;
  margin: 12px 0;
  border: 1px solid rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.ai-pane pre.code-block-enhanced {
  padding-top: 40px;
}

.ai-pane code {
  font-family: 'Fira Code', 'Consolas', 'Monaco', monospace;
  font-size: 0.875rem;
  background: transparent !important;
  display: block;
  padding: 1rem;
  overflow-x: auto;
  line-height: 1.5;
}

.ai-pane :not(pre) > code {
  background: rgba(0, 0, 0, 0.08) !important;
  padding: 2px 6px;
  border-radius: var(--tblr-border-radius);
  font-size: 0.875em;
  color: var(--tblr-body-color);
  display: inline;
}

.code-header {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 36px;
  background: rgba(0, 0, 0, 0.2);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 12px;
  z-index: 10;
}

.code-language {
  font-size: 0.75rem;
  font-weight: 600;
  color: #98c379;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  font-family: 'Fira Code', monospace;
}

.code-copy-btn {
  background: none;
  border: none;
  color: #fff;
  padding: 4px 10px;
  font-size: 0.75rem;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 6px;
  height: 24px;
}

.code-copy-btn:hover {
  background: rgba(255, 255, 255, 0.2);
  transform: translateY(-1px);
}

.code-copy-btn:active {
  transform: translateY(0);
}

.code-copy-btn.copied {
  background: rgba(152, 195, 121, 0.2);
  border-color: #98c379;
  color: #98c379;
}

.code-copy-btn i {
  font-size: 0.875rem;
}

/* === Syntax Highlighting (Do Not Touch) === */
.hljs-comment,
.hljs-quote {
  color: #5c6370;
  font-style: italic;
}

.hljs-keyword,
.hljs-selector-tag,
.hljs-built_in {
  color: #c678dd;
}

.hljs-string,
.hljs-title,
.hljs-section,
.hljs-attribute,
.hljs-literal,
.hljs-template-tag,
.hljs-template-variable,
.hljs-type {
  color: #98c379;
}

.hljs-number,
.hljs-symbol,
.hljs-bullet,
.hljs-meta,
.hljs-selector-id,
.hljs-selector-class {
  color: #d19a66;
}

.hljs-function,
.hljs-params {
  color: #61afef;
}

.hljs-regexp,
.hljs-link {
  color: #e06c75;
}

/* === Math Rendering (Do Not Touch) === */
.ai-pane .katex {
  font-size: 1.05em;
}

.ai-pane .katex-display {
  margin: 1em 0;
  overflow-x: auto;
  overflow-y: hidden;
}

/* === Scrollbar Styling === */
.ai-pane pre::-webkit-scrollbar {
  height: 8px;
}

.ai-pane pre::-webkit-scrollbar-track {
  background: rgba(0, 0, 0, 0.2);
  border-radius: 4px;
}

.ai-pane pre::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.3);
  border-radius: 4px;
}

.ai-pane pre::-webkit-scrollbar-thumb:hover {
  background: rgba(255, 255, 255, 0.4);
}

#chat-scroll-container::-webkit-scrollbar {
  width: 6px;
}

#chat-scroll-container::-webkit-scrollbar-track {
  background: transparent;
}

#chat-scroll-container::-webkit-scrollbar-thumb {
  background: rgba(0, 0, 0, 0.15);
  border-radius: 3px;
}

#chat-scroll-container::-webkit-scrollbar-thumb:hover {
  background: rgba(0, 0, 0, 0.25);
}

/* === History Sidebar === */
.history-sidebar {
  position: absolute;
  top: 65px;
  left: 0;
  bottom: 0;
  width: 50%;
  background: var(--tblr-bg-surface);
  border-right: 1px solid var(--tblr-border-color);
  z-index: 100;
  transform: translateX(-100%);
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  display: flex;
  flex-direction: column;
}

.history-sidebar.show {
  transform: translateX(0);
}

/* History Item */
.history-item-container {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  border-bottom: 1px solid var(--tblr-border-color-light);
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
}

.history-item-container:hover {
  background: var(--tblr-bg-surface-secondary);
  padding-left: 20px;
}

.history-item-container.active {
  background: rgba(var(--tblr-primary-rgb), 0.08);
  border-left: 3px solid var(--tblr-primary);
  padding-left: 13px;
}

.history-item-container.active::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 3px;
  background: var(--tblr-primary);
}

.history-content {
  flex: 1;
  min-width: 0;
  margin-right: 8px;
}

.history-delete-wrapper {
  opacity: 0;
  transition: opacity 0.2s ease-in-out;
  flex-shrink: 0;
}

.history-item-container:hover .history-delete-wrapper {
  opacity: 1;
}

.history-title {
  font-weight: 500;
  font-size: 0.875rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  color: var(--tblr-body-color);
  margin-bottom: 2px;
}

.history-date {
  font-size: 0.75rem;
  color: var(--tblr-muted);
  opacity: 0.75;
}

/* === Modern Input Group === */
.input-group-modern {
  position: relative;
  display: flex;
  align-items: flex-end;
  gap: 12px;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.input-wrapper {
  flex: 1;
  display: flex;
}

.input-group-modern .form-group {
  margin-bottom: 0 !important;
  width: 100%;
}

.input-group-modern textarea {
  width: 100% !important;
  border-radius: 16px !important;
  border: 2px solid var(--tblr-border-color) !important;
  padding: 14px 18px !important;
  font-size: 0.9375rem !important;
  transition: all 0.2s ease !important;
  resize: none !important;
  background: var(--tblr-bg-surface-secondary) !important;
}

.input-group-modern textarea:focus {
  border-color: var(--tblr-primary) !important;
  background: var(--tblr-bg-surface) !important;
  outline: none !important;
}

.input-group-modern textarea::placeholder {
  color: var(--tblr-muted);
  opacity: 0.6;
}

/* Send Button */
.btn-send {
  width: 48px !important;
  height: 48px !important;
  min-width: 48px !important;
  border-radius: 12px !important;
  display: flex !important;
  align-items: center !important;
  justify-content: center !important;
  padding: 0 !important;
  background: var(--tblr-primary) !important;
  border: none !important;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1) !important;
}

.btn-send:hover {
  transform: translateY(-2px) !important;
  background: var(--tblr-primary) !important;
}

.btn-send:active {
  transform: translateY(0) !important;
}

.btn-send i {
  font-size: 1.125rem;
}

/* === Empty State & Welcome === */
#chat-scroll-container {
  flex: 1;
  opacity: 1;
  transition: flex-grow 0.6s cubic-bezier(0.4, 0, 0.2, 1),
              opacity 0.4s ease,
              padding 0.4s ease;
}

.pane-footer {
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  transition: flex-grow 0.6s cubic-bezier(0.4, 0, 0.2, 1),
              padding 0.6s ease,
              background 0.4s ease;
}

/* Chat Empty State */
.ai-pane.chat-empty #chat-scroll-container {
  flex: 0;
  opacity: 0;
  padding: 0 !important;
  overflow: hidden;
}

.ai-pane.chat-empty .pane-footer {
  flex: 1;
  justify-content: center;
  align-items: center;
  border-top: none !important;
  background: transparent !important;
}

.ai-pane.chat-empty .input-group-modern {
  width: 80%;
  max-width: 700px;
  transform: scale(1.05);
}

.ai-pane.chat-empty .footer-controls {
  opacity: 0.6;
  transition: opacity 0.3s ease;
}

/* Welcome Hero */
.welcome-hero {
  display: none;
  text-align: center;
  align-items: center;
  justify-content: center;
  margin-bottom: 2.5rem;
  animation: fadeInUp 0.8s cubic-bezier(0.4, 0, 0.2, 1);
}

.ai-pane.chat-empty .welcome-hero {
  display: block;
}

.welcome-hero .avatar {
  background-image: url('mudskipper_logo.svg');
  background-size: cover;
  background-color: var(--tblr-primary);
}

.welcome-hero h2 {
  color: var(--tblr-primary);
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(24px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* === Responsive Design === */
@media (max-width: 768px) {
  .ai-pane .card {
    max-width: 95% !important;
  }

  .ai-pane code {
    font-size: 0.8rem;
  }

  .code-language {
    font-size: 0.7rem;
  }

  .history-sidebar {
    width: 260px;
  }

  .pane-header {
    padding: 1rem;
  }

  .ai-pane.chat-empty .input-group-modern {
    width: 90%;
  }

  .btn-icon {
    width: 24px;
    height: 24px;
  }
}

/*==========Hover stules==========*/

#utilityRail .rail-btn{
  width:30px;
  height:30px;
  border-radius: var(--tblr-border-radius);
  background:var(--bs-body-bg);
  border:0;
  display:flex;
  align-items:center;
  justify-content:center;
  cursor:pointer;
  color:var(--bs-body-color);
  margin: 15px 0 !important;
}

.rail-btn.active {
  color: var(--tblr-white) !important;
  background-color: var(--tblr-primary) !important;
  box-shadow: inset 0 0 0 1px var(--tblr-primary-bg-subtle);
  border: 0.5px solid var(--tblr-border-color) !important;
  border-bottom: 4px solid var(--tblr-body-color) !important;
}

/* 1. Define the structure in the base class */
.rail-btn {
  width: 24px;
  height: 24px;
  border-radius: var(--tblr-border-radius);
  border: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  background-color: transparent; /* Default state */
  transition: background-color 0.2s ease; /* Optional: Makes the color fade in smoothly */
}

/* 2. Change ONLY the color on hover */
.rail-btn:hover {
  background-color: var(--tblr-border-color) !important;
}


"
      ))
    ),

    # Main app container with conditional UI
    div(
      id = "appContainer",

      # HOMEPAGE DASHBOARD: show when output.showHomepage is TRUE and NOT in profile view
      conditionalPanel(
        condition = "output.showHomepage == true && output.isProfileView == false",
        div(id = "homePage", class = "homepage", uiOutput("tabler_home"))
      ),

      # PROFILE PAGE: show when output.showHomepage is TRUE and IN profile view
      conditionalPanel(
        condition = "output.showHomepage == true && output.isProfileView == true",
        div(id = "profilePage", class = "profilepage", style = "position: relative; min-height: 100vh;",
          # Background Spinner (Visible during load)
          div(class = "d-flex justify-content-center align-items-center w-100", 
              style = "position: absolute; top: 0; bottom: 0; left: 0; right: 0; z-index: 0;",
              HTML('<i class="spinner-border text-primary" style="width: 40px; height: 40px; border-width: 1px;"></i>')
          ),
          # Profile Content (Z-index 1 ensures it covers the spinner once loaded)
          div(style = "position: relative; z-index: 1;",
              uiOutput("profile_page_ui")
          )
        )
      ),

      # Editor View (your existing main UI)
      conditionalPanel(
        condition = "output.showHomepage == false",
        tags$head(
          HTML(
            '
                <meta charset="utf-8"/>
                <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover"/>
                <meta http-equiv="X-UA-Compatible" content="ie=edge"/>
                <title>Mudskipper</title>
                <meta name="msapplication-TileColor" content="#066fd1"/>
                <meta name="theme-color" content="#066fd1"/>
                <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent"/>
                <meta name="apple-mobile-web-app-capable" content="yes"/>
                <meta name="mobile-web-app-capable" content="yes"/>
                <meta name="HandheldFriendly" content="True"/>
                <meta name="MobileOptimized" content="320"/>
                <link rel="icon" href="/favicon/favicon.ico" type="image/x-icon"/>
                <link rel="shortcut icon" href="/favicon/favicon.ico" type="image/x-icon"/>
                <meta name="description" content=""/>
                <meta name="canonical" content="https://mudskipper.io/"/>
                <meta name="twitter:image:src" content="https://raw.githubusercontent.com/SulmanOlieko/sulmanolieko.github.io/main/img/ekonly-logo.svg"/>
                <meta name="twitter:site" content="@Mudskipper"/>
                <meta name="twitter:card" content="summary"/>
                <meta property="og:image" content="https://raw.githubusercontent.com/SulmanOlieko/sulmanolieko.github.io/main/img/ekonly-logo.svg"/>
                <meta property="og:image:width" content="1280"/>
                <meta property="og:image:height" content="640"/>
                <meta property="og:site_name" content="Mudskipper"/>
                <meta property="og:type" content="object"/>
                <meta property="og:url" content="https://raw.githubusercontent.com/SulmanOlieko/sulmanolieko.github.io/main/img/ekonly-logo.svg"/>
                <link href="https://cdn.jsdelivr.net/npm/@tabler/core@1.4.0/dist/css/tabler.min.css" rel="stylesheet"/>
                <style>
                  @import url("https://rsms.me/inter/inter.css");
                </style>
              '
          )
        ),
        div(
          class = "card border border-opacity-100",
          style = "border-radius: 0 !important; border-color: var(--tblr-border-color); height: 100%; background-color: var(--tblr-bg-surface); border-collapse: separate; border-spacing: 0; overflow: hidden; margin: 0 !important;",
          # Include your <body> HTML
          HTML(
            '
            <div id="editorPage" class="layout-fluid">
              <!-- BEGIN NAVBAR -->
              <div class="sticky-top">
              <header class="navbar navbar-expand-md navbar-overlap d-print-none border-0">
              <div class="container-xl">
              <div class="navbar-nav flex-row align-items-center gap-2 nav-brand-toggle"
               onclick="if (window.Shiny) Shiny.setInputValue(\'backToHomepage\', Date.now(), {priority:\'event\'})"
               title="Go to Homepage (Ctrl+Shift+P)"
               data-bs-toggle="tooltip"
               data-bs-placement="bottom"
               style="cursor: pointer; position: relative; width: 34px; height: 34px; padding: 0 !important; margin-left: 0 !important; margin: 0 0 !important;">

               <div class="brand-layer brand-default">
                  <img src="mudskipper_logo.svg" alt="Mudskipper" width="34" height="34" decoding="async" style="display:block;" />
               </div>

               <div class="brand-layer brand-hover">
                  <div class="project-icon-circle">
                    <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="18" height="18" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
                      <path d="M12.707 2.293l9 9c.63 .63 .184 1.707 -.707 1.707h-1v6a3 3 0 0 1 -3 3h-1v-7a3 3 0 0 0 -2.824 -2.995l-.176 -.005h-2a3 3 0 0 0 -3 3v7h-1a3 3 0 0 1 -3 -3v-6h-1c-.89 0 -1.337 -1.077 -.707 -1.707l9 -9a1 1 0 0 1 1.414 0m.293 11.707a1 1 0 0 1 1 1v7h-4v-7a1 1 0 0 1 .883 -.993l.117 -.007z" />
                    </svg>
                  </div>
               </div>
          </div>

          <div class="nav-item">&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; </div>

          <div class="nav-item dropdown ms-2">
            <a href="javascript:void(0);" class="nav-link d-flex lh-1 p-0" data-bs-toggle="dropdown" aria-label="Open File Menu">
              <span class="nav-link-title" style="color: var(--tblr-body-color); font-weight: 500; font-size: 0.95rem;">File</span>
            </a>
            <div class="dropdown-menu">
              <a class="dropdown-item" onclick="openAddFilesOverlay(\'add-file-tab\')">
              <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="icon icon-1"
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  stroke-width="2"
                  stroke="currentColor"
                  fill="none"
                  stroke-linecap="round"
                  stroke-linejoin="round">
                    <path d="M14 3v4a1 1 0 0 0 1 1h4" />
                    <path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2z" />
                    <path d="M12 11l0 6" />
                    <path d="M9 14l6 0" />
                  </svg>
                 New file
              </a>
              <a class="dropdown-item" onclick="openAddFilesOverlay(\'add-folder-tab\')">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="icon icon-1"
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  stroke-width="2"
                  stroke="currentColor"
                  fill="none"
                  stroke-linecap="round"
                  stroke-linejoin="round">
                   <path d="M12 19h-7a2 2 0 0 1 -2 -2v-11a2 2 0 0 1 2 -2h4l3 3h7a2 2 0 0 1 2 2v3.5" />
                   <path d="M16 19h6" />
                   <path d="M19 16v6" />
                </svg>
                 New folder
              </a>
              <a class="dropdown-item" onclick="openAddFilesOverlay(\'upload-tab\')">
                <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="icon icon-1"
                    width="24"
                    height="24"
                    viewBox="0 0 24 24"
                    stroke-width="2"
                    stroke="currentColor"
                    fill="none"
                    stroke-linecap="round"
                    stroke-linejoin="round">
                      <path d="M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2 -2v-2" />
                      <path d="M7 9l5 -5l5 5" />
                      <path d="M12 4l0 12" />
                  </svg>
                 Upload file
              </a>
              <div class="dropdown-divider"></div>
              <a class="dropdown-item" onclick="openCopyProjectOverlay()">
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
                    <path d="M7 7m0 2.667a2.667 2.667 0 0 1 2.667 -2.667h8.666a2.667 2.667 0 0 1 2.667 2.667v8.666a2.667 2.667 0 0 1 -2.667 2.667h-8.666a2.667 2.667 0 0 1 -2.667 -2.667z" />
                    <path d="M4.012 16.737a2.005 2.005 0 0 1 -1.012 -1.737v-10c0 -1.1 .9 -2 2 -2h10c.75 0 1.158 .385 1.5 1" />
                  </svg>
                 Make a copy
              </a>
              <div class="dropdown-divider"></div>
              <a class="dropdown-item" onclick="if(window.Shiny) Shiny.setInputValue(\'openHistoryBtn\', Math.random(), {priority: \'event\'})">
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
                    stroke-linejoin="round">
                    <path d="M12 8l0 4l2 2"></path>
                    <path d="M3.05 11a9 9 0 1 1 .5 4m-.5 5v-5h5"></path>
                  </svg>
                Show version history
              </a>
              <a class="dropdown-item">
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
                  stroke-linejoin="round">
                    <path d="M14 3v4a1 1 0 0 0 1 1h4" />
                    <path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2" />
                    <path d="M9 12l1.333 5l1.667 -4l1.667 4l1.333 -5" />
                </svg>
                Word count: <span id="wordCountDisplay" class="badge bg-primary-lt me-2" style="font-size: 0.9em; min-width: 60px;">0 words</span>
              </a>
              <div class="text-muted" style="font-size: 0.8em; min-width: 60px;">&nbsp;&nbsp; Click word count to see breakdown.</div>
              <div class="dropdown-divider"></div>
              <a class="dropdown-item" onclick="document.getElementById(\'global_project_download_link\').click()">
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
                      <path d="M6 20.735a2 2 0 0 1 -1 -1.735v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2h-1" />
                      <path d="M11 17a2 2 0 0 1 2 2v2a1 1 0 0 1 -1 1h-2a1 1 0 0 1 -1 -1v-2a2 2 0 0 1 2 -2z" />
                      <path d="M11 5l-1 0" />
                      <path d="M13 7l-1 0" />
                      <path d="M11 9l-1 0" />
                      <path d="M13 11l-1 0" />
                      <path d="M11 13l-1 0" />
                      <path d="M13 15l-1 0" />
                    </svg>
                 Download as source (.zip)
                </a>
              <a class="dropdown-item" onclick="document.getElementById(\'pdf_download_link\').click()">
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
                      <path d="M14 3v4a1 1 0 0 0 1 1h4" />
                      <path d="M5 12v-7a2 2 0 0 1 2 -2h7l5 5v4" />
                      <path d="M5 18h1.5a1.5 1.5 0 0 0 0 -3h-1.5v6" />
                      <path d="M17 18h2" />
                      <path d="M20 15h-3v6" />
                      <path d="M11 15v6h1a2 2 0 0 0 2 -2v-2a2 2 0 0 0 -2 -2h-1z" />
                    </svg>
                 Download as PDF
              </a>
              <div class="dropdown-divider"></div>
              <a class="dropdown-item" onclick="openSettingsOverlay()">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="icon icon-1"
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  stroke-width="2"
                  stroke="currentColor"
                  fill="none"
                  stroke-linecap="round"
                  stroke-linejoin="round">
                    <path stroke="none" d="M0 0h24v24H0z" fill="none" />
                    <path
                      d="M10.325 4.317c.426 -1.756 2.924 -1.756 3.35 0a1.724 1.724 0 0 0 2.573 1.066c1.543 -.94 3.31 .826 2.37 2.37a1.724 1.724 0 0 0 1.065 2.572c1.756 .426 1.756 2.924 0 3.35a1.724 1.724 0 0 0 -1.066 2.573c.94 1.543 -.826 3.31 -2.37 2.37a1.724 1.724 0 0 0 -2.572 1.065c-.426 1.756 -2.924 1.756 -3.35 0a1.724 1.724 0 0 0 -2.573 -1.066c-1.543 .94 -3.31 -.826 -2.37 -2.37a1.724 1.724 0 0 0 -1.065 -2.572c-1.756 -.426 -1.756 -2.924 0 -3.35a1.724 1.724 0 0 0 1.066 -2.573c-.94 -1.543 .826 -3.31 2.37 -2.37c1 .608 2.296 .07 2.572 -1.065z" />
                    <circle cx="12" cy="12" r="3" />
                </svg>
               Settings
              </a>
            </div>
          </div>

         <div class="nav-item">&nbsp; &nbsp; &nbsp;</div>

          <div class="nav-item dropdown ms-2">
            <a href="javascript:void(0);" class="nav-link d-flex lh-1 p-0" data-bs-toggle="dropdown">
              <span class="nav-link-title" style="color: var(--tblr-body-color); font-weight: 500; font-size: 0.95rem;">Insert</span>
            </a>
            <div class="dropdown-menu">

              <div class="dropend">
                <a class="dropdown-item dropdown-toggle" href="javascript:void(0);">
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
                  stroke-linejoin="round">
                  <path d="M19 5h-7l-4 14l-3 -6h-2" />
                  <path d="M14 13l6 6" />
                  <path d="M14 19l6 -6" />
                </svg>

                Math</a>
                <div class="dropdown-menu">
                  <a class="dropdown-item" onclick="insertLatex(\'inline\')">Inline math</a>
                  <a class="dropdown-item" onclick="insertLatex(\'display\')">Display math</a>
                </div>
              </div>

              <a class="dropdown-item" onclick="toggleSymbolPalette()">
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
                stroke-linejoin="round">
                <path d="M3 12l18 0" />
                <path d="M12 3l0 18" />
                <path d="M16.5 4.5l3 3" />
                <path d="M19.5 4.5l-3 3" />
                <path d="M6 4l0 4" />
                <path d="M4 6l4 0" />
                <path d="M18 16l.01 0" />
                <path d="M18 20l.01 0" />
                <path d="M4 18l4 0" />
              </svg>
              Symbols
              </a>

              <div class="dropend">
                <a class="dropdown-item dropdown-toggle" href="javascript:void(0);">
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
                    stroke-linejoin="round">
                    <path d="M3 20h18l-6.921 -14.612a2.3 2.3 0 0 0 -4.158 0l-6.921 14.612z" />
                    <path d="M7.5 11l2 2.5l2.5 -2.5l2 3l2.5 -2" />
                  </svg>
                Figure</a>
                <div class="dropdown-menu">
                  <a class="dropdown-item" onclick="openFigureOverlay(\'fig-upload-tab\')">
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
                    stroke-linejoin="round">
                    <path d="M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2 -2v-2" />
                    <path d="M7 9l5 -5l5 5" />
                    <path d="M12 4l0 12" />
                  </svg>
                  Upload from computer</a>
                  <a class="dropdown-item" onclick="openFigureOverlay(\'fig-project-tab\')">
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
                      stroke-linejoin="round">
                      <path d="M12 6m-8 0a8 3 0 1 0 16 0a8 3 0 1 0 -16 0" />
                      <path d="M4 6v6a8 3 0 0 0 16 0v-6" />
                      <path d="M4 12v6a8 3 0 0 0 16 0v-6" />
                    </svg>
                  From project files</a>
                  <a class="dropdown-item" onclick="openFigureOverlay(\'fig-other-tab\')">
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
                      stroke-linejoin="round">
                      <path d="M12 6m-8 0a8 3 0 1 0 16 0a8 3 0 1 0 -16 0" />
                      <path d="M4 6v6a8 3 0 0 0 16 0v-6" />
                      <path d="M4 12v6a8 3 0 0 0 16 0v-6" />
                    </svg>From another project</a>
                  <a class="dropdown-item" onclick="openFigureOverlay(\'fig-url-tab\')">
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
                      stroke-linejoin="round">
                      <path d="M9 15l6 -6" />
                      <path d="M11 6l.463 -.536a5 5 0 0 1 7.071 7.072l-.534 .464" />
                      <path d="M13 18l-.397 .534a5.068 5.068 0 0 1 -7.127 0a4.972 4.972 0 0 1 0 -7.071l.524 -.463" />
                    </svg>
                  From URL</a>
                </div>
              </div>

              <div class="dropdown-divider"></div>

              <div class="dropend">
              <a class="dropdown-item dropdown-toggle" href="javascript:void(0);">
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
                  stroke-linejoin="round">
                  <path d="M12.5 21h-7.5a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v7.5" />
                  <path d="M3 10h18" />
                  <path d="M10 3v18" />
                  <path d="M16 19h6" />
                  <path d="M19 16v6" />
                </svg>
              Table
              </a>
              <div class="dropdown-menu">
              <a class="dropdown-item" onclick="insertLatex(\'table\')">
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
                  stroke-linejoin="round">
                  <path d="M12.5 21h-7.5a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v7.5" />
                  <path d="M3 10h18" />
                  <path d="M10 3v18" />
                  <path d="M16 19h6" />
                  <path d="M19 16v6" />
                </svg>
              Quick table
              </a>
              <a class="dropdown-item" onclick="openTableOverlay()">
                  <svg xmlns="http://www.w3.org/2000/svg"
                     class="icon icon-tabler icon-tabler-table"
                     width="24"
                     height="24"
                     viewBox="0 0 24 24"
                     stroke-width="2"
                     stroke="currentColor"
                     fill="none"
                     stroke-linecap="round"
                     stroke-linejoin="round">
                      <path d="M12 21h-7a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v7" />
                      <path d="M3 10h18" />
                      <path d="M10 3v18" />
                      <path d="M19.001 19m-2 0a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" />
                      <path d="M19.001 15.5v1.5" />
                      <path d="M19.001 21v1.5" />
                      <path d="M22.032 17.25l-1.299 .75" />
                      <path d="M17.27 20l-1.3 .75" />
                      <path d="M15.97 17.25l1.3 .75" />
                      <path d="M20.733 20l1.3 .75" />
                  </svg>
                  From table builder
                </a>
              </div>
              </div>

              <div class="dropdown-divider"></div>
              <a class="dropdown-item" onclick="insertLatex(\'cite\')">
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
                stroke-linejoin="round">
                <path d="M5 4m0 1a1 1 0 0 1 1 -1h2a1 1 0 0 1 1 1v14a1 1 0 0 1 -1 1h-2a1 1 0 0 1 -1 -1z" />
                <path d="M9 4m0 1a1 1 0 0 1 1 -1h2a1 1 0 0 1 1 1v14a1 1 0 0 1 -1 1h-2a1 1 0 0 1 -1 -1z" />
                <path d="M5 8h4" />
                <path d="M9 16h4" />
                <path d="M13.803 4.56l2.184 -.53c.562 -.135 1.133 .19 1.282 .732l3.695 13.418a1.02 1.02 0 0 1 -.634 1.219l-.133 .041l-2.184 .53c-.562 .135 -1.133 -.19 -1.282 -.732l-3.695 -13.418a1.02 1.02 0 0 1 .634 -1.219l.133 -.041z" />
                <path d="M14 9l4 -1" />
                <path d="M16 16l3.923 -.98" />
              </svg>
              Citation</a>
              <a class="dropdown-item" onclick="insertLatex(\'link\')">
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
                  stroke-linejoin="round">
                  <path d="M9 15l6 -6" />
                  <path d="M11 6l.463 -.536a5 5 0 0 1 7.071 7.072l-.534 .464" />
                  <path d="M13 18l-.397 .534a5.068 5.068 0 0 1 -7.127 0a4.972 4.972 0 0 1 0 -7.071l.524 -.463" />
                </svg>
              Link</a>
              <a class="dropdown-item" onclick="insertLatex(\'ref\')">
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
                  stroke-linejoin="round">
                  <path d="M19 8.268a2 2 0 0 1 1 1.732v8a2 2 0 0 1 -2 2h-8a2 2 0 0 1 -2 -2v-8a2 2 0 0 1 2 -2h3" />
                  <path d="M5 15.734a2 2 0 0 1 -1 -1.734v-8a2 2 0 0 1 2 -2h8a2 2 0 0 1 2 2v8a2 2 0 0 1 -2 2h-3" />
                </svg>
              Cross reference
              </a>
              <a class="dropdown-item" onclick="openCitationOverlay()">
                  <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler icon-tabler-blockquote" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
                    <path stroke="none" d="M0 0h24v24H0z" fill="none"></path>
                    <path d="M6 15h15"></path>
                    <path d="M21 19h-15"></path>
                    <path d="M15 11h6"></path>
                    <path d="M21 7h-6"></path>
                    <path d="M9 9h1a1 1 0 1 1 -1 1v-2.5a2 2 0 0 1 2 -2"></path>
                    <path d="M3 9h1a1 1 0 1 1 -1 1v-2.5a2 2 0 0 1 2 -2"></path>
                  </svg>
                  Import citation
                </a>
            </div>
          </div>

          <div class="nav-item">&nbsp; &nbsp; &nbsp;</div>

                <div class="nav-item dropdown ms-2">
                <a href="javascript:void(0);"
                   class="nav-link d-flex lh-1 p-0"
                   data-bs-toggle="dropdown">
                  <span class="nav-link-title"
                        style="color: var(--tblr-body-color); font-weight: 500; font-size: 0.95rem;">
                    View
                  </span>
                </a>

                <div class="dropdown-menu">
                  <div class="dropdown-header">Layout</div>

                  <a class="dropdown-item layout-selector" data-layout="split" onclick="toggleMainLayout(\'split\');">
                    <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24"
                         viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                         stroke-linecap="round" stroke-linejoin="round">
                      <path d="M4 4m0 2a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2z"/>
                      <path d="M4 9h8"/>
                      <path d="M12 15h8"/>
                      <path d="M12 4v16"/>
                    </svg>
                    Split view
                  </a>

                  <a class="dropdown-item layout-selector" data-layout="editor-only" onclick="toggleMainLayout(\'editor-only\');">
                    <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24"
                         viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                         stroke-linecap="round" stroke-linejoin="round">
                      <path d="M7 8l-4 4l4 4"/>
                      <path d="M17 8l4 4l-4 4"/>
                      <path d="M14 4l-4 16"/>
                    </svg>
                    Editor only
                  </a>

                  <a class="dropdown-item layout-selector" data-layout="pdf-only" onclick="toggleMainLayout(\'pdf-only\');">
                    <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24"
                         viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                         stroke-linecap="round" stroke-linejoin="round">
                      <path d="M14 3v4a1 1 0 0 0 1 1h4"/>
                      <path d="M5 12v-7a2 2 0 0 1 2 -2h7l5 5v4"/>
                      <path d="M5 18h1.5a1.5 1.5 0 0 0 0 -3h-1.5v6"/>
                      <path d="M17 18h2"/>
                      <path d="M20 15h-3v6"/>
                      <path d="M11 15v6h1a2 2 0 0 0 2 -2v-2a2 2 0 0 0 -2 -2h-1z"/>
                    </svg>
                    PDF only
                  </a>

                  <a class="dropdown-item"
                     onclick="if (window.Shiny) Shiny.setInputValue(\'btnOpenPDF\', Math.random(), {priority: \'event\'});">
                    <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24"
                         viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                         stroke-linecap="round" stroke-linejoin="round">
                      <path d="M4 8h8"/>
                      <path d="M20 11.5v6.5a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2v-12a2 2 0 0 1 2 -2h6.5"/>
                      <path d="M8 4v4"/>
                      <path d="M16 8l5 -5"/>
                      <path d="M21 7.5v-4.5h-4.5"/>
                    </svg>
                    Open PDF in separate tab
                  </a>

                  <div class="dropdown-divider"></div>

                  <div class="dropdown-header">Editor</div>

                    <a class="dropdown-item toggle-sync" data-toggle-id="enableMathPreviewPanel" href="javascript:void(0);">
                      <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24"
                           viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                           stroke-linecap="round" stroke-linejoin="round">
                        <path d="M19 5h-7l-4 14l-3 -6h-2"/>
                        <path d="M14 13l6 6"/>
                        <path d="M14 19l6 -6"/>
                      </svg>
                      Show equation preview
                    </a>

                    <a class="dropdown-item toggle-sync" data-toggle-id="enableStickyScrollPanel" href="javascript:void(0);">
                      <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24"
                           viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                           stroke-linecap="round" stroke-linejoin="round">
                            <path d="M4 10.005h16v-5a1 1 0 0 0 -1 -1h-14a1 1 0 0 0 -1 1v5z" />
                            <path d="M4 15.005v-.01" />
                            <path d="M4 20.005v-.01" />
                            <path d="M9 20.005v-.01" />
                            <path d="M15 20.005v-.01" />
                            <path d="M20 20.005v-.01" />
                            <path d="M20 15.005v-.01" />
                      </svg>
                      Enable sticky scroll
                    </a>

                    <a class="dropdown-item toggle-sync" data-toggle-id="enableMinimapPanel" href="javascript:void(0);">
                      <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24"
                           viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                           stroke-linecap="round" stroke-linejoin="round">
                            <path d="M15 15h2" />
                            <path d="M3 5a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v14a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-14z" />
                            <path d="M11 12h6" />
                            <path d="M13 9h4" />
                      </svg>
                      Enable minimap view
                    </a>

                  <div class="dropdown-divider"></div>

                  <div class="dropdown-header">PDF</div>

                  <a class="dropdown-item"
                     onclick="if (window.Shiny) Shiny.setInputValue(\'btnPresentationMode\', Math.random(), {priority: \'event\'});">
                    <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24"
                         viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                         stroke-linecap="round" stroke-linejoin="round">
                      <path d="M9 12v-4"/>
                      <path d="M15 12v-2"/>
                      <path d="M12 12v-1"/>
                      <path d="M3 4h18"/>
                      <path d="M4 4v10a2 2 0 0 0 2 2h12a2 2 0 0 0 2 -2v-10"/>
                      <path d="M12 16v4"/>
                      <path d="M9 20h6"/>
                    </svg>
                    Presentation mode
                  </a>

                  <a class="dropdown-item"
                     onclick = "pdfZoomIn(); return false;">
                    <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24"
                         viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                         stroke-linecap="round" stroke-linejoin="round">
                      <circle cx="10" cy="10" r="7"/>
                      <line x1="21" y1="21" x2="15" y2="15"/>
                      <line x1="10" y1="7" x2="10" y2="13"/>
                      <line x1="7" y1="10" x2="13" y2="10"/>
                    </svg>
                    Zoom in <kbd>⌘+</kbd>
                  </a>

                  <a class="dropdown-item"
                     onclick = "pdfZoomOut(); return false;">
                    <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24"
                         viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                         stroke-linecap="round" stroke-linejoin="round">
                      <circle cx="10" cy="10" r="7"/>
                      <line x1="21" y1="21" x2="15" y2="15"/>
                      <line x1="7" y1="10" x2="13" y2="10"/>
                    </svg>
                    Zoom out <kbd>⌘-</kbd>
                  </a>

                  <a class="dropdown-item"
                     onclick = "pdfFitToWidth(); return false;">
                    <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24"
                         viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                         stroke-linecap="round" stroke-linejoin="round">
                      <path d="M4 12v-6a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v6"/>
                      <path d="M4 18h16"/>
                    </svg>
                    Fit to width <kbd>⌘0</kbd>
                  </a>

                  <a class="dropdown-item"
                     onclick = "pdfFitToHeight(); return false;">
                    <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24"
                         viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                         stroke-linecap="round" stroke-linejoin="round">
                      <path d="M12 4v16"/>
                      <path d="M8 16h8"/>
                      <path d="M8 8h8"/>
                    </svg>
                    Fit to height <kbd>⌘9</kbd>
                  </a>

                </div>
              </div>

          <div class="nav-item">&nbsp; &nbsp; &nbsp;</div>


            <div class="navbar-nav flex-row mx-auto">
                <div style="display: flex; align-items: center; gap: 5px;">
                     <span class="file-on-editor">
                     <i class="fa-regular fa-folder" style="color: var(--tblr-primary); opacity: 1;"></i>
                   </span>
                   <div class="dropdown">
                  <div id="activeProjectName" class="shiny-text-output fw-bold" data-bs-toggle="dropdown" style="color: var(--tblr-body-color);"></div>
                  <div class="dropdown-menu">
                    <a class="dropdown-item" onclick="document.getElementById(\'global_project_download_link\').click()">
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
                        <path d="M6 20.735a2 2 0 0 1 -1 -1.735v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2h-1" />
                        <path d="M11 17a2 2 0 0 1 2 2v2a1 1 0 0 1 -1 1h-2a1 1 0 0 1 -1 -1v-2a2 2 0 0 1 2 -2z" />
                        <path d="M11 5l-1 0" />
                        <path d="M13 7l-1 0" />
                        <path d="M11 9l-1 0" />
                        <path d="M13 11l-1 0" />
                        <path d="M11 13l-1 0" />
                        <path d="M13 15l-1 0" />
                      </svg>

                      Download as source (.zip)</a>
                    <a class="dropdown-item" onclick="document.getElementById(\'pdf_download_link\').click()">
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
                      stroke-linejoin="round">
                      <path d="M14 3v4a1 1 0 0 0 1 1h4" />
                      <path d="M5 12v-7a2 2 0 0 1 2 -2h7l5 5v4" />
                      <path d="M5 18h1.5a1.5 1.5 0 0 0 0 -3h-1.5v6" />
                      <path d="M17 18h2" />
                      <path d="M20 15h-3v6" />
                      <path d="M11 15v6h1a2 2 0 0 0 2 -2v-2a2 2 0 0 0 -2 -2h-1z" />
                    </svg>
                    Download as PDF</a>

                    <div class="dropdown-divider"></div>
                    <a class="dropdown-item" onclick="openCopyProjectOverlay()">
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
                        <path d="M7 7m0 2.667a2.667 2.667 0 0 1 2.667 -2.667h8.666a2.667 2.667 0 0 1 2.667 2.667v8.666a2.667 2.667 0 0 1 -2.667 2.667h-8.666a2.667 2.667 0 0 1 -2.667 -2.667z" />
                        <path d="M4.012 16.737a2.005 2.005 0 0 1 -1.012 -1.737v-10c0 -1.1 .9 -2 2 -2h10c.75 0 1.158 .385 1.5 1" />
                      </svg>
                      Make a copy</a>
                    <a class="dropdown-item" onclick="openEditProjectOverlay()">
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
                        <path d="M7 7h-1a2 2 0 0 0 -2 2v9a2 2 0 0 0 2 2h9a2 2 0 0 0 2 -2v-1" />
                        <path d="M20.385 6.585a2.1 2.1 0 0 0 -2.97 -2.97l-8.415 8.385v3h3l8.385 -8.415z" />
                        <path d="M16 5l3 3" />
                      </svg>
                      Rename</a>
                  </div>
                </div>
              </div>


              <div class="navbar-status-group status-section-context">
                <span class="px-2">
                  <i class="fa-solid fa-chevron-right" style="font-size: 0.8em; color: var(--tblr-body-color);"></i>
                </span>
                <div style="display: flex; align-items: center; gap: 5px;">
                   <span class="file-on-editor">
                     <i class="fa-regular fa-file-lines" style="color: var(--tblr-primary); opacity: 1;"></i>
                   </span>
                   <span id="statusBar" class="status-item-text" style="color: var(--tblr-body-color);"></span>
                </div>
              </div>
            </div>

            <div class="navbar-nav flex-row order-md-last" style="color: var(--tblr-body-color) !important;">

             <div class="nav-divider"></div>

              <div class="nav-item">
              <div id="openHistoryBtn",
                class="nav-link d-flex lh-1 p-0"
                title="History"
                data-bs-toggle="tooltip"
                data-bs-placement="bottom"
                onclick="if (window.Shiny) Shiny.setInputValue(\'openHistoryBtn\', Math.random(), {priority: \'event\'});">
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
                    stroke-linejoin="round">
                    <path d="M12 8l0 4l2 2"></path>
                    <path d="M3.05 11a9 9 0 1 1 .5 4m-.5 5v-5h5"></path>
                  </svg>
                </div>
              </div>

            <div class="nav-divider"></div>
            <div class="nav-item dropdown">
              <a class="nav-link d-flex lh-1 p-0"
                 href="javascript:void(0);"
                 data-bs-toggle="dropdown"
                 aria-expanded="false">
                  <span data-bs-toggle="tooltip" data-bs-placement="bottom" title="Layout">
                      <svg xmlns="http://www.w3.org/2000/svg"
                      class="icon icon-1"
                      width="24" height="24"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round">
                        <path d="M5 4h4a1 1 0 0 1 1 1v6a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1v-6a1 1 0 0 1 1 -1" />
                        <path d="M5 16h4a1 1 0 0 1 1 1v2a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1v-2a1 1 0 0 1 1 -1" />
                        <path d="M15 12h4a1 1 0 0 1 1 1v6a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1v-6a1 1 0 0 1 1 -1" />
                        <path d="M15 4h4a1 1 0 0 1 1 1v2a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1v-2a1 1 0 0 1 1 -1" />
                      </svg>
                  </span>
              </a>
              <div class="dropdown-menu dropdown-menu-end dropdown-menu-arrow">
              <a class="dropdown-item layout-selector" data-layout="no-sidebar" onclick="toggleMainLayout(\'no-sidebar\');">
                <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" >
                  <path d="M4 4m0 2a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2z" />
                  <path d="M9 4v16" />
                  <path d="M15 10l-2 2l2 2" />
                </svg>
                Hide Sidebar
              </a>

              <a class="dropdown-item layout-selector" data-layout="editor-only" onclick="toggleMainLayout(\'editor-only\');">
                <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" >
                  <path d="M7 8l-4 4l4 4" />
                  <path d="M17 8l4 4l-4 4" />
                  <path d="M14 4l-4 16" />
                </svg>
                Editor Only
              </a>

              <a class="dropdown-item layout-selector" data-layout="pdf-only" onclick="toggleMainLayout(\'pdf-only\');">
                <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" >
                  <path d="M14 3v4a1 1 0 0 0 1 1h4" />
                  <path d="M5 12v-7a2 2 0 0 1 2 -2h7l5 5v4" />
                  <path d="M5 18h1.5a1.5 1.5 0 0 0 0 -3h-1.5v6" />
                  <path d="M17 18h2" />
                  <path d="M20 15h-3v6" />
                  <path d="M11 15v6h1a2 2 0 0 0 2 -2v-2a2 2 0 0 0 -2 -2h-1z" />
                </svg>
                PDF Only
              </a>

              <a class="dropdown-item layout-selector" data-layout="split" onclick="toggleMainLayout(\'split\');">
                <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" >
                  <path d="M4 4m0 2a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2z" />
                  <path d="M4 9h8" />
                  <path d="M12 15h8" />
                  <path d="M12 4v16" />
                </svg>
                Split View
              </a>
            </div>
          </div>
          <div class="nav-divider"></div>
          <div class="nav-item" style="color: var(--tblr-body-color) !important;">
            <a href="javascript:void(0);" class="nav-link px-0 hide-theme-dark" title="Enable dark mode" data-bs-toggle="tooltip" data-bs-placement="bottom"
               onclick="var r = document.querySelector(\'input[name=theme][value=dark]\'); if(r) r.click();">
              <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-1 text-muted">
                <path d="M12 3c.132 0 .263 0 .393 0a7.5 7.5 0 0 0 7.92 12.446a9 9 0 1 1 -8.313 -12.454z" />
              </svg>
            </a>

            <a href="javascript:void(0);" class="nav-link px-0 hide-theme-light" title="Enable light mode" data-bs-toggle="tooltip" data-bs-placement="bottom"
               onclick="var r = document.querySelector(\'input[name=theme][value=light]\'); if(r) r.click();">
              <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-1 text-muted">
                <path d="M12 12m-4 0a4 4 0 1 0 8 0a4 4 0 1 0 -8 0" />
                <path d="M3 12h1m8 -9v1m8 8h1m-9 8v1m-6.4 -15.4l.7 .7m12.1 -.7l-.7 .7m0 11.4l.7 .7m-12.1 -.7l-.7 .7" />
              </svg>
            </a>

          </div>

            </div>
          </div>
        </div>
      </header>
    </div>

        <!-- Main File -->
        <div class="mb-4 visually-hidden">
          <label class="form-label"></label>
          <div id="mainFileSelect" class="shiny-html-output form-select"></div>
        </div>'
          ),
          div(
            class = "page-wrapper",
            div(
              div(
                id = "mainArea",
                div(
                  id = "utilityRail",
                  div(
                    HTML(
                      '<div class="rail-btn btn-icon active"
                                  id="railSidebarToggle"
                                  title="Files"
                                  data-bs-toggle="tooltip"
                                  data-bs-placement="right"
                                  onclick="handleRailClick(\'files\')">
                                  <svg
                                    xmlns="http://www.w3.org/2000/svg"
                                    class="icon icon-1"
                                    width="24"
                                    height="24"
                                    viewBox="0 0 24 24"
                                    stroke-width="2"
                                    stroke="currentColor"
                                    fill="none"
                                    stroke-linecap="round"
                                    stroke-linejoin="round">
                                    <path d="M14 3v4a1 1 0 0 0 1 1h4" />
                                    <path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2z" />
                                    <path d="M9 9l1 0" />
                                    <path d="M9 13l6 0" />
                                    <path d="M9 17l6 0" />
                                  </svg>
                                </div>

                                <div
                                  class="rail-btn btn-icon"
                                  id="btnToggleFileSearch"
                                  title="Search Files"
                                  data-bs-toggle="tooltip"
                                  data-bs-placement="right"
                                  onclick="handleRailClick(\'search\')">
                                  <svg
                                    xmlns="http://www.w3.org/2000/svg"
                                    class="icon icon-1"
                                    width="24"
                                    height="24"
                                    viewBox="0 0 24 24"
                                    stroke-width="2"
                                    stroke="currentColor"
                                    fill="none"
                                    stroke-linecap="round"
                                    stroke-linejoin="round">
                                    <path stroke="none" d="M0 0h24v24H0z" fill="none" />
                                    <circle cx="10" cy="10" r="7" />
                                    <line x1="21" y1="21" x2="15" y2="15" />
                                  </svg>
                                </div>

                                  <div
                                    class = "rail-btn btn-icon"
                                    id = "railReviewBtn"
                                    title = "Review & Comments"
                                    data-bs-toggle = "tooltip"
                                    data-bs-placement = "right"
                                    onclick="handleRailClick(\'review\')">
                                    <svg xmlns="http://www.w3.org/2000/svg"
                                      class="icon icon-1"
                                      width="24"
                                      height="24"
                                      viewBox="0 0 24 24"
                                      fill="none"
                                      stroke="currentColor"
                                      stroke-width="2"
                                      stroke-linecap="round"
                                      stroke-linejoin="round">
                                      <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
                                      <path d="M8 9h8" />
                                      <path d="M8 13h6" />
                                      <path d="M18 4a3 3 0 0 1 3 3v8a3 3 0 0 1 -3 3h-5l-5 3v-3h-2a3 3 0 0 1 -3 -3v-8a3 3 0 0 1 3 -3h12z" />
                                    </svg>
                                  </div>

                                  <div class="rail-btn btn-icon"
                                   id="railChatBtn"
                                   title="Team Chat"
                                   data-bs-toggle="tooltip"
                                   data-bs-placement="right"
                                   onclick="handleRailClick(\'chat\')">
                                <div style="position: relative;">
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
                                  stroke-linejoin="round">
                                    <path d="M21 14l-3 -3h-7a1 1 0 0 1 -1 -1v-6a1 1 0 0 1 1 -1h9a1 1 0 0 1 1 1v10" />
                                    <path d="M14 15v2a1 1 0 0 1 -1 1h-7l-3 3v-10a1 1 0 0 1 1 -1h2" />
                                  </svg>
                                  <span id="chatUnreadBadge" class="badge bg-red badge-blink" style="position: absolute; top: -5px; right: -5px; width: 8px; height: 8px; padding: 0; display: none;"></span>
                                </div>
                              </div>

                              <div class="rail-btn btn-icon"
                                id="railAiBtn"
                                title="AI Assistant"
                                data-bs-toggle="tooltip"
                                data-bs-placement="right"
                                onclick="handleRailClick(\'ai\')">
                                <svg xmlns="http://www.w3.org/2000/svg"
                                class="icon"
                                width="24"
                                height="24"
                                viewBox="0 0 24 24"
                                stroke-width="2"
                                stroke="currentColor"
                                fill="none"
                                stroke-linecap="round"
                                stroke-linejoin="round">
                                  <path d="M6 4m0 2a2 2 0 0 1 2 -2h8a2 2 0 0 1 2 2v4a2 2 0 0 1 -2 2h-8a2 2 0 0 1 -2 -2z" />
                                  <path d="M12 2v2" />
                                  <path d="M9 12v9" />
                                  <path d="M15 12v9" />
                                  <path d="M5 16l4 -2" />
                                  <path d="M15 14l4 2" />
                                  <path d="M9 18h6" />
                                  <path d="M10 8v.01" />
                                  <path d="M14 8v.01" />
                                </svg>
                            </div>

                              '
                    )
                  ),
                  HTML(
                    '
                              <div>
                              <a class="rail-btn btn-icon"
                                  href="javascript:void(0);"
                                   title="Lock"
                                   data-bs-toggle="tooltip"
                                   data-bs-placement="top"
                                   data-bs-trigger="hover"
                                   data-bs-html="true"
                                   onclick="Shiny.setInputValue(\'manual_lock_trigger\', Math.random(), { priority: \'event\' });">
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
                                  stroke-linejoin="round">
                                  <path d="M5 13a2 2 0 0 1 2 -2h10a2 2 0 0 1 2 2v6a2 2 0 0 1 -2 2h-10a2 2 0 0 1 -2 -2v-6z" />
                                  <path d="M11 16a1 1 0 1 0 2 0a1 1 0 0 0 -2 0" />
                                  <path d="M8 11v-4a4 4 0 1 1 8 0v4" />
                                </svg>
                              </a>

                                <a class="rail-btn btn-icon"
                                   href="https://www.latex-project.org/help/links/#question-and-answer-websites"
                                   id="railHelpPageBtn"
                                   title="Help"
                                   data-bs-toggle="tooltip"
                                   data-bs-placement="top"
                                   data-bs-trigger="hover"
                                   data-bs-html="true"
                                   >
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
                                  stroke-linejoin="round">
                                  <path d="M12 12m-9 0a9 9 0 1 0 18 0a9 9 0 1 0 -18 0" />
                                  <path d="M12 17l0 .01" />
                                  <path d="M12 13.5a1.5 1.5 0 0 1 1 -1.5a2.6 2.6 0 1 0 -3 -4" />
                                </svg>
                              </a>

                               <div class="rail-btn btn-icon"
                                   id="railSettingsPageBtn"
                                   title = "Settings"
                                   data-bs-toggle="tooltip",
                                   data-bs-placement="right",
                                   onclick="if (window.Shiny) Shiny.setInputValue(\'railSettingsPageBtn\', Math.random(), {priority: \'event\'});">
                                <svg
                                  xmlns="http://www.w3.org/2000/svg"
                                  class="icon icon-1"
                                  width="24"
                                  height="24"
                                  viewBox="0 0 24 24"
                                  stroke-width="2"
                                  stroke="currentColor"
                                  fill="none"
                                  stroke-linecap="round"
                                  stroke-linejoin="round">
                                    <path stroke="none" d="M0 0h24v24H0z" fill="none" />
                                    <path
                                      d="M10.325 4.317c.426 -1.756 2.924 -1.756 3.35 0a1.724 1.724 0 0 0 2.573 1.066c1.543 -.94 3.31 .826 2.37 2.37a1.724 1.724 0 0 0 1.065 2.572c1.756 .426 1.756 2.924 0 3.35a1.724 1.724 0 0 0 -1.066 2.573c.94 1.543 -.826 3.31 -2.37 2.37a1.724 1.724 0 0 0 -2.572 1.065c-.426 1.756 -2.924 1.756 -3.35 0a1.724 1.724 0 0 0 -2.573 -1.066c-1.543 .94 -3.31 -.826 -2.37 -2.37a1.724 1.724 0 0 0 -1.065 -2.572c-1.756 -.426 -1.756 -2.924 0 -3.35a1.724 1.724 0 0 0 1.066 -2.573c-.94 -1.543 .826 -3.31 2.37 -2.37c1 .608 2.296 .07 2.572 -1.065z" />
                                    <circle cx="12" cy="12" r="3" />
                                </svg>
                              </div>
                              </div>
                             '
                  )
                ),
                div(
                  id = "splitWrapper",
                  style = "display: flex; flex: 1; height: 100%; overflow: hidden; min-width: 0;",
                  div(
                    id = "fileSidebar",
                    div(
                      id = "reviewPane",
                      class = "sidebar-pane",
                      style = "display:none; flex-direction: column; height: 100%;",
                      # 1. Header
                      div(
                        class = "pane-header",
                        style = "height: 38px; min-height: 38px; padding: 0 10px; display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid var(--tblr-border-color);",
                        tags$strong(
                          "Review",
                          style = "font-size:14px; font-weight:600;"
                        ),
                        div(
                          style = "display:flex; gap:10px;",
                          HTML(
                            '<div class="rail-btn btn-icon" title="Close" onclick="closeSidebar()" style="border:none;background:none;cursor:pointer;">
                                           <svg
                                              xmlns="http://www.w3.org/2000/svg"
                                              class="icon icon-1"
                                              width="24"
                                              height="24"
                                              viewBox="0 0 24 24"
                                              stroke-width="2"
                                              stroke="currentColor"
                                              fill="none"
                                              stroke-linecap="round"
                                              stroke-linejoin="round">
                                               <path d="M4 4m0 2a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2z" />
                                               <path d="M9 4l0 16" />
                                              </svg>
                                           </div>'
                          )
                        )
                      ),

                      # 2. Scrollable Content
                      div(
                        id = "reviewContent",
                        class = "pane-body",
                        style = "flex:1; overflow-y:auto; padding:15px;",
                        uiOutput("commentStream")
                      ),

                      # 3. Bottom Tabs (Vertical Split)
                      div(
                        class = "review-footer",
                        div(
                          class = "review-tab active",
                          id = "tabActiveComments",
                          onclick = "document.getElementById('tabResolvedComments').classList.remove('active'); this.classList.add('active'); Shiny.setInputValue('reviewFilter', 'active', {priority:'event'});",
                          "Active"
                        ),
                        div(
                          class = "review-tab",
                          id = "tabResolvedComments",
                          onclick = "document.getElementById('tabActiveComments').classList.remove('active'); this.classList.add('active'); Shiny.setInputValue('reviewFilter', 'resolved', {priority:'event'});",
                          "Resolved"
                        )
                      )
                    ),
                    div(
                      id = "chatPane",
                      class = "sidebar-pane",
                      style = "height: 38px; min-height: 38px; display:none; flex-direction: column; height: 100%; background: var(--bs-body-bg); border-right: 1px solid var(--tblr-border-color); padding-bottom: 2px; padding-top: 2px;",

                      # 1. Header with Color Picker & Search
                      div(
                        class = "pane-header",
                        style = "height: 38px; min-height: 38px; border-bottom: 1px solid var(--tblr-border-color); display: flex; flex-direction: column; gap: 10px; min-height: fit-content; flex-shrink: 0; z-index: 10; padding-bottom: 2px; padding-top: 2px;",

                        # ---Title and Controls ---
                        div(
                          style = "height: 38px; min-height: 38px; display:flex; justify-content:space-between; align-items:center; width: 100%; border-bottom: 1px solid var(--tblr-border-color); padding-bottom: 2px; padding-top: 2px;",
                          tags$strong(
                            "Team Chat",
                            style = "font-size:14px; font-weight:600;"
                          ),
                          div(
                            style = "height: 38px; min-height: 38px; display:flex; align-items:center; gap: 8px; padding-bottom: 2px; padding-top: 2px;",
                            # COLOR PICKER DROPDOWN
                            div(
                              class = "dropdown",
                              HTML(
                                '
                                                  <div class="rail-btn btn-icon"
                                                       data-bs-toggle="dropdown"
                                                       title="Message Color">
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
                                                          stroke-linejoin="round">
                                                            <path d="M9 12h6" />
                                                            <path d="M12 9v6" />
                                                            <path d="M3 5a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v14a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-14z" />
                                                        </svg>
                                                        </div>
                                                        '
                              ),
                              div(
                                class = "dropdown-menu dropdown-menu-end",
                                lapply(
                                  c(
                                    "blue",
                                    "azure",
                                    "indigo",
                                    "purple",
                                    "pink",
                                    "red",
                                    "orange",
                                    "yellow",
                                    "lime",
                                    "green",
                                    "teal",
                                    "cyan"
                                  ),
                                  function(c) {
                                    tags$a(
                                      class = "dropdown-item",
                                      href = "javascript:void(0);",
                                      onclick = sprintf(
                                        "Shiny.setInputValue('setChatColor', '%s-lt', {priority:'event'})",
                                        c
                                      ),
                                      div(
                                        class = paste0(
                                          "badge bg-",
                                          c,
                                          "-lt me-2"
                                        ),
                                        " "
                                      ),
                                      tools::toTitleCase(c)
                                    )
                                  }
                                )
                              )
                            ),

                            # CLOSE BUTTON
                            HTML(
                              '<button class="rail-btn btn-icon" title="Close Team Chat" data-bs-toggle="tooltip" data-bs-placement="right" onclick="closeSidebar()" style="border:none;background:none;cursor:pointer;">
                                             <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
                                               <path d="M4 4m0 2a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2z" />
                                               <path d="M9 4l0 16" />
                                             </svg>
                                           </button>'
                            )
                          )
                        ),

                        # --- BOTTOM ROW: Search Box ---
                        div(
                          style = "width: 100%;",
                          div(
                            class = "input-icon",
                            HTML(
                              '<span class="input-icon-addon">
                                            <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
                                              <circle cx="10" cy="10" r="7" />
                                              <line x1="21" y1="21" x2="15" y2="15" />
                                            </svg>
                                          </span>'
                            ),
                            tags$input(
                              id = "chatSearch",
                              type = "text",
                              class = "form-control form-control-sm",
                              placeholder = "Search messages...",
                              autocomplete = "off"
                            )
                          )
                        ),

                        # Typing Indicator
                        div(
                          id = "chatTypingIndicator",
                          style = "height: 14px; font-size: 10px; color: var(--tblr-secondary); margin-top: 4px; font-style: italic; transition: opacity 0.3s;",
                          ""
                        )
                      ),

                      # 2. Message Stream
                      div(
                        class = "position-relative",
                        style = "flex: 1; overflow: hidden; display: flex; flex-direction: column;",
                        div(
                          id = "chatContent",
                          class = "pane-body",
                          style = "flex: 1; overflow-y: auto; padding: 15px; background: var(--tblr-bg-surface-secondary); display: flex; flex-direction: column; gap: 12px;",
                          uiOutput("chatMessageStream")
                        ),
                        div(
                          id = "chatScrollBtn",
                          class = "btn btn-icon btn-primary rounded-circle shadow",
                          style = "position: absolute; bottom: 20px; right: 20px; display: none; z-index: 10;",
                          onclick = "scrollToBottom()",
                          HTML(
                            '<svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="16" y1="15" x2="12" y2="19"></line><line x1="8" y1="15" x2="12" y2="19"></line></svg>'
                          )
                        ),
                        div(
                          id = "emojiPicker",
                          class = "card shadow-sm",
                          style = "display: none; position: absolute; bottom: 80px; left: 10px; width: 260px; z-index: 20;",
                          div(
                            class = "card-body p-2",
                            div(
                              class = "d-flex flex-wrap gap-2",
                              id = "emojiGrid",
                              lapply(
                                c(
                                  "👍",
                                  "👎",
                                  "😀",
                                  "😂",
                                  "🎉",
                                  "❤️",
                                  "🚀",
                                  "🔥",
                                  "👀",
                                  "✅",
                                  "❌",
                                  "❓",
                                  "📎",
                                  "📂",
                                  "📊",
                                  "🤝"
                                ),
                                function(e) {
                                  tags$button(
                                    class = "btn btn-ghost-secondary btn-icon btn-sm emoji-btn",
                                    onclick = sprintf("insertEmoji('%s')", e),
                                    e
                                  )
                                }
                              )
                            )
                          )
                        )
                      ),

                      # 3. Input Area
                      div(
                        class = "chat-footer",
                        style = "padding: 10px; background: var(--bs-body-bg); border-top: 1px solid var(--tblr-border-color); position: relative;",
                        uiOutput("chatAttachmentPreview"),
                        tags$textarea(
                          id = "chatInputMsg",
                          class = "form-control mb-2",
                          rows = 2,
                          placeholder = "Type a message...",
                          style = "resize:none; font-size: 13px;",
                          onkeydown = "Shiny.setInputValue('userTyping', true, {priority:'event'});"
                        ),
                        div(
                          class = "d-flex justify-content-between align-items-center",
                          div(
                            class = "text-muted small",
                            style = "font-size: 10px; line-height: 1.2;",
                            "Enter to send",
                            br(),
                            "Shift+Enter for new line"
                          ),
                          div(
                            class = "d-flex align-items-center gap-2",
                            tags$button(
                              class = "btn btn-sm btn-icon",
                              style = "width: 32px; height: 32px;",
                              onclick = "toggleEmojiPicker(); event.stopPropagation();",
                              title = "Add Emoji",
                              `data-bs-toggle` = "tooltip",
                              `data-bs-placement` = "bottom",
                              HTML(
                                '<svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path d="M12 12m-9 0a9 9 0 1 0 18 0a9 9 0 1 0 -18 0" /><path d="M9 10l.01 0" /><path d="M15 10l.01 0" /><path d="M9.5 15a3.5 3.5 0 0 0 5 0" /></svg>'
                              )
                            ),
                            tags$button(
                              class = "btn btn-sm btn-icon",
                              style = "width: 32px; height: 32px;",
                              onclick = "$('#chatFileUpload').click()",
                              title = "Attach File",
                              `data-bs-toggle` = "tooltip",
                              `data-bs-placement` = "bottom",
                              HTML(
                                '<svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path d="M15 7l-6.5 6.5a1.5 1.5 0 0 0 3 3l6.5 -6.5a3 3 0 0 0 -6 -6l-6.5 6.5a4.5 4.5 0 0 0 9 9l6.5 -6.5" /></svg>'
                              )
                            ),
                            div(
                              style = "display:none;",
                              fileInput(
                                "chatFileUpload",
                                label = NULL,
                                multiple = TRUE,
                                accept = NULL,
                                width = "0px"
                              )
                            ),
                            tags$button(
                              class = "btn btn-primary btn-sm btn-icon",
                              style = "width: 32px; height: 32px; flex-shrink: 0;",
                              type = "button",
                              onclick = "Shiny.setInputValue('chatInputMsg', document.getElementById('chatInputMsg').value); Shiny.setInputValue('triggerSendChat', Math.random(), {priority: 'event'});",
                              title = "Send",
                              `data-bs-toggle` = "tooltip",
                              `data-bs-placement` = "bottom",
                              HTML(
                                '<svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><line x1="10" y1="14" x2="21" y2="3"></line><path d="M21 3L14.5 21a.55 .55 0 0 1 -1 0L10 14L3 10.5a.55 .55 0 0 1 0 -1L21 3"></path></svg>'
                              )
                            )
                          )
                        )
                      )
                    ),

                    # --- NEW SEARCH CONTAINER (Styled like Chat Pane) ---
                    div(
                      id = "fileSearchContainer",
                      style = "display:none; height: 100%; flex-direction: column;",

                      # 1. Header: Standard Pane Header with Title & Close Button
                      div(
                        class = "pane-header d-flex align-items-center justify-content-between px-3 py-2 border-bottom",
                        style = "height: 38px; min-height: 38px; padding: 0 10px;",
                        h3(class = "m-0", "Search Files"),
                        div(
                          style = "display:flex; gap:10px;",
                          HTML(
                            '<div class="rail-btn btn-icon" title="Close" onclick="closeSidebar()" style="border:none;background:none;cursor:pointer;">
                                         <svg
                                            xmlns="http://www.w3.org/2000/svg"
                                            class="icon icon-1"
                                            width="24"
                                            height="24"
                                            viewBox="0 0 24 24"
                                            stroke-width="2"
                                            stroke="currentColor"
                                            fill="none"
                                            stroke-linecap="round"
                                            stroke-linejoin="round">
                                             <path d="M4 4m0 2a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2z" />
                                             <path d="M9 4l0 16" />
                                            </svg>
                                         </div>'
                          )
                        )
                      ),

                      # 2. Search Input Toolbar
                      div(
                        class = "p-3 border-bottom",
                        HTML(
                          '
                                      <div class="input-icon">
                                        <span class="input-icon-addon">
                                          <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
                                          <path stroke="none" d="M0 0h24v24H0z" fill="none"/><circle cx="10" cy="10" r="7" /><line x1="21" y1="21" x2="15" y2="15" /></svg>
                                        </span>
                                        <input type="text" id="txtFileSearch" class="form-control" placeholder="Search filename or content..." autocomplete="off">
                                        <span class="input-icon-addon" style="cursor:pointer; pointer-events:auto;" onclick="document.getElementById(\'txtFileSearch\').value=\'\'; Shiny.setInputValue(\'fileSearchQuery\', \'\', {priority:\'event\'});">
                                          <svg xmlns="http://www.w3.org/2000/svg" class="icon" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
                                          <line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                                        </span>
                                      </div>
                                    '
                        )
                      ),

                      # 3. Results Area
                      div(
                        id = "fileSearchResults",
                        class = "shiny-html-output",
                        style = "flex: 1; overflow-y: auto; padding: 8px;"
                      )
                    ),

                    # --- AI Pane UI ---
                    div(
                      id = "aiPane",
                      class = "ai-pane chat-empty",
                      style = "display:none; flex-direction: column; background: var(--tblr-body-bg); height: 100%; border-left: 1px solid var(--tblr-border-color); position: relative; padding-bottom: 2px; padding-top: 1px;",

                      # 1. Header
                      div(
                        class = "pane-header",
                        div(
                          HTML(
                            '<span class="avatar avatar-sm rounded-circle me-2 ai-avatar-glow"></span>'
                          ),
                          tags$strong(
                            "Mudskipper Assistant",
                            style = "font-size:15px; font-weight:400; letter-spacing: -0.01em; padding-bottom: 2px; padding-top: 2px;"
                          )
                        ),
                        div(
                          class = "d-flex align-items-center gap-2",
                          style = "display:flex; align-items:center; gap: 16px; padding-bottom: 2px; padding-top: 2px;",
                          HTML(
                            '
                                        <div class="d-flex align-items-center" style = "display:flex; align-items:center; gap: 16px;">

                                        <div class="rail-btn btn-icon"
                                         id="ai_new_chat"
                                         style="pointer-events: auto; cursor: pointer;"
                                         title="New Chat"
                                         data-bs-toggle="tooltip"
                                         data-bs-placement="bottom"
                                         aria-label="New Chat"
                                         onclick="Shiny.setInputValue(\'ai_new_chat\', Math.random(), {priority: \'event\'});">
                                       <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                         <path d="M12 5l0 14" />
                                         <path d="M5 12l14 0" />
                                       </svg>
                                    </div>

                                    <div class="rail-btn btn-icon"
                                         id="ai_toggle_history"
                                         style="pointer-events: auto; cursor: pointer;"
                                         title="Chat History"
                                         data-bs-toggle="tooltip"
                                         data-bs-placement="bottom"
                                         aria-label="Chat History"
                                         onclick="Shiny.setInputValue(\'ai_toggle_history\', Math.random(), {priority: \'event\'});">
                                       <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                         <path d="M12 8l0 4l2 2"></path>
                                         <path d="M3.05 11a9 9 0 1 1 .5 4m-.5 5v-5h5"></path>
                                       </svg>
                                    </div>

                                      <div class="rail-btn btn-icon" title="Close AI Pane" data-bs-toggle="tooltip" data-bs-placement="right" onclick="closeSidebar()" style="border:none;background:none;cursor:pointer;">
                                         <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
                                         <path d="M4 4m0 2a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2z" />
                                         <path d="M9 4l0 16" />
                                         </svg>
                                        </div>

                                        </div>
                                        '
                          )
                        )
                      ),

                      # --- History Sidebar ---
                      div(
                        id = "aiHistorySidebar",
                        class = "history-sidebar",
                        div(
                          class = "p-3 border-bottom",
                          style = "font-weight: 600; color: var(--tblr-body-color); font-size: 0.5rem; letter-spacing: 0.02em;",
                          "RECENT CHATS"
                        ),
                        div(
                          style = "overflow-y: auto; flex: 1;",
                          uiOutput("chat_history_list")
                        )
                      ),

                      # 2. Chat Area
                      div(
                        id = "chat-scroll-container",
                        style = "flex:1; overflow-y:auto; padding:1.5rem; display: flex; flex-direction: column; gap: 1.25rem; scroll-behavior: smooth;",
                        uiOutput("chat_ui"),
                        conditionalPanel(
                          condition = "output.is_ai_typing == true",
                          div(
                            class = "d-flex align-items-start mb-2 fade-in",
                            div(
                              HTML(
                                '<span class="avatar avatar-sm rounded-circle me-2 ai-avatar-glow"></span>'
                              )
                            ),
                            div(
                              class = "card typing-indicator-card",
                              style = "background: var(--tblr-bg-surface-secondary); border: none; border-radius: 12px 12px 12px 4px; padding: 0.875rem 1rem;",
                              tags$em(
                                style = "font-size: 0.875rem; color: var(--tblr-muted);",
                                HTML(
                                  'Thinking <span class="animated-dots"></span>'
                                )
                              )
                            )
                          )
                        )
                      ),

                      # 3. Footer (Input Section)
                      div(
                        class = "pane-footer",
                        style = "padding: 1.5rem; border-top: 1px solid var(--tblr-border-color); background: var(--tblr-bg-surface);",

                        # --- Welcome Hero (Only visible in center mode) ---
                        div(
                          class = "welcome-hero",
                          div(
                            HTML(
                              '<span class="avatar avatar-sm rounded-circle me-2 ai-avatar-glow"></span>'
                            )
                          ),
                          h2(
                            "How can I help you today?",
                            style = "font-weight: 700; margin-bottom: 0.75rem; font-size: 1.75rem; letter-spacing: -0.02em;"
                          ),
                          p(
                            "I can help you write code, explain concepts, or debug errors.",
                            class = "text-muted",
                            style = "font-size: 0.9375rem; margin-bottom: 0;"
                          )
                        ),

                        # Input Group
                        div(
                          class = "input-group-modern mb-3",
                          textAreaInput(
                            "gemini_prompt",
                            label = NULL,
                            placeholder = "Ask me anything...",
                            width = "100%",
                            height = "56px",
                            resize = "none"
                          ),
                          actionButton(
                            "ai_send",
                            "",
                            icon = icon("arrow-up"),
                            class = "btn btn-primary btn-send"
                          )
                        ),

                        # Footer Controls
                        div(
                          class = "footer-controls d-flex justify-content-center align-items-center mt-3",
                          div(tags$small(
                            class = "text-muted",
                            style = "font-size: 0.8125rem; opacity: 0.8;",
                            "AI can make mistakes. Verify important information."
                          ))
                        )
                      )
                    ),
                    div(
                      id = "filesPane",
                      # Files pane header
                      div(
                        class = "pane-header",
                        style = "height: 38px; min-height: 38px; padding: 0 10px; display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid var(--tblr-border-color);",
                        div(
                          style = "display:flex; align-items:center; gap:8px;",
                          # Collapse chevron
                          HTML(
                            '<button type="button"
                                              id="toggleFilesPane"
                                              class="btn-icon"
                                              title="Collapse files"
                                              style="color: var(--bs-secondary-color); background: none; border: none; padding: 0; cursor: pointer; font-size: 16px;">
                                              <i class="fa-solid fa-chevron-down" id="filesPaneChevron"></i>
                                           </button>'
                          ),
                          tags$strong(
                            "Files",
                            style = "font-size:14px; font-weight:600;"
                          )
                        ),
                        div(
                          style = "display:flex; gap:10px; align-items:center;",
                          HTML(
                            '<button class="rail-btn btn-icon"
                                                type="button"
                                                 onclick="openAddFilesOverlay(\'add-file-tab\')"
                                                 title="New File"
                                                 data-bs-toggle="tooltip"
                                                 data-bs-placement="bottom"
                                                 style="color: var(--bs-secondary-color); background: none; border: none;padding: 0;cursor: pointer;">
                                                <svg
                                                  xmlns="http://www.w3.org/2000/svg"
                                                  class="icon icon-1"
                                                  width="24"
                                                  height="24"
                                                  viewBox="0 0 24 24"
                                                  stroke-width="2"
                                                  stroke="currentColor"
                                                  fill="none"
                                                  stroke-linecap="round"
                                                  stroke-linejoin="round">
                                                    <path d="M14 3v4a1 1 0 0 0 1 1h4" />
                                                    <path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2z" />
                                                    <path d="M12 11l0 6" />
                                                    <path d="M9 14l6 0" />
                                                  </svg>
                                              </button>
                                              <button class="rail-btn btn-icon"
                                                 type="button"
                                                 onclick="openAddFilesOverlay(\'add-folder-tab\')"
                                                 title="New Folder"
                                                 data-bs-toggle="tooltip"
                                                 data-bs-placement="bottom"
                                                 style="color: var(--bs-secondary-color); background: none; border: none;padding: 0;cursor: pointer;">
                                              <svg
                                                xmlns="http://www.w3.org/2000/svg"
                                                class="icon icon-1"
                                                width="24"
                                                height="24"
                                                viewBox="0 0 24 24"
                                                stroke-width="2"
                                                stroke="currentColor"
                                                fill="none"
                                                stroke-linecap="round"
                                                stroke-linejoin="round">
                                                 <path d="M12 19h-7a2 2 0 0 1 -2 -2v-11a2 2 0 0 1 2 -2h4l3 3h7a2 2 0 0 1 2 2v3.5" />
                                                 <path d="M16 19h6" />
                                                 <path d="M19 16v6" />
                                              </svg>
                                              </button>
                                              <button class="rail-btn btn-icon"
                                                 type="button"
                                                 onclick="openAddFilesOverlay(\'upload-tab\')"
                                                 title="Upload Files"
                                                 data-bs-toggle="tooltip"
                                                 data-bs-placement="bottom"
                                                 style="color: var(--bs-secondary-color); background: none; border: none;padding: 0;cursor: pointer;">
                                              <svg
                                                xmlns="http://www.w3.org/2000/svg"
                                                class="icon icon-1"
                                                width="24"
                                                height="24"
                                                viewBox="0 0 24 24"
                                                stroke-width="2"
                                                stroke="currentColor"
                                                fill="none"
                                                stroke-linecap="round"
                                                stroke-linejoin="round">
                                                  <path d="M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2 -2v-2" />
                                                  <path d="M7 9l5 -5l5 5" />
                                                  <path d="M12 4l0 12" />
                                              </svg>
                                              </button>
                                              <button class="rail-btn btn-icon"
                                                type="button"
                                                id="closeSidebarBtn"
                                                class="btn-link"
                                                title="Close Sidebar"
                                                data-bs-toggle="tooltip"
                                                data-bs-placement="right"
                                                style="color: var(--bs-secondary-color); background: none;border: none;padding: 0;cursor: pointer;">
                                              <svg
                                                xmlns="http://www.w3.org/2000/svg"
                                                class="icon icon-1"
                                                width="24"
                                                height="24"
                                                viewBox="0 0 24 24"
                                                stroke-width="2"
                                                stroke="currentColor"
                                                fill="none"
                                                stroke-linecap="round"
                                                stroke-linejoin="round">
                                                 <path d="M4 4m0 2a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2z" />
                                                 <path d="M9 4l0 16" />
                                              </svg>
                                           </button>
                                        '
                          )
                        )
                      ),
                      div(
                        class = "pane-body",
                        id = "filesPaneBody",
                        style = "overflow-y:auto; padding:12px; position: relative;",
                        HTML(
                          '<span id="filesSpinner" style="display:none; margin-left:8px;">
                                          <i class="spinner-border spinner-border-sm" style="width:40px; height:40px; border-width:1px; color:var(--tblr-primary);"></i>
                                        </span>'
                        ),

                        # --- EXISTING FILE TREE WRAPPER ---
                        div(
                          id = "fileTreeContainer",
                          HTML(
                            "<div id='fileListSidebar' class='shiny-html-output'></div>"
                          )
                        )
                      )
                    ),
                    div(
                      id = "outlinePane",
                      div(
                        class = "pane-header",
                        style = "height: 38px; min-height: 38px; padding: 0 10px; display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid var(--tblr-border-color); flex-shrink:0;",
                        div(
                          style = "display:flex; align-items:center; gap:8px;",
                          # Collapse chevron
                          HTML(
                            '<button type="button"
                                              id="toggleOutlinePane"
                                              class="btn-icon"
                                              title="Collapse outline"
                                              style="color: var(--bs-secondary-color); background: none; border: none; padding: 0; cursor: pointer; font-size: 16px; display:inline-flex; align-items:center; justify-content:center; width:24px; height:24px; transition:all 0.2s ease;">
                                              <i class="fa-solid fa-chevron-down" id="outlinePaneChevron" style="transition:transform 0.3s ease;"></i>
                                           </button>'
                          ),
                          tags$strong(
                            "Outline",
                            style = "font-size:14px; font-weight:600;"
                          )
                        )
                      ),
                      div(
                        class = "pane-body",
                        id = "outlinePaneBody",
                        style = "flex:1; overflow-y:auto; padding:12px; transition:max-height 0.3s ease, opacity 0.3s ease;",
                        HTML(
                          '<span id="outlineSpinner" style="display:none; margin-left:8px;">
                                          <i class="spinner-border spinner-border-sm" style="width:40px; height:40px; border-width:1px; color:var(--tblr-primary);"></i>
                                        </span>'
                        ),
                        div(
                          id = "outlineSidebar",
                          class = "shiny-html-output",
                          style = "white-space: nowrap; overflow:hidden; text-overflow: ellipsis;"
                        )
                      )
                    )
                  ),
                  div(
                    id = "editorArea",
                    HTML(
                      '
                              <div id="ace-comment-tooltip" class="comment-tooltip btn-sm" style="display:none;">
                                <button id="btnAddComment" onclick="triggerAddComment()">
                                  <svg
                                    xmlns="http://www.w3.org/2000/svg"
                                    class="icon icon-1"
                                    width="24"
                                    height="24"
                                    viewBox="0 0 24 24"
                                    fill="currentColor"
                                  >
                                    <path d="M18 3a4 4 0 0 1 4 4v8a4 4 0 0 1 -4 4h-4.724l-4.762 2.857a1 1 0 0 1 -1.508 -.743l-.006 -.114v-2h-1a4 4 0 0 1 -3.995 -3.8l-.005 -.2v-8a4 4 0 0 1 4 -4zm-4 9h-6a1 1 0 0 0 0 2h6a1 1 0 0 0 0 -2m2 -4h-8a1 1 0 1 0 0 2h8a1 1 0 0 0 0 -2" />
                                  </svg>

                                  Add comment
                                </button>
                              </div>
                            '
                    ),
                    div(
                      id = "equation-editor",
                      class = "border-bottom",
                      div(
                        style = "white-space: nowrap; overflow: hidden;",
                        div(
                          id = "toolbar",
                          style = "padding-left:5px; padding-right:5px; padding-bottom: 0px !important; display: inline-block; vertical-align: top; max-width: calc(100% - 50px); white-space: nowrap; height: 100%; background: var(--tblr-bg-surface) !important;"
                        ),
                        div(
                          style = "padding-top: 2px; padding-bottom: 0px; padding-left: 8px; width: auto; display: inline-flex; flex-direction: column; justify-content: center; vertical-align: center; height: 100%; border-left: 1px solid var(--tblr-border-color); border-radius: 0; gap: 12px;",

                          # 1. Dictate Button (Top)
                          tags$div(
                            id = "btnDictate",
                            class = "rail-btn btn-icon",
                            onclick = "window.toggleDictation()",
                            title = "Dictate",
                            "data-bs-toggle" = "tooltip",
                            "data-bs-placement" = "bottom",
                            HTML(
                              '
                                        <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                          <path d="M3 3l18 18" />
                                          <path d="M9 5a3 3 0 0 1 6 0v5a3 3 0 0 1 -.13 .874m-2 2a3 3 0 0 1 -3.87 -2.872v-1" />
                                          <path d="M5 10a7 7 0 0 0 10.846 5.85m2 -2a6.967 6.967 0 0 0 1.152 -3.85" />
                                          <path d="M8 21l8 0" />
                                          <path d="M12 17l0 4" />
                                        </svg>
                                      '
                            )
                          ),

                          # 2. Search Button (Bottom)
                          tags$div(
                            id = "railSearchBtn",
                            class = "rail-btn btn-icon",
                            "data-bs-toggle" = "tooltip",
                            "data-bs-placement" = "right",
                            "data-bs-html" = "true",
                            title = "<div>Find/Replace</div><div> CTRL/⌘ + F</div>",
                            onclick = "var editor = ace.edit('sourceEditor'); if (editor) { ace.require('ace/ext/searchbox').Search(editor, false);}",
                            HTML(
                              '
                                        <svg xmlns="http://www.w3.org/2000/svg" class="icon icon-1" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">
                                          <path stroke="none" d="M0 0h24v24H0z" fill="none" />
                                          <circle cx="10" cy="10" r="7" />
                                          <line x1="21" y1="21" x2="15" y2="15" />
                                        </svg>
                                      '
                            )
                          )
                        )
                      )
                    ),
                    HTML(
                      '
                              <div id="filePreviewOverlay">
                                <div id="filePreviewDialog">
                                  <div id="filePreviewHeader">
                                    <h3 id="filePreviewTitle" class="m-0" style="font-size: 1rem; font-weight: 600;"></h3>

                                    <a id="previewDownloadBtn"
                                        href="javascript:void(0);"
                                        class="btn-icon"
                                        title="Download file"
                                        data-bs-toggle="tooltip"
                                        data-bs-placement="bottom"
                                        style="color: var(--tblr-body-color); cursor: pointer;">
                                      <svg
                                        xmlns="http://www.w3.org/2000/svg"
                                        class="icon icon-1"
                                        width="20"
                                        height="20"
                                        viewBox="0 0 24 24"
                                        fill="none"
                                        stroke="currentColor"
                                        stroke-width="2"
                                        stroke-linecap="round"
                                        stroke-linejoin="round">
                                          <path d="M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2 -2v-2"></path>
                                          <polyline points="7 11 12 16 17 11"></polyline>
                                          <line x1="12" y1="4" x2="12" y2="16"></line>
                                      </svg>
                                    </a>
                                  </div>
                                  <div id="filePreviewBody"></div>
                                </div>
                              </div>
                              '
                    ),
                    div(
                      id = "editorSplit",
                      style = "height: calc(100% - 30px); position: relative;",
                      HTML(
                        '<span id="editorSpinner" style="display:none; margin-left:8px;">
                                          <i class="spinner-border spinner-border-sm" style="width:40px; height:40px; border-width: 1px; color:var(--tblr-primary); z-index: 2000;"></i>
                                        </span>'
                      ),
                      aceEditor(
                        "sourceEditor",
                        value = "",
                        height = "92%",
                        wordWrap = TRUE,
                        showPrintMargin = FALSE,
                        autoComplete = "live",
                        tabSize = 4,
                        useSoftTabs = TRUE,
                        showInvisibles = FALSE
                      ),
                      HTML(
                        '
                              <div id="symbolPalette" style="border-top: 4px solid var(--tblr-border-color);">
                                <div style="display: flex; justify-content: space-between; align-items: center; padding: 5px 10px; color: var(--tblr-body-color);">
                                  <ul class="nav nav-tabs border-0 p-0 m-0" role="tablist">
                                    <li class="nav-item"><button class="nav-link active" data-bs-toggle="tab" data-bs-target="#sym-greek">Greek</button></li>
                                    <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#sym-arrows">Arrows</button></li>
                                    <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#sym-ops">Operators</button></li>
                                    <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#sym-rel">Relations</button></li>
                                    <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#sym-misc">Misc</button></li>
                                    <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#sym-math">Math</button></li>
                                    <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#sym-sets">Sets</button></li>
                                  </ul>

                                  <div class="nav-item" style="display:flex; gap:10px; align-items:center;">
                                    <input type="text" id="symbolSearch" class="form-control form-control-sm" placeholder="Search symbols..." onkeyup="filterSymbols(this.value)" style="background: var(--tblr-white); color: var(--tblr-black);">
                                    <button type="button" title="Close" data-bs-toggle="tooltip" class="btn-close" onclick="toggleSymbolPalette()"></button>
                                  </div>
                                </div>

                                <div class="tab-content" style="flex:1; overflow-y:auto; padding:10px;">

                                  <div class="tab-pane show active" id="sym-greek">
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\alpha \')" title="\\alpha" data-bs-toggle="tooltip">α</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\beta \')" title="\\beta" data-bs-toggle="tooltip">β</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\gamma \')" title="\\gamma" data-bs-toggle="tooltip">γ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\delta \')" title="\\delta" data-bs-toggle="tooltip">δ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\epsilon \')" title="\\epsilon" data-bs-toggle="tooltip">ϵ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\varepsilon \')" title="\\varepsilon" data-bs-toggle="tooltip">ε</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\zeta \')" title="\\zeta" data-bs-toggle="tooltip">ζ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\eta \')" title="\\eta" data-bs-toggle="tooltip">η</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\theta \')" title="\\theta" data-bs-toggle="tooltip">θ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\vartheta \')" title="\\vartheta" data-bs-toggle="tooltip">ϑ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\iota \')" title="\\iota" data-bs-toggle="tooltip">ι</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\kappa \')" title="\\kappa" data-bs-toggle="tooltip">κ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\lambda \')" title="\\lambda" data-bs-toggle="tooltip">λ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\mu \')" title="\\mu" data-bs-toggle="tooltip">μ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\nu \')" title="\\nu" data-bs-toggle="tooltip">ν</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\xi \')" title="\\xi" data-bs-toggle="tooltip">ξ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\pi \')" title="\\pi" data-bs-toggle="tooltip">π</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\varpi \')" title="\\varpi" data-bs-toggle="tooltip">ϖ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\rho \')" title="\\rho" data-bs-toggle="tooltip">ρ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\varrho \')" title="\\varrho" data-bs-toggle="tooltip">ϱ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\sigma \')" title="\\sigma" data-bs-toggle="tooltip">σ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\varsigma \')" title="\\varsigma" data-bs-toggle="tooltip">ς</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\tau \')" title="\\tau" data-bs-toggle="tooltip">τ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\upsilon \')" title="\\upsilon" data-bs-toggle="tooltip">υ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\phi \')" title="\\phi" data-bs-toggle="tooltip">ϕ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\varphi \')" title="\\varphi" data-bs-toggle="tooltip">φ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\chi \')" title="\\chi" data-bs-toggle="tooltip">χ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\psi \')" title="\\psi" data-bs-toggle="tooltip">ψ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\omega \')" title="\\omega" data-bs-toggle="tooltip">ω</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Gamma \')" title="\\Gamma" data-bs-toggle="tooltip">Γ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Delta \')" title="\\Delta" data-bs-toggle="tooltip">Δ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Theta \')" title="\\Theta" data-bs-toggle="tooltip">Θ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Lambda \')" title="\\Lambda" data-bs-toggle="tooltip">Λ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Xi \')" title="\\Xi" data-bs-toggle="tooltip">Ξ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Pi \')" title="\\Pi" data-bs-toggle="tooltip">Π</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Sigma \')" title="\\Sigma" data-bs-toggle="tooltip">Σ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Upsilon \')" title="\\Upsilon" data-bs-toggle="tooltip">Υ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Phi \')" title="\\Phi" data-bs-toggle="tooltip">Φ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Psi \')" title="\\Psi" data-bs-toggle="tooltip">Ψ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Omega \')" title="\\Omega" data-bs-toggle="tooltip">Ω</button>
                                  </div>

                                  <div class="tab-pane" id="sym-arrows">
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\leftarrow \')" title="\\leftarrow" data-bs-toggle="tooltip">←</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\rightarrow \')" title="\\rightarrow" data-bs-toggle="tooltip">→</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\leftrightarrow \')" title="\\leftrightarrow" data-bs-toggle="tooltip">↔</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\uparrow \')" title="\\uparrow" data-bs-toggle="tooltip">↑</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\downarrow \')" title="\\downarrow" data-bs-toggle="tooltip">↓</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\updownarrow \')" title="\\updownarrow" data-bs-toggle="tooltip">↕</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Leftarrow \')" title="\\Leftarrow" data-bs-toggle="tooltip">⇐</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Rightarrow \')" title="\\Rightarrow" data-bs-toggle="tooltip">⇒</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Leftrightarrow \')" title="\\Leftrightarrow" data-bs-toggle="tooltip">⇔</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Uparrow \')" title="\\Uparrow" data-bs-toggle="tooltip">⇑</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Downarrow \')" title="\\Downarrow" data-bs-toggle="tooltip">⇓</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Updownarrow \')" title="\\Updownarrow" data-bs-toggle="tooltip">⇕</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\mapsto \')" title="\\mapsto" data-bs-toggle="tooltip">↦</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\longleftarrow \')" title="\\longleftarrow" data-bs-toggle="tooltip">⟵</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\longrightarrow \')" title="\\longrightarrow" data-bs-toggle="tooltip">⟶</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Longleftarrow \')" title="\\Longleftarrow" data-bs-toggle="tooltip">⟸</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Longrightarrow \')" title="\\Longrightarrow" data-bs-toggle="tooltip">⟹</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Longleftrightarrow \')" title="\\Longleftrightarrow" data-bs-toggle="tooltip">⟺</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\iff \')" title="\\iff" data-bs-toggle="tooltip">⟺</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\implies \')" title="\\implies" data-bs-toggle="tooltip">⟹</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\nearrow \')" title="\\nearrow" data-bs-toggle="tooltip">↗</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\searrow \')" title="\\searrow" data-bs-toggle="tooltip">↘</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\swarrow \')" title="\\swarrow" data-bs-toggle="tooltip">↙</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\nwarrow \')" title="\\nwarrow" data-bs-toggle="tooltip">↖</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\rightleftharpoons \')" title="\\rightleftharpoons" data-bs-toggle="tooltip">⇌</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\leftharpoonup \')" title="\\leftharpoonup" data-bs-toggle="tooltip">↼</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\rightharpoonup \')" title="\\rightharpoonup" data-bs-toggle="tooltip">⇀</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\leftharpoondown \')" title="\\leftharpoondown" data-bs-toggle="tooltip">↽</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\rightharpoondown \')" title="\\rightharpoondown" data-bs-toggle="tooltip">⇁</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\hookrightarrow \')" title="\\hookrightarrow" data-bs-toggle="tooltip">↪</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\hookleftarrow \')" title="\\hookleftarrow" data-bs-toggle="tooltip">↩</button>
                                  </div>

                                  <div class="tab-pane" id="sym-ops">
                                    <button class="symbol-btn operator" onclick="insertSymbol(\'+\')" title="+" data-bs-toggle="tooltip">+</button>
                                    <button class="symbol-btn operator" onclick="insertSymbol(\'-\')" title="-" data-bs-toggle="tooltip">−</button>
                                    <button class="symbol-btn operator" onclick="insertSymbol(\'\\times \')" title="\\times" data-bs-toggle="tooltip">×</button>
                                    <button class="symbol-btn operator" onclick="insertSymbol(\'\\div \')" title="\\div" data-bs-toggle="tooltip">÷</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\pm \')" title="\\pm" data-bs-toggle="tooltip">±</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\mp \')" title="\\mp" data-bs-toggle="tooltip">∓</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\cdot \')" title="\\cdot" data-bs-toggle="tooltip">⋅</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\cdots \')" title="\\cdots" data-bs-toggle="tooltip">⋯</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\bullet \')" title="\\bullet" data-bs-toggle="tooltip">∙</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\circ \')" title="\\circ" data-bs-toggle="tooltip">◦</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\cap \')" title="\\cap" data-bs-toggle="tooltip">∩</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\cup \')" title="\\cup" data-bs-toggle="tooltip">∪</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\uplus \')" title="\\uplus" data-bs-toggle="tooltip">⊎</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\sqcap \')" title="\\sqcap" data-bs-toggle="tooltip">⊓</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\sqcup \')" title="\\sqcup" data-bs-toggle="tooltip">⊔</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\wedge \')" title="\\wedge" data-bs-toggle="tooltip">∧</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\vee \')" title="\\vee" data-bs-toggle="tooltip">∨</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\setminus \')" title="\\setminus" data-bs-toggle="tooltip">∖</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\oplus \')" title="\\oplus" data-bs-toggle="tooltip">⊕</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\ominus \')" title="\\ominus" data-bs-toggle="tooltip">⊖</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\otimes \')" title="\\otimes" data-bs-toggle="tooltip">⊗</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\oslash \')" title="\\oslash" data-bs-toggle="tooltip">⊘</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\odot \')" title="\\odot" data-bs-toggle="tooltip">⊙</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\bigcirc \')" title="\\bigcirc" data-bs-toggle="tooltip">○</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Box \')" title="\\Box" data-bs-toggle="tooltip">▢</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\boxtimes \')" title="\\boxtimes" data-bs-toggle="tooltip">⊠</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\sum \')" title="\\sum" data-bs-toggle="tooltip">∑</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\prod \')" title="\\prod" data-bs-toggle="tooltip">∏</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\coprod \')" title="\\coprod" data-bs-toggle="tooltip">∐</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\int \')" title="\\int" data-bs-toggle="tooltip">∫</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\iint \')" title="\\iint" data-bs-toggle="tooltip">∬</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\iiint \')" title="\\iiint" data-bs-toggle="tooltip">∭</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\oint \')" title="\\oint" data-bs-toggle="tooltip">∮</button>
                                  </div>

                                  <div class="tab-pane" id="sym-rel">
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'=\')" title="=" data-bs-toggle="tooltip">=</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'\\neq \')" title="\\neq" data-bs-toggle="tooltip">≠</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'<\')" title="<" data-bs-toggle="tooltip"><</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'>\')" title=">" data-bs-toggle="tooltip">></button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'\\leq \')" title="\\leq" data-bs-toggle="tooltip">≤</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'\\geq \')" title="\\geq" data-bs-toggle="tooltip">≥</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'\\ll \')" title="\\ll" data-bs-toggle="tooltip">≪</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'\\gg \')" title="\\gg" data-bs-toggle="tooltip">≫</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'\\prec \')" title="\\prec" data-bs-toggle="tooltip">≺</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'\\succ \')" title="\\succ" data-bs-toggle="tooltip">≻</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'\\preceq \')" title="\\preceq" data-bs-toggle="tooltip">⪯</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'\\succeq \')" title="\\succeq" data-bs-toggle="tooltip">⪰</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'\\equiv \')" title="\\equiv" data-bs-toggle="tooltip">≡</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'\\approx \')" title="\\approx" data-bs-toggle="tooltip">≈</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'\\sim \')" title="\\sim" data-bs-toggle="tooltip">∼</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'\\simeq \')" title="\\simeq" data-bs-toggle="tooltip">≃</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'\\cong \')" title="\\cong" data-bs-toggle="tooltip">≅</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'\\doteq \')" title="\\doteq" data-bs-toggle="tooltip">≐</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'\\mid \')" title="\\mid" data-bs-toggle="tooltip">∣</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'\\nmid \')" title="\\nmid" data-bs-toggle="tooltip">∤</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'\\parallel \')" title="\\parallel" data-bs-toggle="tooltip">∥</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'\\perp \')" title="\\perp" data-bs-toggle="tooltip">⟂</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'\\vdash \')" title="\\vdash" data-bs-toggle="tooltip">⊢</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'\\models \')" title="\\models" data-bs-toggle="tooltip">⊨</button>
                                    <button class="symbol-btn relation" onclick="insertSymbol(\'\\propto \')" title="\\propto" data-bs-toggle="tooltip">∝</button>
                                  </div>

                                  <div class="tab-pane" id="sym-misc">
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\infty \')" title="\\infty" data-bs-toggle="tooltip">∞</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\partial \')" title="\\partial" data-bs-toggle="tooltip">∂</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\nabla \')" title="\\nabla" data-bs-toggle="tooltip">∇</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\forall \')" title="\\forall" data-bs-toggle="tooltip">∀</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\exists \')" title="\\exists" data-bs-toggle="tooltip">∃</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\nexists \')" title="\\nexists" data-bs-toggle="tooltip">∄</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\neg \')" title="\\neg" data-bs-toggle="tooltip">¬</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\therefore \')" title="\\therefore" data-bs-toggle="tooltip">∴</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\because \')" title="\\because" data-bs-toggle="tooltip">∵</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\emptyset \')" title="\\emptyset" data-bs-toggle="tooltip">∅</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\varnothing \')" title="\\varnothing" data-bs-toggle="tooltip">⌀</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Re \')" title="\\Re" data-bs-toggle="tooltip">ℜ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\Im \')" title="\\Im" data-bs-toggle="tooltip">ℑ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\aleph \')" title="\\aleph" data-bs-toggle="tooltip">ℵ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\wp \')" title="\\wp" data-bs-toggle="tooltip">℘</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\ell \')" title="\\ell" data-bs-toggle="tooltip">ℓ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\hbar \')" title="\\hbar" data-bs-toggle="tooltip">ℏ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\square \')" title="\\square" data-bs-toggle="tooltip">□</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\blacksquare \')" title="\\blacksquare" data-bs-toggle="tooltip">■</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\triangle \')" title="\\triangle" data-bs-toggle="tooltip">△</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\angle \')" title="\\angle" data-bs-toggle="tooltip">∠</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\measuredangle \')" title="\\measuredangle" data-bs-toggle="tooltip">∡</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\surd \')" title="\\surd" data-bs-toggle="tooltip">√</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\prime \')" title="\\prime" data-bs-toggle="tooltip">′</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\{\')" title="\\{" data-bs-toggle="tooltip">{</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\}\')" title="\\}" data-bs-toggle="tooltip">}</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\langle \')" title="\\langle" data-bs-toggle="tooltip">⟨</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\rangle \')" title="\\rangle" data-bs-toggle="tooltip">⟩</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\#\')" title="\\#" data-bs-toggle="tooltip">#</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\$\')" title="\\$" data-bs-toggle="tooltip">$</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\%\')" title="\\%" data-bs-toggle="tooltip">%</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\&\')" title="\\&" data-bs-toggle="tooltip">&</button>
                                  </div>

                                  <div class="tab-pane" id="sym-math">
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\ast \')" title="\\ast" data-bs-toggle="tooltip">∗</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\star \')" title="\\star" data-bs-toggle="tooltip">⋆</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\diamond \')" title="\\diamond" data-bs-toggle="tooltip">⋄</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\dagger \')" title="\\dagger" data-bs-toggle="tooltip">†</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\ddagger \')" title="\\ddagger" data-bs-toggle="tooltip">‡</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\amalg \')" title="\\amalg" data-bs-toggle="tooltip">⨿</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\top \')" title="\\top" data-bs-toggle="tooltip">⊤</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\bot \')" title="\\bot" data-bs-toggle="tooltip">⊥</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\flat \')" title="\\flat" data-bs-toggle="tooltip">♭</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\natural \')" title="\\natural" data-bs-toggle="tooltip">♮</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\sharp \')" title="\\sharp" data-bs-toggle="tooltip">♯</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\clubsuit \')" title="\\clubsuit" data-bs-toggle="tooltip">♣</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\diamondsuit \')" title="\\diamondsuit" data-bs-toggle="tooltip">♢</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\heartsuit \')" title="\\heartsuit" data-bs-toggle="tooltip">♡</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\spadesuit \')" title="\\spadesuit" data-bs-toggle="tooltip">♠</button>
                                  </div>

                                  <div class="tab-pane" id="sym-sets">
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\in \')" title="\\in" data-bs-toggle="tooltip">∈</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\notin \')" title="\\notin" data-bs-toggle="tooltip">∉</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\ni \')" title="\\ni" data-bs-toggle="tooltip">∋</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\subset \')" title="\\subset" data-bs-toggle="tooltip">⊂</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\subseteq \')" title="\\subseteq" data-bs-toggle="tooltip">⊆</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\supset \')" title="\\supset" data-bs-toggle="tooltip">⊃</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\supseteq \')" title="\\supseteq" data-bs-toggle="tooltip">⊇</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\sqsubset \')" title="\\sqsubset" data-bs-toggle="tooltip">⊏</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\sqsubseteq \')" title="\\sqsubseteq" data-bs-toggle="tooltip">⊑</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\sqsupset \')" title="\\sqsupset" data-bs-toggle="tooltip">⊐</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\sqsupseteq \')" title="\\sqsupseteq" data-bs-toggle="tooltip">⊒</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\mathbb{R}\')" title="\\mathbb{R}" data-bs-toggle="tooltip">ℝ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\mathbb{Q}\')" title="\\mathbb{Q}" data-bs-toggle="tooltip">ℚ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\mathbb{Z}\')" title="\\mathbb{Z}" data-bs-toggle="tooltip">ℤ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\mathbb{N}\')" title="\\mathbb{N}" data-bs-toggle="tooltip">ℕ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\mathbb{C}\')" title="\\mathbb{C}" data-bs-toggle="tooltip">ℂ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\mathbb{H}\')" title="\\mathbb{H}" data-bs-toggle="tooltip">ℍ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\mathbb{P}\')" title="\\mathbb{P}" data-bs-toggle="tooltip">ℙ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\mathcal{A}\')" title="\\mathcal{A}" data-bs-toggle="tooltip">𝒜</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\mathcal{B}\')" title="\\mathcal{B}" data-bs-toggle="tooltip">ℬ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\mathcal{C}\')" title="\\mathcal{C}" data-bs-toggle="tooltip">𝒞</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\mathcal{L}\')" title="\\mathcal{L}" data-bs-toggle="tooltip">ℒ</button>
                                    <button class="symbol-btn" onclick="insertSymbol(\'\\mathcal{O}\')" title="\\mathcal{O}" data-bs-toggle="tooltip">𝒪</button>
                                  </div>
                                </div>
                              </div>
                              '
                      ),
                    )
                  ),
                  div(
                    id = "pdfPreview",
                    div(
                      class = "pdf-header",
                      # 1. Enable Container Queries on the header itself
                      style = "height: 38px; min-height: 38px; padding: 0 10px; display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid var(--tblr-border-color); background: var(--tblr-bg-surface) !important; container-type: inline-size;",

                      # 2. Inject CSS for Wide/Narrow toggling based on container width
                      tags$style(HTML(
                        "
                                    /* Default: WIDE View */
                                    .header-wide-only { display: flex !important; align-items: center; }
                                    .header-narrow-only { display: none !important; }

                                    /* Switch to NARROW View when header is smaller than 450px */
                                    @container (max-width: 450px) {
                                      .header-wide-only { display: none !important; }
                                      .header-narrow-only { display: block !important; }
                                    }
                                  "
                      )),

                      # --- LEFT SIDE: Compile Group + Download ---
                      div(
                        style = "display:flex; align-items: center; gap: 8px;",

                        # Compile Button Group
                        div(
                          class = "btn-group",
                          style = "border-radius: 50px;",
                          actionButton(
                            "compile",
                            HTML(
                              "Recompile &nbsp; <span id='compileSpinner' style='display:none;'><i class='spinner-border spinner-border-sm me-2 cursor-not-allowed'></i></span>"
                            ),
                            class = "btn btn-sm btn-primary",
                            style = "border-radius: 50px 0 0 50px; height: 24px; padding-top: 0; padding-bottom: 0; display: flex; align-items: center;"
                          ),
                          tags$button(
                            class = "btn btn-sm btn-primary dropdown-toggle dropdown-toggle-split",
                            type = "button",
                            `data-bs-toggle` = "dropdown",
                            `aria-expanded` = "false",
                            style = "width: 2.2em; border-left: 1px solid rgba(255,255,255,0.2); border-radius: 0 50px 50px 0; padding: 0 0.4em; height: 24px;",
                            tags$span(
                              class = "visually-hidden",
                              "Toggle dropdown"
                            )
                          ),
                          div(
                            class = "dropdown",
                            div(
                              class = "dropdown-menu dropdown-menu-end",
                              h6(class = "dropdown-header", "Auto compile"),
                              tags$label(
                                class = "dropdown-item",
                                tags$input(
                                  type = "radio",
                                  name = "autoCompile",
                                  value = "on",
                                  id = "autoCompileOn"
                                ),
                                tags$i(class = "ti ti-check tick-icon"),
                                "On"
                              ),
                              tags$label(
                                class = "dropdown-item",
                                tags$input(
                                  type = "radio",
                                  name = "autoCompile",
                                  value = "off",
                                  id = "autoCompileOff",
                                  checked = NA
                                ),
                                tags$i(class = "ti ti-check tick-icon"),
                                "Off"
                              ),
                              div(class = "dropdown-divider"),
                              h6(class = "dropdown-header", "Compile mode"),
                              tags$label(
                                class = "dropdown-item",
                                tags$input(
                                  type = "radio",
                                  name = "compileMode",
                                  value = "normal",
                                  id = "compileModeNormal",
                                  checked = NA
                                ),
                                tags$i(class = "ti ti-check tick-icon"),
                                "Normal"
                              ),
                              tags$label(
                                class = "dropdown-item",
                                tags$input(
                                  type = "radio",
                                  name = "compileMode",
                                  value = "fast",
                                  id = "compileModeFast"
                                ),
                                tags$i(class = "ti ti-check tick-icon"),
                                "Fast [draft]"
                              ),
                              div(class = "dropdown-divider"),
                              h6(class = "dropdown-header", "Syntax checks"),
                              tags$label(
                                class = "dropdown-item",
                                tags$input(
                                  type = "radio",
                                  name = "syntaxCheck",
                                  value = "before",
                                  id = "syntaxCheckBefore"
                                ),
                                tags$i(class = "ti ti-check tick-icon"),
                                "Check syntax before compile"
                              ),
                              tags$label(
                                class = "dropdown-item",
                                tags$input(
                                  type = "radio",
                                  name = "syntaxCheck",
                                  value = "none",
                                  id = "syntaxCheckNone",
                                  checked = NA
                                ),
                                tags$i(class = "ti ti-check tick-icon"),
                                "Don't check syntax"
                              ),
                              div(class = "dropdown-divider"),
                              h6(
                                class = "dropdown-header",
                                "Compile error handling"
                              ),
                              tags$label(
                                class = "dropdown-item",
                                tags$input(
                                  type = "radio",
                                  name = "errorHandling",
                                  value = "stopFirst",
                                  id = "errorHandlingStop"
                                ),
                                tags$i(class = "ti ti-check tick-icon"),
                                "Stop on first error"
                              ),
                              tags$label(
                                class = "dropdown-item",
                                tags$input(
                                  type = "radio",
                                  name = "errorHandling",
                                  value = "tryCompile",
                                  id = "errorHandlingTry",
                                  checked = NA
                                ),
                                tags$i(class = "ti ti-check tick-icon"),
                                "Try to compile despite errors"
                              ),
                              div(class = "dropdown-divider"),
                              actionLink(
                                "stopCompilation",
                                HTML(
                                  '<i class="ti ti-square me-2"></i> Stop compilation'
                                ),
                                class = "dropdown-item text-danger"
                              ),
                              actionLink(
                                "recompileFromScratch",
                                HTML(
                                  '<i class="ti ti-refresh me-2"></i> Recompile from scratch'
                                ),
                                class = "dropdown-item"
                              )
                            )
                          )
                        ),
                        HTML(
                          '
                                  <div class="nav-badge-container"
                                    id="railErrorLogBtn"
                                    title="Error log and compiled files"
                                    data-bs-toggle="tooltip"
                                    data-bs-placement="bottom"
                                    onclick="if (window.Shiny) Shiny.setInputValue(\'railErrorLogBtn\', Math.random(), {priority: \'event\'});"
                                    >
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
                                      <path d="M14 3v4a1 1 0 0 0 1 1h4" />
                                      <path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2z" />
                                      <path d="M9 9l1 0" />
                                      <path d="M9 13l6 0" />
                                      <path d="M9 17l6 0" />
                                    </svg>
                                      <span id="errorLogBadge" class="nav-badge-counter"></span>
                                    </div>

                                  '
                        ),
                        # Download Button (Left Side)
                        div(
                          id = "pdfDownload",
                          title = "Download PDF",
                          `data-bs-toggle` = "tooltip",
                          `data-bs-placement` = "bottom",
                          class = "rail-btn btn-icon",
                          style = "width: 24px; height: 24px; background: none; cursor: pointer; display: flex; align-items: center; justify-content: center;",
                          onclick = "pdfDownload()",
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
                                                 <path d="M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2 -2v-2" />
                                                 <path d="M7 11l5 5l5 -5" />
                                                 <path d="M12 4l0 12" />
                                           </svg>'
                          )
                        )
                      ),

                      # --- RIGHT SIDE: Navigation, Zoom, Invert ---
                      div(
                        style = "display:flex; align-items: center; gap: 8px;",

                        # 1. NARROW MODE: "..." Menu (Replaces d-md-none with custom class)
                        div(
                          class = "dropdown header-narrow-only",
                          tags$a(
                            href = "javascript:void(0);",
                            class = "text-muted",
                            `data-bs-toggle` = "dropdown",
                            HTML(
                              '<svg
                                                    xmlns="http://www.w3.org/2000/svg"
                                                    class="icon icon-1"
                                                    width="24"
                                                    height="24"
                                                    viewBox="0 0 24 24"
                                                    stroke-width="2"
                                                    stroke="currentColor"
                                                    fill="none"
                                                    stroke-linecap="round"
                                                    stroke-linejoin="round">
                                                      <circle cx="12" cy="12" r="1" />
                                                      <circle cx="19" cy="12" r="1" />
                                                      <circle cx="5" cy="12" r="1" />
                                                  </svg>'
                            )
                          ),
                          div(
                            class = "dropdown-menu dropdown-menu-end",
                            tags$a(
                              class = "dropdown-item",
                              href = "javascript:void(0);",
                              onclick = "pdfPreviousPage(); return false;",
                              HTML(
                                '<i class="fa-solid fa-chevron-left me-2"></i> Previous Page'
                              )
                            ),
                            tags$a(
                              class = "dropdown-item",
                              href = "javascript:void(0);",
                              onclick = "pdfNextPage(); return false;",
                              HTML(
                                '<i class="fa-solid fa-chevron-right me-2"></i> Next Page'
                              )
                            ),
                            div(class = "dropdown-divider"),
                            # Input inside dropdown needs stopPropagation
                            div(
                              class = "px-3 py-2",
                              onclick = "event.stopPropagation();",
                              div(
                                class = "d-flex align-items-center gap-2",
                                tags$label(
                                  "Page:",
                                  class = "form-label mb-0 small"
                                ),
                                tags$input(
                                  type = "number",
                                  class = "form-control form-control-sm",
                                  style = "width: 60px;",
                                  min = "1",
                                  placeholder = "#",
                                  onkeypress = "if(event.key === 'Enter') { pdfGoToPage(this.value); }"
                                )
                              )
                            ),
                            div(class = "dropdown-divider"),
                            tags$a(
                              class = "dropdown-item",
                              href = "javascript:void(0);",
                              onclick = "pdfZoomOut(); return false;",
                              HTML(
                                '<i class="fa-solid fa-magnifying-glass-minus me-2"></i> Zoom Out'
                              )
                            ),
                            tags$a(
                              class = "dropdown-item",
                              href = "javascript:void(0);",
                              onclick = "pdfZoomIn(); return false;",
                              HTML(
                                '<i class="fa-solid fa-magnifying-glass-plus me-2"></i> Zoom In'
                              )
                            )
                          )
                        ),

                        # 2. WIDE MODE: Standard Controls (Replaces d-none d-md-flex)
                        div(
                          class = "header-wide-only gap-2",
                          div(
                            id = "pdfPrevPage",
                            title = "Previous page",
                            `data-bs-toggle` = "tooltip",
                            `data-bs-placement` = "bottom",
                            class = "rail-btn btn-icon",
                            style = "width: 24px; height: 24px; cursor: pointer; display: flex; align-items: center; justify-content: center;",
                            onclick = "pdfPreviousPage()",
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
                                                     <path d="M13 15l-3 -3l3 -3" />
                                                      <path d="M3 3m0 2a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v14a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2z" />
                                                  </svg>'
                            )
                          ),
                          div(
                            id = "pdfNextPage",
                            title = "Next page",
                            `data-bs-toggle` = "tooltip",
                            `data-bs-placement` = "bottom",
                            class = "rail-btn btn-icon",
                            style = "width: 24px; height: 24px; cursor: pointer; display: flex; align-items: center; justify-content: center;",
                            onclick = "pdfNextPage()",
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
                                                     <path d="M11 9l3 3l-3 3" />
                                                     <path d="M3 3m0 2a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v14a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2z" />
                                                  </svg>'
                            )
                          ),
                          div(
                            style = "display:flex; align-items:center; gap:6px;",
                            tags$input(
                              type = "number",
                              id = "pdfPageInput",
                              class = "form-control form-control-sm",
                              style = "width: 40px; height: 24px; padding: 2px 4px; text-align: center; line-height: 1; -moz-appearance: textfield;",
                              min = "1",
                              value = "1",
                              onkeypress = "if(event.key === 'Enter') pdfGoToPage(this.value)"
                            ),
                            div(
                              style = "display:flex; align-items:center; gap:2px; white-space: nowrap;",
                              span("/"),
                              span(id = "pdfTotalPages", "0")
                            )
                          ),
                          div(
                            id = "pdfZoomOut",
                            title = "Zoom out",
                            `data-bs-toggle` = "tooltip",
                            `data-bs-placement` = "bottom",
                            class = "rail-btn btn-icon",
                            style = "width: 24px; height: 24px; cursor: pointer; display: flex; align-items: center; justify-content: center;",
                            onclick = "pdfZoomOut()",
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
                                                    <path d="M5 12l14 0" />
                                               </svg>'
                            )
                          ),
                          div(
                            id = "pdfZoomIn",
                            title = "Zoom in",
                            `data-bs-toggle` = "tooltip",
                            `data-bs-placement` = "bottom",
                            class = "rail-btn btn-icon",
                            style = "width: 24px; height: 24px; cursor: pointer; display: flex; align-items: center; justify-content: center;",
                            onclick = "pdfZoomIn()",
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
                                                     <path d="M12 5l0 14" />
                                                     <path d="M5 12l14 0" />
                                               </svg>'
                            )
                          )
                        ),

                        # 3. Always Visible Controls (Invert & Dropdown)
                        div(
                          id = "btnInvertPDF",
                          title = "Toggle PDF theme",
                          `data-bs-toggle` = "tooltip",
                          `data-bs-placement` = "bottom",
                          class = "rail-btn btn-icon",
                          style = "width: 24px; height: 24px; cursor: pointer; display: flex; align-items: center; justify-content: center;",
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
                                                 <path d="M18.421 11.56a6.702 6.702 0 0 0 -.357 -.683l-4.89 -7.26c-.42 -.625 -1.287 -.803 -1.936 -.397a1.376 1.376 0 0 0 -.41 .397l-4.893 7.26c-1.695 2.838 -1.035 6.441 1.567 8.546a7.144 7.144 0 0 0 4.518 1.58" />
                                                 <path d="M19.001 19m-2 0a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" />
                                                 <path d="M19.001 15.5v1.5" />
                                                 <path d="M19.001 21v1.5" />
                                                 <path d="M22.032 17.25l-1.299 .75" />
                                                 <path d="M17.27 20l-1.3 .75" />
                                                 <path d="M15.97 17.25l1.3 .75" />
                                                 <path d="M20.733 20l1.3 .75" />
                                           </svg>'
                          )
                        ),
                        div(
                          class = "dropdown",
                          div(
                            class = "dropdown-toggle",
                            id = "pdfZoomDropdown",
                            `data-bs-toggle` = "dropdown",
                            `aria-expanded` = "false",
                            style = "min-width: 40px; cursor:pointer; font-size: 0.9rem;",
                            span(id = "pdfZoomPercent", "100%")
                          ),
                          div(
                            class = "dropdown-menu dropdown-menu-end",
                            tags$a(
                              class = "dropdown-item",
                              href = "javascript:void(0);",
                              onclick = "pdfZoomIn(); return false;",
                              HTML("Zoom in <kbd>⌘+</kbd>")
                            ),
                            tags$a(
                              class = "dropdown-item",
                              href = "javascript:void(0);",
                              onclick = "pdfZoomOut(); return false;",
                              HTML("Zoom out <kbd>⌘-</kbd>")
                            ),
                            tags$a(
                              class = "dropdown-item",
                              href = "javascript:void(0);",
                              onclick = "pdfFitToWidth(); return false;",
                              HTML("Fit to width <kbd>⌘0</kbd>")
                            ),
                            tags$a(
                              class = "dropdown-item",
                              href = "javascript:void(0);",
                              onclick = "pdfFitToHeight(); return false;",
                              HTML("Fit to height <kbd>⌘9</kbd>")
                            ),
                            div(class = "dropdown-divider"),
                            div(h6(class = "dropdown-header", "Zoom to")),
                            tags$a(
                              class = "dropdown-item",
                              href = "javascript:void(0);",
                              onclick = "pdfSetZoom(0.5); return false;",
                              "50%"
                            ),
                            tags$a(
                              class = "dropdown-item",
                              href = "javascript:void(0);",
                              onclick = "pdfSetZoom(0.75); return false;",
                              "75%"
                            ),
                            tags$a(
                              class = "dropdown-item",
                              href = "javascript:void(0);",
                              onclick = "pdfSetZoom(1.0); return false;",
                              "100%"
                            ),
                            tags$a(
                              class = "dropdown-item",
                              href = "javascript:void(0);",
                              onclick = "pdfSetZoom(1.5); return false;",
                              "150%"
                            ),
                            tags$a(
                              class = "dropdown-item",
                              href = "javascript:void(0);",
                              onclick = "pdfSetZoom(2.0); return false;",
                              "200%"
                            ),
                            tags$a(
                              class = "dropdown-item",
                              href = "javascript:void(0);",
                              onclick = "pdfSetZoom(4.0); return false;",
                              "400%"
                            )
                          )
                        )
                      )
                    ),
                    div(
                      id = "pdfContainer",
                      div(id = "pdfViewUI", class = "shiny-html-output")
                    ),
                    div(
                      id = "dockerConsoleContainer",
                      div(
                        class = "console-tabs",
                        style = "overflow: hidden; text-overflow: ellipsis; white-space: nowrap;",
                        div(
                          class = "console-tab active",
                          `data-tab` = "errors",
                          onclick = "switchConsoleTab('errors')",
                          HTML(
                            '<svg
                                               xmlns="http://www.w3.org/2000/svg"
                                               width="16"
                                               height="16"
                                               viewBox="0 0 24 24"
                                               fill="none"
                                               stroke="currentColor"
                                               stroke-width="2"
                                               stroke-linecap="round"
                                               stroke-linejoin="round">
                                                 <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                                                 <line x1="12" y1="9" x2="12" y2="13"></line>
                                                 <line x1="12" y1="17" x2="12.01" y2="17"></line>
                                           </svg>'
                          ),
                          tags$strong("Error log")
                        ),
                        div(
                          class = "console-tab",
                          style = "overflow: hidden; text-overflow: ellipsis; white-space: nowrap;",
                          `data-tab` = "console",
                          onclick = "switchConsoleTab('console')",
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
                                              <path d="M4 6h16" />
                                              <path d="M6 12h12" />
                                              <path d="M9 18h2" />
                                              <path d="M17 17l-2 2l2 2" />
                                              <path d="M20 21l2 -2l-2 -2" />
                                            </svg>
                                            '
                          ),
                          tags$strong("Console log")
                        ),
                        div(
                          style = "margin-left: auto; display: flex; gap: 10px; align-items: center; padding-right: 10px;",
                          HTML(
                            '
                                        <div
                                          class="action-button"
                                          id="btnToggleConsole"
                                          title="Collapse"
                                          data-bs-toggle="tooltip"
                                          data-bs-placement="top"
                                        >
                                          <svg
                                            xmlns="http://www.w3.org/2000/svg"
                                            class="icon me-2"
                                            width="24"
                                            height="24"
                                            viewBox="0 0 24 24"
                                            stroke-width="2"
                                            stroke="currentColor"
                                            fill="none"
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                          >
                                            <path d="M7 3m0 2.667a2.667 2.667 0 0 1 2.667 -2.667h8.666a2.667 2.667 0 0 1 2.667 2.667v8.666a2.667 2.667 0 0 1 -2.667 2.667h-8.666a2.667 2.667 0 0 1 -2.667 -2.667z" />
                                            <path d="M4.012 7.26a2.005 2.005 0 0 0 -1.012 1.737v10c0 1.1 .9 2 2 2h10c.75 0 1.158 -.385 1.5 -1" />
                                            <path d="M11 10h6" />
                                          </svg>
                                        </div>
                                        '
                          )
                        )
                      ),
                      div(
                        class = "console-content",

                        # Error Log Console
                        div(
                          id = "errorLogConsole",
                          class = "active",
                          div(
                            class = "error-log-tabs",
                            div(
                              class = "error-log-tab tab-all active",
                              `data-filter` = "all",
                              HTML(
                                '<svg
                                                       xmlns="http://www.w3.org/2000/svg"
                                                       class="icon icon-1"
                                                       width="16"
                                                       height="16"
                                                       viewBox="0 0 24 24"
                                                       fill="none"
                                                       stroke="currentColor"
                                                       stroke-width="2"
                                                       stroke-linecap="round"
                                                       stroke-linejoin="round">
                                                         <path d="M9 5H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2"/>
                                                         <rect x="9" y="3" width="6" height="4" rx="2"/>
                                                         <path d="M9 14l2 2 4-4"/>
                                                   </svg>'
                              ),
                              "All",
                              tags$span(class = "count", id = "allCount", "0")
                            ),
                            div(
                              class = "error-log-tab tab-errors",
                              `data-filter` = "error",
                              HTML(
                                '<svg
                                                       xmlns="http://www.w3.org/2000/svg"
                                                       class="icon icon-1"
                                                       width="16"
                                                       height="16"
                                                       viewBox="0 0 24 24"
                                                       fill="none"
                                                       stroke="currentColor"
                                                       stroke-width="2"
                                                       stroke-linecap="round"
                                                       stroke-linejoin="round">
                                                         <circle cx="12" cy="12" r="10"></circle>
                                                         <line x1="12" y1="8" x2="12" y2="12"></line>
                                                         <line x1="12" y1="16" x2="12.01" y2="16"></line>
                                                   </svg>'
                              ),
                              "Errors",
                              tags$span(class = "count", id = "errorCount", "0")
                            ),
                            div(
                              class = "error-log-tab tab-warnings",
                              `data-filter` = "warning",
                              HTML(
                                '<svg
                                                       xmlns="http://www.w3.org/2000/svg"
                                                       class="icon icon-1"
                                                       width="16"
                                                       height="16"
                                                       viewBox="0 0 24 24"
                                                       fill="none"
                                                       stroke="currentColor"
                                                       stroke-width="2"
                                                       stroke-linecap="round"
                                                       stroke-linejoin="round">
                                                         <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                                                         <line x1="12" y1="9" x2="12" y2="13"></line>
                                                         <line x1="12" y1="17" x2="12.01" y2="17"></line>
                                                   </svg>'
                              ),
                              "Warnings",
                              tags$span(
                                class = "count",
                                id = "warningCount",
                                "0"
                              )
                            ),
                            div(
                              class = "error-log-tab tab-info",
                              `data-filter` = "info",
                              HTML(
                                '<svg
                                                       xmlns="http://www.w3.org/2000/svg"
                                                       class="icon icon-1"
                                                       width="16"
                                                       height="16"
                                                       viewBox="0 0 24 24"
                                                       fill="none"
                                                       stroke="currentColor"
                                                       stroke-width="2"
                                                       stroke-linecap="round"
                                                       stroke-linejoin="round">
                                                         <circle cx="12" cy="12" r="10"></circle>
                                                         <line x1="12" y1="16" x2="12" y2="12"></line>
                                                         <line x1="12" y1="8" x2="12.01" y2="8"></line>
                                                   </svg>'
                              ),
                              "Info",
                              tags$span(class = "count", id = "infoCount", "0")
                            )
                          ),
                          div(
                            class = "error-log-body",
                            id = "errorLogBody",
                            div(
                              class = "error-log-empty",
                              div(
                                class = "empty",
                                ui_success_illustration(),
                                HTML(
                                  '
                                                       <p class="empty-title">NO PROBLEMS FOUND</p>
                                                       <p class="empty-subtitle text-secondary">No problems detected.</p>
                                              '
                                )
                              )
                            )
                          ),
                          HTML(
                            '
                                            <div class="mb-0">
                                                <a id="bulkDownloadCompiled" href="javascript:void(0);" class="btn btn-sm btn-primary w-100 shiny-download-link" target="_blank">
                                                  <svg
                                                    xmlns="http://www.w3.org/2000/svg"
                                                    class="icon icon-1"
                                                    width="16"
                                                    height="16"
                                                    viewBox="0 0 24 24"
                                                    fill="none"
                                                    stroke="currentColor"
                                                    stroke-width="2"
                                                    stroke-linecap="round"
                                                    stroke-linejoin="round"
                                                    class="icon me-2">
                                                      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                                                      <polyline points="7 10 12 15 17 10" />
                                                      <line x1="12" y1="15" x2="12" y2="3" />
                                                  </svg>
                                                  Download compiled files
                                                </a>
                                              </div>
                                          '
                          )
                        ),
                        aceEditor(
                          "dockerConsole",
                          value = "",
                          mode = "text",
                          readOnly = TRUE,
                          height = "100%",
                          fontSize = 12,
                          wordWrap = TRUE,
                          showPrintMargin = FALSE
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  ),

  # =================== CLIENT JS ENHANCEMENTS ===================
  tags$script(HTML(
    "

  document.addEventListener('input', function (event) {
        if (event.target.tagName.toLowerCase() !== 'textarea') return;
        event.target.style.height = 'auto';
        event.target.style.height = event.target.scrollHeight + 'px';
      }, false);

//====File loading====//

  Shiny.addCustomMessageHandler('cmdSafeLoadFile', function(data) {
    var editor = ace.edit('sourceEditor');
    if (!editor) return;

    // 1. Update Content and Mode
    // The -1 parameter ensures the cursor moves to start and doesn't select all
    editor.setValue(data.content, -1);
    editor.getSession().setMode('ace/mode/' + data.mode);

    // 2. NUCLEAR FIX: Wipe the Undo History
    // We create a fresh UndoManager. This clears the stack instantly.
    // Since we do this AFTER setValue, the 'file load' itself is gone from history.
    editor.getSession().setUndoManager(new ace.UndoManager());

    // 3. Force Shiny to see the new content immediately
    Shiny.setInputValue('sourceEditor', data.content, {priority: 'event'});
  });



  /* =================== CLIPBOARD FUNCTIONS =================== */

            // 1. Copy for Equation Input
            window.copyInputLatex = function() {
              var el = document.getElementById('inputLatex');
              if (!el) return;

              // Get text
              var text = el.innerText || el.textContent;

              // SVGs
              var svgClipboard = '<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"icon icon-1\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M17.997 4.17a3 3 0 0 1 2.003 2.83v12a3 3 0 0 1 -3 3h-10a3 3 0 0 1 -3 -3v-12a3 3 0 0 1 2.003 -2.83a4 4 0 0 0 3.997 3.83h4a4 4 0 0 0 3.98 -3.597zm-3.997 -2.17a2 2 0 1 1 0 4h-4a2 2 0 1 1 0 -4z\" /></svg>';
              var svgCheck = '<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"icon icon-1\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M5 12l5 5l10 -10\" /></svg>';

              navigator.clipboard.writeText(text).then(function() {
                var btn = document.getElementById('copyLatexBtn');
                if(!btn) return;

                // Visual Feedback
                btn.innerHTML = svgCheck;
                btn.style.color = 'var(--tblr-success)';

                // Revert
                setTimeout(function(){
                  btn.innerHTML = svgClipboard;
                  btn.style.color = '';
                }, 1500);
              }).catch(function(err) {
                console.error('Failed to copy: ', err);
              });
            };

            // 2. Copy for Ace Editors (Source & Console)
            window.copyAceContent = function(editorId, btnId) {
              var editor = ace.edit(editorId);
              if (!editor) return;

              // Get content from Ace
              var text = editor.getValue();

              // SVGs (Slightly smaller width/height for these buttons if desired, or keep same)
              var svgClipboard = '<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"icon icon-1\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M9 5h-2a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-12a2 2 0 0 0 -2 -2h-2\" /><path d=\"M9 3m0 2a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2v0a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2z\" /></svg>';
              var svgCheck = '<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"icon icon-1\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M5 12l5 5l10 -10\" /></svg>';

              navigator.clipboard.writeText(text).then(function() {
                var btn = document.getElementById(btnId);
                if(!btn) return;

                // Visual Feedback
                btn.innerHTML = svgCheck;
                btn.style.color = 'var(--tblr-success)';
                btn.style.borderColor = 'var(--tblr-success)';

                // Revert
                setTimeout(function(){
                  btn.innerHTML = svgClipboard;
                  btn.style.color = 'var(--tblr-secondary)';
                  btn.style.borderColor = 'var(--tblr-border-color)';
                }, 1500);
              }).catch(function(err) {
                console.error('Failed to copy: ', err);
              });
            };


    // Connectivity banners & save tip
    // Connectivity alerts & monitoring
    (function(){
      var connectivityTimer;
      var baseCountdown = 10;
      var currentCountdown = baseCountdown;
      var currentWarningToast = null;

      function updateWarningContent() {
        if (!currentWarningToast) return;
        var body = currentWarningToast.querySelector('.toast-body');
        if (body) {
          body.innerHTML = 'Your internet connectivity is slow or down. Retrying sync in <b>' + currentCountdown + '</b> seconds... Changes you make offline are saved and will be synced when you get online.';
        }
      }

      function startConnectivityTimer() {
        if (connectivityTimer) return;

        // Show initial Tabler alert
        if (window.showTablerAlert) {
          // We manually manage this one to handle updates
          window.showTablerAlert('warning', 'Connectivity Issue', 'Your internet connectivity is slow or down. Retrying sync in <b>' + baseCountdown + '</b> seconds... Changes you make offline are saved and will be synced when you get online.', 999999);

          // Find the toast we just created (it should be the last one in alertContainer)
          var container = document.getElementById('alertContainer');
          if (container) {
            currentWarningToast = container.lastElementChild;
            if (currentWarningToast) {
              currentWarningToast.id = 'connectivityWarningToast';
              // Remove the close button to make it truly modal/persistent if desired,
              // or just let them close it but it will come back if we are still offline.
            }
          }
        }

        currentCountdown = baseCountdown;
        connectivityTimer = setInterval(function() {
          currentCountdown--;
          if (currentCountdown <= 0) {
            baseCountdown += 5;
            currentCountdown = baseCountdown;
          }
          updateWarningContent();
        }, 1000);
      }

      function stopConnectivityTimer() {
        if (connectivityTimer) {
          clearInterval(connectivityTimer);
          connectivityTimer = null;
        }
        baseCountdown = 10;
        currentCountdown = baseCountdown;

        // Remove the warning toast if it exists
        if (currentWarningToast && currentWarningToast.parentNode) {
          // If the showTablerAlert has a standardized way to remove, use it,
          // otherwise manual removal.
          if (currentWarningToast.querySelector('.btn-close')) {
            currentWarningToast.querySelector('.btn-close').click();
          } else {
            currentWarningToast.parentNode.removeChild(currentWarningToast);
          }
        }
        currentWarningToast = null;
      }

      window.addEventListener('offline', startConnectivityTimer);
      window.addEventListener('online', function() {
        stopConnectivityTimer();
        if (window.showTablerAlert) {
          window.showTablerAlert('success', 'Back Online', 'You are back online!', 3000);
        }
      });

      if (!navigator.onLine) { startConnectivityTimer(); }
    })();

    // Folder collapse + drag and drop
    (function(){
      document.addEventListener('click', function(e){
        var t = e.target.closest('.folder-name');
        if (!t) return;
        var li = t.closest('li');
        if (!li) return;
        var child = li.querySelector('ul.child-tree');
        if (child){ child.style.display = (child.style.display === 'none' || child.style.display === '') ? 'block' : 'none'; }
        var caret = t.querySelector('.toggle-icon');
        if (caret){ caret.classList.toggle('fa-caret-right'); caret.classList.toggle('fa-caret-down'); }
        e.stopPropagation();
      });
      document.addEventListener('dragstart', function(event){
        var target = event.target.closest('.file-item');
        if (target){ event.dataTransfer.setData('text/plain', target.getAttribute('data-path')); }
      });
      document.addEventListener('dragover', function(event){
        var target = event.target.closest('.folder-item');
        if (target){ event.preventDefault(); }
      });
      document.addEventListener('drop', function(event){
        var target = event.target.closest('.folder-item');
        if (!target) return;
        event.preventDefault();
        var filePath = event.dataTransfer.getData('text/plain');
        var folderPath = target.getAttribute('data-path');
        if (window.Shiny && Shiny.setInputValue){
          Shiny.setInputValue('dragDropMove', {file:filePath, folder:folderPath, nonce:Math.random()});
        }
      });
    })();

/* ---- Split.js offline shim: used only when Split isn't present ---- */
(function(){
  if (window.Split) return;  // real library loaded -> do nothing

  console.warn('[mudskipper] Split.js not found; using offline shim (no gutters).');

  window.Split = function(elements, opts){
    // normalize to array of selectors
    if (!Array.isArray(elements)) elements = [elements];

    var isVertical = (opts && opts.direction === 'vertical');
    var sizes = (opts && Array.isArray(opts.sizes)) ? opts.sizes.slice() : elements.map(function(){ return 100/elements.length; });

    function setDim(el, i, v){
      if (!el) return;
      // Ensure flex container behavior still works without gutters
      el.style.minWidth = '0';
      el.style.minHeight = '0';
      if (isVertical){
        el.style.height = v + '%';
        el.style.flex = '0 0 ' + v + '%';
      } else {
        el.style.width = v + '%';
        el.style.flex = '0 0 ' + v + '%';
      }
    }

    elements.forEach(function(sel, i){
      var el = (typeof sel === 'string') ? document.querySelector(sel) : sel;
      setDim(el, i, sizes[i]);
    });

    return {
      setSizes: function(newSizes){
        sizes = newSizes.slice();
        elements.forEach(function(sel, i){
          var el = (typeof sel === 'string') ? document.querySelector(sel) : sel;
          setDim(el, i, sizes[i]);
        });
        if (opts && typeof opts.onDragEnd === 'function') { try { opts.onDragEnd(sizes); } catch(e){} }
      },
      getSizes: function(){ return sizes.slice(); }
    };
  };
})();

/* ============== Split.js Final Robust Initialization (v4) & Rail Handler Unified ============== */
var mainSplit, sidebarVSplit, previewVSplit;
window.currentSidebarTab = 'files'; // Shared state

(function(){
  // Configuration
  var MAIN_SIZES_KEY = 'mudskipper.mainSplitSizes';
  var defaultSizes = [20, 47.5, 32.5];
  var minSizes = [0, 0, 0];

  // --- SEARCH LOCK MECHANISM ---
  var searchLock = false;
  document.addEventListener('mousedown', function(e) {
      if (e.target.closest('#fileSearchResults') || e.target.closest('#fileSearchContainer')) {
          searchLock = true;
          setTimeout(function(){ searchLock = false; }, 1500);
      }
  }, true);

  // Helpers
  function readJSON(key, fallback){
    try { var v = JSON.parse(localStorage.getItem(key)); return v || fallback; }
    catch(e){ return fallback; }
  }
  function writeJSON(key, value){
    try { localStorage.setItem(key, JSON.stringify(value)); } catch(e){}
  }

  // --- 1. Custom Gutter Creator ---
  function createGutter(index, direction) {
    var gutter = document.createElement('div');
    gutter.className = 'gutter gutter-horizontal';

    var btn = document.createElement('div');
    btn.className = 'gutter-collapse-btn';

    var icon = document.createElement('i');
    icon.className = 'fa-solid';

    if (index === 1) { // Sidebar Toggle
        btn.id = 'btn-toggle-sidebar';
        btn.setAttribute('data-action', 'toggle-sidebar');
        btn.setAttribute('data-bs-toggle', 'tooltip');
        btn.setAttribute('data-bs-placement', 'bottom');
        icon.classList.add('fa-chevron-left');
        btn.title = 'Toggle Sidebar';
    } else { // PDF Toggle
        btn.id = 'btn-toggle-pdf';
        btn.setAttribute('data-action', 'toggle-pdf');
        btn.setAttribute('data-bs-toggle', 'tooltip');
        btn.setAttribute('data-bs-placement', 'bottom');
        icon.classList.add('fa-chevron-right');
        btn.title = 'Toggle PDF';
    }

    btn.appendChild(icon);
    gutter.appendChild(btn);
    return gutter;
  }

  // --- 2. Initialize Main Split ---
  function initMainSplit() {
    var savedSizes = readJSON(MAIN_SIZES_KEY, defaultSizes);

    mainSplit = Split(['#fileSidebar', '#editorArea', '#pdfPreview'], {
      sizes: savedSizes,
      minSize: minSizes,
      snapOffset: 15,
      gutterSize: 8,
      cursor: 'col-resize',
      gutter: createGutter,
      onDragEnd: function (sizes) {
        writeJSON(MAIN_SIZES_KEY, sizes);
        updateUIState(sizes);
        resizeEditors();
      }
    });

    updateUIState(savedSizes);
  }

  // --- 3. Unified Rail & Pane Handler ---
  window.handleRailClick = function(mode) {

    // Search Lock Check
    if (window.currentSidebarTab === 'search' && mode === 'files' && searchLock) {
        return;
    }

    window.currentSidebarTab = mode;

    const map = {
        'files':  { btn: 'railSidebarToggle',   pane: 'filesPane' },
        'search': { btn: 'btnToggleFileSearch', pane: 'filesPane' },
        'review': { btn: 'railReviewBtn',       pane: 'reviewPane' },
        'chat':   { btn: 'railChatBtn',         pane: 'chatPane' },
        'ai':     { btn: 'railAiBtn',           pane: 'aiPane' }
    };
    const target = map[mode];
    if (!target) return;

    var sizes = (mainSplit) ? mainSplit.getSizes() : [0,0,0];
    var sidebarWidth = sizes[0];

    var btnEl = document.getElementById(target.btn);
    var isAlreadyActive = btnEl && btnEl.classList.contains('active');

    // Close if clicking active button (ONLY if not locked by search)
    if (isAlreadyActive && sidebarWidth > 2 && !searchLock) {
        window.closeSidebar();
        return;
    }

    updateSidebarContent(mode);

    // Ensure Sidebar Open (Drift-Free)
    if (sidebarWidth < 2 && mainSplit) {
        const pdfWidth = sizes[2];
        const newEditorWidth = 100 - 20 - pdfWidth;

        if (newEditorWidth < 0) {
             mainSplit.setSizes([20, 0, 80]);
        } else {
             mainSplit.setSizes([20, newEditorWidth, pdfWidth]);
        }
    }

    afterLayoutChange();
  };

  function updateSidebarContent(mode) {
    // 1. Hide all sidebar panes
    ['filesPane', 'outlinePane', 'reviewPane', 'chatPane', 'aiPane'].forEach(id => {
        const el = document.getElementById(id);
        if(el) el.style.display = 'none';
    });

    // 2. Hide Sidebar Gutters (Files ↕ Outline) ONLY
    // FIX: Scope this selector to #fileSidebar so we don't hide the PDF gutter
    var sidebarGutters = document.querySelectorAll('#fileSidebar .gutter-vertical');
    sidebarGutters.forEach(g => g.style.display = 'none');

    const tree = document.getElementById('fileTreeContainer');
    const search = document.getElementById('fileSearchContainer');

    if (mode === 'review') {
        const el = document.getElementById('reviewPane');
        if(el) el.style.display = 'flex';
        if(window.Shiny) Shiny.setInputValue('activeSidebarTab', 'review', {priority:'event'});
    }
    else if (mode === 'chat') {
        const el = document.getElementById('chatPane');
        if(el) el.style.display = 'flex';
        if(window.Shiny) Shiny.setInputValue('activeSidebarTab', 'chat', {priority:'event'});
    }
    else if (mode === 'ai') {
        const el = document.getElementById('aiPane');
        if(el) el.style.display = 'flex';
        if(window.Shiny) Shiny.setInputValue('activeSidebarTab', 'ai', {priority:'event'});
    }
    else {
        // Files or Search
        const fPane = document.getElementById('filesPane');
        const oPane = document.getElementById('outlinePane');

        if(fPane) fPane.style.display = 'flex';

        if (mode === 'search') {
            if(tree) tree.style.display = 'none';
            if(search) search.style.display = 'flex';
            if(oPane) oPane.style.display = 'none';

            setTimeout(() => {
               const input = document.getElementById('txtFileSearch');
               if(input) input.focus();
            }, 50);
        } else {
            // Files Mode
            if(tree) tree.style.display = 'block';
            if(search) search.style.display = 'none';
            if(oPane) oPane.style.display = 'flex';

            // Restore Sidebar Gutters
            sidebarGutters.forEach(g => g.style.display = 'flex');
        }
    }
  }

  window.closeSidebar = function() {
    if(mainSplit) mainSplit.collapse(0);
    afterLayoutChange();
  };

  // --- 4. Toggle Actions (DRIFT FIXED) ---
  window.toggleSidebar = function() {
    var sizes = mainSplit.getSizes();
    var sb = sizes[0];
    var pdf = sizes[2];

    if (sb < 1) {
        // EXPAND
        updateSidebarContent(window.currentSidebarTab);
        var targetSb = 20;
        var targetEd = 100 - targetSb - pdf;
        if (targetEd < 0) { targetEd = 0; pdf = 100 - targetSb; }
        mainSplit.setSizes([targetSb, targetEd, pdf]);
    } else {
        // COLLAPSE
        var targetEd = 100 - pdf;
        mainSplit.setSizes([0, targetEd, pdf]);
    }
    afterLayoutChange();
  };

  window.togglePDF = function() {
    var sizes = mainSplit.getSizes();
    var sb = sizes[0];
    var pdf = sizes[2];

    if (pdf < 1) {
        // EXPAND
        var targetPdf = 40;
        var targetEd = 100 - sb - targetPdf;
        if (targetEd < 0) { targetEd = 0; sb = 100 - targetPdf; }
        mainSplit.setSizes([sb, targetEd, targetPdf]);
    } else {
        // COLLAPSE
        var targetEd = 100 - sb;
        mainSplit.setSizes([sb, targetEd, 0]);
    }
    afterLayoutChange();
  };

  window.toggleMainLayout = function(mode) {
    switch(mode) {
      case 'split': mainSplit.setSizes([0, 50, 50]); break;
      case 'no-sidebar':
        var s=mainSplit.getSizes(); mainSplit.setSizes([0, 100 - s[2], s[2]]);
        break;
      case 'editor-only': mainSplit.setSizes([0, 100, 0]); break;
      case 'pdf-only': mainSplit.setSizes([0, 0, 100]); break;
      case 'reset':
        mainSplit.setSizes(defaultSizes);
        if(sidebarVSplit) sidebarVSplit.setSizes([50,50]);
        if(previewVSplit) previewVSplit.setSizes([0,100]);
        break;
    }
    afterLayoutChange();
  };

  function afterLayoutChange() {
    var s = mainSplit.getSizes();
    writeJSON(MAIN_SIZES_KEY, s);
    updateUIState(s);
    resizeEditors();
  }

  // --- 5. UI State Update ---
  function updateUIState(sizes) {
    var sidebarEl = document.getElementById('fileSidebar');
    var editorEl  = document.getElementById('editorArea');

    var btnLeftIcon = document.querySelector('#btn-toggle-sidebar i');
    var btnRightIcon = document.querySelector('#btn-toggle-pdf i');

    if (sizes[0] < 1) sidebarEl.classList.add('pane-collapsed');
    else sidebarEl.classList.remove('pane-collapsed');

    if (sizes[1] < 1) editorEl.classList.add('pane-collapsed');
    else editorEl.classList.remove('pane-collapsed');

    if (btnLeftIcon) btnLeftIcon.className = (sizes[0] < 1) ? 'fa-solid fa-chevron-right' : 'fa-solid fa-chevron-left';
    if (btnRightIcon) btnRightIcon.className = (sizes[2] < 1) ? 'fa-solid fa-chevron-left' : 'fa-solid fa-chevron-right';

    // Rail Buttons Active State
    document.querySelectorAll('.rail-btn').forEach(b => b.classList.remove('active'));
    if (sizes[0] > 1) {
        var activeBtnId = null;
        if (window.currentSidebarTab === 'files') activeBtnId = 'railSidebarToggle';
        else if (window.currentSidebarTab === 'search') activeBtnId = 'btnToggleFileSearch';
        else if (window.currentSidebarTab === 'review') activeBtnId = 'railReviewBtn';
        else if (window.currentSidebarTab === 'chat') activeBtnId = 'railChatBtn';
        else if (window.currentSidebarTab === 'ai') activeBtnId = 'railAiBtn';

        if (activeBtnId) {
            var btn = document.getElementById(activeBtnId);
            if (btn) btn.classList.add('active');
        }
    }
  }

  function resizeEditors() {
    setTimeout(function(){
      try {
        var ed = ace.edit('sourceEditor');
        ed.resize(true);
        ed.renderer.scrollCursorIntoView(ed.getCursorPosition(), 0.5);
      } catch(e){}
      try { ace.edit('dockerConsole').resize(true); } catch(e){}
    }, 50);
  }

  // --- 6. Global Event Listener ---
  document.addEventListener('click', function(e) {
      var target = e.target.closest('button, .gutter-collapse-btn, .rail-btn, a');
      if (!target) return;

      if (target.dataset.action === 'toggle-sidebar') {
          e.preventDefault(); e.stopPropagation();
          toggleSidebar();
          return;
      }
      if (target.dataset.action === 'toggle-pdf') {
          e.preventDefault(); e.stopPropagation();
          togglePDF();
          return;
      }
      if (target.id === 'closeSidebarBtn' || target.id === 'toggleChatPane') {
          e.preventDefault(); e.stopPropagation();
          var s = mainSplit.getSizes();
          if (s[0] > 0) toggleSidebar();
          return;
      }
  });

  if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', initMainSplit);
  } else {
      initMainSplit();
  }
})();

/* ============== Split.js: PDF (top) ↕ Console (bottom) with persistence ============== */
(function () {
  function onReady(fn){ if(document.readyState!=='loading') fn(); else document.addEventListener('DOMContentLoaded', fn); }
  function readJSON(key, fallback){ try{ var v = JSON.parse(localStorage.getItem(key)||'null'); return (v==null?fallback:v); }catch(e){ return fallback; } }
  function writeJSON(key, val){ try{ localStorage.setItem(key, JSON.stringify(val)); }catch(e){} }

  onReady(function(){
    if (window.previewVSplit && typeof window.previewVSplit.getSizes === 'function') return;

    if (typeof Split !== 'function') return;
    var top  = document.getElementById('pdfContainer');
    var bot  = document.getElementById('dockerConsoleContainer');
    if (!top || !bot) return;

    var PREVIEW_SIZES_KEY     = 'mudskipper.previewSplitSizes';
    var CONSOLE_COLLAPSED_KEY = 'mudskipper.consoleCollapsed';

    var defaultSizes = [100, 0];
    var headerPx = 38;

    var init = readJSON(PREVIEW_SIZES_KEY, defaultSizes);
    if (!Array.isArray(init) || init.length!==2) init = defaultSizes;

    window.previewVSplit = Split(['#pdfContainer', '#dockerConsoleContainer'], {
      direction: 'vertical',
      sizes: init,
      minSize: [0, headerPx],
      gutterSize: 4,
      cursor: 'row-resize',
      onDragEnd: function(sizes){
        var headerPct = getHeaderPct();
        // If bottom pane is larger than header, it's open
        if (sizes[1] > headerPct + 2) {
           writeJSON(PREVIEW_SIZES_KEY, sizes);
           localStorage.setItem(CONSOLE_COLLAPSED_KEY, '0');
        } else {
           localStorage.setItem(CONSOLE_COLLAPSED_KEY, '1');
        }

        // Check badge visibility after drag
        if(window.checkErrorBadgeVisibility) window.checkErrorBadgeVisibility();

        try{ ace.edit('dockerConsole').resize(true); }catch(e){}
        try{ ace.edit('sourceEditor').resize(true); }catch(e){}
      }
    });

    var btn = document.getElementById('btnToggleConsole');

    function getHeaderPct(){
      var host = document.getElementById('pdfPreview');
      var total = (host && host.getBoundingClientRect().height) || 1;
      return Math.max((headerPx / total) * 100, 2);
    }

    function isCollapsed(){
      try{
        var s = window.previewVSplit.getSizes();
        var hp = getHeaderPct();
        return s[1] <= hp + 1.5;
      }catch(e){ return false; }
    }

    function setCollapsedState(collapsed){
      if (!window.previewVSplit) return;
      var hp = getHeaderPct();

      if (collapsed){
        if (!isCollapsed()) {
           writeJSON(PREVIEW_SIZES_KEY, window.previewVSplit.getSizes());
        }
        window.previewVSplit.setSizes([100 - hp, hp]);
        bot.classList.add('collapsed');
        localStorage.setItem(CONSOLE_COLLAPSED_KEY, '1');
      } else {
        var last = readJSON(PREVIEW_SIZES_KEY, defaultSizes);
        if (!Array.isArray(last) || last.length!==2 || last[1] <= hp + 2) {
            last = [60, 40];
        }
        window.previewVSplit.setSizes(last);
        bot.classList.remove('collapsed');
        localStorage.setItem(CONSOLE_COLLAPSED_KEY, '0');
      }

      // Check badge visibility after state change
      if(window.checkErrorBadgeVisibility) window.checkErrorBadgeVisibility();

      setTimeout(function(){
        try{ ace.edit('dockerConsole').resize(true); }catch(e){}
        try{ ace.edit('sourceEditor').resize(true); }catch(e){}
      }, 60);
    }

    window.consolePane = {
      expand: function() { setCollapsedState(false); },
      collapse: function() { setCollapsedState(true); },
      toggle: function() { setCollapsedState(!isCollapsed()); },
      isCollapsed: isCollapsed
    };

    if (localStorage.getItem(CONSOLE_COLLAPSED_KEY) === '1') {
        setTimeout(function(){ setCollapsedState(true); }, 50);
    } else {
        // Initial check on load
        setTimeout(function(){
            if(window.checkErrorBadgeVisibility) window.checkErrorBadgeVisibility();
        }, 100);
    }

    if (btn){
      var newBtn = btn.cloneNode(true);
      btn.parentNode.replaceChild(newBtn, btn);
      newBtn.addEventListener('click', function(){
          setCollapsedState(!isCollapsed());
      });
    }

    window.addEventListener('beforeunload', function(){
      if (!isCollapsed()) {
        try{ writeJSON(PREVIEW_SIZES_KEY, window.previewVSplit.getSizes()); }catch(e){}
      }
    });
  });
})();

/* ============== Split.js: Files (top) ↕ Outline (bottom) with persistence ============== */
(function () {
  function onReady(fn){ if(document.readyState!=='loading') fn(); else document.addEventListener('DOMContentLoaded', fn); }
  function readJSON(key, fallback){ try{ var v = JSON.parse(localStorage.getItem(key)||'null'); return (v==null?fallback:v); }catch(e){ return fallback; } }
  function writeJSON(key, val){ try{ localStorage.setItem(key, JSON.stringify(val)); }catch(e){} }

  onReady(function(){
    // Don't double-init
    if (window.sidebarVSplit && typeof window.sidebarVSplit.getSizes === 'function') return;

    // Ensure Split and panes exist
    if (typeof Split !== 'function') return;
    var top  = document.getElementById('filesPane');
    var bot  = document.getElementById('outlinePane');
    if (!top || !bot) return;

    var OUTLINE_SIZES_KEY     = 'mudskipper.outlineLastSizes';
    var OUTLINE_COLLAPSED_KEY = 'mudskipper.outlineCollapsed';

    var defaultSizes = [50, 50]; // %
    var headerOnlySize = 5; // Size when showing only header (in percentage)

    var init = readJSON(OUTLINE_SIZES_KEY, defaultSizes);
    if (!Array.isArray(init) || init.length!==2 || init[1]===0) init = defaultSizes;

    window.sidebarVSplit = Split(['#filesPane', '#outlinePane'], {
      direction: 'vertical',
      sizes: init,
      minSize: [50, headerOnlySize],
      gutterSize: 4,
      onDragEnd: function(sizes){
        // Only save if outline is not at header-only size
        if (sizes[1] > headerOnlySize + 1) {
          writeJSON(OUTLINE_SIZES_KEY, sizes);
        }
        try{ ace.edit('sourceEditor').resize(true); }catch(e){}
      }
    });

    var btn = document.getElementById('btnToggleOutline');

    function getHeaderHeight() {
      var header = bot.querySelector('.pane-header');
      if (header) {
        var headerPx = header.offsetHeight;
        var totalPx = top.parentElement.offsetHeight;
        return Math.max((headerPx / totalPx) * 100, headerOnlySize);
      }
      return headerOnlySize;
    }

    function isCollapsed(){
      try{
        var s = window.sidebarVSplit.getSizes();
        var headerPct = getHeaderHeight();
        return s[1] <= headerPct + 1;
      }catch(e){ return false; }
    }

    function setCollapsedState(collapsed){
      if (!window.sidebarVSplit) return;
      var headerPct = getHeaderHeight();

      if (collapsed){
        // Save current size before collapsing (only if not already at header size)
        var currentSizes = window.sidebarVSplit.getSizes();
        if (currentSizes[1] > headerPct + 1) {
          writeJSON(OUTLINE_SIZES_KEY, currentSizes);
        }
        window.sidebarVSplit.setSizes([100 - headerPct, headerPct]);
        localStorage.setItem(OUTLINE_COLLAPSED_KEY, '1');
      } else {
        var last = readJSON(OUTLINE_SIZES_KEY, defaultSizes);
        if (!Array.isArray(last) || last.length!==2 || last[1] <= headerPct + 1) last = defaultSizes;
        window.sidebarVSplit.setSizes(last);
        localStorage.setItem(OUTLINE_COLLAPSED_KEY, '0');
      }
      setTimeout(function(){ try{ ace.edit('sourceEditor').resize(true); }catch(e){} }, 60);
    }

    // Apply initial collapsed state
    if (localStorage.getItem(OUTLINE_COLLAPSED_KEY) === '1') setCollapsedState(true);

    if (btn){
      btn.addEventListener('click', function(){ setCollapsedState(!isCollapsed()); });
    }

    window.addEventListener('beforeunload', function(){
      try{
        var sizes = window.sidebarVSplit.getSizes();
        var headerPct = getHeaderHeight();
        // Only save if not at header-only size
        if (sizes[1] > headerPct + 1) {
          writeJSON(OUTLINE_SIZES_KEY, sizes);
        }
      }catch(e){}
    });

    // Expose functions for synchronization
    window.syncOutlinePane = {
      collapse: function() { setCollapsedState(true); },
      expand: function() { setCollapsedState(false); },
      isCollapsed: isCollapsed
    };
  });
})();


//============ Active layout highlights========//

document.addEventListener('DOMContentLoaded', function() {

    // Function to update the active state in the UI
    window.updateLayoutActiveState = function(mode) {
      // 1. Remove 'active' from all items with class 'layout-selector'
      document.querySelectorAll('.layout-selector').forEach(function(el) {
        el.classList.remove('active');
      });

      // 2. Add 'active' to the item matching the current mode
      document.querySelectorAll('.layout-selector[data-layout=\"' + mode + '\"]').forEach(function(el) {
        el.classList.add('active');
      });
    };

    // 3. Wrap the existing toggleMainLayout function
    // We check if it exists first to avoid errors
    var originalToggle = window.toggleMainLayout;
    window.toggleMainLayout = function(mode) {
      if (typeof originalToggle === 'function') {
        originalToggle(mode);
      }
      updateLayoutActiveState(mode);
    };

    // 4. Initialize with default state (usually 'split')
    updateLayoutActiveState('split');
  });


//========== Equation preview, sticky scroll and minimap togglers in View navbar and synchronisation with settings overlay=====//

document.addEventListener('DOMContentLoaded', function() {

    // --- SYNC FUNCTION ---
    function initToggleSync() {
      // The IDs of the settings checkboxes we want to sync
      const toggleIds = ['enableMathPreviewPanel', 'enableStickyScrollPanel', 'enableMinimapPanel'];

      toggleIds.forEach(function(id) {
        const checkbox = document.getElementById(id);
        if (!checkbox) return;

        // 1. Define update logic: Checkbox State -> Menu Item Class
        const updateMenuState = () => {
          const menuItems = document.querySelectorAll('.toggle-sync[data-toggle-id=\"' + id + '\"]');
          menuItems.forEach(function(item) {
            if (checkbox.checked) {
              item.classList.add('active');
            } else {
              item.classList.remove('active');
            }
          });
        };

        // 2. Run immediately to set initial state
        updateMenuState();

        // 3. Listen for changes on the checkbox (e.g. changed via Settings Overlay)
        checkbox.addEventListener('change', updateMenuState);
      });
    }

    // --- CLICK HANDLER ---
    // When a menu item is clicked, toggle the corresponding hidden checkbox
    document.body.addEventListener('click', function(e) {
      const target = e.target.closest('.toggle-sync');
      if (target) {
        e.preventDefault(); // Prevent default link jump
        const id = target.getAttribute('data-toggle-id');
        const checkbox = document.getElementById(id);
        if (checkbox) {
          checkbox.click(); // Click the actual setting checkbox
        }
      }
    });

    // Initialize
    initToggleSync();
  });





// =================== ACE ANNOTATIONS & ERROR LOG BRIDGE ===================
Shiny.addCustomMessageHandler('setAnnotations', function(annotations){
  var safeAnnotations = annotations || [];

  // 1. Update Ace Editor Gutter (Visual Red/Yellow dots)
  try {
    var ed = ace.edit('sourceEditor');
    if (ed && ed.getSession()) {
      ed.getSession().setAnnotations(safeAnnotations);
    }
  } catch(e) { console.error('Error setting annotations:', e); }

  // 2. Update Error Log Console (Bottom Pane List)
  if (window.updateErrorLog) {
    window.updateErrorLog(safeAnnotations);
  }

  // 3. Update Navbar Badge (Red counter)
  // Calculate counts manually if updateErrorLog didn't handle it
  var err = 0, warn = 0, info = 0;
  safeAnnotations.forEach(function(a) {
    if(a.type === 'error') err++;
    else if(a.type === 'warning') warn++;
    else info++;
  });

  var badge = document.getElementById('errorLogBadge');
  if (badge) {
    var total = err + warn + info;
    if (total > 0) {
      badge.textContent = total;
      badge.classList.add('show');

      // Color logic: Red if errors, Orange if warnings, Blue if info
      badge.classList.remove('bg-red', 'bg-orange', 'bg-blue');
      if (err > 0) badge.classList.add('bg-red');
      else if (warn > 0) badge.classList.add('bg-orange');
      else badge.classList.add('bg-blue');
    } else {
      badge.classList.remove('show');
    }
  }
});



  // updateStatus handler is registered in www/status_bar.js to avoid conflicts.
    Shiny.addCustomMessageHandler('scrollDockerConsole', function(message){
      var editor = ace.edit('dockerConsole');
      if (editor) {
        var session = editor.getSession();
        editor.scrollToLine(session.getLength(), true, true, function() {});
      }
    });
    Shiny.addCustomMessageHandler('applyUISettings', function(data){
      if (typeof data.dockerConsoleVisible !== 'undefined') {
        document.getElementById('dockerConsoleContainer').style.display = data.dockerConsoleVisible ? 'block' : 'none';
      }
      if (typeof data.pdfPreviewVisible !== 'undefined') {
        var show = !!data.pdfPreviewVisible;
        document.getElementById('pdfContainer').style.display = show ? 'block' : 'none';
        var head = document.querySelector('#pdfPreview .pdf-header'); if (head) head.style.display = show ? 'flex':'none';
      }
      setTimeout(function(){ try{ ace.edit('sourceEditor').resize(true); }catch(e){} }, 50);
    });
    Shiny.addCustomMessageHandler('toggleCompileSpinner', function(show){
      document.getElementById('compileSpinner').style.display = show ? 'inline-block' : 'none';
    });
    Shiny.addCustomMessageHandler('saveSettingsToLocal', function(settings){
      try{ localStorage.setItem('latexerSettings', JSON.stringify(settings)); }catch(e){}
      
      // Sync History Editor if active
      if (settings.editorTheme && window.HistoryManager && HistoryManager.editor) {
        HistoryManager.editor.setTheme('ace/theme/' + settings.editorTheme);
      }
      if (settings.fontSize && window.HistoryManager && HistoryManager.editor) {
        HistoryManager.editor.setFontSize(+settings.fontSize);
      }
    });


Shiny.addCustomMessageHandler('aceGoTo', function(data){
  var editor = ace.edit('sourceEditor');
  if (!editor) return;

  // Validate input (default to 0 if missing)
  var line = (data && typeof data.line === 'number') ? data.line : 0;

  // 1. Force Resize (Fixes scroll issues if panel size changed)
  editor.resize(true);

  // 2. Move Cursor & Focus
  editor.focus();
  editor.moveCursorTo(line, 0);
  editor.clearSelection(); // Prevent selecting text from previous operations

  // 3. FORCE SCROLL TO CENTER (Most reliable method)
  editor.centerSelection();

});


      // Apply local settings on load (mirrors Ace immediately)
      (function(){
        try {
          var s = JSON.parse(localStorage.getItem('latexerSettings') || 'null');
          if (!s) return;

          var ed  = ace.edit('sourceEditor');
          ed.setOption('scrollPastEnd', true);
          var con = ace.edit('dockerConsole');



          if (s.editorTheme) {
            ed.setTheme('ace/theme/' + s.editorTheme);
            con.setTheme('ace/theme/' + s.editorTheme);
            if (window.HistoryManager && HistoryManager.editor) HistoryManager.editor.setTheme('ace/theme/' + s.editorTheme);
            // Also reflect Selectize (like your working theme selector)
            if (window.$ && $('#editorThemePanel')[0]?.selectize) {
              $('#editorThemePanel')[0].selectize.setValue(String(s.editorTheme), true);
            } else {
              var th = document.getElementById('editorThemePanel');
              if (th) { th.value = String(s.editorTheme); th.dispatchEvent(new Event('change', {bubbles:true})); }
            }
          }
          if (s.fontSize) {
            var fs = +s.fontSize;
            ed.setFontSize(fs);
            con.setFontSize(fs);
            if (window.HistoryManager && HistoryManager.editor) HistoryManager.editor.setFontSize(fs);

            // Reflect Selectize value EXACTLY like theme
            if (window.$ && $('#editorFontSizePanel')[0]?.selectize) {
              $('#editorFontSizePanel')[0].selectize.setValue(String(fs), true);
            } else {
              var fsSel = document.getElementById('editorFontSizePanel');
              if (fsSel) { fsSel.value = String(fs); fsSel.dispatchEvent(new Event('change', {bubbles:true})); }
            }
          }

          if (typeof s.wordWrap    !== 'undefined') { ed.session.setUseWrapMode(!!s.wordWrap); }
          if (typeof s.lineNumbers !== 'undefined') { ed.setOption('showLineNumbers', !!s.lineNumbers); }

          // Always hide print margin
          ed.setShowPrintMargin(false);
          con.setShowPrintMargin(false);
          setTimeout(function(){
            try { ed.setShowPrintMargin(false); con.setShowPrintMargin(false); } catch(e){}
          }, 0);

          if (typeof s.autocomplete !== 'undefined') {
            ed.setOptions({ enableLiveAutocompletion: !!s.autocomplete });
          }
          if (typeof s.tabSize !== 'undefined') {
            ed.session.setTabSize(+s.tabSize);
            var tsv=document.getElementById('tabSizeVal'); if(tsv) tsv.innerText=String(s.tabSize);
          }

          setTimeout(function(){ try{ ed.resize(true); }catch(e){} }, 50);
        } catch(e) {}
      })();


// =================== CUSTOM ACE TOOLTIP SYSTEM (STACKED & INDEPENDENT) ===================
(function() {
  var setupDone = false;
  var customTooltip = null;
  var hideTimer = null;

  function setupAceEnhancements() {
    if (setupDone) return;
    try {
      var editor = ace.edit('sourceEditor');
      if (!editor || !editor.renderer || !editor.renderer.$gutterLayer) return false;

      // Create our custom tooltip element once
      if (!customTooltip) {
        customTooltip = document.createElement('div');
        customTooltip.id = 'custom-ace-tooltip';
        document.body.appendChild(customTooltip);

        // Make tooltip sticky
        customTooltip.addEventListener('mouseenter', function() {
          clearTimeout(hideTimer);
        });
        customTooltip.addEventListener('mouseleave', function() {
          hideCustomTooltip();
        });
        customTooltip.addEventListener('click', function(e) {
          e.stopPropagation();
          clearTimeout(hideTimer);
        });
      }

      // Function to show custom tooltip with multiple annotations
      function showCustomTooltip(annotations, x, y) {
        clearTimeout(hideTimer);

        if (!annotations || annotations.length === 0) return;

        // 1. Sort Annotations: Column asc, then Type priority (Error < Warning < Info)
        var typePriority = { 'error': 1, 'warning': 2, 'info': 3 };

        annotations.sort(function(a, b) {
          // Sort by column (position) first
          if (a.column !== b.column) return a.column - b.column;
          // If same position, sort by severity
          var pA = typePriority[a.type] || 4;
          var pB = typePriority[b.type] || 4;
          return pA - pB;
        });

        // 2. Build Content: Independent Items
        var contentHtml = annotations.map(function(ann, index) {
            var safeText = (ann.text || \"\").replace(/</g, \"&lt;\").replace(/>/g, \"&gt;\");

            // Determine color for THIS specific item
            var color = '#4299e1'; // Info (default)
            if (ann.type === 'error') color = '#d63939';
            else if (ann.type === 'warning') color = '#f59f00';

            // Add border-bottom separator to all except the last item
            var borderStyle = (index < annotations.length - 1) ? 'border-bottom: 1px solid var(--tblr-border-color);' : '';

            // Render Item: Colored left border + Tight Padding
            return '<div style=\"border-left: 4px solid ' + color + '; padding: 4px 8px; ' + borderStyle + '\">' + safeText + '</div>';
        }).join('');

        // 3. Container Style
        // Removed border-left. Added padding:0 so items sit flush with the edges.
        customTooltip.style.cssText = `
          position: fixed;
          z-index: 99999;
          display: block;
          background: var(--tblr-body-bg) !important;
          border: 1px solid var(--tblr-border-color);
          border-radius: var(--tblr-border-radius);
          padding: 0;
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
          font-size: 12px;
          line-height: 1.4;
          max-width: 400px;
          pointer-events: auto;
          cursor: pointer;
          white-space: normal;
          word-wrap: break-word;
          color: var(--tblr-body-color) !important;
          opacity: 1;
          box-shadow: 0 4px 12px rgba(0,0,0,0.15);
          overflow: hidden;
        `;

        customTooltip.innerHTML = contentHtml;

        // Position tooltip near cursor
        var finalX = Math.min(x, window.innerWidth - 420);
        var finalY = y;

        // Check if tooltip would go off bottom of screen
        // Approximate height calculation based on items
        var approxHeight = annotations.length * 24;
        if (finalY + approxHeight + 50 > window.innerHeight) {
          finalY = y - approxHeight - 20;
        }

        customTooltip.style.left = finalX + 'px';
        customTooltip.style.top = finalY + 'px';
      }

      // Function to hide custom tooltip
      function hideCustomTooltip() {
        hideTimer = setTimeout(function() {
          if (customTooltip && !customTooltip.matches(':hover')) {
            customTooltip.style.display = 'none';
          }
        }, 300);
      }

      // Get ALL annotations at specific row
      function getAnnotationsAtRow(row) {
        var session = editor.getSession();
        var annotations = session.getAnnotations();
        if (!annotations) return [];

        return annotations.filter(function(a) {
            return a.row === row;
        });
      }

      // Add hover listeners to gutter
      var gutterElement = editor.renderer.$gutterLayer.element;
      gutterElement.addEventListener('mouseover', function(e) {
        var target = e.target;

        // Find the gutter cell
        while (target && !target.classList.contains('ace_gutter-cell')) {
          target = target.parentElement;
          if (target === gutterElement) return;
        }

        if (!target) return;

        // Check if this cell has an annotation marker
        if (!target.classList.contains('ace_error') &&
            !target.classList.contains('ace_warning') &&
            !target.classList.contains('ace_info')) {
          return;
        }

        // Get the row number
        var textContent = target.textContent.trim();
        var row = parseInt(textContent) - 1;
        if (isNaN(row)) return;

        // Get ALL annotations for this row
        var annotations = getAnnotationsAtRow(row);
        if (annotations.length === 0) return;

        // Show tooltip with stacked annotations
        var rect = target.getBoundingClientRect();
        showCustomTooltip(
          annotations,
          rect.right - 30,
          rect.top + 15
        );
      });

      gutterElement.addEventListener('mouseout', function(e) {
        var relatedTarget = e.relatedTarget;
        // Don't hide if moving to tooltip
        if (relatedTarget === customTooltip || (customTooltip && customTooltip.contains(relatedTarget))) {
          return;
        }
        hideCustomTooltip();
      });

      // Disable Ace's default tooltips
      var gutterLayer = editor.renderer.$gutterLayer;
      gutterLayer.$showTooltips = false;

      // Hide tooltip on scroll
      editor.session.on('changeScrollTop', function() {
        if (customTooltip) {
          customTooltip.style.display = 'none';
        }
      });

      // Hide tooltip when clicking elsewhere
      document.addEventListener('click', function(e) {
        if (customTooltip && !customTooltip.contains(e.target) && !gutterElement.contains(e.target)) {
          customTooltip.style.display = 'none';
        }
      });

      setupDone = true;
      return true;
    } catch(e) {
      console.error('Failed to setup custom Ace tooltips:', e);
      return false;
    }
  }

  // Initialize
  setTimeout(setupAceEnhancements, 500);
  document.addEventListener('DOMContentLoaded', function() {
    setTimeout(setupAceEnhancements, 500);
  });
})();

  // Outline click -> jump
    (function(){
      document.addEventListener('click', function(e){
        var t = e.target.closest('.outline-item');
        if (!t) return;
        var ln = Number(t.getAttribute('data-line')||0);
        if (window.Shiny && Shiny.setInputValue){
          Shiny.setInputValue('outlineGo', { line: ln, nonce: Math.random() }, {priority:'event'});
        }
      });
    })();

    // --- Dynamic kebab menu: position + close behavior ---
    (function(){
      function closeAllMenus(){
        document.querySelectorAll('.context-menu.open').forEach(m => {
          m.classList.remove('open');
          m.style.display = 'none';
        });
      }
      function positionMenu(btn, menu){
        const r = btn.getBoundingClientRect();
        menu.style.display = 'block'; // allow measurement
        const mw = menu.offsetWidth, mh = menu.offsetHeight;
        let left = Math.max(8, r.right - mw);
        let top  = Math.min(window.innerHeight - mh - 8, r.bottom + 6);
        left = Math.min(left, window.innerWidth - mw - 8);
        top  = Math.max(8, top);
        menu.style.left = left + 'px';
        menu.style.top  = top + 'px';
      }

      // Toggle/open on kebab click
      document.addEventListener('click', function(e){
        const btn = e.target.closest('.kebab-btn');
        if (!btn) return;
        const menuId = btn.getAttribute('data-menu-id');
        const menu = document.getElementById(menuId);
        if (!menu) return;

        const isOpen = menu.classList.contains('open');
        closeAllMenus();
        if (!isOpen){
          positionMenu(btn, menu);
          menu.classList.add('open');
        }
        e.stopPropagation();
      }, true);

      document.addEventListener('shown.bs.modal', function(e){
        ['previewEditor','sourceEditor','dockerConsole'].forEach(function(id){
          try { ace.edit(id).setShowPrintMargin(false); } catch(_) {}
        });
      }, true);

      // Click on a menu item -> trigger Shiny input + close
      document.addEventListener('click', function(e){
        const item = e.target.closest('.context-menu .menu-item');
        if (!item) return;
        const id = item.getAttribute('data-id');
        if (id && window.Shiny && Shiny.setInputValue){
          Shiny.setInputValue(id, Math.random(), {priority: 'event'});
        }
        closeAllMenus();
        e.preventDefault();
        e.stopPropagation();
      }, true);

      // Click outside any open menu -> close
      document.addEventListener('mousedown', function(e){
        if (!e.target.closest('.context-menu') && !e.target.closest('.kebab-btn')){
          closeAllMenus();
        }
      }, true);

      // Close on ESC
      document.addEventListener('keydown', function(e){
        if (e.key === 'Escape') closeAllMenus();
      });

      // Close on resize/scroll to avoid misplaced menus
      window.addEventListener('resize', closeAllMenus, true);
      window.addEventListener('scroll', closeAllMenus, true);
    })();

  document.addEventListener('DOMContentLoaded', function(){
  document.querySelectorAll('.gutter').forEach(function(g){
    g.setAttribute('role','separator');
    g.setAttribute('aria-label','Drag to resize panes');
    g.setAttribute('tabindex','0');
    g.addEventListener('keydown', function(e){
      const step = 2; // percentage-ish nudge; Split.js will still handle pointer drags
      if(e.key === 'ArrowLeft' || e.key === 'ArrowUp'){ g.dispatchEvent(new MouseEvent('mousedown')); }
      if(e.key === 'ArrowRight' || e.key === 'ArrowDown'){ g.dispatchEvent(new MouseEvent('mousedown')); }
      // (We keep it minimal to avoid fighting Split.js sizing; this just enables focus & hinting.)
    });
  });
});


// ============== Split.js: PDF (top) ↕ Console (bottom) ==============
var previewVSplit;  // new
(function(){
  var pdfTop = document.getElementById('pdfContainer');
  var conBot = document.getElementById('dockerConsoleContainer');
  if(!pdfTop || !conBot) return;


  // ----- Console toggle keeps header visible (36px): compute % dynamically
  function setConsoleCollapsed(collapsed){
    var host = document.getElementById('pdfPreview');
    if(!host) return;
    var total = host.getBoundingClientRect().height || 1;
    var headerPx = 36;
    var headerPct = Math.max( (headerPx / total) * 100, 1.5 ); // keep ~1.5% min
    if(collapsed){
      previewVSplit.setSizes([100 - headerPct, headerPct]);
      try{ localStorage.setItem(SS_KEY_CONCOL, '1'); }catch(e){}
    } else {
      var s = parseSizes();
      // if previously collapsed, restore a sane default
      if(s[1] <= headerPct + 0.1) s = defaultSizes;
      previewVSplit.setSizes(s);
      try{ localStorage.setItem(SS_KEY_CONCOL, '0'); }catch(e){}
    }
    setTimeout(function(){
      try{ ace.edit('sourceEditor').resize(true); }catch(e){}
      try{ ace.edit('dockerConsole').resize(true); }catch(e){}
    }, 60);
  }

  // initial collapsed state
  try{ setConsoleCollapsed(localStorage.getItem(SS_KEY_CONCOL) === '1'); }catch(e){}

  // wire the button
  var btnC = document.getElementById('btnToggleConsole');
  if(btnC){
    btnC.addEventListener('click', function(){
      var host = document.getElementById('pdfPreview');
      var total = host.getBoundingClientRect().height || 1;
      var sizes = previewVSplit.getSizes();
      var headerPct = Math.max((36/total)*100, 1.5);
      var isCollapsed = sizes[1] <= headerPct + 0.1;
      setConsoleCollapsed(!isCollapsed);
    });
  }
})();

// ============== Outline collapse / expand (Files ↕ Outline) ==============
(function(){
  var KEY = 'mudskipper.outlineCollapsed';
  var KEY_LAST = 'mudskipper.outlineLastSizes';
  function ready(fn){ if(document.readyState!=='loading') fn(); else document.addEventListener('DOMContentLoaded', fn); }
  ready(function(){
    if(typeof sidebarVSplit === 'undefined') return;
    var btn = document.getElementById('btnToggleOutline');
    if(!btn) return;

    // Load last saved sizes or a sane default
    function loadLastSizes(){
      try{
        var s = JSON.parse(localStorage.getItem(KEY_LAST)||'null');
        if(Array.isArray(s) && s.length===2 && s[1] > 0) return s;
      }catch(e){}
      return [50,50];
    }
    function saveLastSizes(s){
      try{ localStorage.setItem(KEY_LAST, JSON.stringify(s)); }catch(e){}
    }

    function isCollapsed(){
      var s = sidebarVSplit.getSizes();
      return s[1] === 0;
    }

    function collapse(){
      // remember current before hiding
      saveLastSizes(sidebarVSplit.getSizes());
      sidebarVSplit.setSizes([90,10]);
      localStorage.setItem(KEY,'1');
      setTimeout(function(){ try{ ace.edit('sourceEditor').resize(true); }catch(e){} },60);
    }
    function expand(){
      var s = loadLastSizes();
      sidebarVSplit.setSizes(s);
      localStorage.setItem(KEY,'0');
      setTimeout(function(){ try{ ace.edit('sourceEditor').resize(true); }catch(e){} },60);
    }

    // initial
    if(localStorage.getItem(KEY)==='1') collapse();

    btn.addEventListener('click', function(){
      if(isCollapsed()) expand(); else collapse();
    });
  });
})();



// =================== ROBUST CURSOR & SCROLL TRACKING ===================
(function() {
  // 1. Debounce Utility
  function debounce(func, wait) {
    var timeout;
    return function() {
      var context = this, args = arguments;
      clearTimeout(timeout);
      timeout = setTimeout(function() {
        func.apply(context, args);
      }, wait);
    };
  }

  // 2. Tracking Logic
  function initCursorTracking() {
    try {
      var editor = ace.edit('sourceEditor');
      if (!editor) return;

      var sendToShiny = debounce(function() {
        var pos = editor.getCursorPosition();
        if (window.Shiny && Shiny.setInputValue) {
          Shiny.setInputValue('cursorPosition', {
            row: pos.row,
            column: pos.column,
            nonce: Math.random()
          }, {priority: 'event'});
        }
      }, 500);

      editor.getSession().selection.on('changeCursor', sendToShiny);
    } catch(e) {
      console.error('Error setting up cursor tracking:', e);
    }
  }

// 3. Restore & Scroll Handler (Aggressive Scroll)
  Shiny.addCustomMessageHandler('cursorRestore', function(data) {
    var editor = ace.edit('sourceEditor');
    if (!editor || !data) return;

    var r = (typeof data.row !== 'undefined') ? parseInt(data.row) : 0;
    var c = (typeof data.column !== 'undefined') ? parseInt(data.column) : 0;

    // Multiple attempts with increasing delays to ensure editor is ready
    function attemptRestore(attempt) {
      if (attempt > 5) return; // Give up after 5 attempts

      setTimeout(function() {
        try {
          // 1. Force resize to ensure proper rendering
          editor.resize(true);

          // 2. Set the cursor position
          editor.moveCursorTo(r, c);

          // 3. Clear any selection
          editor.clearSelection();

          // 4. Scroll to the line (multiple methods for reliability)
          editor.scrollToLine(r, true, true, function() {});

          // 5. Center the cursor in view
          editor.centerSelection();

          // 6. Force focus and ensure cursor is visible
          editor.focus();
          editor.navigateTo(r, c);

          // 7. Force a re-render
          editor.renderer.updateFull(true);

          // 8. Ensure the cursor is blinking
          editor.textInput.focus();

        } catch(e) {
          console.error('Cursor restore attempt ' + attempt + ' failed:', e);
          // Retry with longer delay
          attemptRestore(attempt + 1);
        }
      }, 100 * attempt); // Increasing delays: 100ms, 200ms, 300ms, etc.
    }

    // Start restoration attempts
    attemptRestore(1);
  });

  // Initialize
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() { setTimeout(initCursorTracking, 500); });
  } else {
    setTimeout(initCursorTracking, 500);
  }
})();


// Project management JavaScript
// Navigate back to homepage with browser back button
window.addEventListener('popstate', function(event) {
  if (window.Shiny && Shiny.setInputValue) {
    Shiny.setInputValue('backToHomepage', Math.random(), {priority: 'event'});
  }
});

// Update URL when opening project
Shiny.addCustomMessageHandler('updateProjectURL', function(projectId) {
  if (projectId) {
    const newUrl = window.location.pathname + '?project=' + encodeURIComponent(projectId);
    window.history.pushState({project: projectId}, '', newUrl);
  } else {
    window.history.pushState({}, '', window.location.pathname);
  }
});


// =================== ACE EDITOR PLACEHOLDER ON EMPTY LINES ===================
(function () {

  function initEmptyLinePlaceholder() {
    var editor = ace.edit('sourceEditor');
    if (!editor) return;

    var placeholder = document.createElement('div');
    placeholder.id = 'ace-empty-line-placeholder';

    Object.assign(placeholder.style, {
      position: 'absolute',
      pointerEvents: 'none',
      color: 'var(--tblr-black)',
      opacity: '1',
      fontStyle: 'italic',
      zIndex: 1,
      whiteSpace: 'nowrap',
      display: 'none'
    });

    placeholder.textContent =
      'Mudskipper auto-saves as you type...';

    editor.renderer.scroller.appendChild(placeholder);

    function hide() {
      placeholder.style.display = 'none';
    }

    function update() {
      editor.renderer.once('afterRender', function () {

        var session = editor.session;
        var cursor = editor.getCursorPosition();
        var row = cursor.row;

        if (session.getLine(row).trim() !== '' || !editor.isFocused()) {
          hide();
          return;
        }

        // TRUE cursor pixel position on screen
        var screenPos = editor.renderer.textToScreenCoordinates(
          row,
          cursor.column
        );

        // Get ACE scroller position relative to screen
        var scrollerRect = editor.renderer.scroller.getBoundingClientRect();

        // Convert screen coords → coords inside ACE
        var top = screenPos.pageY - scrollerRect.top;
        var left = screenPos.pageX - scrollerRect.left;

        placeholder.style.top = top + 'px';
        placeholder.style.left = left + 'px';
        placeholder.style.fontSize = editor.getFontSize() + 'px';
        placeholder.style.display = 'block';
      });
    }

    editor.selection.on('changeCursor', update);
    editor.on('change', update);
    editor.on('focus', update);
    editor.on('blur', hide);
    editor.session.on('changeScrollTop', update);
    editor.session.on('changeScrollLeft', update);
    window.addEventListener('resize', update);

    setTimeout(update, 150);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () {
      setTimeout(initEmptyLinePlaceholder, 500);
    });
  } else {
    setTimeout(initEmptyLinePlaceholder, 500);
  }
})();


// =================== SHARED AUTOCOMPLETE MANAGER ===================
(function() {
  window.AceAutocompleteManager = {
    disableCount: 0,
    originalState: true,
    editor: null,

    init: function(editor) {
      if (!this.editor) {
        this.editor = editor;
        this.originalState = editor.getOption('enableLiveAutocompletion');
      }
    },

    disable: function() {
      if (this.disableCount === 0 && this.editor) {
        // First disable request - capture state and disable
        this.originalState = this.editor.getOption('enableLiveAutocompletion');
        this.editor.setOption('enableLiveAutocompletion', false);
      }
      this.disableCount++;
    },

    enable: function() {
      this.disableCount = Math.max(0, this.disableCount - 1);
      if (this.disableCount === 0 && this.editor) {
        // Last enable request - restore original state
        this.editor.setOption('enableLiveAutocompletion', this.originalState);
      }
    },

    forceEnable: function() {
      // Emergency restore
      this.disableCount = 0;
      if (this.editor) {
        this.editor.setOption('enableLiveAutocompletion', this.originalState);
      }
    }
  };
})();


// =================== BIBTEX CITATION AUTOCOMPLETE ===================
(function() {
  var bibEntries = [];
  var currentCitePopup = null;
  var aceEditor = null;
  var selectedIndex = 0;
  var bibDisabledAce = false;  // ADD THIS - tracks if THIS popup disabled ace

  // Function to parse .bib file content and extract citation keys
  function parseBibFile(content) {
    if (!content || typeof content !== 'string') return [];

    var entries = [];
    // Match @article, @book, @inproceedings, etc. with their keys
    var pattern = /@\\w+\\s*\\{\\s*([^,\\s]+)/g;
    var match;

    while ((match = pattern.exec(content)) !== null) {
      if (match[1]) {
        entries.push(match[1].trim());
      }
    }

    return entries;
  }

// Function to create and position popup
  function showCitePopup(entries, aceEditor, prefix) {
    if (!currentCitePopup && !bibDisabledAce) {
      aceEditor.setOption('enableLiveAutocompletion', false);
      bibDisabledAce = true;
    }

    hideCitePopup(true);
    selectedIndex = 0;

    if (!entries || entries.length === 0) {
      currentCitePopup = createMessagePopup('No matching entries', aceEditor);
      return;
    }

    var searchTerm = prefix.split(',').pop().trim();
    var filtered = searchTerm ? entries.filter(function(e) {
      return e.toLowerCase().indexOf(searchTerm.toLowerCase()) !== -1;
    }) : entries.slice(0, 200);

    if (filtered.length === 0) {
      currentCitePopup = createMessagePopup('No matching entries', aceEditor);
      return;
    }

    // --- UPDATED: Create Premium Popup Structure ---
    var popup = document.createElement('div');
    popup.id = 'cite-autocomplete-popup';
    popup.className = 'autocomplete-popup'; // Apply new CSS class

    // Add Header
    var header = document.createElement('div');
    header.className = 'autocomplete-header';
    header.textContent = 'Citations';
    popup.appendChild(header);

    filtered.forEach(function(entry, idx) {
      var item = document.createElement('div');
      item.textContent = entry;
      // Add 'autocomplete-item' for styling, keep 'cite-popup-item' for logic
      item.className = 'autocomplete-item cite-popup-item';
      item.setAttribute('data-index', idx);

      // Default selection styling
      if (idx === 0) item.classList.add('active');

      item.onmouseover = function() {
        var items = popup.querySelectorAll('.cite-popup-item');
        items.forEach(function(it) { it.classList.remove('active'); });
        this.classList.add('active');
        selectedIndex = idx;
      };

      item.onclick = function(e) {
        e.preventDefault(); e.stopPropagation();
        insertCitation(aceEditor, entry);
        hideCitePopup();
        return false;
      };

      item.onmousedown = function(e) { e.preventDefault(); e.stopPropagation(); return false; };
      popup.appendChild(item);
    });

    document.body.appendChild(popup);
    currentCitePopup = popup;
    currentCitePopup.filteredEntries = filtered;
    positionPopup(aceEditor, popup);
  }

  function createMessagePopup(message, aceEditor) {
    var popup = document.createElement('div');
    popup.id = 'cite-autocomplete-popup';
    popup.className = 'autocomplete-popup'; // Apply new CSS class
    popup.style.padding = '8px 12px';       // Specific padding for messages
    popup.style.fontStyle = 'italic';
    popup.style.color = 'var(--tblr-secondary)';

    popup.textContent = message;
    document.body.appendChild(popup);
    positionPopup(aceEditor, popup);

    return popup;
  }

  function positionPopup(aceEditor, popup) {
    var cursor = aceEditor.getCursorPosition();
    var coords = aceEditor.renderer.textToScreenCoordinates(cursor.row, cursor.column);

    popup.style.left = coords.pageX + 'px';
    popup.style.top = (coords.pageY + 20) + 'px';

    // Adjust if off-screen
    setTimeout(function() {
      var rect = popup.getBoundingClientRect();
      if (rect.right > window.innerWidth) {
        popup.style.left = (window.innerWidth - rect.width - 20) + 'px';
      }
      if (rect.bottom > window.innerHeight) {
        popup.style.top = (coords.pageY - rect.height - 5) + 'px';
      }
    }, 0);
  }

function hideCitePopup(skipRestore) {
    if (currentCitePopup) {
      currentCitePopup.remove();
      currentCitePopup = null;
      selectedIndex = 0;
    }

    // Only restore if we were the ones who disabled it AND not just refreshing
    if (!skipRestore && bibDisabledAce) {
      // Check if label popup is also closed before restoring
      if (!document.getElementById('label-autocomplete-popup')) {
        aceEditor.setOption('enableLiveAutocompletion', true);
      }
      bibDisabledAce = false;
    }
  }

function insertCitation(aceEditor, citation) {
    // 1. FIX: Require Range from the ace module system
    var Range = ace.require('ace/range').Range;

    var cursor = aceEditor.getCursorPosition();
    var line = aceEditor.session.getLine(cursor.row);

    // Find the { before cursor
    var beforeCursor = line.substring(0, cursor.column);
    var bracePos = beforeCursor.lastIndexOf('{');

    if (bracePos !== -1) {
      // Get text between { and cursor
      var textInBrace = beforeCursor.substring(bracePos + 1);

      // Find position after last comma (if any)
      var lastCommaPos = textInBrace.lastIndexOf(',');

      if (lastCommaPos !== -1) {
        // There's a comma, insert after it
        var startPos = bracePos + 1 + lastCommaPos + 1;
        var afterComma = textInBrace.substring(lastCommaPos + 1);

        // 2. FIX: Use trimStart() instead of trimLeft()
        var trimmedAfterComma = afterComma.trimStart();
        var spacesToRemove = afterComma.length - trimmedAfterComma.length;
        startPos += spacesToRemove;

        // Delete text from startPos to cursor and insert citation
        var range = new Range(cursor.row, startPos, cursor.row, cursor.column);
        aceEditor.session.replace(range, citation);
      } else {
        // No comma, replace everything after {
        var range = new Range(cursor.row, bracePos + 1, cursor.row, cursor.column);
        aceEditor.session.replace(range, citation);
      }

      // Move cursor after inserted citation
      var newCursorCol = bracePos + 1 + citation.length;
      if (lastCommaPos !== -1) {
        newCursorCol = bracePos + 1 + lastCommaPos + 1 + citation.length;
      }
      aceEditor.moveCursorTo(cursor.row, newCursorCol);
      aceEditor.focus();
    }
  }

  // Detect cite commands and show popup
  function handleEditorChange(aceEditor) {
    var cursor = aceEditor.getCursorPosition();
    var line = aceEditor.session.getLine(cursor.row);
    var beforeCursor = line.substring(0, cursor.column);

    // Match cite variants followed by {
    var citeMatch = beforeCursor.match(/\\\\cite[a-zA-Z]*\\{([^}]*)$/);

    if (citeMatch) {
      var prefix = citeMatch[1]; // Text after {

      if (bibEntries.length === 0) {
        // Check if we have bib files
        if (window.Shiny && Shiny.setInputValue) {
          Shiny.setInputValue('checkBibFiles', Math.random(), {priority: 'event'});
        }
        hideCitePopup();
        currentCitePopup = createMessagePopup('Loading citations <span class=\"animated-dots\"></span>', aceEditor);
      } else {
        showCitePopup(bibEntries, aceEditor, prefix);
      }
    } else {
      hideCitePopup();
    }
  }

  // Handle keyboard navigation
  function handleKeyDown(e, aceEditor) {
    if (!currentCitePopup || !currentCitePopup.filteredEntries) return;

    var items = currentCitePopup.querySelectorAll('.cite-popup-item');
    if (!items || items.length === 0) return;

    // Arrow Down
    if (e.keyCode === 40) {
      e.preventDefault();
      e.stopPropagation();
      selectedIndex = (selectedIndex + 1) % items.length;
      updateSelection(items);
      return;
    }

    // Arrow Up
    if (e.keyCode === 38) {
      e.preventDefault();
      e.stopPropagation();
      selectedIndex = (selectedIndex - 1 + items.length) % items.length;
      updateSelection(items);
      return;
    }

    // Enter
    if (e.keyCode === 13) {
      e.preventDefault();
      e.stopPropagation();

      if (currentCitePopup.filteredEntries[selectedIndex]) {
        insertCitation(aceEditor, currentCitePopup.filteredEntries[selectedIndex]);
        hideCitePopup();
      }
      return;
    }

    // Tab
    if (e.keyCode === 9) {
      e.preventDefault();
      e.stopPropagation();

      if (currentCitePopup.filteredEntries[selectedIndex]) {
        insertCitation(aceEditor, currentCitePopup.filteredEntries[selectedIndex]);
        hideCitePopup();
      }
      return;
    }

    // Escape
    if (e.keyCode === 27) {
      e.preventDefault();
      e.stopPropagation();
      hideCitePopup();
      return;
    }
  }

function updateSelection(items) {
    items.forEach(function(item, idx) {
      if (idx === selectedIndex) {
        item.classList.add('active'); // Use CSS class
        item.scrollIntoView({ block: 'nearest' });
      } else {
        item.classList.remove('active');
      }
    });
  }

  // Initialize when editor is ready
  function initCiteAutocomplete() {
    try {
      aceEditor = ace.edit('sourceEditor');
      if (!aceEditor) return false;

      // Listen to changes
      aceEditor.on('change', function() {
        handleEditorChange(aceEditor);
      });

      aceEditor.selection.on('changeCursor', function() {
        var cursor = aceEditor.getCursorPosition();
        var line = aceEditor.session.getLine(cursor.row);
        var beforeCursor = line.substring(0, cursor.column);

        if (!beforeCursor.match(/\\\\cite[a-zA-Z]*\\{[^}]*$/)) {
          hideCitePopup();
        }
      });

      // Add global keydown listener
      document.addEventListener('keydown', function(e) {
        if (currentCitePopup && currentCitePopup.filteredEntries) {
          handleKeyDown(e, aceEditor);
        }
      }, true);

      // Add Ace keyboard handler
      aceEditor.keyBinding.addKeyboardHandler({
        handleKeyboard: function(data, hash, keyString, keyCode, event) {
          if (currentCitePopup && currentCitePopup.filteredEntries) {
            if ([13, 9, 38, 40, 27].indexOf(keyCode) !== -1) {
              handleKeyDown(event, aceEditor);
              return { command: 'null' };
            }
          }
          return false;
        }
      });

      return true;
    } catch(e) {
      console.error('Failed to initialize citation autocomplete:', e);
      return false;
    }
  }

  // Expose functions globally
  window.updateBibEntries = function(entries) {
    bibEntries = entries || [];
  };

  window.showNoBibMessage = function(message) {
    if (aceEditor && currentCitePopup) {
      hideCitePopup();
      currentCitePopup = createMessagePopup(message, aceEditor);
    }
  };

  // Initialize
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      setTimeout(initCiteAutocomplete, 500);
    });
  } else {
    setTimeout(initCiteAutocomplete, 500);
  }
})();


 // =================== LABEL AUTOCOMPLETE ===================
(function() {
  var labelEntries = [];
  var currentLabelPopup = null;
  var aceLabelEditor = null;
  var selectedLabelIndex = 0;
  var labelDisabledAce = false;  // ADD THIS - tracks if THIS popup disabled ace

  // Function to parse .tex file content and extract label keys
  function parseLabelsFromContent(content) {
    if (!content || typeof content !== 'string') return [];

    var entries = [];
    // Match \\label{key} patterns
    var pattern = /\\\\label\\{([^}]+)\\}/g;
    var match;

    while ((match = pattern.exec(content)) !== null) {
      if (match[1]) {
        entries.push(match[1].trim());
      }
    }

    return entries;
  }

// Function to create and position popup
  function showLabelPopup(entries, aceEditor, prefix) {
    if (!currentLabelPopup && !labelDisabledAce) {
      aceEditor.setOption('enableLiveAutocompletion', false);
      labelDisabledAce = true;
    }

    hideLabelPopup(true);
    selectedLabelIndex = 0;

    if (!entries || entries.length === 0) {
      currentLabelPopup = createLabelMessagePopup('No matching labels', aceEditor);
      return;
    }

    var searchTerm = prefix.split(',').pop().trim();
    var filtered = searchTerm ? entries.filter(function(e) {
      return e.toLowerCase().indexOf(searchTerm.toLowerCase()) !== -1;
    }) : entries.slice(0, 200);

    if (filtered.length === 0) {
      currentLabelPopup = createLabelMessagePopup('No matching labels', aceEditor);
      return;
    }

    // --- UPDATED: Create Premium Popup Structure ---
    var popup = document.createElement('div');
    popup.id = 'label-autocomplete-popup';
    popup.className = 'autocomplete-popup'; // Apply new CSS class

    // Add Header
    var header = document.createElement('div');
    header.className = 'autocomplete-header';
    header.textContent = 'Labels';
    popup.appendChild(header);

    filtered.forEach(function(entry, idx) {
      var item = document.createElement('div');
      item.textContent = entry;
      // Add 'autocomplete-item' for styling, keep 'label-popup-item' for logic
      item.className = 'autocomplete-item label-popup-item';
      item.setAttribute('data-index', idx);

      if (idx === 0) item.classList.add('active');

      item.onmouseover = function() {
        var items = popup.querySelectorAll('.label-popup-item');
        items.forEach(function(it) { it.classList.remove('active'); });
        this.classList.add('active');
        selectedLabelIndex = idx;
      };

      item.onclick = function(e) {
        e.preventDefault(); e.stopPropagation();
        insertLabel(aceEditor, entry);
        hideLabelPopup();
        return false;
      };

      item.onmousedown = function(e) { e.preventDefault(); e.stopPropagation(); return false; };
      popup.appendChild(item);
    });

    document.body.appendChild(popup);
    currentLabelPopup = popup;
    currentLabelPopup.filteredEntries = filtered;
    positionLabelPopup(aceEditor, popup);
  }

  function createLabelMessagePopup(message, aceEditor) {
    var popup = document.createElement('div');
    popup.id = 'label-autocomplete-popup';
    popup.className = 'autocomplete-popup';
    popup.style.padding = '8px 12px';
    popup.style.fontStyle = 'italic';
    popup.style.color = 'var(--tblr-secondary)';

    popup.textContent = message;
    document.body.appendChild(popup);
    positionLabelPopup(aceEditor, popup);

    return popup;
  }

  function positionLabelPopup(aceEditor, popup) {
    var cursor = aceEditor.getCursorPosition();
    var coords = aceEditor.renderer.textToScreenCoordinates(cursor.row, cursor.column);

    popup.style.left = coords.pageX + 'px';
    popup.style.top = (coords.pageY + 20) + 'px';

    // Adjust if off-screen
    setTimeout(function() {
      var rect = popup.getBoundingClientRect();
      if (rect.right > window.innerWidth) {
        popup.style.left = (window.innerWidth - rect.width - 20) + 'px';
      }
      if (rect.bottom > window.innerHeight) {
        popup.style.top = (coords.pageY - rect.height - 5) + 'px';
      }
    }, 0);
  }

  function hideLabelPopup(skipRestore) {
    if (currentLabelPopup) {
      currentLabelPopup.remove();
      currentLabelPopup = null;
      selectedLabelIndex = 0;
    }

    // Only restore if we were the ones who disabled it AND not just refreshing
    if (!skipRestore && labelDisabledAce) {
      // Check if cite popup is also closed before restoring
      if (!document.getElementById('cite-autocomplete-popup')) {
        aceLabelEditor.setOption('enableLiveAutocompletion', true);
      }
      labelDisabledAce = false;
    }
  }

  function insertLabel(aceEditor, label) {
    // 1. FIX: Require Range from the ace module system
    var Range = ace.require('ace/range').Range;

    var cursor = aceEditor.getCursorPosition();
    var line = aceEditor.session.getLine(cursor.row);

    // Find the { before cursor
    var beforeCursor = line.substring(0, cursor.column);
    var bracePos = beforeCursor.lastIndexOf('{');

    if (bracePos !== -1) {
      // Get text between { and cursor
      var textInBrace = beforeCursor.substring(bracePos + 1);

      // Find position after last comma (if any)
      var lastCommaPos = textInBrace.lastIndexOf(',');

      if (lastCommaPos !== -1) {
        // There's a comma, insert after it
        var startPos = bracePos + 1 + lastCommaPos + 1;
        var afterComma = textInBrace.substring(lastCommaPos + 1);

        // 2. FIX: Use trimStart() instead of trimLeft()
        var trimmedAfterComma = afterComma.trimStart();
        var spacesToRemove = afterComma.length - trimmedAfterComma.length;
        startPos += spacesToRemove;

        // Delete text from startPos to cursor and insert label
        var range = new Range(cursor.row, startPos, cursor.row, cursor.column);
        aceEditor.session.replace(range, label);
      } else {
        // No comma, replace everything after {
        var range = new Range(cursor.row, bracePos + 1, cursor.row, cursor.column);
        aceEditor.session.replace(range, label);
      }

      // Move cursor after inserted label
      var newCursorCol = bracePos + 1 + label.length;
      if (lastCommaPos !== -1) {
        newCursorCol = bracePos + 1 + lastCommaPos + 1 + label.length;
      }
      aceEditor.moveCursorTo(cursor.row, newCursorCol);
      aceEditor.focus();
    }
  }

  // Detect ref commands and show popup
  function handleLabelEditorChange(aceEditor) {
    var cursor = aceEditor.getCursorPosition();
    var line = aceEditor.session.getLine(cursor.row);
    var beforeCursor = line.substring(0, cursor.column);

    // Match ref variants followed by {
    var refMatch = beforeCursor.match(/\\\\(?:ref|eqref|pageref|autoref|cref|Cref)\\{([^}]*)$/);

    if (refMatch) {
      var prefix = refMatch[1];

      if (labelEntries.length === 0) {
        // Check if we have label data
        if (window.Shiny && Shiny.setInputValue) {
          Shiny.setInputValue('checkLabelKeys', Math.random(), {priority: 'event'});
        }
        hideLabelPopup();
        currentLabelPopup = createLabelMessagePopup('Loading labels <span class=\"animated-dots\"></span>', aceEditor);
      } else {
        showLabelPopup(labelEntries, aceEditor, prefix);
      }
    } else {
      hideLabelPopup();
    }
  }

  // Handle keyboard navigation
  function handleLabelKeyDown(e, aceEditor) {
    if (!currentLabelPopup || !currentLabelPopup.filteredEntries) return;

    var items = currentLabelPopup.querySelectorAll('.label-popup-item');
    if (!items || items.length === 0) return;

    // Arrow Down
    if (e.keyCode === 40) {
      e.preventDefault();
      e.stopPropagation();
      selectedLabelIndex = (selectedLabelIndex + 1) % items.length;
      updateLabelSelection(items);
      return;
    }

    // Arrow Up
    if (e.keyCode === 38) {
      e.preventDefault();
      e.stopPropagation();
      selectedLabelIndex = (selectedLabelIndex - 1 + items.length) % items.length;
      updateLabelSelection(items);
      return;
    }

    // Enter
    if (e.keyCode === 13) {
      e.preventDefault();
      e.stopPropagation();

      if (currentLabelPopup.filteredEntries[selectedLabelIndex]) {
        insertLabel(aceEditor, currentLabelPopup.filteredEntries[selectedLabelIndex]);
        hideLabelPopup();
      }
      return;
    }

    // Tab
    if (e.keyCode === 9) {
      e.preventDefault();
      e.stopPropagation();

      if (currentLabelPopup.filteredEntries[selectedLabelIndex]) {
        insertLabel(aceEditor, currentLabelPopup.filteredEntries[selectedLabelIndex]);
        hideLabelPopup();
      }
      return;
    }

    // Escape
    if (e.keyCode === 27) {
      e.preventDefault();
      e.stopPropagation();
      hideLabelPopup();
      return;
    }
  }

function updateLabelSelection(items) {
    items.forEach(function(item, idx) {
      if (idx === selectedLabelIndex) {
        item.classList.add('active');
        item.scrollIntoView({ block: 'nearest' });
      } else {
        item.classList.remove('active');
      }
    });
  }

  // Initialize when editor is ready
  function initLabelAutocomplete() {
    try {
      aceLabelEditor = ace.edit('sourceEditor');
      if (!aceLabelEditor) return false;

      // Listen to changes
      aceLabelEditor.on('change', function() {
        handleLabelEditorChange(aceLabelEditor);
      });

      aceLabelEditor.selection.on('changeCursor', function() {
        var cursor = aceLabelEditor.getCursorPosition();
        var line = aceLabelEditor.session.getLine(cursor.row);
        var beforeCursor = line.substring(0, cursor.column);

        if (!beforeCursor.match(/\\\\(?:ref|eqref|pageref|autoref|cref|Cref)\\{[^}]*$/)) {
          hideLabelPopup();
        }
      });

      // Add global keydown listener
      document.addEventListener('keydown', function(e) {
        if (currentLabelPopup && currentLabelPopup.filteredEntries) {
          handleLabelKeyDown(e, aceLabelEditor);
        }
      }, true);

      // Add Ace keyboard handler
      aceLabelEditor.keyBinding.addKeyboardHandler({
        handleKeyboard: function(data, hash, keyString, keyCode, event) {
          if (currentLabelPopup && currentLabelPopup.filteredEntries) {
            if ([13, 9, 38, 40, 27].indexOf(keyCode) !== -1) {
              handleLabelKeyDown(event, aceLabelEditor);
              return { command: 'null' };
            }
          }
          return false;
        }
      });

      return true;
    } catch(e) {
      console.error('Failed to initialize label autocomplete:', e);
      return false;
    }
  }

  // Expose functions globally
  window.updateLabelEntries = function(entries) {
    labelEntries = entries || [];
  };

  window.showNoLabelMessage = function(message) {
    if (aceLabelEditor && currentLabelPopup) {
      hideLabelPopup();
      currentLabelPopup = createLabelMessagePopup(message, aceLabelEditor);
    }
  };

  // Initialize
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      setTimeout(initLabelAutocomplete, 500);
    });
  } else {
    setTimeout(initLabelAutocomplete, 500);
  }
})();


// updateCitationCount and updateLabelCount handlers are now registered
// exclusively in www/status_bar.js to display counts in the status bar.

//==================CITATION MANAGER===================//

document.addEventListener('DOMContentLoaded', function() {

    // --- CITATION MANAGER HELPERS ---

    // Map for cleaning Unicode to LaTeX
    const BIBTEX_REPLACEMENTS = {
      '\\u2018': \"`\",    // Left single quote
      '\\u2019': \"'\",    // Right single quote
      '\\u201C': \"``\",   // Left double quote
      '\\u201D': \"''\",   // Right double quote
      '\\u2013': \"--\",   // En-dash
      '\\u2014': \"---\",  // Em-dash
      '\\u00A0': \" \",    // Non-breaking space
      '\\u00E9': \"\\\\'e\",    // é
      '\\u00E8': \"\\\\`e\",    // è
      '\\u00E0': \"\\\\`a\",    // à
      '\\u00F6': \"\\\\\\\"o\", // ö
      '\\u00FC': \"\\\\\\\"u\", // ü
      '\\u00E4': \"\\\\\\\"a\", // ä
      '\\u00DF': \"{\\\\ss}\"   // ß
    };

    window.cleanAndFormatBibTeX = function(rawBib) {
      if (!rawBib) return \"\";

      // 1. Clean Unicode
      let cleanBib = rawBib.replace(/[\\u2018\\u2019\\u201C\\u201D\\u2013\\u2014\\u00A0\\u00E9\\u00E8\\u00E0\\u00F6\\u00FC\\u00E4\\u00DF]/g, function(char) {
        return BIBTEX_REPLACEMENTS[char] || char;
      });

      // 2. Formatting
      cleanBib = cleanBib.replace(/\\r\\n|\\r|\\n/g, ' ');
      cleanBib = cleanBib.replace(/(@[a-zA-Z]+\\s*\\{[^,]+,)/, '$1\\n');
      cleanBib = cleanBib.replace(/,(\\s*)([a-zA-Z0-9_]+)(\\s*)=/g, ',\\n  $2$3=');
      cleanBib = cleanBib.replace(/\\}(\\s*)$/, '\\n}');
      cleanBib = cleanBib.replace(/  =/g, ' =');

      return cleanBib;
    };

    // --- MAIN LOGIC ---

    window.openCitationOverlay = function() {
      document.getElementById('citationOverlay').classList.add('show');
    };

    window.closeCitationOverlay = function() {
      document.getElementById('citationOverlay').classList.remove('show');
      document.getElementById('citationPreviewArea').style.display = 'none';
      document.getElementById('citationSearchInput').value = '';
    };

    // --- SMART SEARCH FUNCTION ---
    window.searchCitation = async function() {
      const inputVal = document.getElementById('citationSearchInput').value.trim();
      if (!inputVal) return;

      const btn = document.getElementById('btnSearchCitation');
      const originalText = btn.innerText;

      btn.innerHTML = 'Searching <span class=\"animated-dots\"></span>';
      btn.disabled = true;

      try {
        let bibtex = null;
        let doi = null;

        // STEP 1: Detect if input is a DOI or a Title
        // Regex: Check for standard DOI pattern (starts with 10.xxxx/...)
        const doiRegex = /\\b(10\\.\\d{4,9}\\/[-._;()/:A-Z0-9]+)\\b/i;
        const match = inputVal.match(doiRegex);

        if (match) {
          // It looks like a DOI
          doi = match[0];
          console.log(\"Detected DOI:\", doi);
          bibtex = await fetchBibtexFromDoi(doi);
        } else {
          // It looks like a Title -> Search CrossRef Metadata first
          console.log(\"Detected Title, searching metadata...\");
          doi = await findDoiFromTitle(inputVal);
          if (doi) {
            console.log(\"Found DOI from title:\", doi);
            bibtex = await fetchBibtexFromDoi(doi);
          } else {
            throw new Error(\"Could not find a matching paper for this title.\");
          }
        }

        // STEP 2: Display Result
        if (bibtex) {
          const formatted = window.cleanAndFormatBibTeX(bibtex);
          document.getElementById('bibtexPreview').innerText = formatted;
          document.getElementById('citationPreviewArea').style.display = 'block';
        } else {
          throw new Error(\"DOI found, but BibTeX could not be generated.\");
        }

      } catch (err) {
        console.error(err);
        alert(err.message || 'Error fetching citation.');
      } finally {
        btn.innerText = originalText;
        btn.disabled = false;
      }
    };

    // Helper: Fetch BibTeX (Try CrossRef, then DataCite)
    async function fetchBibtexFromDoi(doi) {
      // 1. Try CrossRef (Fastest/Standard)
      try {
        const resp = await fetch(`https://api.crossref.org/works/${encodeURIComponent(doi)}/transform/application/x-bibtex`);
        if (resp.status === 200) {
          return await resp.text();
        }
      } catch (e) { console.warn(\"CrossRef failed, trying DataCite...\"); }

      // 2. Try DataCite (Great for datasets/software) using Content Negotiation
      try {
        const resp = await fetch(`https://api.datacite.org/dois/${encodeURIComponent(doi)}`, {
          headers: { 'Accept': 'application/x-bibtex' }
        });
        if (resp.status === 200) {
          return await resp.text();
        }
      } catch (e) { console.warn(\"DataCite failed.\"); }

      // 3. Last Resort: Generic DOI Content Negotiation
      try {
        const resp = await fetch(`https://doi.org/${encodeURIComponent(doi)}`, {
          headers: { 'Accept': 'application/x-bibtex; charset=utf-8' }
        });
        if (resp.status === 200) {
          return await resp.text();
        }
      } catch (e) {}

      throw new Error(\"Reference not found in CrossRef or DataCite.\");
    }

    // Helper: Find DOI from Title
    async function findDoiFromTitle(query) {
      // Search CrossRef Metadata
      const url = `https://api.crossref.org/works?query.bibliographic=${encodeURIComponent(query)}&rows=1&select=DOI`;
      const resp = await fetch(url);
      const data = await resp.json();

      if (data.message && data.message.items && data.message.items.length > 0) {
        return data.message.items[0].DOI;
      }
      return null;
    }

    window.appendCitationToBib = function() {
      const bibtex = document.getElementById('bibtexPreview').innerText;
      Shiny.setInputValue('append_bibtex_entry', bibtex, {priority: 'event'});
      closeCitationOverlay();
    };

  });



//============================= Alert System=====================//
window.showTablerAlert = function(type, heading, message, duration) {
  duration = duration || 5000;

  const icons = {
    success: '<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M5 12l5 5l10 -10\" /></svg>',
    info: '<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0\" /><path d=\"M12 9h.01\" /><path d=\"M11 12h1v4h1\" /></svg>',
    warning: '<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M12 9v4\" /><path d=\"M10.363 3.591l-8.106 13.534a1.914 1.914 0 0 0 1.636 2.871h16.214a1.914 1.914 0 0 0 1.636 -2.87l-8.106 -13.536a1.914 1.914 0 0 0 -3.274 0z\" /><path d=\"M12 16h.01\" /></svg>',
    danger: '<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0\" /><path d=\"M12 8v4\" /><path d=\"M12 16h.01\" /></svg>',
    error: '<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0\" /><path d=\"M12 8v4\" /><path d=\"M12 16h.01\" /></svg>'
  };

  // Normalize type
  if (type === 'message') type = 'success';
  if (type === 'error') type = 'danger';

  // Apply colors ONLY to the text and icons
  const textColors = {
    success: 'text-success',
    info: 'text-info',
    warning: 'text-warning',
    danger: 'text-danger'
  };
  const textColorClass = textColors[type] || 'text-info';

  const toastDiv = document.createElement('div');
  // Kept 'fade' removed to prevent CSS conflicts. Let Tabler handle default toast background.
  toastDiv.className = 'toast show';
  toastDiv.setAttribute('role', 'alert');
  toastDiv.setAttribute('aria-live', 'assertive');
  toastDiv.setAttribute('aria-atomic', 'true');

  // Apply the text color class to the icon and heading only. Standard close button.
  toastDiv.innerHTML = `
    <div class=\"toast-header\">
      <span class=\"me-2 ${textColorClass}\">${icons[type] || icons.info}</span>
      <strong class=\"me-auto ${textColorClass}\">${heading}</strong>
      <small>just now</small>
      <button type=\"button\" class=\"ms-2 btn-close\" aria-label=\"Close\"></button>
    </div>
    <div class=\"toast-body\">${message}</div>
  `;

  const container = document.getElementById('alertContainer');
  if (container) {
    container.appendChild(toastDiv);

    // Centralized remove function to trigger animation
    const removeToast = function() {
      if (!toastDiv.classList.contains('removing')) {
        toastDiv.classList.add('removing');
        setTimeout(function() {
          if (toastDiv.parentNode) {
            toastDiv.parentNode.removeChild(toastDiv);
          }
        }, 300); // Wait for slideOutUp animation to finish
      }
    };

    // Auto-dismiss
    let autoDismiss = setTimeout(removeToast, duration);

    // Click 'X' button to dismiss manually
    const closeBtn = toastDiv.querySelector('.btn-close');
    closeBtn.addEventListener('click', function(e) {
      clearTimeout(autoDismiss);
      removeToast();
    });
  }
};

// Shiny custom message handler
Shiny.addCustomMessageHandler('showTablerAlert', function(data) {
  window.showTablerAlert(data.type, data.heading, data.message, data.duration);
});


// Keyboard shortcut to return to projects (Ctrl/Cmd + Shift + P)
document.addEventListener('keydown', function(e) {
  if ((e.ctrlKey || e.metaKey) && e.shiftKey && e.key === 'p') {
    e.preventDefault();
    if (window.Shiny && Shiny.setInputValue) {
      Shiny.setInputValue('backToHomepage', Math.random(), {priority: 'event'});
    }
  }

  // Keyboard shortcut to compile (Ctrl/Cmd + S)
  if ((e.ctrlKey || e.metaKey) && e.key === 's') {
    e.preventDefault();
    if (window.Shiny && Shiny.setInputValue) {
      Shiny.setInputValue('compile', Math.random(), {priority: 'event'});
    }
  }
});


 $(document).on('change', 'input[name=\"autoCompile\"]', function() {
    Shiny.setInputValue('autoCompile', this.value, {priority: 'event'});
  });


  // Track cursor position in Ace editor for outline highlighting
(function() {
  function trackCursorPosition() {
    try {
      var editor = ace.edit('sourceEditor');
      if (!editor) return;

      editor.getSession().selection.on('changeCursor', function() {
        var cursorPosition = editor.getCursorPosition();
        if (window.Shiny && Shiny.setInputValue) {
          Shiny.setInputValue('cursorPosition', {
            row: cursorPosition.row,
            column: cursorPosition.column
          }, {priority: 'event'});
        }
      });
    } catch(e) {
      console.error('Error setting up cursor tracking:', e);
    }
  }

  // Initialize when editor is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      setTimeout(trackCursorPosition, 500);
    });
  } else {
    setTimeout(trackCursorPosition, 500);
  }
})();


// Show File Preview
  Shiny.addCustomMessageHandler('showFilePreview', function(data) {
    var overlay = document.getElementById('filePreviewOverlay');
    var editorSplit = document.getElementById('editorSplit');
    var visualEditor = document.getElementById('visual-editor-container');
    var toolbar = document.getElementById('equation-editor');
    var title = document.getElementById('filePreviewTitle');
    var body = document.getElementById('filePreviewBody');
    var dlBtn = document.getElementById('previewDownloadBtn');

    if (!overlay || !title || !body) return;

    // 1. Swap Views
    if (editorSplit) editorSplit.style.display = 'none';
    if (visualEditor) visualEditor.style.display = 'none';
    if (toolbar) toolbar.style.display = 'none';
    overlay.style.display = 'flex';

    // 2. Setup Header & Download
    title.innerText = data.filename;
    if (dlBtn) {
      dlBtn.href = data.url;
      dlBtn.download = data.filename;
    }

    // 3. Render Content
    body.innerHTML = '';

    if (data.type === 'image') {
      var img = document.createElement('img');
      img.src = data.url;
      img.style.maxWidth = '100%';
      img.style.maxHeight = '100%';
      img.style.objectFit = 'contain';
      body.appendChild(img);

    } else if (data.type === 'pdf') {
      var iframe = document.createElement('iframe');
      iframe.src = 'Mudskipper_viewer.html?file=' + encodeURIComponent(data.url);

      // Initial styling
      iframe.style.width = '100%';
      iframe.style.border = 'none';
      iframe.style.background = 'transparent';
      iframe.allowTransparency = 'true';

      // --- INJECT STYLES & AUTO-HEIGHT LOGIC ON LOAD ---
      iframe.onload = function() {
        try {
            var doc = iframe.contentDocument || iframe.contentWindow.document;

            // A. Inject CSS
            var style = doc.createElement('style');
            style.textContent = `
                html, body {
                    background: transparent !important;
                    background-color: transparent !important;
                    height: auto !important;
                    overflow: visible !important;
                    min-height: 0 !important; /* Prevent sticking */
                }
                #viewerContainer {
                    background: transparent !important;
                    background-color: transparent !important;
                    position: static !important;
                    height: auto !important;
                    overflow: visible !important;
                    padding: 0 !important;
                }
                /* Remove margins and shadows from PDF pages */
                .page {
                    margin: 0 !important;
                    box-shadow: none !important;
                    border: none !important;
                }
                ::-webkit-scrollbar { display: none; }
            `;
            doc.head.appendChild(style);

            // B. Resize Observer: Watch #viewerContainer ONLY
            var viewerDiv = doc.getElementById('viewerContainer');
            if(viewerDiv) {
                var resizeObserver = new ResizeObserver(entries => {
                    for (let entry of entries) {
                        // Use the contentRect height (actual height of the pages wrapper)
                        // Adding a small buffer (e.g., 30px) for shadows/margins
                        var newHeight = entry.contentRect.height + 30;
                        iframe.style.height = newHeight + 'px';
                    }
                });
                resizeObserver.observe(viewerDiv);
            }

        } catch (e) {
            console.warn('Cannot inject styles/scripts into PDF viewer', e);
        }
      };

      body.appendChild(iframe);

    } else {
      var pre = document.createElement('pre');
      pre.textContent = data.content;
      body.appendChild(pre);
    }

    // 4. Highlight Active File in Sidebar
    document.querySelectorAll('.filetree-item-row').forEach(function(el) {
       el.classList.remove('active');
    });

    var relPath = data.relPath ? data.relPath : data.url.replace(/^project_files\\//, '');

    var sidebarItems = document.querySelectorAll('.filetree-item-row');
    sidebarItems.forEach(function(row) {
       if (row.getAttribute('data-path') === relPath) {
           row.classList.add('active');
       }
    });
  });

// Hide File Preview (Restores Editor & Highlights active file)
Shiny.addCustomMessageHandler('hideFilePreview', function(message) {
  var overlay = document.getElementById('filePreviewOverlay');
  var editorSplit = document.getElementById('editorSplit');
  var toolbar = document.getElementById('equation-editor');

  // 1. Swap Views Back
  if (overlay) overlay.style.display = 'none';
  if (toolbar) toolbar.style.display = 'block';
  if (editorSplit) {
    editorSplit.style.display = 'block';
    setTimeout(function() {
      var editor = ace.edit('sourceEditor');
      if(editor) editor.resize();
    }, 50);
  }

  // 2. Re-highlight the Code File in Sidebar
  // logic: remove active from all -> find specific path -> add active
  var path = null;

  // Handle if message is simple boolean or object
  if (typeof message === 'string') {
    path = message;
  } else if (message && message.path) {
    path = message.path;
  }

  if (path) {
    // Remove highlighting from everything (including the previewed file)
    document.querySelectorAll('.filetree-item-row').forEach(el => el.classList.remove('active'));

    // Find the row with the matching data-path attribute
    // We use CSS.escape for safety, though activePath usually is clean
    try {
      var target = document.querySelector('.filetree-item-row[data-path=\"' + path.replace(/\"/g, '\\\\\"') + '\"]');
      if (target) target.classList.add('active');
    } catch(e) { console.error('Could not highlight file:', e); }
  }
});


/* =================== ADD FILES OVERLAY LOGIC =================== */

function openAddFilesOverlay(targetTabId) {
  var overlay = document.getElementById('addFilesOverlay');
  if (overlay) {
    overlay.classList.add('show');
    document.body.style.overflow = 'hidden';

    // Switch to the requested tab if provided
    if (targetTabId) {
      // Fake an event object or directly call logic
      var navLinks = document.querySelectorAll('#addFilesOverlay .settings-nav .nav-link');
      var targetLink = document.querySelector('#addFilesOverlay .settings-nav .nav-link[href=\"#' + targetTabId + '\"]');
                   if (targetLink) {
                     // Deactivate all
                     navLinks.forEach(l => l.classList.remove('active'));
                     document.querySelectorAll('#addFilesOverlay .tab-pane').forEach(p => p.classList.remove('show', 'active'));

                     // Activate target
                     targetLink.classList.add('active');
                     document.getElementById(targetTabId).classList.add('show', 'active');
                   }
                   }

// Auto-focus input if New File or New Folder
setTimeout(function(){
  if(targetTabId === 'add-file-tab') document.getElementById('newFileNameInput').focus();
  if(targetTabId === 'add-folder-tab') document.getElementById('newFolderNameInput').focus();
}, 100);
}
}

function closeAddFilesOverlay() {
  var overlay = document.getElementById('addFilesOverlay');
  if (overlay) {
    overlay.classList.remove('show');
    document.body.style.overflow = '';
  }
}

function switchAddFilesTab(event, tabId) {
  event.preventDefault();
  // Remove active from all nav links in this overlay
  var navLinks = document.querySelectorAll('#addFilesOverlay .settings-nav .nav-link');
  navLinks.forEach(function(link) { link.classList.remove('active'); });

  // Add active to clicked
  event.currentTarget.classList.add('active');

  // Hide all panes
  var panes = document.querySelectorAll('#addFilesOverlay .tab-pane');
  panes.forEach(function(pane) { pane.classList.remove('show', 'active'); });

  // Show target
  var target = document.getElementById(tabId);
  if (target) target.classList.add('show', 'active');
}

// Close on backdrop click (specific to addFilesOverlay)
document.addEventListener('click', function(e) {
  if (e.target.id === 'addFilesOverlay') {
    closeAddFilesOverlay();
  }
});
// Close on ESC
document.addEventListener('keydown', function(e) {
  if (e.key === 'Escape') {
    var overlay = document.getElementById('addFilesOverlay');
    if (overlay && overlay.classList.contains('show')) closeAddFilesOverlay();
  }
});

/* =================== NEW FILE / FOLDER HANDLERS =================== */

  // New File Button Click
document.getElementById('createNewFileBtn').addEventListener('click', function() {
  var fullFileName = document.getElementById('newFileNameInput').value.trim();

  if (!fullFileName) {
    if(window.showTablerAlert) window.showTablerAlert('warning', 'No file name', 'Please enter a file name', 5000);
    return;
  }

  if (window.Shiny && Shiny.setInputValue) {
    // Send just the name; R will handle parsing extension if needed, or we send it as part of name
    Shiny.setInputValue('createNewFileTrigger', {
      name: fullFileName,
      type: '', // Empty type means R should infer from name
      nonce: Math.random()
    }, {priority: 'event'});
  }

  closeAddFilesOverlay();
  // Reset input
  document.getElementById('newFileNameInput').value = 'name.tex';
});

// New Folder Button Click
document.getElementById('createNewFolderBtn').addEventListener('click', function() {
  var folderName = document.getElementById('newFolderNameInput').value.trim();

  if (!folderName) {
    if(window.showTablerAlert) window.showTablerAlert('warning', 'No folder name', 'Please enter a folder name', 5000);
    return;
  }

  if (window.Shiny && Shiny.setInputValue) {
    Shiny.setInputValue('createNewFolderTrigger', {
      name: folderName,
      nonce: Math.random()
    }, {priority: 'event'});
  }

  closeAddFilesOverlay();
  document.getElementById('newFolderNameInput').value = '';
});

// Handle Enter keys
document.getElementById('newFileNameInput').addEventListener('keypress', function(e) {
  if (e.key === 'Enter') document.getElementById('createNewFileBtn').click();
});
document.getElementById('newFolderNameInput').addEventListener('keypress', function(e) {
  if (e.key === 'Enter') document.getElementById('createNewFolderBtn').click();
});


/* =================== DROPZONE LOGIC UPDATE =================== */
// Updated Dropzone initialization to work with Overlay instead of Modal events
(function() {
  if (typeof Dropzone !== 'undefined') Dropzone.autoDiscover = false;

  var dropzoneInstance = null;
  var uploadBtnListener = null;

  // Blocked extensions (dangerous executables and scripts)
  var blockedExtensions = [
    '.exe','.msi','.bat','.cmd','.com','.scr','.pif',
    '.ps1','.vbs','.js','.jse','.wsf','.wsh',
    '.apk','.app','.deb','.rpm',
    '.dll','.sys','.drv',
    '.jar','.class',
    '.sh','.bash','.zsh',
    '.cgi','.pl','.php','.asp','.aspx','.jsp',
    '.htaccess'
  ];

  function initDropzoneOverlay() {
    var el = document.getElementById('dropzone-upload');
    if (!el) return; // Not ready yet
    if (dropzoneInstance) return; // Already inited

    try {
      dropzoneInstance = new Dropzone('#dropzone-upload', {
        url: 'javascript:void(0)',
        autoProcessQueue: false,
        autoQueue: false,
        uploadMultiple: false,
        parallelUploads: 1,
        maxFiles: 50,
        maxFilesize: 100,
        addRemoveLinks: true,
        clickable: true,
        acceptedFiles: null,

        accept: function(file, done) {
          var name = file.name.toLowerCase();
          var isBlocked = blockedExtensions.some(function(ext) {
            return name.endsWith(ext);
          });

          if (isBlocked) {
            done('This file type is not allowed.');
          } else {
            done();
          }
        },

        init: function() {
          var myDropzone = this;
          var uploadBtn = document.getElementById('processUploadBtn');

          this.on('addedfile', function(file) {
            file.status = Dropzone.SUCCESS;
            file.previewElement.classList.add('dz-success');
          });

          // Upload Button Logic
          if (uploadBtn) {
            uploadBtn.addEventListener('click', function(e) {
              e.preventDefault();
              e.stopPropagation();
              var files = myDropzone.files;
              if (!files || files.length === 0) {
                if(window.showTablerAlert) window.showTablerAlert('warning', 'No files', 'Please add files.', 5000);
                return;
              }

              // Process files (Client-side reading)
              var fileData = [];
              var processed = 0;

              uploadBtn.disabled = true;
              uploadBtn.innerHTML = 'Uploading <span class=\"animated-dots\"></span>';

              files.forEach(function(file) {
                var reader = new FileReader();
                reader.onload = function(evt) {
                  fileData.push({
                    name: file.name, size: file.size, type: file.type||'', data: evt.target.result
                  });
                  processed++;
                  if (processed === files.length) {
                    // Send to Shiny
                    if (window.Shiny && Shiny.setInputValue) {
                      Shiny.setInputValue('dropzoneFiles', { files: fileData, nonce: Math.random() }, {priority:'event'});

                      setTimeout(function() {
                        myDropzone.removeAllFiles();
                        uploadBtn.disabled = false;
                        uploadBtn.innerHTML = 'Upload Selected Files';
                        closeAddFilesOverlay();
                      }, 500);
                    }
                  }
                };
                reader.readAsDataURL(file);
              });
            });
          }
        }
      });
    } catch(e) { console.error('Dropzone init failed', e); }
  }

  // Initialize once DOM is ready
  document.addEventListener('DOMContentLoaded', function() {
    setTimeout(initDropzoneOverlay, 1000);
  });
})();


/* =================== CREATE/EDIT PROJECT OVERLAY LOGIC =================== */

// --- Create Project Overlay ---
function openCreateProjectOverlay(targetTabId) {
  var overlay = document.getElementById('createProjectOverlay');
  if (overlay) {
    overlay.classList.add('show');
    document.body.style.overflow = 'hidden';

    // Clear inputs
    document.getElementById('newProjectName').value = '';
    document.getElementById('newProjectDesc').value = '';
    document.getElementById('uploadProjectName').value = '';
    document.getElementById('uploadProjectDesc').value = '';

    // Switch tab
    if (targetTabId) {
      switchCreateProjectTab(null, targetTabId);
    }
  }
}

function closeCreateProjectOverlay() {
  var overlay = document.getElementById('createProjectOverlay');
  if (overlay) {
    overlay.classList.remove('show');
    document.body.style.overflow = '';
  }
}

function switchCreateProjectTab(event, tabId) {
  if(event) event.preventDefault();

  var navLinks = document.querySelectorAll('#createProjectOverlay .settings-nav .nav-link');
  var panes = document.querySelectorAll('#createProjectOverlay .tab-pane');

  // Deactivate all
  navLinks.forEach(l => l.classList.remove('active'));
  panes.forEach(p => p.classList.remove('show', 'active'));

  // Activate target
  var targetLink = document.querySelector('#createProjectOverlay .settings-nav .nav-link[href=\"#' + tabId + '\"]');
var targetPane = document.getElementById(tabId);

if (targetLink) targetLink.classList.add('active');
if (targetPane) targetPane.classList.add('show', 'active');

// Focus appropriate input
if (tabId === 'create-blank-tab') document.getElementById('newProjectName').focus();
if (tabId === 'create-upload-tab') document.getElementById('uploadProjectName').focus();
}

// --- Edit Project Overlay ---
  function openEditProjectOverlay(id, name, desc) {
    var overlay = document.getElementById('editProjectOverlay');
    if (overlay) {
      document.getElementById('editProjectId').value = id;
      document.getElementById('editProjectName').value = name;
      document.getElementById('editProjectDesc').value = desc;

      overlay.classList.add('show');
      document.body.style.overflow = 'hidden';
    }
  }

function closeEditProjectOverlay() {
  var overlay = document.getElementById('editProjectOverlay');
  if (overlay) {
    overlay.classList.remove('show');
    document.body.style.overflow = '';
  }
}

// Global click/key handlers
document.addEventListener('click', function(e) {
  if (e.target.id === 'createProjectOverlay') closeCreateProjectOverlay();
  if (e.target.id === 'editProjectOverlay') closeEditProjectOverlay();
});
document.addEventListener('keydown', function(e) {
  if (e.key === 'Escape') {
    closeCreateProjectOverlay();
    closeEditProjectOverlay();
  }
});

// --- Button Listeners (Trigger Shiny) ---

  // 1. Create Project from Template
document.getElementById('btnCreateBlank').addEventListener('click', function() {
  var name = document.getElementById('newProjectName').value.trim();
  var desc = document.getElementById('newProjectDesc').value.trim();
  var tmpl = document.getElementById('newProjectTemplate').value;

  if (!name) {
    if(window.showTablerAlert) window.showTablerAlert('warning', 'No project name', 'Please enter a project name', 5000);
    return;
  }

  if (window.Shiny) {
    Shiny.setInputValue('createProjectTrigger', {
      type: 'blank',
      name: name,
      desc: desc,
      template: tmpl,
      nonce: Math.random()
    }, {priority: 'event'});
  }
  closeCreateProjectOverlay();
});

// 2. Save Edit
document.getElementById('btnSaveProjectEdit').addEventListener('click', function() {
  var id = document.getElementById('editProjectId').value;
  var name = document.getElementById('editProjectName').value.trim();
  var desc = document.getElementById('editProjectDesc').value.trim();

  if (!name) {
    if(window.showTablerAlert) window.showTablerAlert('warning', 'No project name', 'Project name cannot be empty', 5000);
    return;
  }

  if (window.Shiny) {
    Shiny.setInputValue('renameProject', {
      id: id,
      name: name,
      desc: desc
    }, {priority: 'event'});
  }
  closeEditProjectOverlay();
});

// --- Project Dropzone Initialization ---
(function() {
  if (typeof Dropzone !== 'undefined') Dropzone.autoDiscover = false;
  var projDropzone = null;

  // Blocked extensions (dangerous executables and scripts)
  var blockedExtensions = [
    '.exe','.msi','.bat','.cmd','.com','.scr','.pif',
    '.ps1','.vbs','.js','.jse','.wsf','.wsh',
    '.apk','.app','.deb','.rpm',
    '.dll','.sys','.drv',
    '.jar','.class',
    '.sh','.bash','.zsh',
    '.cgi','.pl','.php','.asp','.aspx','.jsp',
    '.htaccess'
  ];

  function initProjectDropzone() {
    var el = document.getElementById('dropzone-project');
    if (!el) return;
    if (projDropzone) return;

    try {
      projDropzone = new Dropzone('#dropzone-project', {
        url: 'javascript:void(0)',
        autoProcessQueue: false,
        autoQueue: false,
        uploadMultiple: false,
        parallelUploads: 1,
        maxFiles: 50,
        maxFilesize: 100,
        addRemoveLinks: true,
        clickable: true,
        acceptedFiles: null,

        accept: function(file, done) {
          var name = file.name.toLowerCase();
          var isBlocked = blockedExtensions.some(function(ext) {
            return name.endsWith(ext);
          });

          if (isBlocked) {
            done('This file type is not allowed.');
          } else {
            done();
          }
        },

        init: function() {
          var myDropzone = this;
          var createBtn = document.getElementById('btnCreateFromUpload');

          this.on('addedfile', function(file) {
            file.status = Dropzone.SUCCESS;
            file.previewElement.classList.add('dz-success');
          });

          // Create from Upload Logic
          if (createBtn) {
            createBtn.addEventListener('click', function(e) {
              e.preventDefault();
              var name = document.getElementById('uploadProjectName').value.trim();
              var desc = document.getElementById('uploadProjectDesc').value.trim();
              var files = myDropzone.files;

              if (!name) {
                if(window.showTablerAlert) window.showTablerAlert('warning', 'No project name', 'Please enter a project name', 5000);
                return;
              }

              // We allow creation without files (just acts like blank), but prompt usually implies files
              // Process files if any
              var fileData = [];
              var processed = 0;

              createBtn.disabled = true;
              createBtn.innerHTML = 'Creating <span class=\"animated-dots\"></span>';

              if (files.length === 0) {
                // No files, just send name/desc
                sendToShiny(fileData);
              } else {
                files.forEach(function(file) {
                  var reader = new FileReader();
                  reader.onload = function(evt) {
                    fileData.push({
                      name: file.name, size: file.size, type: file.type||'', data: evt.target.result
                    });
                    processed++;
                    if (processed === files.length) {
                      sendToShiny(fileData);
                    }
                  };
                  reader.readAsDataURL(file);
                });
              }

              function sendToShiny(fData) {
                if (window.Shiny) {
                  Shiny.setInputValue('createProjectTrigger', {
                    type: 'upload',
                    name: name,
                    desc: desc,
                    files: fData,
                    nonce: Math.random()
                  }, {priority:'event'});

                  setTimeout(function() {
                    myDropzone.removeAllFiles();
                    createBtn.disabled = false;
                    createBtn.innerHTML = 'Create from Upload';
                    closeCreateProjectOverlay();
                  }, 500);
                }
              }
            });
          }
        }
      });
    } catch(e) { console.error('Project Dropzone init failed', e); }
  }

  document.addEventListener('DOMContentLoaded', function() {
    setTimeout(initProjectDropzone, 1000);
  });
})();

// --- Archive Import Dropzone Initialization ---
(function() {
  if (typeof Dropzone !== 'undefined') Dropzone.autoDiscover = false;
  var zipDropzone = null;

  function initZipDropzone() {
    var el = document.getElementById('dropzone-import-zip');
    if (!el) return;
    if (zipDropzone) return;

    try {
      zipDropzone = new Dropzone('#dropzone-import-zip', {
        url: 'javascript:void(0)',
        autoProcessQueue: false,
        uploadMultiple: false,
        maxFiles: 1,
        // Update 1: Accept multiple extensions in the file picker
        acceptedFiles: '.zip,.tar,.tar.gz,.tgz',
        addRemoveLinks: true,
        dictDefaultMessage: 'Drop archive file (.zip, .tar, .tar.gz) here',

        // Update 2: Validate against list of extensions
        accept: function(file, done) {
          var validExts = ['.zip', '.tar', '.tar.gz', '.tgz'];
          var fileName = file.name.toLowerCase();
          var isValid = validExts.some(function(ext) {
            return fileName.endsWith(ext);
          });

          if (!isValid) {
            done('Only .zip, .tar, and .tar.gz files are allowed.');
          } else {
            done();
          }
        },

        init: function() {
          var myDropzone = this;
          var importBtn = document.getElementById('btnImportZip');

          this.on('addedfile', function(file) {
            if (file.previewElement) file.previewElement.classList.add('dz-success');
          });

          if (importBtn) {
            importBtn.addEventListener('click', function(e) {
              e.preventDefault();

              var files = myDropzone.files;

              if (files.length === 0) {
                 if(window.showTablerAlert) window.showTablerAlert('warning', 'No files', 'Please drop an archive file first.', 5000);
                 return;
              }

              var file = files[0];
              var customName = document.getElementById('importZipName').value.trim();

              importBtn.disabled = true;
              importBtn.innerHTML = 'Importing<span class=\"animated-dots\"></span>';

              var reader = new FileReader();
              reader.onload = function(evt) {
                 var base64Content = evt.target.result.split(',')[1];

                 if (window.Shiny) {
                   Shiny.setInputValue('importZipTrigger', {
                     filename: file.name,
                     customName: customName,
                     content: base64Content,
                     size: file.size,
                     nonce: Math.random()
                   }, {priority: 'event'});

                   setTimeout(function() {
                     myDropzone.removeAllFiles();
                     document.getElementById('importZipName').value = '';
                     importBtn.disabled = false;
                     importBtn.innerHTML = 'Import Project';
                     closeCreateProjectOverlay();
                   }, 500);
                 }
              };

              reader.onerror = function() {
                 importBtn.disabled = false;
                 importBtn.innerHTML = 'Import Project';
                 alert('Error reading file');
              };

              reader.readAsDataURL(file);
            });
          }
        }
      });
    } catch(e) { console.error('Zip Dropzone init failed', e); }
  }

  document.addEventListener('DOMContentLoaded', function() {
    setTimeout(initZipDropzone, 1000);
  });
})();

/* =================== EDIT PROFILE OVERLAY LOGIC =================== */

function openEditProfileOverlay() {
  var overlay = document.getElementById('editProfileOverlay');
  if (overlay) {
    overlay.classList.add('show');
    document.body.style.overflow = 'hidden';

    // Trigger R to update the input values with current server-side data
    if (window.Shiny) {
      Shiny.setInputValue('editProfileBtn', Date.now(), {priority:'event'});
    }
  }
}

function closeEditProfileOverlay() {
  var overlay = document.getElementById('editProfileOverlay');
  if (overlay) {
    overlay.classList.remove('show');
    document.body.style.overflow = '';
  }
}

function switchEditProfileTab(event, tabId) {
  event.preventDefault();
  var navLinks = document.querySelectorAll('#editProfileOverlay .settings-nav .nav-link');
  var panes = document.querySelectorAll('#editProfileOverlay .tab-pane');

  navLinks.forEach(l => l.classList.remove('active'));
  panes.forEach(p => p.classList.remove('show', 'active'));

  event.currentTarget.classList.add('active');
  document.getElementById(tabId).classList.add('show', 'active');
}

// Close handlers
document.addEventListener('click', function(e) {
  if (e.target.id === 'editProfileOverlay') closeEditProfileOverlay();
});

// Save Button Handler
document.getElementById('saveProfileChangesBtn').addEventListener('click', function() {
  var username = document.getElementById('editProfileUsername').value;
  var email = document.getElementById('editProfileEmail').value;
  var institution = document.getElementById('editProfileInstitution').value;
  var bio = document.getElementById('editProfileBio').value;

  // Note: Profile pic is handled via the Dropzone queue in the init function below

  if (window.Shiny) {
    Shiny.setInputValue('saveProfileChanges', {
      username: username,
      email: email,
      institution: institution,
      bio: bio,
      nonce: Math.random()
    }, {priority: 'event'});
  }

  closeEditProfileOverlay();
});


/* =================== PROFILE PICTURE DROPZONE =================== */
(function() {
  if (typeof Dropzone !== 'undefined') Dropzone.autoDiscover = false;
  var profileDropzone = null;

  function initProfileDropzone() {
    var el = document.getElementById('dropzone-profile');
    if (!el) return;
    if (profileDropzone) return;

    try {
      profileDropzone = new Dropzone('#dropzone-profile', {
        url: 'javascript:void(0)',
        autoProcessQueue: false,
        autoQueue: false,
        uploadMultiple: false,
        maxFiles: 1, // Only 1 profile picture
        maxFilesize: 2, // 2MB limit
        acceptedFiles: 'image/jpeg,image/png,image/gif,image/webp',
        addRemoveLinks: true,

        init: function() {
          var myDropzone = this;

          this.on('addedfile', function(file) {
            // Replace previous file if exists (ensure only 1)
            if (this.files.length > 1) {
              this.removeFile(this.files[0]);
            }
            file.status = Dropzone.SUCCESS;
            file.previewElement.classList.add('dz-success');

            // Read and send immediately when added
            var reader = new FileReader();
            reader.onload = function(evt) {
              if (window.Shiny) {
                // Send raw base64 data to R
                Shiny.setInputValue('dropzoneProfilePic', {
                  name: file.name,
                  type: file.type,
                  data: evt.target.result,
                  nonce: Math.random()
                }, {priority: 'event'});
              }
            };
            reader.readAsDataURL(file);
          });

          this.on('removedfile', function(file) {
             // Optional: Clear on server if removed
          });
        }
      });
    } catch(e) { console.error('Profile Dropzone init failed', e); }
  }

  document.addEventListener('DOMContentLoaded', function() {
    setTimeout(initProfileDropzone, 1000);
  });
})();


// =================== CLOSE SIDEBAR BUTTON ===================
(function() {
  function initCloseSidebarBtn() {
    var closeBtn = document.getElementById('closeSidebarBtn');
    var toggleBtn = document.getElementById('railSidebarToggle');

    if (!closeBtn || !toggleBtn) {
      return false;
    }

    closeBtn.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();

      // Trigger the main toggle
      toggleBtn.click();

    });

    return true;
  }

  // Try to initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      setTimeout(initCloseSidebarBtn, 100);
    });
  } else {
    setTimeout(initCloseSidebarBtn, 100);
  }
})();

// =================== FILES PANE COLLAPSE/EXPAND ===================
(function() {
  function initFilesPaneCollapse() {
    var toggleBtn = document.getElementById('toggleFilesPane');
    var chevron = document.getElementById('filesPaneChevron');
    var paneBody = document.getElementById('filesPaneBody');

    if (!toggleBtn || !chevron || !paneBody) {
      return false;
    }

    // Load saved state from localStorage
    var isCollapsed = localStorage.getItem('mudskipper.filesPaneCollapsed') === 'true';

    // Apply initial state
    if (isCollapsed) {
      paneBody.classList.add('collapsed');
      chevron.classList.add('rotated');
      // Synchronize outline pane - move it up
      setTimeout(function() {
        if (window.syncOutlinePane) {
          window.syncOutlinePane.collapse();
        }
      }, 150);
    }

    // Toggle handler
    toggleBtn.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();

      var willCollapse = !paneBody.classList.contains('collapsed');

      if (willCollapse) {
        // Files pane is collapsing
        paneBody.classList.add('collapsed');
        chevron.classList.add('rotated');
        localStorage.setItem('mudskipper.filesPaneCollapsed', 'true');

        // Synchronize: collapse outline pane header to top
        setTimeout(function() {
          if (window.sidebarVSplit) {
            // Calculate header height as percentage
            var filesPane = document.getElementById('filesPane');
            var outlinePane = document.getElementById('outlinePane');
            if (filesPane && outlinePane) {
              var filesHeader = filesPane.querySelector('.pane-header');
              if (filesHeader) {
                var headerPx = filesHeader.offsetHeight;
                var totalPx = filesPane.parentElement.offsetHeight;
                var headerPct = Math.max((headerPx / totalPx) * 100, 8);

                // Set outline pane to fill remaining space
                window.sidebarVSplit.setSizes([headerPct, 100 - headerPct]);
              }
            }
          }
        }, 50);

      } else {
        // Files pane is expanding
        paneBody.classList.remove('collapsed');
        chevron.classList.remove('rotated');
        localStorage.setItem('mudskipper.filesPaneCollapsed', 'false');

        // Synchronize: restore outline pane to saved position
        setTimeout(function() {
          if (window.sidebarVSplit) {
            var savedSizes = localStorage.getItem('mudskipper.outlineLastSizes');
            var sizes = savedSizes ? JSON.parse(savedSizes) : [50, 50];
            if (!Array.isArray(sizes) || sizes.length !== 2) sizes = [50, 50];
            window.sidebarVSplit.setSizes(sizes);
          }
        }, 50);
      }
    });

    return true;
  }

  // Try to initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      setTimeout(initFilesPaneCollapse, 100);
    });
  } else {
    setTimeout(initFilesPaneCollapse, 100);
  }
})();

// =================== OUTLINE PANE COLLAPSE/EXPAND ===================
(function() {
  function initOutlinePaneCollapse() {
    var toggleBtn = document.getElementById('toggleOutlinePane');
    var chevron = document.getElementById('outlinePaneChevron');
    var paneBody = document.getElementById('outlinePaneBody');

    if (!toggleBtn || !chevron || !paneBody) {
      return false;
    }

    // Load saved state from localStorage
    var isCollapsed = localStorage.getItem('mudskipper.outlinePaneCollapsed') === 'true';

    // Apply initial state
    if (isCollapsed) {
      paneBody.classList.add('collapsed');
      chevron.classList.add('rotated');
    }

    // Toggle handler
    toggleBtn.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();

      var willCollapse = !paneBody.classList.contains('collapsed');

      if (willCollapse) {
        // Outline body is collapsing
        paneBody.classList.add('collapsed');
        chevron.classList.add('rotated');
        localStorage.setItem('mudskipper.outlinePaneCollapsed', 'true');

        // Synchronize Split.js - move outline header to bottom
        setTimeout(function() {
          if (window.sidebarVSplit) {
            var outlinePane = document.getElementById('outlinePane');
            if (outlinePane) {
              var header = outlinePane.querySelector('.pane-header');
              if (header) {
                var headerPx = header.offsetHeight;
                var totalPx = outlinePane.parentElement.offsetHeight;
                var headerPct = Math.max((headerPx / totalPx) * 100, 8);

                window.sidebarVSplit.setSizes([100 - headerPct, headerPct]);
              }
            }
          }
        }, 50);

      } else {
        // Outline body is expanding
        paneBody.classList.remove('collapsed');
        chevron.classList.remove('rotated');
        localStorage.setItem('mudskipper.outlinePaneCollapsed', 'false');

        // Synchronize Split.js - restore to saved position
        setTimeout(function() {
          if (window.sidebarVSplit) {
            var savedSizes = localStorage.getItem('mudskipper.outlineLastSizes');
            var sizes = savedSizes ? JSON.parse(savedSizes) : [50, 50];
            if (!Array.isArray(sizes) || sizes.length !== 2) sizes = [50, 50];
            window.sidebarVSplit.setSizes(sizes);
          }
        }, 50);
      }
    });

    return true;
  }

  // Try to initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      setTimeout(initOutlinePaneCollapse, 100);
    });
  } else {
    setTimeout(initOutlinePaneCollapse, 100);
  }
})();

// =================== CONSOLE TAB SWITCHING & BADGE LOGIC ===================

// Global helper to determine if badge should be hidden
window.checkErrorBadgeVisibility = function() {
  var btn = document.getElementById('railErrorLogBtn');
  if (!btn) return;

  // 1. Check if panel is physically open
  var isExpanded = false;
  if (window.consolePane && typeof window.consolePane.isCollapsed === 'function') {
    isExpanded = !window.consolePane.isCollapsed();
  }

  // 2. Check if the 'errors' tab is currently selected
  var errTab = document.querySelector('.console-tab[data-tab=\"errors\"]');
  var isErrorTabActive = errTab ? errTab.classList.contains('active') : false;

  // LOGIC: Hide ONLY if Expanded AND Error Tab is Active
  if (isExpanded && isErrorTabActive) {
    btn.classList.add('hide-badge');
  } else {
    btn.classList.remove('hide-badge');
  }
};

window.switchConsoleTab = function(tab) {
  // Update tab active states
  document.querySelectorAll('.console-tab').forEach(function(t) {
    t.classList.remove('active');
  });

  // Only add active class if the tab exists
  var targetTab = document.querySelector('.console-tab[data-tab=\"' + tab + '\"]');
  if (targetTab) targetTab.classList.add('active');

  // Show/hide content - hide all first
  var errConsole = document.getElementById('errorLogConsole');
  var dockConsole = document.getElementById('dockerConsole');

  if (errConsole) errConsole.classList.remove('active');
  if (dockConsole) dockConsole.classList.remove('active');

  // Show the selected tab
  if (tab === 'errors' && errConsole) {
    errConsole.classList.add('active');
  } else if (tab === 'console' && dockConsole) {
    dockConsole.classList.add('active');
  }

  // Re-evaluate badge visibility
  if (window.checkErrorBadgeVisibility) window.checkErrorBadgeVisibility();
};

// =================== ERROR LOG CONSOLE ===================
(function() {
  var currentFilter = 'all'; // CHANGED: Default is now 'all'
  var allAnnotations = [];

  // Toggle error log console
  window.toggleErrorLog = function() {
    // 1. Always switch to errors tab
    window.switchConsoleTab('errors');

    // 2. Ensure the pane is expanded
    if (window.consolePane) {
      if (window.consolePane.isCollapsed()) {
        window.consolePane.expand();
      }
    }
  };

  // Update badge on rail button
  function updateErrorBadge(errorCount, warningCount, infoCount) {
    var badge = document.getElementById('errorLogBadge');
    if (!badge) return;

    var total = errorCount + warningCount + infoCount;

    if (total === 0) {
      badge.classList.remove('show');
      return;
    }

    badge.textContent = total;
    badge.classList.add('show');

    badge.classList.remove('text-red-fg', 'bg-red-lt');
    badge.classList.remove('text-orange-fg', 'bg-orange-lt');
    badge.classList.remove('text-blue-fg', 'bg-blue-lt');

    if (errorCount > 0) {
      badge.classList.add('text-red-fg', 'bg-red');
    } else if (warningCount > 0) {
      badge.classList.add('text-orange-fg', 'bg-orange');
    } else if (infoCount > 0) {
      badge.classList.add('text-blue-fg', 'bg-blue');
    }
  }

  // Update error log display
  window.updateErrorLog = function(annotations) {
    allAnnotations = annotations || [];

    // SORTING LOGIC: Errors (1) -> Warnings (2) -> Info (3), then by line number
    allAnnotations.sort(function(a, b) {
      var priority = { 'error': 1, 'warning': 2, 'info': 3 };
      var pA = priority[a.type] || 4;
      var pB = priority[b.type] || 4;

      if (pA !== pB) {
        return pA - pB;
      }
      return a.row - b.row;
    });

    // Count by type
    var errorCount = 0;
    var warningCount = 0;
    var infoCount = 0;

    allAnnotations.forEach(function(ann) {
      if (ann.type === 'error') errorCount++;
      else if (ann.type === 'warning') warningCount++;
      else infoCount++;
    });

    var totalCount = errorCount + warningCount + infoCount;

    // Update counts in tabs
    var elAll = document.getElementById('allCount');
    if(elAll) elAll.textContent = totalCount;

    document.getElementById('errorCount').textContent = errorCount;
    document.getElementById('warningCount').textContent = warningCount;
    document.getElementById('infoCount').textContent = infoCount;

    // Update badge
    updateErrorBadge(errorCount, warningCount, infoCount);

    // Render filtered items
    renderErrorLog(currentFilter);
  };

  function renderErrorLog(filter) {
    var body = document.getElementById('errorLogBody');
    if (!body) return;

    // Filter logic
    var filtered = allAnnotations.filter(function(ann) {
      return filter === 'all' || ann.type === filter;
    });

    if (filtered.length === 0) {
      // Determine message based on filter
      var msg = 'No problems detected';
      if (filter !== 'all') {
        msg = 'No ' + filter.charAt(0).toUpperCase() + filter.slice(1) + 's detected';
      }

      body.innerHTML = '<div class=\"error-log-empty\">' +
      '<p>' + msg + '</p>' +
        '</div>';
      return;
    }

    var html = '';
    filtered.forEach(function(ann) {
      var icon = '';
      if (ann.type === 'error') {
        icon = '<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><circle cx=\"12\" cy=\"12\" r=\"10\"></circle><line x1=\"12\" y1=\"8\" x2=\"12\" y2=\"12\"></line><line x1=\"12\" y1=\"16\" x2=\"12.01\" y2=\"16\"></line></svg>';
      } else if (ann.type === 'warning') {
        icon = '<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z\"></path><line x1=\"12\" y1=\"9\" x2=\"12\" y2=\"13\"></line><line x1=\"12\" y1=\"17\" x2=\"12.01\" y2=\"17\"></line></svg>';
      } else {
        icon = '<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><circle cx=\"12\" cy=\"12\" r=\"10\"></circle><line x1=\"12\" y1=\"16\" x2=\"12\" y2=\"12\"></line><line x1=\"12\" y1=\"8\" x2=\"12.01\" y2=\"8\"></line></svg>';
      }

      html += '<div class=\"error-log-item ' + ann.type + '\" data-line=\"' + ann.row + '\">' +
        '<div class=\"error-log-item-header\">' +
        '<div class=\"error-log-type\">' + icon + ' ' + ann.type.charAt(0).toUpperCase() + ann.type.slice(1) + '</div>' +
        '<div class=\"error-log-line\">Line ' + (ann.row + 1) + ', Col ' + (ann.column + 1) + '</div>' +
        '</div>' +
        '<div class=\"error-log-message\">' + ann.text + '</div>' +
        '</div>';
    });

    body.innerHTML = html;

    // Add click handlers
    body.querySelectorAll('.error-log-item').forEach(function(item) {
      item.addEventListener('click', function() {
        var line = parseInt(this.getAttribute('data-line'));
        if (window.Shiny && Shiny.setInputValue) {
          Shiny.setInputValue('errorLogGoTo', {line: line, nonce: Math.random()}, {priority: 'event'});
        }
      });
    });
  }

  // Tab switching within error log
  document.addEventListener('click', function(e) {
    var tab = e.target.closest('.error-log-tab');
    if (!tab) return;

    // Update active tab
    document.querySelectorAll('.error-log-tab').forEach(function(t) {
      t.classList.remove('active');
    });
    tab.classList.add('active');

    // Update filter and render
    currentFilter = tab.getAttribute('data-filter');
    renderErrorLog(currentFilter);
  });

  window.updateErrorLog([]);

})();


// ============== Settings Overlay Functions ==============

function switchSettingsTab(event, tabId) {
  event.preventDefault();

  // Remove active from all nav links
  var navLinks = document.querySelectorAll('.settings-nav .nav-link');
  navLinks.forEach(function(link) {
    link.classList.remove('active');
  });

  // Add active to clicked link
  event.currentTarget.classList.add('active');

  // Hide all tab panes
  var panes = document.querySelectorAll('.settings-content .tab-pane');
  panes.forEach(function(pane) {
    pane.classList.remove('show', 'active');
  });

  // Show target pane
  var targetPane = document.getElementById(tabId);
  if (targetPane) {
    targetPane.classList.add('show', 'active');
  }
}

function openSettingsOverlay() {
  var overlay = document.getElementById('settingsOverlay');
  if (overlay) {
    overlay.classList.add('show');
    document.body.style.overflow = 'hidden';

    // Initialize form with current settings
    setTimeout(initializeSettingsForm, 100);
  }
}

function closeSettingsOverlay() {
  var overlay = document.getElementById('settingsOverlay');
  if (overlay) {
    overlay.classList.remove('show');
    document.body.style.overflow = '';
  }
}

function initializeSettingsForm() {
  var form = document.getElementById('settingsOverlayForm');
  if (!form) return;

  var themeConfig = {
    'theme': 'dark',
    'theme-base': 'zinc',
    'theme-font': 'sans-serif',
    'theme-primary': 'green',
    'theme-radius': '1',
  };

  for (var key in themeConfig) {
    var value = window.localStorage['tabler-' + key] || themeConfig[key];
    if (value) {
      var inputs = form.querySelectorAll('[name=\\'' + key + '\\']');
      inputs.forEach(function(input) {
        if (input.value === value) {
          input.checked = true;
          input.setAttribute('checked', 'checked');
        } else {
          input.checked = false;
          input.removeAttribute('checked');
        }
      });
    }
  }
}

// Close on backdrop click
document.addEventListener('click', function(e) {
  if (e.target.id === 'settingsOverlay') {
    closeSettingsOverlay();
  }
});

// Close on ESC
document.addEventListener('keydown', function(e) {
  if (e.key === 'Escape') {
    var overlay = document.getElementById('settingsOverlay');
    if (overlay && overlay.classList.contains('show')) {
      closeSettingsOverlay();
    }
  }
});

// Settings form change handler
document.addEventListener('DOMContentLoaded', function() {
  var form = document.getElementById('settingsOverlayForm');
  if (!form) return;

  var url = new URL(window.location);

  form.addEventListener('change', function(event) {
    var target = event.target;
    var name = target.name;
    var value = target.value;

    document.documentElement.setAttribute('data-bs-' + name, value);
    window.localStorage.setItem('tabler-' + name, value);
    url.searchParams.set(name, value);
    window.history.pushState({}, '', url);
  });

  // Reset button
  var resetBtn = document.getElementById('reset-settings-overlay');
  if (resetBtn) {
    resetBtn.addEventListener('click', function() {
      var themeConfig = {
        'theme': 'dark',
        'theme-base': 'zinc',
        'theme-font': 'sans-serif',
        'theme-primary': 'green',
        'theme-radius': '1',
      };

      for (var key in themeConfig) {
        var value = themeConfig[key];
        document.documentElement.setAttribute('data-bs-' + key, value);
        window.localStorage.removeItem('tabler-' + key);
        url.searchParams.delete(key);
      }

      initializeSettingsForm();
      window.history.pushState({}, '', url);
    });
  }

  // Save button
  var saveBtn = document.getElementById('save-settings-overlay');
  if (saveBtn) {
    saveBtn.addEventListener('click', function() {
      var params = [];
      params.push('theme=' + form.querySelector('[name=\\'theme\\']:checked').value);
      params.push('theme-primary=' + form.querySelector('[name=\\'theme-primary\\']:checked').value);
      params.push('theme-font=' + form.querySelector('[name=\\'theme-font\\']:checked').value);
      params.push('theme-base=' + form.querySelector('[name=\\'theme-base\\']:checked').value);
      params.push('theme-radius=' + form.querySelector('[name=\\'theme-radius\\']:checked').value);

      window.location.href = window.location.pathname + '?' + params.join('&');
    });
  }

  // Initialize form when opened
  setTimeout(initializeSettingsForm, 200);
});

function openPresentationMode() {
  // We use the custom HTML viewer we generated in app.R
  // It handles PDF.js rendering and slides logic

  var pdfUrl = '/compiled/output.pdf?t=' + Date.now();
  var viewerUrl = 'presentation.html?file=' + encodeURIComponent(pdfUrl);

  // Open in new window
  var presentationWindow = window.open(
    viewerUrl,
    'MudskipperPresentation',
    'width=' + screen.width + ',height=' + screen.height + ',menubar=no,toolbar=no,location=no,status=no'
  );

  if (presentationWindow) {
    if (window.showTablerAlert) {
      window.showTablerAlert('info', 'Presentation mode',
        'Click anywhere in the new window to enter fullscreen.', 5000);
    }
  } else {
    if (window.showTablerAlert) {
      window.showTablerAlert('warning', 'Popup blocked',
        'Please allow popups for this site to use presentation mode.', 5000);
    }
  }
}


Shiny.addCustomMessageHandler('enableInlineRename', function(data) {
    var path = data.path;

    // Robust selector handling for special characters
    var row = document.querySelector('.filetree-item-row[data-path=\"' + CSS.escape(path) + '\"]');
    if (!row) return;

    var labelSpan = row.querySelector('.filetree-label');
    if (!labelSpan) return;

    // 1. ROBUST TEXT EXTRACTION
    // Clone node to safely manipulate without affecting DOM yet
    var clone = labelSpan.cloneNode(true);
    // Remove icons/badges (any child elements), leaving only text nodes
    Array.from(clone.children).forEach(function(child) { child.remove(); });
    var currentName = clone.textContent.trim();

    // Fallback: If text extraction fails, assume it's the basename of the path
    if (!currentName) {
       var parts = path.split(/[\\\\/]/);
       currentName = parts[parts.length - 1];
    }

    var originalHTML = labelSpan.innerHTML;

    // Disable dragging
    row.setAttribute('draggable', 'false');

    // Create Input
    var input = document.createElement('input');
    input.type = 'text';
    input.value = currentName;
    input.className = 'rename-input';

    // Swap content
    labelSpan.innerHTML = '';
    labelSpan.appendChild(input);
    input.focus();

    // Intelligent selection (exclude extension)
    var dotIndex = currentName.lastIndexOf('.');
    if (dotIndex > 0) {
      input.setSelectionRange(0, dotIndex);
    } else {
      input.select();
    }

    var isSaving = false;

    function save() {
      if (isSaving) return;
      isSaving = true;

      var newName = input.value.trim();

      // If empty or unchanged, just cancel
      if (newName === '' || newName === currentName) {
         cancel();
         return;
      }

      Shiny.setInputValue('confirmInlineRename', {
        oldPath: path,
        newName: newName,
        nonce: Math.random()
      }, {priority: 'event'});

      // Temporary visual feedback (R will refresh the tree shortly)
      labelSpan.innerHTML = originalHTML;
    }

    function cancel() {
      isSaving = true;
      labelSpan.innerHTML = originalHTML;
      row.setAttribute('draggable', 'true');
    }

    // Bind Events
    input.addEventListener('click', function(e) { e.stopPropagation(); });
    input.addEventListener('dblclick', function(e) { e.stopPropagation(); });

    input.addEventListener('keydown', function(e) {
      if (e.key === 'Enter') {
        e.preventDefault();
        save();
      } else if (e.key === 'Escape') {
        e.preventDefault();
        cancel();
      }
      e.stopPropagation();
    });

    input.addEventListener('blur', function() {
      setTimeout(save, 100);
    });
  });


  // Files spinner toggle
Shiny.addCustomMessageHandler('toggleFilesSpinner', function(show) {
  var spinner = document.getElementById('filesSpinner');
  if (spinner) {
    spinner.style.display = show ? 'inline-block' : 'none';
  }
});

Shiny.addCustomMessageHandler('toggleHistoryFilesSpinner', function(show) {
  var spinner = document.getElementById('historyFilesSpinner');
  if (spinner) {
    spinner.style.display = show ? 'inline-block' : 'none';
  }
});

Shiny.addCustomMessageHandler('toggleHistoryVersionsSpinner', function(show) {
  var spinner = document.getElementById('historyVersionsSpinner');
  if (spinner) {
    spinner.style.display = show ? 'inline-block' : 'none';
  }
});

// Outline spinner toggle
Shiny.addCustomMessageHandler('toggleOutlineSpinner', function(show) {
  var spinner = document.getElementById('outlineSpinner');
  if (spinner) {
    spinner.style.display = show ? 'inline-block' : 'none';
  }
});


// Editor spinner toggle
Shiny.addCustomMessageHandler('toggleEditorSpinner', function(show) {
  var spinner = document.getElementById('editorSpinner');
  if (spinner) {
    spinner.style.display = show ? 'inline-block' : 'none';
  }
});

/* =================== PDF Invert (Persistence + Toggle) =================== */
(function() {
  var PDF_INVERT_KEY = 'mudskipper.pdfInverted';

  // 1. Function to apply saved state
  function loadPdfInvertState() {
    var container = document.getElementById('pdfContainer');
    // Check if key exists and is 'true'
    if (container && localStorage.getItem(PDF_INVERT_KEY) === 'true') {
      container.classList.add('inverted');
    }
  }

  // 2. Run immediately on load
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', loadPdfInvertState);
  } else {
    loadPdfInvertState();
  }

  // 3. Toggle Listener with Save Logic
  document.addEventListener('click', function(e) {
    if (e.target.closest('#btnInvertPDF')) {
      var container = document.getElementById('pdfContainer');
      if (container) {
        // Toggle class and get the new boolean state
        var isNowInverted = container.classList.toggle('inverted');

        // Save to LocalStorage
        localStorage.setItem(PDF_INVERT_KEY, isNowInverted);

        // Force browser repaint (fix for PDF plugin rendering issues)
        var oldDisplay = container.style.display;
        container.style.display = 'none';
        container.offsetHeight; // trigger reflow
        container.style.display = oldDisplay;
      }
    }
  });
})();



/* =================== PDF CONTROLS SYSTEM =================== */
(function() {
  function getPdfWindow() {
    var iframe = document.getElementById('pdfIframe');
    return (iframe && iframe.contentWindow) ? iframe.contentWindow : null;
  }

  // --- 1. Button Handlers ---
  window.pdfZoomIn = function() {
    var win = getPdfWindow(); if(win && win.zoomIn) win.zoomIn();
  };
  window.pdfZoomOut = function() {
    var win = getPdfWindow(); if(win && win.zoomOut) win.zoomOut();
  };

  // FIXED: Explicit Zoom Setter for Dropdown (50%, 75%...)
  window.pdfSetZoom = function(scaleFactor) {
    var win = getPdfWindow();
    if(win && win.setZoom) {
        // scaleFactor comes in as float (e.g. 1.5)
        win.setZoom(parseFloat(scaleFactor));
    }
  };

  window.pdfFitToWidth = function() {
    var win = getPdfWindow(); if(win && win.fitWidth) win.fitWidth();
  };
  window.pdfFitToHeight = function() {
    var win = getPdfWindow(); if(win && win.fitHeight) win.fitHeight();
  };

  // --- 2. Navigation Handlers ---
  window.pdfNextPage = function() {
    var win = getPdfWindow();
    var input = document.getElementById('pdfPageInput');
    var cur = parseInt(input.value) || 1;
    var totalEl = document.getElementById('pdfTotalPages');
    var total = totalEl ? parseInt(totalEl.innerText) : 1;

    if(cur < total) {
       // Optimistically update UI
       input.value = cur + 1;
       if(win && win.goToPage) win.goToPage(cur + 1);
    }
  };

  window.pdfPreviousPage = function() {
    var win = getPdfWindow();
    var input = document.getElementById('pdfPageInput');
    var cur = parseInt(input.value) || 1;
    if(cur > 1) {
       input.value = cur - 1;
       if(win && win.goToPage) win.goToPage(cur - 1);
    }
  };

  window.pdfGoToPage = function(pageNum) {
    var win = getPdfWindow();
    if(win && win.goToPage) win.goToPage(pageNum);
  };

window.pdfDownload = function() {
    // 1. Determine where the URL is coming from
    var src = \"\";
    var iframe = document.getElementById('pdfIframe');

    if (iframe) {
        // Context: Main Window (we need to look at the iframe's source)
        src = iframe.getAttribute('src');
    } else {
        // Context: Inside the Viewer (we use the current location)
        src = window.location.href;
    }

    if (!src) {
        showTablerAlert(\"error\",\"PDF download failed: No PDF source found (Viewer might be empty).\");
        return;
    }

    // 2. Extract the 'file' parameter using Regex
    // (This safely finds '?file=...' or '&file=...' in the string)
    var match = src.match(/[?&]file=([^&]+)/);

    if (match && match[1]) {
        var path = decodeURIComponent(match[1]);

        // 3. Trigger Download
        var link = document.createElement('a');
        // Ensure we handle existing query params correctly when adding the timestamp
        var separator = path.includes('?') ? '&' : '?';
        link.href = path + separator + 'download_t=' + Date.now();
        link.download = 'document.pdf';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    } else {
        showTablerAlert(\"error\",\"PDF download failed: Could not extract file path from URL.\");
    }
};

  // --- 4. Listeners (Update Inputs from Viewer) ---
  window.addEventListener('message', function(e) {
    var data = e.data;
    if (!data) return;

    if (data.type === 'pdfLoaded') {
      var totalEl = document.getElementById('pdfTotalPages');
      var inputEl = document.getElementById('pdfPageInput');
      if (totalEl) totalEl.innerText = data.pages;
      if (inputEl) inputEl.max = data.pages;
    }
    else if (data.type === 'pageChange') {
      var inputEl = document.getElementById('pdfPageInput');
      // Only update if user is not focussed on input to avoid typing conflicts
      if (inputEl && document.activeElement !== inputEl) {
        inputEl.value = data.page;
      }
    }
    else if (data.type === 'zoomChange') {
      var zoomEl = document.getElementById('pdfZoomPercent');
      if (zoomEl) zoomEl.innerText = data.zoom + '%';
    }
  });
})();


// =================== FILE SEARCH LOGIC ===================
(function() {

  // Debounce Input
  var searchTimeout;
  document.addEventListener('input', function(e) {
    if (e.target.id === 'txtFileSearch') {
      clearTimeout(searchTimeout);
      searchTimeout = setTimeout(function() {
        var val = e.target.value;
        if (window.Shiny) {
          Shiny.setInputValue('fileSearchQuery', val, {priority: 'event'});
        }
      }, 400); // 400ms debounce
    }
  });
})();

/* =================== REVIEW & COMMENT SYSTEM =================== */

window.closeReviewPane = function() {
  Shiny.setInputValue('toggleReviewPane', false, {priority:'event'});
};

// 2. Selection Listener for 'Add Comment' Popup
(function() {
  function initCommentTooltip() {
    var editor = ace.edit('sourceEditor');
    var tooltip = document.getElementById('ace-comment-tooltip');
    if(!editor || !tooltip) return;

    editor.selection.on('changeSelection', function() {
      if (!editor.selection.isEmpty()) {
        var range = editor.selection.getRange();

        // 1. Get screen coordinates of the END of the selection
        var screenPos = editor.renderer.textToScreenCoordinates(range.end.row, range.end.column);
        var lineHeight = editor.renderer.lineHeight || 20;

        // 2. Default: Place immediately at the bottom of the line
        // Use 'fixed' to align perfectly with screen coordinates regardless of parents
        tooltip.style.position = 'fixed';
        var top = screenPos.pageY + lineHeight;
        var left = screenPos.pageX;

        // 3. Boundary Check: Highlighting near bottom of screen?
        // Assume tooltip height is approx 35px. If it goes off-screen, flip to top.
        if (top + 35 > window.innerHeight) {
           // Position ABOVE the line (Top of line - Tooltip Height)
           top = screenPos.pageY - 35;
        }

        // Apply
        tooltip.style.top = top + 'px';
        tooltip.style.left = left + 'px';
        tooltip.style.display = 'block';
      } else {
        tooltip.style.display = 'none';
      }
    });

    // Hide tooltip on scroll/type
    editor.session.on('change', function() { tooltip.style.display = 'none'; });
    editor.session.on('changeScrollTop', function() { tooltip.style.display = 'none'; });
  }

  // Wait for Ace
  var checkAce = setInterval(function() {
    if (window.ace && ace.edit('sourceEditor')) {
      clearInterval(checkAce);
      initCommentTooltip();
    }
  }, 500);
})();

// 3. Trigger Add Comment (Sends Data to R)
window.triggerAddComment = function() {
  var editor = ace.edit('sourceEditor');
  var range = editor.getSelectionRange();
  var text = editor.session.getTextRange(range);

  if (!text.trim()) return;

  // Send to Shiny
  Shiny.setInputValue('addCommentTrigger', {
    text: text,
    startRow: range.start.row,
    startCol: range.start.column,
    endRow: range.end.row,
    endCol: range.end.column,
    nonce: Math.random()
  }, {priority: 'event'});

  // Hide tooltip
  document.getElementById('ace-comment-tooltip').style.display = 'none';
};

// 4. Manage Highlights (Markers) & Persistence Fix
window.commentMarkers = [];

Shiny.addCustomMessageHandler('renderCommentMarkers', function(comments) {
  var editor = ace.edit('sourceEditor');
  if(!editor) return;
  var session = editor.getSession();
  var Range = ace.require('ace/range').Range;

  // Clear old markers first (Fix for persistence issue)
  if (window.commentMarkers && window.commentMarkers.length > 0) {
    window.commentMarkers.forEach(function(id) {
      session.removeMarker(id);
    });
  }
  window.commentMarkers = [];

  if (!comments || comments.length === 0) return;

  comments.forEach(function(c) {
    if (!c.resolved) {
      var range = new Range(c.startRow, c.startCol, c.endRow, c.endCol);
      var markerId = session.addMarker(range, 'ace_comment_highlight', 'text');
      window.commentMarkers.push(markerId);
    }
  });
});

// Helper to show reply box
window.toggleReplyBox = function(id) {
  var box = document.getElementById('reply-box-' + id);
  if(box) box.classList.toggle('show');
};

/* =================== PREMIUM REVIEW SYSTEM LOGIC (PRODUCTION READY) =================== */
(function() {
  // Registry: { id: { startAnchor, endAnchor, markerId, resolved, originalCoords... } }
  window.activeCommentAnchors = {};
  var syncQueue = {}; // Queue for changes waiting to be sent to R
  var syncTimer = null;
  var isRendering = false; // Semaphore to prevent loops

  // Ace Modules
  var Anchor = ace.require('ace/anchor').Anchor;
  var Range = ace.require('ace/range').Range;

  // --- 1. CORE: RENDER & SYNC MARKERS (R -> JS) ---
  Shiny.addCustomMessageHandler('renderCommentMarkers', function(payload) {
    // payload structure: { comments: [...], force: bool }
    var comments = payload.comments || [];
    var forceRefresh = payload.force || false;

    var editor = ace.edit('sourceEditor');
    if(!editor || !editor.getSession()) return;

    var session = editor.getSession();
    var doc = session.getDocument();
    isRendering = true; // Block sync while rendering from R

    // A. Cleanup deleted comments
    var newIds = comments.map(function(c){ return c.id; });
    Object.keys(window.activeCommentAnchors).forEach(function(id) {
      if (!newIds.includes(id) || forceRefresh) {
        var obj = window.activeCommentAnchors[id];
        session.removeMarker(obj.markerId);
        if(obj.startAnchor) obj.startAnchor.detach();
        if(obj.endAnchor) obj.endAnchor.detach();
        delete window.activeCommentAnchors[id];
      }
    });

    // B. Create/Update Anchors
    comments.forEach(function(c) {
      if (c.resolved) return; // Do not render resolved highlights

      if (window.activeCommentAnchors[c.id]) {
        // --- EXISTING: Validate Position ---
        // If R sends different coordinates than our live anchors,
        // it means we reloaded the file. We must trust R's saved state on file load.
        if (forceRefresh) {
           updateLocalAnchorFromData(c, doc, session);
        } else {
           // Ensure visual marker exists (Ace sometimes wipes markers on redraws)
           ensureMarkerExists(c.id, session);
        }
      } else {
        // --- NEW: Create Anchors ---
        createLocalAnchor(c, doc, session);
      }
    });

    isRendering = false;
    highlightActiveComment(); // Re-eval active highlight
  });

function createLocalAnchor(c, doc, session) {
  var startAnchor = new Anchor(doc, c.startRow, c.startCol);
  var endAnchor = new Anchor(doc, c.endRow, c.endCol);

  // ✅ Store listener so we can reattach later
  var onChange = function() {
    if(isRendering) return;
    refreshMarkerPosition(c.id, session);
    queueSync(c.id);
  };
  startAnchor.on('change', onChange);
  endAnchor.on('change', onChange);

  var range = new Range(c.startRow, c.startCol, c.endRow, c.endCol);
  var markerId = session.addMarker(range, 'ace_comment_highlight', 'text');

  window.activeCommentAnchors[c.id] = {
    startAnchor: startAnchor,
    endAnchor: endAnchor,
    markerId: markerId,
    onChange: onChange  // ✅ STORED
  };
}

function updateLocalAnchorFromData(c, doc, session) {
  var obj = window.activeCommentAnchors[c.id];
  // Detach old
  obj.startAnchor.detach();
  obj.endAnchor.detach();
  session.removeMarker(obj.markerId);

  // Recreate anchors
  var startAnchor = new Anchor(doc, c.startRow, c.startCol);
  var endAnchor = new Anchor(doc, c.endRow, c.endCol);

  // ✅ RE-ATTACH listener (reuse stored, or create new)
  var onChange = obj.onChange || function() {
    if(isRendering) return;
    refreshMarkerPosition(c.id, session);
    queueSync(c.id);
  };
  startAnchor.on('change', onChange);
  endAnchor.on('change', onChange);

  var range = new Range(c.startRow, c.startCol, c.endRow, c.endCol);
  var markerId = session.addMarker(range, 'ace_comment_highlight', 'text');

  window.activeCommentAnchors[c.id] = {
    startAnchor: startAnchor,
    endAnchor: endAnchor,
    markerId: markerId,
    onChange: onChange
  };
}

  function ensureMarkerExists(id, session) {
    var obj = window.activeCommentAnchors[id];
    var markers = session.getMarkers();
    if (!markers[obj.markerId]) {
       var range = new Range(
         obj.startAnchor.row, obj.startAnchor.column,
         obj.endAnchor.row, obj.endAnchor.column
       );
       obj.markerId = session.addMarker(range, 'ace_comment_highlight', 'text');
    }
  }

  // --- 2. LOCAL UPDATE LOGIC (Handling Typing) ---
  function refreshMarkerPosition(id, session) {
    var obj = window.activeCommentAnchors[id];
    if(!obj) return;

    // Remove old visual marker
    session.removeMarker(obj.markerId);

    // Validate Range (Start must be before End)
    var sRow = obj.startAnchor.row;
    var sCol = obj.startAnchor.column;
    var eRow = obj.endAnchor.row;
    var eCol = obj.endAnchor.column;

    // Sanity check: if end is before start, collapse or swap (simple collapse here)
    if (sRow > eRow || (sRow === eRow && sCol > eCol)) {
        eRow = sRow; eCol = sCol;
    }

    var range = new Range(sRow, sCol, eRow, eCol);
    obj.markerId = session.addMarker(range, 'ace_comment_highlight', 'text');
  }

  // --- 3. DISK SYNC LOGIC (The Fix for Persistence) ---
  function queueSync(id) {
    // Add current live coordinates to queue
    var obj = window.activeCommentAnchors[id];
    if(!obj) return;

    syncQueue[id] = {
      id: id,
      startRow: obj.startAnchor.row,
      startCol: obj.startAnchor.column,
      endRow: obj.endAnchor.row,
      endCol: obj.endAnchor.column
    };

    // Debounce the send
    clearTimeout(syncTimer);
    syncTimer = setTimeout(flushSyncQueue, 2000); // 2 seconds silence before save
  }

function flushSyncQueue() {

  // --- ADDITION: Block sync if switching files ---
  if (window.isSwitchingFile) return;

  // --- NEW FIX: SAFETY GUARD FOR EMPTY EDITOR ---
  // If the editor is empty, it means we are in the middle of a load/reload.
  // Do NOT sync coordinates now, or all anchors will collapse to (0,0).
  var editor = ace.edit('sourceEditor');
  if (!editor || editor.getSession().getValue().length < 1) {
      // Clear queue to prevent delayed bad syncs
      syncQueue = {};
      return;
  }
  // ---------------------------------------------

  if (Object.keys(syncQueue).length === 0) return;

  // SyncQueue values are {id, startRow...}
  var updates = Object.values(syncQueue);

  if (window.Shiny) {
    // Send as JSON string
    Shiny.setInputValue('updateCommentCoordinates', JSON.stringify(updates), {priority: 'event'});
  }

  syncQueue = {};
}

  // Flush on save (Ctrl+S) or Window Blur to be safe
  document.addEventListener('keydown', function(e) {
    if ((e.ctrlKey || e.metaKey) && e.key === 's') flushSyncQueue();
  });
  window.addEventListener('blur', flushSyncQueue);


  // --- 4. NAVIGATION & UX HELPERS ---

  // Highlight active comment based on cursor
  function highlightActiveComment() {
    var editor = ace.edit('sourceEditor');
    if (!editor) return;
    var cursor = editor.getCursorPosition();

    var foundId = null;
    var minLen = Infinity; // For nested comments, pick smallest range

    Object.keys(window.activeCommentAnchors).forEach(function(id) {
      var obj = window.activeCommentAnchors[id];
      var sRow = obj.startAnchor.row, sCol = obj.startAnchor.column;
      var eRow = obj.endAnchor.row, eCol = obj.endAnchor.column;

      // Logic: Cursor is inclusive of start, exclusive of end (standard UI feel)
      var afterStart = (cursor.row > sRow) || (cursor.row === sRow && cursor.column >= sCol);
      var beforeEnd  = (cursor.row < eRow) || (cursor.row === eRow && cursor.column <= eCol);

      if (afterStart && beforeEnd) {
        // Calculate size to find most specific comment
        var len = (eRow - sRow) * 10000 + (eCol - sCol);
        if (len < minLen) {
          minLen = len;
          foundId = id;
        }
      }
    });

    // Update Sidebar UI
    document.querySelectorAll('.comment-card').forEach(el => el.classList.remove('active-comment'));
    if (foundId) {
      var card = document.getElementById('card-' + foundId);
      if (card) {
        card.classList.add('active-comment');
        // Only scroll if we aren't actively using the sidebar
        if (!document.querySelector('#reviewPane:hover')) {
           card.scrollIntoView({behavior: 'smooth', block: 'nearest'});
        }
      }
    }
  }

  // Hook cursor change
  var cursorTimeout;
  var initCheckTimer = setInterval(function(){
      var editor = ace.edit('sourceEditor');
      if(editor) {
          clearInterval(initCheckTimer);
          editor.selection.on('changeCursor', function() {
            clearTimeout(cursorTimeout);
            cursorTimeout = setTimeout(highlightActiveComment, 200);
          });
          // Also trigger request for markers on load
          if(window.Shiny) Shiny.setInputValue('aceEditorReady', Math.random(), {priority: 'event'});
      }
  }, 200);

  // Jump To Code (Fixed Scroll Logic)
  window.jumpToCode = function(commentId) {
    var obj = window.activeCommentAnchors[commentId];
    if (!obj) return;

    var editor = ace.edit('sourceEditor');

    // 1. Force resize to handle split pane visibility changes
    editor.resize(true);

    // 2. Center the target line
    var sRow = obj.startAnchor.row;

    // Center selection vertically
    editor.scrollToLine(sRow, true, true, function() {});

    // 3. Set Selection
    editor.selection.setRange({
      start: {row: sRow, column: obj.startAnchor.column},
      end:   {row: obj.endAnchor.row,   column: obj.endAnchor.column}
    });

    editor.focus();
    highlightActiveComment();
  };

})();

// =================== AUTO-GROW TEXTAREAS ===================
document.addEventListener('input', function(e) {
  if (e.target.classList.contains('reply-textarea')) {
    // 1. Reset height to 'auto' to allow shrinking when text is deleted
    e.target.style.height = 'auto';

    // 2. Set height to scrollHeight (content height)
    // We compare with min-height (38px) to ensure it doesn't collapse too far
    var newHeight = Math.max(38, e.target.scrollHeight);
    e.target.style.height = newHeight + 'px';
  }
});


// Request *current live* comment positions from frontend
Shiny.addCustomMessageHandler('requestLiveCommentCoordinates', function(_) {
  if (!window.activeCommentAnchors) return;
  var updates = [];
  Object.keys(window.activeCommentAnchors).forEach(function(id) {
    var obj = window.activeCommentAnchors[id];
    if (obj && obj.startAnchor && obj.endAnchor) {
      updates.push({
        id: id,
        startRow: obj.startAnchor.row,
        startCol: obj.startAnchor.column,
        endRow: obj.endAnchor.row,
        endCol: obj.endAnchor.column
      });
    }
  });
  if (updates.length > 0 && Shiny.setInputValue) {
    Shiny.setInputValue('updateCommentCoordinates', updates, {priority: 'event'});
  }
});


// --- CRITICAL: Aggressive Marker Cleanup to Prevent Bleeding ---

Shiny.addCustomMessageHandler('clearLocalAnchors', function(msg) {
  var editor = ace.edit('sourceEditor');
  if (!editor || !editor.getSession()) return;

  var session = editor.getSession();

  // 1. Destroy our managed anchor registry
  if (window.activeCommentAnchors) {
    Object.keys(window.activeCommentAnchors).forEach(function(id) {
      var obj = window.activeCommentAnchors[id];
      if (obj.startAnchor) obj.startAnchor.detach();
      if (obj.endAnchor) obj.endAnchor.detach();
      // Remove specific marker if we tracked ID
      if (obj.markerId) session.removeMarker(obj.markerId);
    });
  }
  window.activeCommentAnchors = {};

  // 2. NUCLEAR OPTION: Iterate all markers and remove any that look like comments
  // This catches any 'ghost' markers that might have slipped through
  var markers = session.getMarkers();
  if (markers) {
    Object.keys(markers).forEach(function(key) {
      var m = markers[key];
      if (m.clazz === 'ace_comment_highlight' || m.clazz === 'ace_active_comment_highlight') {
        session.removeMarker(m.id);
      }
    });
  }

  // 3. Block sync temporarily to prevent saving empty/bad states during switch
  window.isSwitchingFile = true;
  setTimeout(function() { window.isSwitchingFile = false; }, 800);
});




// =================== EDITOR -> PDF SYNC (Forward Search) ===================
(function() {
  var initTimer = setInterval(function() {
    var editor = ace.edit(\"sourceEditor\");
    if (editor) {
      clearInterval(initTimer);

      editor.on(\"dblclick\", function(e) {
        // 1. Get cursor position (0-indexed)
        var pos = editor.getCursorPosition();

        // 2. Get active file path (requires existing currentFile logic)
        // We use a safe fallback if the reactive variable isn't immediately available in JS scope
        var filePath = null;
        var fileLabel = document.querySelector(\"#activeProjectName\"); // Or however you track it visually

// Send to R
if (window.Shiny) {
  Shiny.setInputValue(\"editorSyncClick\", {
    line: pos.row + 1,
    column: pos.column + 1,
    nonce: Math.random()
  }, {priority: \"event\"});
}
});
}
}, 500);
})();

// Helper to forward message from R to Iframe
Shiny.addCustomMessageHandler('syncPdfView', function(data) {
  var iframe = document.getElementById(\"pdfIframe\");
  if (iframe && iframe.contentWindow) {
    iframe.contentWindow.postMessage({
      type: \"syncView\",
      page: data.page,
      x: data.x,
      y: data.y
    }, \"*\");
  }
});



// SPELL CHECKER =========================================//
      (function() {
        var spellWorker;
        var spellCheckTimer;
        var suggestionBox;

        // MAPPING: LibreOffice GitHub
const SPELLCHECK_BASE = \"dictionaries/\";

const DICTIONARIES = {
  \"en_AU\": { name: \"English (Australia)\", aff: SPELLCHECK_BASE + \"en-AU/index.aff\", dic: SPELLCHECK_BASE + \"en-AU/index.dic\" },
  \"en_CA\": { name: \"English (Canada)\", aff: SPELLCHECK_BASE + \"en-CA/index.aff\", dic: SPELLCHECK_BASE + \"en-CA/index.dic\" },
  \"en_GB\": { name: \"English (UK)\", aff: SPELLCHECK_BASE + \"en-GB/index.aff\", dic: SPELLCHECK_BASE + \"en-GB/index.dic\" },
  \"en_US\": { name: \"English (US)\", aff: SPELLCHECK_BASE + \"en/index.aff\", dic: SPELLCHECK_BASE + \"en/index.dic\" },
  \"en_ZA\": { name: \"English (South Africa)\", aff: SPELLCHECK_BASE + \"en-ZA/index.aff\", dic: SPELLCHECK_BASE + \"en-ZA/index.dic\" }
};

const OTHER_DICTIONARIES = {
  \"fr_FR\": { name: \"French (France)\", aff: SPELLCHECK_BASE + \"fr/index.aff\", dic: SPELLCHECK_BASE + \"fr/index.dic\" },

  \"es_ES\": { name: \"Spanish (Spain)\", aff: SPELLCHECK_BASE + \"es/index.aff\", dic: SPELLCHECK_BASE + \"es/index.dic\" },
  \"es_AR\": { name: \"Spanish (Argentina)\", aff: SPELLCHECK_BASE + \"es-AR/index.aff\", dic: SPELLCHECK_BASE + \"es-AR/index.dic\" },
  \"es_BO\": { name: \"Spanish (Bolivia)\", aff: SPELLCHECK_BASE + \"es-BO/index.aff\", dic: SPELLCHECK_BASE + \"es-BO/index.dic\" },
  \"es_CL\": { name: \"Spanish (Chile)\", aff: SPELLCHECK_BASE + \"es-CL/index.aff\", dic: SPELLCHECK_BASE + \"es-CL/index.dic\" },
  \"es_CO\": { name: \"Spanish (Colombia)\", aff: SPELLCHECK_BASE + \"es-CO/index.aff\", dic: SPELLCHECK_BASE + \"es-CO/index.dic\" },
  \"es_CR\": { name: \"Spanish (Costa Rica)\", aff: SPELLCHECK_BASE + \"es-CR/index.aff\", dic: SPELLCHECK_BASE + \"es-CR/index.dic\" },
  \"es_CU\": { name: \"Spanish (Cuba)\", aff: SPELLCHECK_BASE + \"es-CU/index.aff\", dic: SPELLCHECK_BASE + \"es-CU/index.dic\" },
  \"es_DO\": { name: \"Spanish (Dominican Republic)\", aff: SPELLCHECK_BASE + \"es-DO/index.aff\", dic: SPELLCHECK_BASE + \"es-DO/index.dic\" },
  \"es_EC\": { name: \"Spanish (Ecuador)\", aff: SPELLCHECK_BASE + \"es-EC/index.aff\", dic: SPELLCHECK_BASE + \"es-EC/index.dic\" },
  \"es_GT\": { name: \"Spanish (Guatemala)\", aff: SPELLCHECK_BASE + \"es-GT/index.aff\", dic: SPELLCHECK_BASE + \"es-GT/index.dic\" },
  \"es_HN\": { name: \"Spanish (Honduras)\", aff: SPELLCHECK_BASE + \"es-HN/index.aff\", dic: SPELLCHECK_BASE + \"es-HN/index.dic\" },
  \"es_MX\": { name: \"Spanish (Mexico)\", aff: SPELLCHECK_BASE + \"es-MX/index.aff\", dic: SPELLCHECK_BASE + \"es-MX/index.dic\" },
  \"es_NI\": { name: \"Spanish (Nicaragua)\", aff: SPELLCHECK_BASE + \"es-NI/index.aff\", dic: SPELLCHECK_BASE + \"es-NI/index.dic\" },
  \"es_PA\": { name: \"Spanish (Panama)\", aff: SPELLCHECK_BASE + \"es-PA/index.aff\", dic: SPELLCHECK_BASE + \"es-PA/index.dic\" },
  \"es_PE\": { name: \"Spanish (Peru)\", aff: SPELLCHECK_BASE + \"es-PE/index.aff\", dic: SPELLCHECK_BASE + \"es-PE/index.dic\" },
  \"es_PH\": { name: \"Spanish (Philippines)\", aff: SPELLCHECK_BASE + \"es-PH/index.aff\", dic: SPELLCHECK_BASE + \"es-PH/index.dic\" },
  \"es_PR\": { name: \"Spanish (Puerto Rico)\", aff: SPELLCHECK_BASE + \"es-PR/index.aff\", dic: SPELLCHECK_BASE + \"es-PR/index.dic\" },
  \"es_PY\": { name: \"Spanish (Paraguay)\", aff: SPELLCHECK_BASE + \"es-PY/index.aff\", dic: SPELLCHECK_BASE + \"es-PY/index.dic\" },
  \"es_SV\": { name: \"Spanish (El Salvador)\", aff: SPELLCHECK_BASE + \"es-SV/index.aff\", dic: SPELLCHECK_BASE + \"es-SV/index.dic\" },
  \"es_US\": { name: \"Spanish (United States)\", aff: SPELLCHECK_BASE + \"es-US/index.aff\", dic: SPELLCHECK_BASE + \"es-US/index.dic\" },
  \"es_UY\": { name: \"Spanish (Uruguay)\", aff: SPELLCHECK_BASE + \"es-UY/index.aff\", dic: SPELLCHECK_BASE + \"es-UY/index.dic\" },
  \"es_VE\": { name: \"Spanish (Venezuela)\", aff: SPELLCHECK_BASE + \"es-VE/index.aff\", dic: SPELLCHECK_BASE + \"es-VE/index.dic\" },

  \"de_DE\": { name: \"German (Germany)\", aff: SPELLCHECK_BASE + \"de/index.aff\", dic: SPELLCHECK_BASE + \"de/index.dic\" },
  \"it_IT\": { name: \"Italian\", aff: SPELLCHECK_BASE + \"it/index.aff\", dic: SPELLCHECK_BASE + \"it/index.dic\" },
  \"pt_PT\": { name: \"Portuguese (Portugal)\", aff: SPELLCHECK_BASE + \"pt-PT/index.aff\", dic: SPELLCHECK_BASE + \"pt-PT/index.dic\" },
  \"pt_BR\": { name: \"Portuguese (Brazil)\", aff: SPELLCHECK_BASE + \"pt-BR/index.aff\", dic: SPELLCHECK_BASE + \"pt-BR/index.dic\" },
  \"ru_RU\": { name: \"Russian\", aff: SPELLCHECK_BASE + \"ru/index.aff\", dic: SPELLCHECK_BASE + \"ru/index.dic\" },
  \"nl_NL\": { name: \"Dutch\", aff: SPELLCHECK_BASE + \"nl/index.aff\", dic: SPELLCHECK_BASE + \"nl/index.dic\" },
  \"pl_PL\": { name: \"Polish\", aff: SPELLCHECK_BASE + \"pl/index.aff\", dic: SPELLCHECK_BASE + \"pl/index.dic\" },
  \"sv_SE\": { name: \"Swedish\", aff: SPELLCHECK_BASE + \"sv/index.aff\", dic: SPELLCHECK_BASE + \"sv/index.dic\" },
  \"tr_TR\": { name: \"Turkish\", aff: SPELLCHECK_BASE + \"tr/index.aff\", dic: SPELLCHECK_BASE + \"tr/index.dic\" },
  \"cs_CZ\": { name: \"Czech\", aff: SPELLCHECK_BASE + \"cs/index.aff\", dic: SPELLCHECK_BASE + \"cs/index.dic\" },
  \"da_DK\": { name: \"Danish\", aff: SPELLCHECK_BASE + \"da/index.aff\", dic: SPELLCHECK_BASE + \"da/index.dic\" },
  \"el_GR\": { name: \"Greek\", aff: SPELLCHECK_BASE + \"el/index.aff\", dic: SPELLCHECK_BASE + \"el/index.dic\" },
  \"hu_HU\": { name: \"Hungarian\", aff: SPELLCHECK_BASE + \"hu/index.aff\", dic: SPELLCHECK_BASE + \"hu/index.dic\" },
  \"ro_RO\": { name: \"Romanian\", aff: SPELLCHECK_BASE + \"ro/index.aff\", dic: SPELLCHECK_BASE + \"ro/index.dic\" },
  \"sk_SK\": { name: \"Slovak\", aff: SPELLCHECK_BASE + \"sk/index.aff\", dic: SPELLCHECK_BASE + \"sk/index.dic\" },
  \"sl_SI\": { name: \"Slovenian\", aff: SPELLCHECK_BASE + \"sl/index.aff\", dic: SPELLCHECK_BASE + \"sl/index.dic\" },
  \"sv_FI\": { name: \"Swedish (Finland)\", aff: SPELLCHECK_BASE + \"sv/index.aff\", dic: SPELLCHECK_BASE + \"sv/index.dic\" },
  \"uk_UA\": { name: \"Ukrainian\", aff: SPELLCHECK_BASE + \"uk/index.aff\", dic: SPELLCHECK_BASE + \"uk/index.dic\" },
  \"sw_TZ\": { name: \"Swahili\", aff: SPELLCHECK_BASE + \"sw/index.aff\", dic: SPELLCHECK_BASE + \"sw/index.dic\" },
  \"zu_ZA\": { name: \"Zulu\", aff: SPELLCHECK_BASE + \"zu/index.aff\", dic: SPELLCHECK_BASE + \"zu/index.dic\" }
};

const LANGUAGE_STOPWORDS = {
  \"en\": [\"the\", \"be\", \"to\", \"of\", \"and\", \"a\", \"in\", \"that\", \"have\", \"i\", \"it\", \"for\", \"not\", \"on\", \"with\", \"he\", \"as\"]
};

const OTHER_LANGUAGE_STOPWORDS = {
  \"es\": [\"el\", \"la\", \"los\", \"las\", \"de\", \"y\", \"a\", \"en\", \"que\", \"un\", \"una\", \"por\", \"con\", \"no\", \"su\", \"para\", \"es\"],
  \"fr\": [\"le\", \"la\", \"les\", \"de\", \"un\", \"une\", \"et\", \"à\", \"il\", \"est\", \"en\", \"que\", \"pour\", \"dans\", \"ce\", \"qui\", \"sur\"],
  \"de\": [\"der\", \"die\", \"das\", \"und\", \"in\", \"den\", \"von\", \"zu\", \"dem\", \"für\", \"mit\", \"ist\", \"auf\", \"sich\", \"dass\", \"er\"],
  \"pt\": [\"o\", \"a\", \"os\", \"as\", \"de\", \"e\", \"em\", \"que\", \"um\", \"uma\", \"por\", \"com\", \"não\", \"para\", \"se\", \"do\", \"da\"],
  \"it\": [\"il\", \"la\", \"i\", \"le\", \"di\", \"e\", \"in\", \"che\", \"un\", \"una\", \"per\", \"con\", \"non\", \"su\", \"da\", \"come\"],
  \"nl\": [\"de\", \"het\", \"een\", \"en\", \"van\", \"in\", \"dat\", \"op\", \"te\", \"voor\", \"zijn\", \"met\", \"niet\", \"ik\", \"is\"],
  \"ru\": [\"и\", \"в\", \"не\", \"на\", \"я\", \"быть\", \"он\", \"с\", \"что\", \"а\", \"по\", \"это\", \"она\", \"этом\", \"к\", \"у\"],
  \"pl\": [\"w\", \"z\", \"i\", \"na\", \"do\", \"nie\", \"że\", \"o\", \"to\", \"od\", \"a\", \"się\", \"jak\", \"jest\", \"dla\"],
  \"sv\": [\"och\", \"i\", \"att\", \"det\", \"som\", \"en\", \"på\", \"är\", \"av\", \"för\", \"med\", \"till\", \"den\", \"har\", \"de\"],
  \"da\": [\"og\", \"i\", \"jeg\", \"det\", \"at\", \"en\", \"den\", \"til\", \"er\", \"som\", \"på\", \"de\", \"med\", \"han\", \"af\"],
  \"cs\": [\"a\", \"v\", \"se\", \"na\", \"že\", \"je\", \"z\", \"do\", \"o\", \"k\", \"pro\", \"to\", \"ale\", \"jak\", \"jako\"],
  \"hu\": [\"a\", \"az\", \"és\", \"hogy\", \"nem\", \"egy\", \"is\", \"meg\", \"vagy\", \"el\", \"ha\", \"de\", \"van\", \"csak\"],
  \"ro\": [\"în\", \"și\", \"de\", \"la\", \"o\", \"un\", \"pe\", \"cu\", \"că\", \"să\", \"din\", \"este\", \"mai\", \"ca\", \"nu\"],
  \"tr\": [\"ve\", \"bir\", \"için\", \"bu\", \"ile\", \"de\", \"da\", \"çok\", \"gibi\", \"daha\", \"en\", \"var\", \"kadar\", \"olan\"],
  \"el\": [\"και\", \"το\", \"η\", \"ο\", \"σε\", \"να\", \"με\", \"για\", \"είναι\", \"από\", \"που\", \"της\", \"ένα\", \"του\"],
  \"uk\": [\"і\", \"в\", \"на\", \"не\", \"з\", \"що\", \"до\", \"як\", \"за\", \"а\", \"це\", \"про\", \"він\", \"та\", \"для\"]
};

function detectDocumentLanguage() {
    var editor = ace.edit(\"sourceEditor\");
    if (!editor) return null;

    // Grab the first 100 lines to guess the language quickly
    var text = editor.getSession().getLines(0, 100).join(\" \").toLowerCase();
    var words = text.match(/[\\p{L}\']+/gu) || [];

    if (words.length === 0) return null;

    var scores = {};
    for (var lang in LANGUAGE_STOPWORDS) {
        scores[lang] = 0;
        LANGUAGE_STOPWORDS[lang].forEach(function(word) {
            // Count exactly matching words
            scores[lang] += words.filter(w => w === word).length;
        });
    }

    // Find the language with the highest score
    var detectedLang = Object.keys(scores).reduce(function(a, b) {
        return scores[a] > scores[b] ? a : b;
    });

    // Safety Net: If the highest score is less than 3 matches,
    // it's too risky to guess. Return null.
    if (scores[detectedLang] < 3) return null;

    return detectedLang;
}

function updateLanguageDropdown() {
    var detectedBase = detectDocumentLanguage();
    var select = document.getElementById(\"editorSpellLangPanel\");

    if (!select) return;

    // If we couldn't confidently detect a language, enable everything and abort.
    if (!detectedBase) {
        for (var k = 0; k < select.options.length; k++) {
            select.options[k].disabled = false;
            select.options[k].style.display = \"\";
        }
        return;
    }

    var validOptionsExist = false;

    // Loop through the dropdown and hide non-matching languages
    for (var i = 0; i < select.options.length; i++) {
        var opt = select.options[i];

        // Match base language (e.g., \"en\" matches \"en_US\", \"en_GB\", \"en\")
        // We replace \"_\" with \"-\" in case your values use hyphens instead
        var optValueBase = opt.value.split(\"_\")[0].split(\"-\")[0];

        if (optValueBase === detectedBase) {
            opt.disabled = false;
            opt.style.display = \"\"; // Keep visible
            validOptionsExist = true;
        } else {
            opt.disabled = true;
            opt.style.display = \"none\"; // Hide it
        }
    }

    // If the currently selected option is now disabled, auto-switch to the first valid one
    if (select.options[select.selectedIndex].disabled && validOptionsExist) {
        for (var j = 0; j < select.options.length; j++) {
            if (!select.options[j].disabled) {
                select.selectedIndex = j;
                select.dispatchEvent(new Event(\"change\"));
                break;
            }
        }
    }
}

        // --- 1. Init Logic ---
        function initWorker() {
          if (typeof Worker === 'undefined') return;

          // Populate Settings Dropdown
          var select = document.getElementById('editorSpellLangPanel');
          if (select) {
            select.innerHTML = '';
            for (var key in DICTIONARIES) {
               var opt = document.createElement('option');
               opt.value = key;
               opt.textContent = DICTIONARIES[key].name;
               select.appendChild(opt);
            }

            // Restore saved setting
            var savedLang = localStorage.getItem('mudskipper_spell_lang') || 'en_GB';
            if(DICTIONARIES[savedLang]) select.value = savedLang;

            // Listen for changes
            select.addEventListener('change', function() {
               var newLang = this.value;
               changeLanguage(newLang);
            });
          }

          // Create Suggestion Box UI
          suggestionBox = document.createElement('div');
          suggestionBox.id = 'spell-suggestions';
          document.body.appendChild(suggestionBox);

          document.addEventListener('click', function(e) {
            if (e.target.closest('#spell-suggestions')) return;
            suggestionBox.style.display = 'none';
          });

          spellWorker = new Worker('spellcheck_worker.js');

          // Load the initial language
          var initLang = localStorage.getItem('mudskipper_spell_lang') || 'en_GB';
          changeLanguage(initLang);

          spellWorker.onmessage = function(e) {
            if (e.data.type === 'result') {
              renderMarkers(e.data.typos);
            } else if (e.data.type === 'suggestions_ready') {
              showSuggestions(e.data.list, e.data.range, e.data.coords);
            } else if (e.data.type === 'ready') {
               // Re-trigger check
               triggerSpellCheck();
            }
          };
        }

        function changeLanguage(langKey) {
            if (!spellWorker) return;
            var conf = DICTIONARIES[langKey];
            if (!conf) return;

            localStorage.setItem('mudskipper_spell_lang', langKey);

            spellWorker.postMessage({
                command: \"load_dictionary\",
                lang: langKey,
                aff: conf.aff,
                dic: conf.dic
            });
        }

        // Trigger check function (Global reference)
        window.triggerSpellCheck = function() {
           var editor = ace.edit('sourceEditor');
           if (!editor) return;
           var session = editor.getSession();
           var lines = session.getLines(0, session.getLength());
           spellWorker.postMessage({ lines: lines });
        };

        // --- 2. Render Markers ---
        function renderMarkers(typos) {
          var editor = ace.edit('sourceEditor');
          if (!editor) return;
          var session = editor.getSession();
          var Range = ace.require('ace/range').Range;

          var markers = session.getMarkers();
          Object.keys(markers).forEach(function(key) {
            if (markers[key].clazz === 'misspelled') {
              session.removeMarker(markers[key].id);
            }
          });

          typos.forEach(function(t) {
            var range = new Range(t.row, t.col, t.row, t.col + t.len);
            range.misspelledWord = t.word;
            session.addMarker(range, 'misspelled', 'text');
          });
        }

        // --- 3. Handle Clicks on Errors ---
        function setupInteraction(editor) {
          editor.on('click', function(e) {
            var pos = e.getDocumentPosition();
            var session = editor.getSession();
            var markers = session.getMarkers();
            var clickedMarker = null;

            Object.keys(markers).forEach(function(key) {
              var m = markers[key];
              if (m.clazz === 'misspelled') {
                if (m.range.contains(pos.row, pos.column)) {
                  clickedMarker = m;
                }
              }
            });

            if (clickedMarker) {
              var wordText = session.getTextRange(clickedMarker.range);
              var screenPos = editor.renderer.textToScreenCoordinates(pos.row, pos.column);

              spellWorker.postMessage({
                command: 'suggest',
                word: wordText,
                range: clickedMarker.range,
                coords: { x: screenPos.pageX, y: screenPos.pageY }
              });
            } else {
              suggestionBox.style.display = 'none';
            }
          });

          // Auto-detect language 2 seconds after the user stops typing
            var langDetectTimer;
            editor.on('change', function() {
                clearTimeout(langDetectTimer);
                langDetectTimer = setTimeout(updateLanguageDropdown, 2000);

                // Keep your existing spellcheck trigger as well
                suggestionBox.style.display = 'none';
                clearTimeout(spellCheckTimer);
                spellCheckTimer = setTimeout(triggerSpellCheck, 1500);
            });

          editor.on('change', function() {
            suggestionBox.style.display = 'none';
            clearTimeout(spellCheckTimer);
            spellCheckTimer = setTimeout(triggerSpellCheck, 1500);
          });

        }

        // --- 4. Show & Apply Suggestions ---
        function showSuggestions(list, range, coords) {
          if (!list || list.length === 0) {
            suggestionBox.innerHTML = '<div class=\"suggestion-header\">No suggestions</div>';
          } else {
            var html = '<div class=\"suggestion-header\">Did you mean?</div>';
            list.slice(0, 5).forEach(function(s) {
              html += '<div class=\"suggestion-item\" data-word=\"' + s + '\">' + s + '</div>';
            });
            suggestionBox.innerHTML = html;
          }

          suggestionBox.style.display = 'block';
          suggestionBox.style.left = coords.x + 'px';

          var boxHeight = suggestionBox.offsetHeight;
          var windowHeight = window.innerHeight;
          var lineHeight = 20;

          if (coords.y + lineHeight + boxHeight > windowHeight) {
            suggestionBox.style.top = (coords.y - boxHeight) + 'px';
          } else {
             suggestionBox.style.top = (coords.y + lineHeight) + 'px';
          }

          var items = suggestionBox.querySelectorAll('.suggestion-item');
          items.forEach(function(item) {
            item.onclick = function() {
              var newWord = this.getAttribute('data-word');
              replaceWord(newWord, range);
              suggestionBox.style.display = 'none';
            };
          });
        }

        function replaceWord(newWord, rangeData) {
          var editor = ace.edit('sourceEditor');
          var Range = ace.require('ace/range').Range;
          var range = new Range(rangeData.start.row, rangeData.start.column, rangeData.end.row, rangeData.end.column);
          editor.getSession().replace(range, newWord);
          triggerSpellCheck();
        }

        // Initialize
        if (document.readyState === 'loading') {
          document.addEventListener('DOMContentLoaded', function() {
             setTimeout(initWorker, 1000);
             setTimeout(function() {
                 var editor = ace.edit('sourceEditor');
                 if(editor) setupInteraction(editor);
             }, 2000);
          });
        } else {
          setTimeout(initWorker, 1000);
          setTimeout(function() {
             var editor = ace.edit('sourceEditor');
             if(editor) setupInteraction(editor);
          }, 2000);
        }

      })();




//======================= Chat Input Handler==========================//
$(document).on('keydown', '#chatInputMsg', function(e) {
  if (e.which == 13 && !e.shiftKey) {
    e.preventDefault();
    Shiny.setInputValue('triggerSendChat', Math.random(), {priority:'event'});
  }
});



// 1. SCROLL LOGIC
var chatContainer = document.getElementById('chatContent');
var scrollBtn = document.getElementById('chatScrollBtn');
var isUserAtBottom = true;

function checkScroll() {
    var el = document.getElementById('chatContent');
    if(!el) return;

    // Logic: If user was at bottom, scroll to new bottom.
    if(isUserAtBottom) {
        scrollToBottom();
    }
}

function scrollToBottom() {
    var el = document.getElementById('chatContent');
    if(el) el.scrollTop = el.scrollHeight;
}

// Listen to scroll events to toggle button
$('#chatContent').on('scroll', function() {
    var el = this;
    var threshold = 50; // pixels from bottom
    var position = el.scrollTop + el.clientHeight;

    if (position >= el.scrollHeight - threshold) {
        // User is at bottom
        isUserAtBottom = true;
        $('#chatScrollBtn').fadeOut();
    } else {
        // User is up
        isUserAtBottom = false;
        $('#chatScrollBtn').fadeIn();
    }
});

// 2. EMOJI LOGIC
function toggleEmojiPicker() {
    var p = document.getElementById('emojiPicker');
    p.style.display = (p.style.display === 'none') ? 'block' : 'none';
}

function insertEmoji(emoji) {
    var input = document.getElementById('chatInputMsg');
    var startPos = input.selectionStart;
    var endPos = input.selectionEnd;

    // Insert text
    input.value = input.value.substring(0, startPos)
        + emoji
        + input.value.substring(endPos, input.value.length);

    // Reset cursor
    input.selectionStart = startPos + emoji.length;
    input.selectionEnd = startPos + emoji.length;

    // Focus and trigger input event for Shiny
    input.focus();
    $(input).trigger('change');

    toggleEmojiPicker(); // Auto close
}

// Close emoji picker if clicking outside
$(document).click(function(event) {
    if(!$(event.target).closest('#emojiPicker, .btn-icon').length) {
        $('#emojiPicker').hide();
    }
});


/* ========== HISTORY MANAGER (FIXED WRAPPING & RESTORE) ================= */

// 1. STYLES
(function() {
    const styleId = 'history-styles-v5';
    const oldStyle = document.getElementById(styleId);
    if (oldStyle) oldStyle.remove();

    const style = document.createElement('style');
    style.id = styleId;
    style.innerHTML = `
        /* --- TEXT HIGHLIGHTS --- */
        .diff-marker-added {
            position: absolute;
            background-color: rgba(40, 167, 69, 0.2);
            border-bottom: 0.5px solid #28a745;
            z-index: 6;
            pointer-events: none;
        }

        .diff-marker-deleted {
            position: absolute;
            background-color: rgba(220, 53, 69, 0.15);
            z-index: 6;
            pointer-events: none;
        }

        .diff-marker-deleted::after {
            content: '';
            position: absolute;
            top: 50%; left: 0; width: 100%; height: 1px;
            background-color: #dc3545;
            display: block;
        }

        /* --- LINE HIGHLIGHTS (Fixed for Wrapping) --- */
        .diff-line-added {
            position: absolute;
            left: 0; right: 0; top: 0; bottom: 0; /* Force fill */
            box-sizing: border-box; /* Important for border rendering */
            background-color: rgba(40, 167, 69, 0.05);
            border-left: 2px solid #28a745;
            z-index: 4;
        }

        .diff-line-deleted {
            position: absolute;
            left: 0; right: 0; top: 0; bottom: 0; /* Force fill */
            box-sizing: border-box;
            background-color: rgba(220, 53, 69, 0.05);
            border-left: 2px solid #dc3545;
            z-index: 4;
        }

        /* --- UI HELPERS --- */
        #historyTooltip {
            position: fixed; display: none;
            background: #2c3e50; color: white;
            padding: 8px 12px; border-radius: 4px;
            font-size: 12px; z-index: 9999;
            box-shadow: 0 4px 6px rgba(0,0,0,0.3);
            pointer-events: none; max-width: 300px;
        }

        .history-message-pane {
            position: absolute; top: 50%; left: 50%;
            transform: translate(-50%, -50%);
            text-align: center; z-index: 100;
        }
    `;
    document.head.appendChild(style);
})();

// --- 2. GLOBAL LISTENERS ---
$(document).ready(function() {
    Shiny.addCustomMessageHandler('toggleHistoryView', function(show) {
        toggleHistoryMode(show);
    });

    Shiny.addCustomMessageHandler('historyContentReady', function(data) {
        if (!HistoryManager.editor) HistoryManager.init();
        HistoryManager.processHistory(data);
    });
});

function toggleHistoryMode(show) {
    const overlay = document.getElementById('historyOverlay');
    if (show) {
        overlay.classList.add('show');
        Shiny.setInputValue('history_mode_active', true);
        if (!HistoryManager.editor) {
            HistoryManager.init();
        } else {
            HistoryManager.editor.resize();
        }

        // Initialize Split.js for history sidebars if not already done
        if (!window.historySplit) {
            window.historySplit = Split(['#historyFileTreeSidebar', '#historyEditorContainer', '#historySidebar'], {
                sizes: [20, 60, 20],
                minSize: [150, 200, 150],
                gutterSize: 2,
                cursor: 'col-resize',
                onDrag: function() {
                    if (HistoryManager.editor) HistoryManager.editor.resize();
                }
            });
        }

    } else {
        overlay.classList.remove('show');
        Shiny.setInputValue('history_mode_active', false);
    }
}

// --- 3. LOGIC ---
window.HistoryManager = {
    editor: null,
    dmp: null,
    tracker: [],
    currentVersionId: null, // Initialized

    init: function() {
        if (typeof diff_match_patch === 'undefined') return;
        this.dmp = new diff_match_patch();

        if (!$('#historyTooltip').length) {
            $('body').append('<div id=\"historyTooltip\"></div>');
        }

        const checkAce = setInterval(() => {
            const el = document.getElementById('historyEditor');
            if (window.ace && el) {
                clearInterval(checkAce);
                this.editor = ace.edit('historyEditor');
                this.editor.setReadOnly(true);
                this.editor.$blockScrolling = Infinity;
                
                // --- Apply Current Theme/Font Settings ---
                try {
                  var s = JSON.parse(localStorage.getItem('latexerSettings') || 'null');
                  if (s) {
                    if (s.editorTheme) this.editor.setTheme('ace/theme/' + s.editorTheme);
                    if (s.fontSize) this.editor.setFontSize(+s.fontSize);
                  }
                  // Font family from its own storage key
                  var ff = localStorage.getItem('mudskipper_font_family');
                  if (ff) this.editor.setOption('fontFamily', ff);
                } catch(e) {}
                
                this.setupInteractions();
            }
        }, 100);
    },

    processHistory: function(data) {
        if (!this.editor) return;

        // --- FIX 1: STORE THE ID SO THE BUTTON WORKS ---
        this.currentVersionId = data.meta.id;

        const session = this.editor.getSession();

        // Cleanup Markers
        const markers = session.getMarkers();
        for (let m in markers) {
            if (markers[m].clazz && (markers[m].clazz.includes('diff-marker') || markers[m].clazz.includes('diff-line'))) {
                session.removeMarker(m);
            }
        }
        this.tracker = [];

        // UI Headers
        $('#historyNavbarInfo').html(`
        <div class=\"d-flex align-items-center gap-2\" style=\"font-size: 0.9rem;\">
            <span><i class=\"fa-regular fa-folder\" style=\"color: var(--tblr-primary); opacity: 1;\"></i></span>
            <strong>${data.meta.projectName}</strong>
            <span><i class=\"fa-solid fa-chevron-right\" style=\"font-size: 0.8em;\"></i></span>
            <span><i class=\"fa-regular fa-file-lines\" style=\"color: var(--tblr-primary); opacity: 1;\"></i></span>
            <span>${data.meta.file}</span>
        </div>
        `);

        const niceDate = new Date(data.meta.timestamp * 1000).toLocaleDateString(undefined, {
            day: 'numeric', month: 'long', hour: '2-digit', minute: '2-digit'
        });
        $('#historyViewDate').text(`Viewing ${niceDate}`);

        // Non-Diff Mode
        if (!data.diffMode) {
            this.editor.setValue(\"\", -1);
            $('#historyEditorContainer .ace_scroller').css('opacity', '0.1');

            if($('#historyMsg').length === 0) {
                 $('#historyEditorContainer').append(`<div id=\"historyMsg\" class=\"history-message-pane\"><h4>${data.content}</h4></div>`);
            } else {
                 $('#historyMsg').html(`<h4>${data.content}</h4>`).show();
            }
            $('#historyChangeCount').text('');
            return;
        }

        // --- DIFF LOGIC ---
        $('#historyEditorContainer .ace_scroller').css('opacity', '1');
        $('#historyMsg').hide();

        const diffs = this.dmp.diff_main(data.previous || \"\", data.content);
        this.dmp.diff_cleanupSemantic(diffs);

        let visualContent = \"\";
        let visualCursor = 0;
        let changesCount = 0;
        const Range = ace.require(\"ace/range\").Range;
        const doc = session.getDocument();

        const rowsAdded = new Set();
        const rowsDeleted = new Set();

        // Pass 1: Build Text
        diffs.forEach((part) => visualContent += part[1]);
        this.editor.setValue(visualContent, -1);

        // Pass 2: Apply Text Markers & Calculate Rows
        diffs.forEach((part) => {
            const type = part[0]; // 0: eq, 1: ins, -1: del
            const text = part[1];
            const len = text.length;
            const meta = { user: data.meta.user, date: niceDate };

            if (type === 0) {
                visualCursor += len;
            } else {
                const startPos = doc.indexToPosition(visualCursor);
                const endPos = doc.indexToPosition(visualCursor + len);

                for(let r = startPos.row; r <= endPos.row; r++) {
                    if (type === 1) rowsAdded.add(r);
                    if (type === -1) rowsDeleted.add(r);
                }

                const range = new Range(startPos.row, startPos.column, endPos.row, endPos.column);

                if (type === 1) {
                    session.addMarker(range, \"diff-marker-added\", \"text\");
                    this.tracker.push({ range: range, type: 'added', ...meta });
                } else {
                    session.addMarker(range, \"diff-marker-deleted\", \"text\");
                    this.tracker.push({ range: range, type: 'deleted', ...meta });
                }

                visualCursor += len;
                changesCount++;
            }
        });

        // Pass 3: Apply Line Highlights
        rowsAdded.forEach(row => {
            const lineRange = new Range(row, 0, row, 1);
            session.addMarker(lineRange, \"diff-line-added\", \"fullLine\");
            if(rowsDeleted.has(row)) rowsDeleted.delete(row);
        });

        rowsDeleted.forEach(row => {
            const lineRange = new Range(row, 0, row, 1);
            session.addMarker(lineRange, \"diff-line-deleted\", \"fullLine\");
        });

        $('#historyChangeCount').text(`${changesCount} changes`);

        if (this.tracker.length > 0) {
            this.editor.scrollToLine(this.tracker[0].range.start.row, true, true, function() {});
        }
    },

    setupInteractions: function() {
        this.editor.on(\"mousemove\", (e) => {
            const pos = e.getDocumentPosition();
            const tooltip = $('#historyTooltip');

            const match = this.tracker.find(t =>
                pos.row >= t.range.start.row &&
                pos.row <= t.range.end.row &&
                (pos.row !== t.range.start.row || pos.column >= t.range.start.column) &&
                (pos.row !== t.range.end.row || pos.column <= t.range.end.column)
            );

            if (match) {
                const color = match.type === 'added' ? '#28a745' : '#dc3545';
                const label = match.type === 'added' ? 'Added Text' : 'Deleted Text';

                tooltip.html(`<strong style='color:${color}'>${label}</strong> by ${match.user || 'User'}<br><span style='opacity:0.8'>${match.date}</span>`);
                tooltip.css({
                    display: 'block',
                    left: e.clientX + 15,
                    top: e.clientY + 15
                });
            } else {
                tooltip.hide();
            }
        });

        this.editor.container.addEventListener('mouseleave', () => {
            $('#historyTooltip').hide();
        });
    }
};

function loadHistoryItem(id) {
  $('.history-card').removeClass('active');
  $('#card-' + id).addClass('active');
  Shiny.setInputValue('history_selected_id', id, {priority: 'event'});
}

function restoreVersion(id) {
    if(confirm(\"Restore this version? This will overwrite the current file.\")) {
        Shiny.setInputValue('history_restore_id', id, {priority: 'event'});
    }
}

function restoreCurrentViewerVersion() {
    if(HistoryManager.currentVersionId) {
        restoreVersion(HistoryManager.currentVersionId);
    }
}


//======================================================//
//========Initialize the LaTeX word counter worker======//

var latexWordCounterWorker;
var wordCountDebounceTimer;
var lastProcessedTextForCounter = '';
var currentStats = null; // Store stats for the overlay

// 1. Initialize the Worker
function initializeLatexWordCounter() {
    try {
        // Create worker
        latexWordCounterWorker = new Worker(\"latex_wordcounter.js\");

        // Handle worker messages (Receives full stats object)
        latexWordCounterWorker.onmessage = function(e) {
            const stats = e.data;
            currentStats = stats; // Store for overlay populating
            updateWordCounterDisplay(stats);
        };

        // Error handling
        latexWordCounterWorker.onerror = function(error) {
            console.error(\"Word count worker error:\", error);
            updateWordCounterDisplay(\"Error\");
        };

        return true;
    } catch (e) {
        console.error(\"Failed to initialize word counter worker:\", e);
        return false;
    }
}

// 2. Send text to worker (Triggered by editor changes)
function updateWordCountWithWorker() {
    const editor = ace.edit(\"sourceEditor\");
    if (!editor || !latexWordCounterWorker) return;

    const text = editor.getSession().getValue();

    // Skip if text hasn't changed
    if (text === lastProcessedTextForCounter) return;

    // Update last processed text
    lastProcessedTextForCounter = text;

    // Debounce rapid changes
    clearTimeout(wordCountDebounceTimer);
    wordCountDebounceTimer = setTimeout(function() {
        // Send text to worker for processing
        latexWordCounterWorker.postMessage(text);
    }, 500); // 500ms debounce
}

// 3. Update the Display (Navbar & Overlay)
function updateWordCounterDisplay(stats) {
    // --- Update Navbar Summary ---
    const el = document.getElementById(\"wordCountDisplay\");
    if (el) {
        if (stats && typeof stats.total !== 'undefined') {
            // Display total words
            el.innerText = stats.total.words.toLocaleString() + \" words\";

            // Make navbar clickable to open overlay
            el.onclick = openWordCountOverlay;
            el.style.cursor = \"pointer\";
            el.setAttribute(\"title\", \"Click to see detailed word count\");
        } else if (typeof stats === 'number') {
            // Fallback for simple number (or fallback mode)
            el.innerText = stats.toLocaleString() + \" words\";
        } else {
            // Error state
            el.innerText = stats;
        }
    }

    // --- Update Overlay Fields (if stats object exists) ---
    if (stats && stats.total) {
        setText(\"wc-total-words\", stats.total.words);
        setText(\"wc-total-chars\", stats.total.chars);

        setText(\"wc-main-words\", stats.main.words);
        setText(\"wc-main-chars\", stats.main.chars);

        setText(\"wc-headers-words\", stats.headers.words);
        setText(\"wc-headers-chars\", stats.headers.chars);
        setText(\"wc-headers-count\", \"(\" + stats.headers.count + \")\");

        setText(\"wc-abstract-words\", stats.abstract.words);
        setText(\"wc-abstract-chars\", stats.abstract.chars);

        setText(\"wc-captions-words\", stats.captions.words);
        setText(\"wc-captions-chars\", stats.captions.chars);

        setText(\"wc-footnotes-words\", stats.footnotes.words);
        setText(\"wc-footnotes-chars\", stats.footnotes.chars);

        setText(\"wc-other-words\", stats.other.words);
        setText(\"wc-other-chars\", stats.other.chars);

        setText(\"wc-math-inline\", stats.math.inline);
        setText(\"wc-math-display\", stats.math.display);
    }
}

// Helper to safely set text content
function setText(id, val) {
    const el = document.getElementById(id);
    if(el) el.innerText = val.toLocaleString();
}

// 4. Overlay Controls
function openWordCountOverlay() {
    const el = document.getElementById(\"wordCountOverlay\");
    if(el) {
        el.classList.add(\"show\");
        // Ensure stats are fresh if opened immediately
        if(currentStats) updateWordCounterDisplay(currentStats);
    }
}

function closeWordCountOverlay() {
    const el = document.getElementById(\"wordCountOverlay\");
    if(el) el.classList.remove(\"show\");
}

// 5. System Setup & Fallbacks
function setupWordCounterSystem() {
    // Try to initialize worker
    const workerReady = initializeLatexWordCounter();

    if (!workerReady) {
        // Fallback if worker fails to initialize
        console.warn(\"Word counter worker not available, using fallback method\");
        document.addEventListener(\"DOMContentLoaded\", function() {
            const editor = ace.edit(\"sourceEditor\");
            if (editor) {
                editor.getSession().on(\"change\", debounce(fallbackWordCount, 500));
                fallbackWordCount();
            }
        });
        return;
    }

    // Setup editor change handler (Worker mode)
    const editor = ace.edit(\"sourceEditor\");
    if (editor) {
        editor.getSession().on(\"change\", updateWordCountWithWorker);
        // Initial count
        updateWordCountWithWorker();
    }

    // Setup MutationObserver for dynamic content changes
    const targetNode = document.getElementById(\"editor-container\");
    if (targetNode && MutationObserver) {
        const observer = new MutationObserver(debounce(updateWordCountWithWorker, 500));
        observer.observe(targetNode, { childList: true, subtree: true });
    }
}

// Fallback word count (in case worker fails)
function fallbackWordCount() {
    const editor = ace.edit(\"sourceEditor\");
    if (!editor) return;

    const text = editor.getSession().getValue();
    if (!text || text.trim().length === 0) {
        updateWordCounterDisplay(0);
        return;
    }

    try {
        // Basic word count as fallback
        const words = text.trim().match(/\\S+/g) || [];
        updateWordCounterDisplay(words.length);
    } catch (e) {
        console.error(\"Fallback word count error:\", e);
        updateWordCounterDisplay(\"Error\");
    }
}

// Helper debounce function
function debounce(func, wait) {
    var timeout;
    return function() {
        var context = this, args = arguments;
        clearTimeout(timeout);
        timeout = setTimeout(function() {
            timeout = null;
            func.apply(context, args);
        }, wait);
    };
}

// Start the system when DOM is ready
if (document.readyState === \"loading\") {
    document.addEventListener(\"DOMContentLoaded\", setupWordCounterSystem);
} else {
    setupWordCounterSystem();
}

//=============================================
// Voice dictation

// --- Safe Dictation Namespace ---
window.MudskipperDictation = {
  recognition: null,
  timeout: null,
  status: 'idle' // idle, starting, recording
};

window.toggleDictation = function() {
  // 1. Safety Check: If browser doesn't support it, just exit silently (check console).
  if (!('webkitSpeechRecognition' in window)) {
    console.warn(\"Dictation API not supported.\");
    return;
  }

  var btn = document.getElementById(\"btnDictate\");

  // 2. STOP LOGIC
  // If we are recording or starting, stop everything.
  if (window.MudskipperDictation.status !== 'idle') {
    if (window.MudskipperDictation.recognition) {
      window.MudskipperDictation.recognition.stop();
    }
    // Force cleanup just in case onend doesn't fire immediately
    clearTimeout(window.MudskipperDictation.timeout);
    window.MudskipperDictation.status = 'idle';
    resetDictationUI(btn);
    return;
  }

  // 3. START LOGIC
  var recognition = new webkitSpeechRecognition();
  recognition.continuous = true;
  recognition.interimResults = false;
  recognition.lang = \"en-US\";

  // Mark as starting so user can't double-click instantly
  window.MudskipperDictation.status = 'starting';

  recognition.onstart = function() {
    window.MudskipperDictation.status = 'recording';
    setDictationActiveUI(btn);

    // Auto-stop after 5 minutes (300,000 ms)
    window.MudskipperDictation.timeout = setTimeout(function() {
      if (window.MudskipperDictation.recognition) {
        window.MudskipperDictation.recognition.stop();
      }
    }, 300000);
  };

  recognition.onend = function() {
    window.MudskipperDictation.status = 'idle';
    resetDictationUI(btn);
    if (window.MudskipperDictation.timeout) {
        clearTimeout(window.MudskipperDictation.timeout);
    }
  };

  recognition.onresult = function(event) {
    var editor = ace.edit(\"sourceEditor\");
    var finalString = \"\";

    // Accumulate text first (don't touch DOM in loop)
    for (var i = event.resultIndex; i < event.results.length; ++i) {
      if (event.results[i].isFinal) {
        finalString += event.results[i][0].transcript + \" \";
      }
    }

    // Single Insert + Single Focus
    if (finalString.length > 0) {
      editor.insert(finalString);
      editor.focus();
    }
  };

  recognition.onerror = function(event) {
    // Log error but DO NOT alert (prevents freezing loops)
    console.error(\"Dictation error:\", event.error);
    // Force stop on error
    recognition.stop();
  };

  window.MudskipperDictation.recognition = recognition;
  recognition.start();
};

// --- UI Helpers ---
function setDictationActiveUI(btn) {
  var iconActive = `
    <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"icon icon-1 icon-blink\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\">
       <path d=\"M9 2m0 3a3 3 0 0 1 3 -3h0a3 3 0 0 1 3 3v5a3 3 0 0 1 -3 3h0a3 3 0 0 1 -3 -3z\" />
       <path d=\"M5 10a7 7 0 0 0 14 0\" />
       <path d=\"M8 21l8 0\" />
       <path d=\"M12 17l0 4\" />
    </svg>`;

  btn.innerHTML = iconActive;
  btn.classList.add(\"text-red\");
}

function resetDictationUI(btn) {
  var iconDefault = `
    <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"icon icon-1\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\">
      <path d=\"M3 3l18 18\" />
      <path d=\"M9 5a3 3 0 0 1 6 0v5a3 3 0 0 1 -.13 .874m-2 2a3 3 0 0 1 -3.87 -2.872v-1\" />
      <path d=\"M5 10a7 7 0 0 0 10.846 5.85m2 -2a6.967 6.967 0 0 0 1.152 -3.85\" />
      <path d=\"M8 21l8 0\" />
      <path d=\"M12 17l0 4\" />
    </svg>`;

  btn.innerHTML = iconDefault;
  btn.classList.remove(\"text-red\");
}



//===================Make a Copy Overlay=================

function openCopyProjectOverlay() {
        var overlay = document.getElementById('copyProjectOverlay');
        var nameInput = document.getElementById('copyProjectNameInput');
        var currentNameEl = document.getElementById('activeProjectName');

        if(overlay && nameInput && currentNameEl) {
          var currentName = currentNameEl.innerText.trim();
          nameInput.value = currentName + \" (Copy)\";
          overlay.classList.add('show');
          setTimeout(() => nameInput.focus(), 100);
        }
      }

      function closeCopyProjectOverlay() {
        var overlay = document.getElementById('copyProjectOverlay');
        if(overlay) overlay.classList.remove('show');
      }

      // Bind the Copy Button to Shiny
      $(document).on('click', '#btnCopyProjectConfirm', function() {
        var name = document.getElementById('copyProjectNameInput').value;
        if(name) {
          Shiny.setInputValue('copyProjectSubmit', name, {priority: 'event'});
          closeCopyProjectOverlay();
        }
      });
//============================================

    // --- Safe Editor Getter ---
    function getAceEditor() {
      if (typeof ace !== \"undefined\") {
        return ace.edit(\"sourceEditor\");
      }
      return null;
    }

    // --- Insert Menu Logic (Corrected Escaping) ---
    function insertLatex(type) {
      var editor = getAceEditor();
      if (!editor) return;

      var text = \"\";
      switch(type) {
        case \"inline\":
          text = \"\\\\( ${1} \\\\)\";
          break;
        case \"display\":
          text = \"\\n\\\\[ ${1}\\\\]\";
          break;
        case \"table\":
          // Uses \\\\ to ensure backslashes survive into JS
          text = \"\\\\begin{table}[h]\\n\\t\\\\centering\\n\\t\\\\begin{tabular}{ccc}\\n\\t\\t & & \\n\\t\\t & & \\n\\t\\t & & \\n\\t\\\\end{tabular}\\n\\t\\\\caption{${1:Caption}}\\n\\t\\\\label{tab:${2:placeholder}}\\n\\\\end{table}\";
          break;
        case \"cite\":
          text = \"\\\\cite{${1}}\";
          break;
        case \"link\":
          text = \"\\\\href{${1:url}}{${2:text}}\";
          break;
        case \"ref\":
          text = \"\\\\ref{${1}}\";
          break;
      }

      if (text) {
        // Check if snippet manager is available, else insert plain text
        if (editor.insertSnippet) {
            editor.insertSnippet(text);
        } else {
            editor.insert(text);
        }
      }
      editor.focus();
    }


    // helper to receive commands from R
    if (window.Shiny) {
        Shiny.addCustomMessageHandler(\"cmdInsertText\", function(data) {
          var editor = getAceEditor();
          if(editor) {
              if (data.text.includes(\"${1\")) {
                 editor.insertSnippet(data.text);
              } else {
                 editor.insert(data.text);
              }
              editor.focus();
          }
        });
    }


// --- Symbol Palette Logic ---
    function toggleSymbolPalette() {
      var p = document.getElementById(\"symbolPalette\");
      if(p) p.classList.toggle(\"show\");
    }

    // Global listener to handle symbol clicks safely
    // Updated to look for 'data-bs-original-title' because Bootstrap tooltips
    // remove the standard 'title' attribute.
    document.addEventListener(\"click\", function(e) {
      if (e.target && e.target.closest(\".symbol-btn\")) {
        var btn = e.target.closest(\".symbol-btn\");

        // Priority: 1. Bootstrap stored title, 2. Standard title, 3. Button text
        var rawTitle = btn.getAttribute(\"data-bs-original-title\") || btn.getAttribute(\"title\");

        if (rawTitle) {
           // Append a space as per your original logic
           insertSymbolToEditor(rawTitle + \" \");
        }
      }
    });

    // Unified Helper function for insertion
    // Checks for Ace Editor first, then falls back to standard textarea
    function insertSymbolToEditor(sym) {
      // 1. Try Ace Editor (RMarkdown/Shiny standard)
      if (typeof getAceEditor === \"function\") {
         var editor = getAceEditor();
         if (editor) {
            editor.insert(sym);
            editor.focus();
            return;
         }
      }

      // 2. Fallback to standard Textarea (sourceEditor)
      var txtEditor = document.getElementById(\"sourceEditor\");
      if (txtEditor) {
        var start = txtEditor.selectionStart;
        var end = txtEditor.selectionEnd;
        var text = txtEditor.value;
        var before = text.substring(0, start);
        var after = text.substring(end);
        txtEditor.value = before + sym + after;
        txtEditor.selectionStart = txtEditor.selectionEnd = start + sym.length;
        txtEditor.focus();
        // Trigger input event for reactivity in Shiny
        txtEditor.dispatchEvent(new Event(\"input\", { bubbles: true }));
      }
    }

    // Dummy function to satisfy the inline onclick generated by R
    // (The actual work is done by the event listener above)
    function insertSymbol(arg) {}

    // Search function updated to read Bootstrap tooltip titles
    function filterSymbols(query) {
      var q = query.toLowerCase();

      // Handle the active tab context or search all (based on your preference).
      // Here we search all buttons to ensure results aren't hidden by inactive tabs.
      var btns = document.querySelectorAll(\".symbol-btn\");

      btns.forEach(function(btn) {
        // Retrieve title from Bootstrap's storage or native attribute
        var title = btn.getAttribute(\"data-bs-original-title\") || btn.getAttribute(\"title\") || \"\";
        var text = btn.innerText || \"\";

        if (title.toLowerCase().includes(q) || text.toLowerCase().includes(q)) {
          btn.style.display = \"inline-flex\"; // Ensure layout doesn't break
        } else {
          btn.style.display = \"none\";
        }
      });
    }

    // Initialize Tabs manually (if Bootstrap JS isn't fully loading tabs)
    // and Symbol Palette logic on load
    document.addEventListener(\"DOMContentLoaded\", function() {
       var tabButtons = document.querySelectorAll(\"#symbolPalette .nav-link\");
       tabButtons.forEach(function(btn) {
          btn.addEventListener(\"click\", function(e) {
             e.preventDefault();
             // 1. Deactivate all tabs
             tabButtons.forEach(function(b) { b.classList.remove(\"active\"); });
             document.querySelectorAll(\".tab-pane\").forEach(function(p) {
                p.classList.remove(\"show\", \"active\");
             });

             // 2. Activate clicked tab
             this.classList.add(\"active\");
             var targetId = this.getAttribute(\"data-bs-target\");
             var targetPane = document.querySelector(targetId);
             if(targetPane) targetPane.classList.add(\"show\", \"active\");

             // 3. Reset Search visibility in the new tab if needed
             var searchInput = document.getElementById(\"symbolSearch\");
             if (searchInput && searchInput.value) {
                filterSymbols(searchInput.value);
             }
          });
       });
    });


/* =================== FIGURE OVERLAY LOGIC =================== */
// Initialize figure overlay
function initFigureOverlay() {
  // Ensure Dropzone is properly initialized when needed
  document.addEventListener('click', function(e) {
    if (e.target.closest('.nav-item') &&
        e.target.closest('.nav-item').querySelector('[onclick*=\"openFigureOverlay\"]')) {
      setTimeout(initFigureDropzone, 300);
    }
  });
}

// Tab Switcher (Clean implementation)
function switchFigureTab(event, tabId) {
  if (event) event.preventDefault();

  // Update Nav Links
  var navLinks = document.querySelectorAll('#figureOverlay .settings-nav .nav-link');
  navLinks.forEach(function(l) { l.classList.remove('active'); });

  var clicked = document.querySelector('#figureOverlay .nav-link[href=\"#' + tabId + '\"]');
if (clicked) clicked.classList.add('active');

// Update Panes
var panes = document.querySelectorAll('#figureOverlay .tab-pane');
panes.forEach(function(p) { p.classList.remove('show', 'active'); });

var target = document.getElementById(tabId);
if (target) target.classList.add('show', 'active');

// Trigger Server Update for lists
if (window.Shiny) {
  Shiny.setInputValue(\"figureTabChanged\", tabId, {priority: \"event\"});
}
}

// Open Figure Overlay
function openFigureOverlay(tabId) {
  var overlay = document.getElementById('figureOverlay');
  if (overlay) {
    overlay.classList.add('show');
    document.body.style.overflow = 'hidden';

    // Default to first tab
    tabId = tabId || 'fig-upload-tab';
    switchFigureTab(null, tabId);

    // Trigger server to populate lists
    if (window.Shiny) {
      Shiny.setInputValue(\"figureOverlayOpened\", Math.random(), {priority: \"event\"});
    }
  }
}

// Close Figure Overlay
function closeFigureOverlay() {
  var overlay = document.getElementById('figureOverlay');
  if (overlay) {
    overlay.classList.remove('show');
    document.body.style.overflow = '';
  }
}

// Handle Escape key
document.addEventListener('keydown', function(e) {
  if (e.key === 'Escape') {
    var ov = document.getElementById('figureOverlay');
    if (ov && ov.classList.contains('show')) closeFigureOverlay();
  }
});

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', initFigureOverlay);



/* =================== FIXED FIGURE DROPZONE LOGIC =================== */
function initFigureDropzone() {
  // Prevent double initialization
  if (document.getElementById('dropzone-figure').dropzone) return;

  new Dropzone(\"#dropzone-figure\", {
    url: \"javascript:void(0);\", // Client-side only
    autoProcessQueue: false,
    maxFiles: 1,
    uploadMultiple: false,
    createImageThumbnails: true,
    acceptedFiles: 'image/*,application/pdf',
    init: function() {
      var myDropzone = this;

      this.on(\"addedfile\", function(file) {
        // 1. Remove previous files if any (enforce maxFiles: 1 visually)
        if (this.files.length > 1) {
          this.removeFile(this.files[0]);
        }

        // 2. Auto-fill filename input
        var nameInput = document.getElementById('fig_upload_name');
        if(nameInput) {
           nameInput.value = file.name;
           // Trigger input event for Shiny
           nameInput.dispatchEvent(new Event('input', { bubbles: true }));
        }

        // 3. Read file content IMMEDIATELY
        var reader = new FileReader();
        reader.onload = function(event) {
          // Send raw data to Shiny immediately
          if(window.Shiny) {
            Shiny.setInputValue('figDropzoneData', {
              name: file.name,
              data: event.target.result, // This is the Base64 string
              nonce: Math.random()
            }, {priority: 'event'});
          }
        };
        reader.readAsDataURL(file);
      });

      this.on(\"removedfile\", function(file) {
         if(this.files.length === 0 && window.Shiny) {
            Shiny.setInputValue('figDropzoneData', null);
         }
      });
    }
  });
}

// Hook into the existing open function
var originalOpenFigureOverlay = window.openFigureOverlay;
window.openFigureOverlay = function(tabId) {
  originalOpenFigureOverlay(tabId);
  setTimeout(initFigureDropzone, 200); // Init dropzone after modal shows
};


//========================== Katex Math Preview (Controllable) =======================//

(function() {
  // Global Controller for External Access
  window.MathPreviewController = {
    editor: null,
    mathPopup: null,
    debounceTimer: null,
    lastRenderedEquation: null,
    isEnabled: false,

    // Store bound function references for cleaner removal
    _onCursorChange: null,
    _onScroll: null,
    _onBlur: null,

    init: function() {
      // 1. Create Popup (Idempotent check)
      if (!document.getElementById('math-preview-popup')) {
        this.mathPopup = document.createElement('div');
        this.mathPopup.id = 'math-preview-popup';
        document.body.appendChild(this.mathPopup);
      } else {
        this.mathPopup = document.getElementById('math-preview-popup');
      }

      // 2. Wait for Ace Editor
      var self = this;
      var checkAce = setInterval(function() {
        if (typeof ace !== 'undefined') {
          var editor = ace.edit('sourceEditor');
          if (editor) {
            clearInterval(checkAce);
            self.editor = editor;
            // Bind handlers once
            self._onCursorChange = function() {
               if (self.debounceTimer) clearTimeout(self.debounceTimer);
               self.debounceTimer = setTimeout(function() {
                 self.detectAndRenderMath();
               }, 100);
            };
            self._onScroll = function() { self.hidePopup(); };
            self._onBlur = function() { self.hidePopup(); };

            // Default: Enable
            self.enable();
          }
        }
      }, 500);
    },

    enable: function() {
      if (this.isEnabled || !this.editor) return;

      this.editor.selection.on('changeCursor', this._onCursorChange);
      this.editor.session.on('changeScrollTop', this._onScroll);
      this.editor.on('blur', this._onBlur);

      this.isEnabled = true;
    },

    disable: function() {
      if (!this.isEnabled || !this.editor) return;

      this.editor.selection.off('changeCursor', this._onCursorChange);
      this.editor.session.off('changeScrollTop', this._onScroll);
      this.editor.off('blur', this._onBlur);

      this.hidePopup();
      this.isEnabled = false;
    },

    hidePopup: function() {
      if (this.mathPopup) {
        this.mathPopup.classList.remove('visible');
        this.lastRenderedEquation = null;
      }
    },

    // --- YOUR ORIGINAL CORE LOGIC PRESERVED BELOW ---

    cleanLatexForPreview: function(tex) {
      tex = tex.replace(/\\\\label\\{[^}]*\\}/g, '');
      tex = tex.replace(/\\\\begin\\{(equation|align|gather|split|multline|flalign)\\}/g, '\\\\begin{$1*}');
      tex = tex.replace(/\\\\end\\{(equation|align|gather|split|multline|flalign)\\}/g, '\\\\end{$1*}');
      return tex.trim();
    },

    detectAndRenderMath: function() {
      if (!this.editor) return;
      var pos = this.editor.getCursorPosition();
      var session = this.editor.getSession();
      var doc = session.getDocument();
      var mathData = null;

      // STRATEGY 1: Block math
      mathData = this.findBlockMath(doc, pos.row, pos.column);

      // STRATEGY 2: Inline math
      if (!mathData) {
        var lineText = session.getLine(pos.row);
        mathData = this.findInlineMath(lineText, pos.column);
      }

      if (mathData) {
        var equationKey = mathData.tex + '|' + mathData.isDisplay;
        if (equationKey === this.lastRenderedEquation) return;

        var cleanTex = this.cleanLatexForPreview(mathData.tex);

        try {
          // Ensure KaTeX is loaded
          if (typeof katex !== 'undefined') {
            katex.render(cleanTex, this.mathPopup, {
              displayMode: mathData.isDisplay,
              throwOnError: false,
              output: 'htmlAndMathml',
              strict: false,
              trust: false
            });

            this.lastRenderedEquation = equationKey;
            this.updatePopupPosition(pos.row, pos.column, mathData.isDisplay);
            this.mathPopup.classList.add('visible');
          }
        } catch(e) {
          console.warn('KaTeX render error:', e);
          this.hidePopup();
        }
      } else {
        this.hidePopup();
      }
    },

    findInlineMath: function(line, col) {
      var parenRegex = /\\\\\\(.*?\\\\\\)/g;
      var match;
      while ((match = parenRegex.exec(line)) !== null) {
        var start = match.index;
        var end = start + match[0].length;
        if (col >= start && col <= end) {
          return { tex: match[0].slice(2, -2), isDisplay: false };
        }
      }

      var dollarRegex = /(?<!\\\\)(?<!\\$)\\$(?!\\$)([^\\$]+?)\\$/g;
      while ((match = dollarRegex.exec(line)) !== null) {
        var start = match.index;
        var end = start + match[0].length;
        if (col >= start && col <= end) {
          return { tex: match[1], isDisplay: false };
        }
      }
      return null;
    },

    findBlockMath: function(doc, currentRow, currentCol) {
      var totalLines = doc.getLength();
      var maxLookUp = 100;
      var maxLookDown = 100;

      var startRow = -1, endRow = -1;
      var startCol = -1, endCol = -1;
      var blockType = null;
      var envName = null;

      // SEARCH UPWARDS
      for (var r = currentRow; r >= Math.max(0, currentRow - maxLookUp); r--) {
        var line = doc.getLine(r);
        var beginMatch = line.match(/\\\\begin\\{(equation|align|gather|split|multline|flalign|eqnarray|alignat|math|displaymath)\\*?\\}/);
        if (beginMatch) {
          startRow = r; startCol = line.indexOf(beginMatch[0]);
          blockType = 'env'; envName = beginMatch[1];
          break;
        }
        var bracketIdx = line.indexOf('\\\\]');
        if (bracketIdx !== -1) { /* Skip if end bracket found first */ }

        var startBracketIdx = line.indexOf('\\\\[');
        if (startBracketIdx !== -1) {
           startRow = r; startCol = startBracketIdx; blockType = 'bracket'; break;
        }

        var dollarIdx = line.indexOf('$$');
        if (dollarIdx !== -1) {
           startRow = r; startCol = dollarIdx; blockType = 'dollar'; break;
        }

        // Break if we hit a definite end delimiter before a start
        if (r < currentRow) {
           if (line.match(/\\\\end\\{/) || line.indexOf('\\\\]') !== -1) return null;
        }
      }

      if (startRow === -1) return null;
      if (currentRow === startRow && currentCol < startCol) return null;

      // SEARCH DOWNWARDS
      for (var r = (blockType === 'dollar' ? startRow : currentRow); r <= Math.min(totalLines - 1, currentRow + maxLookDown); r++) {
        var line = doc.getLine(r);
        if (blockType === 'env') {
          var endPattern = new RegExp('\\\\\\\\end\\\\{' + envName + '\\\\*?\\\\}');
          var endMatch = line.match(endPattern);
          if (endMatch) {
            endRow = r; endCol = line.indexOf(endMatch[0]) + endMatch[0].length; break;
          }
        } else if (blockType === 'bracket') {
          var bracketIdx = line.indexOf('\\\\]');
          if (bracketIdx !== -1) {
            endRow = r; endCol = bracketIdx + 2; break;
          }
        } else if (blockType === 'dollar') {
          var dollarIdx = line.indexOf('$$');
          if (dollarIdx !== -1 && (r > startRow || (r === startRow && dollarIdx > startCol))) {
            endRow = r; endCol = dollarIdx + 2; break;
          }
        }
      }

      if (endRow === -1) return null;
      if (currentRow === endRow && currentCol > endCol) return null;

      var fullText = '';
      if (startRow === endRow) {
        var line = doc.getLine(startRow);
        if (blockType === 'env') fullText = line;
        else if (blockType === 'bracket') {
           fullText = line.substring(line.indexOf('\\\\[') + 2, line.indexOf('\\\\]'));
        } else if (blockType === 'dollar') {
           var d1 = line.indexOf('$$'); var d2 = line.indexOf('$$', d1+2);
           fullText = line.substring(d1+2, d2);
        }
      } else {
        fullText = doc.getLines(startRow, endRow).join('\\n');
        if (blockType === 'bracket') {
           fullText = fullText.substring(fullText.indexOf('\\\\[') + 2, fullText.lastIndexOf('\\\\]'));
        } else if (blockType === 'dollar') {
           fullText = fullText.replace(/\\$\\$/g, '');
        }
      }

      return { tex: fullText.trim(), isDisplay: true };
    },

    updatePopupPosition: function(row, col, isDisplay) {
      var coords = this.editor.renderer.textToScreenCoordinates(row, col);
      var lineHeight = this.editor.renderer.lineHeight;
      var offset = isDisplay ? 20 : 10;

      this.mathPopup.style.left = (coords.pageX + 10) + 'px';
      this.mathPopup.style.top = (coords.pageY + lineHeight + offset) + 'px';
      this.mathPopup.style.display = 'block'; // Measure

      var rect = this.mathPopup.getBoundingClientRect();
      var viewportWidth = window.innerWidth;
      var viewportHeight = window.innerHeight;

      if (rect.right > viewportWidth - 20) {
        this.mathPopup.style.left = Math.max(20, viewportWidth - rect.width - 20) + 'px';
      }
      if (rect.bottom > viewportHeight - 20) {
        this.mathPopup.style.top = (coords.pageY - rect.height - 10) + 'px';
      }
    }
  };

  // --- INITIALIZATION & BINDING ---

  if (typeof $ !== 'undefined') {
    $(document).ready(function() {
      // Initialize Controller
      window.MathPreviewController.init();

      // Bind to Settings Panel Toggle
      $(document).on('change', '#enableMathPreviewPanel', function() {
         if (this.checked) {
            window.MathPreviewController.enable();
         } else {
            window.MathPreviewController.disable();
         }
      });
    });
  } else {
    // Fallback for non-jQuery environments
    document.addEventListener('DOMContentLoaded', function() {
       window.MathPreviewController.init();
    });
  }

})();



//==================COMPILE PROCESS INPUTS==============//

// Bind Custom Dropdown Radios to Shiny Inputs
  $(document).on('change', 'input[name=\"compileMode\"]', function() {
    Shiny.setInputValue('compileMode', this.value, {priority: 'event'});
  });

  $(document).on('change', 'input[name=\"syntaxCheck\"]', function() {
    Shiny.setInputValue('syntaxCheck', this.value, {priority: 'event'});
  });

  $(document).on('change', 'input[name=\"errorHandling\"]', function() {
    Shiny.setInputValue('errorHandling', this.value, {priority: 'event'});
  });


//================ LOCK functionality: 1. Idle Timer ====================//
var idleTimer;
// Load saved preference or default to never (0)
var lockDuration = parseInt(localStorage.getItem('mudskipper_lock_duration')) || 0;

function resetIdleTimer() {
  clearTimeout(idleTimer);

  // If 0, autolock is disabled
  if (lockDuration > 0) {
    idleTimer = setTimeout(function() {
      if(window.Shiny) Shiny.setInputValue('app_idle_lock', Math.random(), {priority: 'event'});
    }, lockDuration);
  }
}

// Activity listeners
window.onmousemove = resetIdleTimer;
window.onmousedown = resetIdleTimer;
window.onkeypress = resetIdleTimer;

// --- Settings Listener (NEW) ---
document.addEventListener(\"DOMContentLoaded\", function() {
  const lockPanel = document.getElementById('autolockTimePanel');
  if (lockPanel) {
    // 1. Sync dropdown with saved value
    lockPanel.value = lockDuration.toString();

    // 2. Listen for changes
    lockPanel.addEventListener('change', function() {
      lockDuration = parseInt(this.value);
      localStorage.setItem('mudskipper_lock_duration', lockDuration);
      resetIdleTimer(); // Apply new duration immediately
    });
  }
});

// --- 2. Startup: Check for Lock Cookie (YOUR EXISTING LOGIC) ---
$(document).ready(function() {
  resetIdleTimer();

  // Check if 'app_locked_user' cookie exists
  var match = document.cookie.match(new RegExp('(^| )app_locked_user=([^;]+)'));
  if (match) {
    var email = decodeURIComponent(match[2]);

    // Force UI to Locked State immediately
    $('#auth_wrapper').hide();
    $('#main_app_wrapper').hide();
    $('#lock_wrapper').show();

    // Tell R to restore the locked user state
    var checkShiny = setInterval(function() {
      if (window.Shiny && window.Shiny.setInputValue) {
        Shiny.setInputValue('restore_lock_state', email, {priority: 'event'});
        clearInterval(checkShiny);
      }
    }, 100);
  }
});

//================ Sticky scroll functionality====================//

/**
 * Sticky Scroll - Hardened Golden Master Edition
 * * COMBINED FEATURES:
 * 1. NATIVE SCOPE MAPPING: Uses Ace's internal folding engine.
 * 2. CENTER-TRIGGER PHYSICS: Docks and slides exactly when hitting the center.
 * 3. ANTI-FREEZE TIME BUDGET: Strict 12ms limit on background scans to maintain 60fps.
 * 4. ACTIVE SESSION MANAGER: Cleans up zombie listeners during Shiny file switches.
 * 5. R-SAFE STRINGS: All double quotes rigorously escaped for seamless Shiny injection.
 */

(function(window) {
  'use strict';

  const CONFIG = {
    maxStickyLines: 8,
    zIndex: 5,
    highlightClass: 'ace_sticky_ghost_highlight'
  };

  class StickyScroll {
    constructor(editorId) {
      this.editorId = editorId;
      this.editor = null;
      this.stickyWrapper = null;
      this.isEnabled = false;

      this.previousStack = '';
      this.ticking = false;
      this.scopeRanges = new Map();
      this.activeMarkerId = null;

      // Bindings for safe cleanup and session swapping
      this.onScroll = this.onScroll.bind(this);
      this.onFoldChange = () => this.update(true);
      this.onSessionChange = this.onSessionChange.bind(this);
      this.onResize = () => this.update(true);
      this.onThemeLoad = () => this.update(true);

      this.debouncedUpdate = this.debounce(() => this.update(true), 100).bind(this);

      // CRITICAL FIX: Clear cache synchronously on text change to prevent out-of-bounds errors
      this.onContentChange = () => {
        this.scopeRanges.clear();
        this.debouncedUpdate();
      };

      this.syncHorizontal = this.syncHorizontal.bind(this);
      this.update = this.update.bind(this);

      this.Range = ace.require('ace/range').Range;

      this.init();
    }

    init() {
      this.injectStyles();
      const waitForAce = setInterval(() => {
        const editor = ace.edit(this.editorId);
        if (editor && editor.renderer && editor.session) {
          clearInterval(waitForAce);
          this.editor = editor;
          this.enable();
        }
      }, 100);
    }

    /* --- SETTINGS CONTROL --- */

    enable() {
      if (this.isEnabled || !this.editor) return;
      this.createWrapper();
      this.attachListeners();
      this.isEnabled = true;
      this.update(true);
    }

    disable() {
      if (!this.isEnabled) return;
      this.detachListeners();
      if (this.stickyWrapper) {
        this.stickyWrapper.remove();
        this.stickyWrapper = null;
      }
      this.removeGhostHighlight();
      this.isEnabled = false;
    }

    /* --- DOM & STYLES --- */

    injectStyles() {
      if (document.getElementById('ace_sticky_styles')) return;
      const style = document.createElement('style');
      style.id = 'ace_sticky_styles';
      style.innerHTML = `
        .ace_sticky_ghost_highlight {
          position: absolute;
          background-color: rgba(128, 128, 128, 0.15);
          border-left: 2px solid rgba(128, 128, 128, 0.5);
          z-index: 5;
        }
        .ace_sticky_layer {
          overflow: hidden;
          will-change: height;
        }
        .ace_sticky_fold_icon {
          display: inline-block;
          width: 10px;
          height: 10px;
          margin-right: 4px;
          opacity: 0.7;
          background-repeat: no-repeat;
          background-position: center;
          background-size: contain;
          background-image: url('data:image/svg+xml;utf8,<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"4\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><polyline points=\"6 9 12 15 18 9\"></polyline></svg>');
          filter: invert(0.5);
          cursor: pointer;
          transition: transform 0.1s;
          pointer-events: auto;
        }
        .ace_dark .ace_sticky_fold_icon {
          filter: invert(0.8);
        }
        .ace_sticky_fold_icon.closed {
          transform: rotate(-90deg);
        }
        .ace_sticky_fold_icon:hover {
          transform: scale(1.2);
          opacity: 1;
        }
        .ace_sticky_fold_icon.closed:hover {
          transform: rotate(-90deg) scale(1.2);
        }
      `;
      document.head.appendChild(style);
    }

createWrapper() {
  this.stickyWrapper = document.createElement('div');
  this.stickyWrapper.className = 'ace_sticky_layer';

  Object.assign(this.stickyWrapper.style, {
    position: 'absolute',
    top: '0',
    left: '0',
    right: '0',
    width: '100%',
    boxSizing: 'border-box',

    zIndex: CONFIG.zIndex,

    background: 'transparent',
    pointerEvents: 'none',
    boxShadow: `
      0 1px 0 rgba(255,255,255,0.04) inset,
      0 2px 6px rgba(0,0,0,0.35)
    `,

    /* subtle separator line */
    borderBottom: '1px solid rgba(255,255,255,0.2)',

    /* modern smoothness */
    backdropFilter: 'blur(2px)',
    WebkitBackdropFilter: 'blur(2px)',

    /* smoother rendering */
    transform: 'translateZ(0)',
    willChange: 'transform'
  });

  this.editor.container.appendChild(this.stickyWrapper);
}


    /* --- ACTIVE SESSION MANAGER --- */

    attachListeners() {
      // Editor-level listeners
      this.editor.on('changeSession', this.onSessionChange);
      this.editor.on('change', this.onContentChange);
      this.editor.renderer.on('themeLoaded', this.onThemeLoad);
      window.addEventListener('resize', this.onResize);

      // Session-level listeners
      this.attachSessionListeners(this.editor.session);
    }

    detachListeners() {
      this.editor.off('changeSession', this.onSessionChange);
      this.editor.off('change', this.onContentChange);
      this.editor.renderer.off('themeLoaded', this.onThemeLoad);
      window.removeEventListener('resize', this.onResize);

      this.detachSessionListeners(this.editor.session);
    }

    attachSessionListeners(session) {
      if (!session) return;
      session.on('changeScrollTop', this.onScroll);
      session.on('changeFold', this.onFoldChange);
      session.on('changeScrollLeft', this.syncHorizontal);
    }

    detachSessionListeners(session) {
      if (!session) return;
      session.off('changeScrollTop', this.onScroll);
      session.off('changeFold', this.onFoldChange);
      session.off('changeScrollLeft', this.syncHorizontal);
    }

    // CRITICAL FIX: Cleanly swaps listeners when Shiny changes files/modes
    onSessionChange(e) {
      this.detachSessionListeners(e.oldSession);
      this.attachSessionListeners(e.session);
      this.scopeRanges.clear();
      this.update(true);
    }

    onScroll() {
      if (!this.ticking) {
        requestAnimationFrame(() => {
          this.update();
          this.ticking = false;
        });
        this.ticking = true;
      }
    }

    /* --- NATIVE FOLD ENGINE PHYSICS --- */

    getFoldRange(row) {
      if (this.scopeRanges.has(row)) return this.scopeRanges.get(row);
      const range = this.editor.session.getFoldWidgetRange(row);
      if (range) {
          this.scopeRanges.set(row, range);
          return range;
      }
      return null;
    }

    traceScopes(startRow) {
      const session = this.editor.session;
      const collectedRows = [];
      const limit = Math.max(0, startRow - 5000);

      // ANTI-FREEZE: strict 12ms time budget per frame to ensure 60fps scrolling
      const startTime = performance.now();

      for (let r = startRow; r >= limit; r--) {
          if (performance.now() - startTime > 12) {
              break; // Gracefully yield to prevent browser lockup
          }

          if (session.getFoldWidget(r) === 'start') {
              const range = this.getFoldRange(r);
              // Mathematics perfectly confirm an ancestor if its end row wraps the start row
              if (range && range.end.row >= startRow) {
                  collectedRows.unshift(r);
                  if (collectedRows.length >= CONFIG.maxStickyLines) break;
              }
          }
      }
      return collectedRows;
    }

    scanForStickyRows() {
      const session = this.editor.session;
      const scrollTop = session.getScrollTop();
      const lineHeight = this.editor.renderer.lineHeight;
      const maxLines = CONFIG.maxStickyLines;

      const topScreenRow = Math.max(0, Math.floor(scrollTop / lineHeight));
      const topDocRow = session.screenToDocumentRow(topScreenRow, 0);
      const baseStack = this.traceScopes(topDocRow);

      const dockingStack = [];
      let searchEndRow = session.screenToDocumentRow(topScreenRow + maxLines + 2, 0);
      searchEndRow = Math.min(searchEndRow, session.getLength() - 1);

      const buffer = lineHeight / 2;

      for (let r = topDocRow + 1; r <= searchEndRow; r++) {
         if (session.getFoldWidget(r) === 'start') {
             const range = this.getFoldRange(r);
             if (range && range.end.row > r) {
                const targetSlotIndex = baseStack.length + dockingStack.length;
                if (targetSlotIndex >= maxLines) break;

                const rowPixelTop = session.documentToScreenRow(r, 0) * lineHeight;
                const slotPixelTop = scrollTop + (targetSlotIndex * lineHeight);

                if (rowPixelTop <= slotPixelTop + buffer) {
                   dockingStack.push(r);
                } else {
                   break;
                }
             }
         }
      }

      return [...baseStack, ...dockingStack];
    }

    update(forceRebuild = false) {
      if (!this.isEnabled || !this.editor) return;

      const rows = this.scanForStickyRows();
      const rowString = rows.join(',');

      if (forceRebuild || this.previousStack !== rowString) {
          this.previousStack = rowString;

          if (rows.length === 0) {
            if (this.stickyWrapper) {
                this.stickyWrapper.innerHTML = '';
                this.stickyWrapper.style.display = 'none';
            }
          } else {
            if (this.stickyWrapper) {
                this.stickyWrapper.style.display = 'block';
                this.renderDOM(rows);
            }
          }
      }

      if (rows.length > 0 && this.stickyWrapper) {
          const lineHeight = this.editor.renderer.lineHeight;
          const offset = this.computePhysicsOffset(rows);

          const stackHeight = (rows.length * lineHeight) + offset;
          this.stickyWrapper.style.height = `${stackHeight}px`;

          Array.from(this.stickyWrapper.children).forEach(child => {
              child.style.transform = 'none';
          });

          if (offset < 0 && this.stickyWrapper.lastElementChild) {
              this.stickyWrapper.lastElementChild.style.transform = `translateY(${offset}px)`;
          }
      }
    }

    computePhysicsOffset(rows) {
      if (rows.length === 0) return 0;
      const lastRow = rows[rows.length - 1];
      const range = this.getFoldRange(lastRow);

      if (range && range.end.row) {
        const renderer = this.editor.renderer;
        const session = this.editor.session;
        const scrollTop = session.getScrollTop();
        const lineHeight = renderer.lineHeight;

        const screenEndRow = session.documentToScreenRow(range.end.row, 0);
        const endRowPixelTop = (screenEndRow * lineHeight) - scrollTop;

        const lastSlotTop = (rows.length - 1) * lineHeight;
        const lastSlotBottom = rows.length * lineHeight;

        const buffer = lineHeight / 2;
        const triggerBottom = lastSlotBottom + buffer;
        const triggerTop = lastSlotTop + buffer;

        if (endRowPixelTop <= triggerBottom && endRowPixelTop > triggerTop) {
           return endRowPixelTop - triggerBottom;
        }
        if (endRowPixelTop <= triggerTop) {
           return -lineHeight;
        }
      }
      return 0;
    }

    /* --- COLORS & RENDERING --- */

    findOpaqueBackground(element) {
      if (!element) return null;
      let el = element;
      while (el) {
        const style = window.getComputedStyle(el);
        const bgColor = style.backgroundColor;
        if (bgColor && bgColor !== 'transparent' && bgColor.replace(/\\s/g, '') !== 'rgba(0,0,0,0)') {
          return bgColor;
        }
        if (el.tagName === 'BODY') break;
        el = el.parentElement;
      }
      return null;
    }

    getColors() {
      const renderer = this.editor.renderer;
      const gutterEl = renderer.$gutterLayer.element;
      const scrollerEl = renderer.scroller;
      const gutterStyle = window.getComputedStyle(gutterEl);
      const scrollerStyle = window.getComputedStyle(scrollerEl);
      return {
        editorBg: this.findOpaqueBackground(scrollerEl) || '#ffffff',
        gutterBg: this.findOpaqueBackground(gutterEl) || '#f0f0f0',
        gutterColor: gutterStyle.color,
        borderRight: gutterStyle.borderRight,
        textColor: scrollerStyle.color,
        fontFamily: scrollerStyle.fontFamily,
        fontSize: scrollerStyle.fontSize
      };
    }

    renderDOM(rows) {
      const renderer = this.editor.renderer;
      const config = {
        lineHeight: renderer.lineHeight,
        gutterWidth: renderer.$gutterLayer.element.offsetWidth,
        scrollLeft: this.editor.session.getScrollLeft(),
        padding: renderer.$padding || 4
      };
      const colors = this.getColors();
      const fragment = document.createDocumentFragment();

      rows.forEach((rowNum, index) => {
        const rowEl = this.createStickyLine(rowNum, config, colors);
        rowEl.style.position = 'relative';
        rowEl.style.zIndex = 100 - index;
        fragment.appendChild(rowEl);
      });

      this.stickyWrapper.innerHTML = '';
      this.stickyWrapper.appendChild(fragment);
      this.stickyWrapper.style.right = `${renderer.scrollBarV.width}px`;
    }

    /* --- THE DETERMINISTIC HELPERS --- */

    findFoldAtRow(row) {
        const session = this.editor.session;
        const range = new this.Range(row, 0, row, Number.MAX_VALUE);
        const folds = session.getFoldsInRange(range);
        return folds.find(f => f.start.row === row);
    }

    toggleFold(row, existingFold) {
       const session = this.editor.session;
       try {
         if (existingFold) {
             session.removeFold(existingFold);
         } else {
             const range = session.getFoldWidgetRange(row);
             if (range) {
                 session.addFold(\"...\", range);
             }
         }
       } catch(e) { console.error('Fold error', e); }
    }

    createStickyLine(rowNum, config, colors) {
      const rowEl = document.createElement('div');
      rowEl.className = 'ace_sticky_row';
      Object.assign(rowEl.style, {
        display: 'flex',
        height: `${config.lineHeight}px`,
        width: '100%',
        backgroundColor: colors.editorBg,
        cursor: 'pointer',
        overflow: 'hidden',
        pointerEvents: 'auto'
      });

      const gutter = document.createElement('div');
      Object.assign(gutter.style, {
        minWidth: `${config.gutterWidth}px`,
        width: `${config.gutterWidth}px`,
        textAlign: 'right',
        paddingRight: '4px',
        color: colors.gutterColor,
        backgroundColor: colors.gutterBg,
        borderRight: colors.borderRight,
        lineHeight: `${config.lineHeight}px`,
        boxSizing: 'border-box',
        display: 'flex',
        justifyContent: 'flex-end',
        alignItems: 'center'
      });

      const foldMode = this.editor.session.getFoldWidget(rowNum);
      if (foldMode === 'start') {
        const icon = document.createElement('span');
        icon.className = 'ace_sticky_fold_icon';

        const activeFold = this.findFoldAtRow(rowNum);
        if (activeFold) {
          icon.classList.add('closed');
        }

        icon.onclick = (e) => {
           e.stopPropagation();
           this.toggleFold(rowNum, activeFold);
        };
        gutter.appendChild(icon);
      }

      const lineNum = document.createElement('span');
      lineNum.textContent = String(rowNum + 1);
      gutter.appendChild(lineNum);

      const content = document.createElement('div');
      Object.assign(content.style, {
        position: 'relative',
        flex: 1,
        overflow: 'hidden',
        color: colors.textColor
      });
      const lineText = this.editor.session.getLine(rowNum);
      content.setAttribute('title', lineText.trim());

      const code = document.createElement('div');
      code.className = 'ace_line';
      Object.assign(code.style, {
        position: 'absolute',
        top: '0',
        left: `${config.padding - config.scrollLeft}px`,
        width: '100%',
        whiteSpace: 'pre',
        lineHeight: `${config.lineHeight}px`,
        fontFamily: colors.fontFamily,
        fontSize: colors.fontSize
      });

      const tokens = this.editor.session.getTokens(rowNum);
      const html = tokens.map(t => {
         const safeVal = t.value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
         return `<span class=\"ace_${t.type.replace(/\\./g, ' ace_')}\">${safeVal}</span>`;
      }).join('');

      code.innerHTML = html;
      content.appendChild(code);
      rowEl.appendChild(gutter);
      rowEl.appendChild(content);

      rowEl.onclick = (e) => {
        e.preventDefault(); e.stopPropagation();
        this.jumpTo(rowNum);
      };

      rowEl.onmouseenter = () => {
        rowEl.style.filter = 'brightness(95%)';
        this.addGhostHighlight(rowNum);
      };
      rowEl.onmouseleave = () => {
        rowEl.style.filter = 'none';
        this.removeGhostHighlight();
      };

      return rowEl;
    }

    jumpTo(row) {
      this.editor.scrollToLine(row, true, false, () => {});
      this.editor.gotoLine(row + 1, 0, false);
      setTimeout(() => {
        this.editor.renderer.updateFull();
        this.editor.focus();
      }, 0);
    }

    addGhostHighlight(startRow) {
      const range = this.getFoldRange(startRow);
      if (range && range.end.row) {
        this.removeGhostHighlight();
        const highlightRange = new this.Range(startRow, 0, range.end.row, Infinity);
        this.activeMarkerId = this.editor.session.addMarker(highlightRange, CONFIG.highlightClass, 'fullLine');
      }
    }

    removeGhostHighlight() {
      if (this.activeMarkerId) {
        this.editor.session.removeMarker(this.activeMarkerId);
        this.activeMarkerId = null;
      }
    }

    syncHorizontal() {
      const scrollLeft = this.editor.session.getScrollLeft();
      const padding = this.editor.renderer.$padding || 4;
      if (this.stickyWrapper) {
        const lines = this.stickyWrapper.querySelectorAll('.ace_line');
        lines.forEach(l => l.style.left = `${padding - scrollLeft}px`);
      }
    }

    debounce(func, wait) {
      let timeout;
      return (...args) => {
        clearTimeout(timeout);
        timeout = setTimeout(() => func.apply(this, args), wait);
      };
    }
  }

  window.enableStickyScroll = (id) => new StickyScroll(id);

  if (typeof $ !== 'undefined') {
    $(document).ready(() => {
      const initCheck = setInterval(() => {
        if (typeof ace !== 'undefined' && ace.edit('sourceEditor')) {
          clearInterval(initCheck);
          window.stickyScrollInstance = new StickyScroll('sourceEditor');
        }
      }, 500);

      $(document).on('change', '#enableStickyScrollPanel', function() {
          if (!window.stickyScrollInstance) return;
          if (this.checked) window.stickyScrollInstance.enable();
          else window.stickyScrollInstance.disable();
      });
    });
  }

})(window);


//================ Minimap functionality====================//

/**
 * Ace Minimap - Enhanced Golden Master Edition
 * * FEATURES:
 * 1. SYNTAX-AWARE: Inherits the exact Ace syntax mode and theme.
 * 2. WRAP SYNC: Explicitly forces minimap wrap limits to match the main editor.
 * 3. OUTSIDE EDITOR: Minimap is placed outside the main editor to prevent text overlap.
 * 4. CONFLICT-FREE: Disables and hides native vertical scrollbars on the main editor.
 * 5. R-SAFE STRINGS: Uses safe string concatenation and escapes for Shiny injection.
 */

(function(window) {
  'use strict';

  var CONFIG = {
    minimapWidth: 40, // Width in pixels
    fontSize: '1px',
    sliderColor: 'rgba(140, 140, 140, 0.62)',
    sliderHover: 'rgba(140, 140, 140, 0.42)',
    sliderActive: 'rgba(140, 140, 140, 0.62)'
  };

  class AceMinimap {
    constructor(mainEditorId) {
      this.mainEditorId = mainEditorId;
      this.mainEditor = null;
      this.miniEditor = null;

      this.minimapWrapper = null;
      this.slider = null;
      this.glassPane = null;

      this.isDragging = false;
      this.isEnabled = false;
      this.originalEditorWidth = '';

      this.syncScroll = this.syncScroll.bind(this);
      this.syncDocument = this.syncDocument.bind(this);
      this.syncMarkers = this.syncMarkers.bind(this);
      this.onDragStart = this.onDragStart.bind(this);
      this.onDragMove = this.onDragMove.bind(this);
      this.onDragEnd = this.onDragEnd.bind(this);
      this.onThemeChange = this.onThemeChange.bind(this);
      this.onWheel = this.onWheel.bind(this);

      this.init();
    }

    init() {
      this.injectStyles();
      var waitForAce = setInterval(() => {
        if (typeof ace !== 'undefined') {
            var editor = ace.edit(this.mainEditorId);
            if (editor && editor.renderer && editor.session) {
              clearInterval(waitForAce);
              this.mainEditor = editor;
              this.enable();
            }
        }
      }, 100);
    }

    enable() {
      if (this.isEnabled || !this.mainEditor) return;

      // 1. Hide native scrollbar to prevent conflicts
      this.mainEditor.setOption('vScrollBarAlwaysVisible', false);
      this.mainEditor.container.classList.add('minimap-active');

      this.buildDOM();
      this.setupMiniEditor();
      this.attachListeners();
      this.isEnabled = true;

      // 2. Force Ace to recalculate dimensions
      setTimeout(() => {
          this.mainEditor.resize(true);
          if (this.miniEditor) this.miniEditor.resize(true);
          this.syncScroll();
          this.syncMarkers();
      }, 100);
    }

    disable() {
      if (!this.isEnabled) return;
      this.detachListeners();

      if (this.minimapWrapper) {
        this.minimapWrapper.remove();
        this.minimapWrapper = null;
      }
      if (this.miniEditor) {
        this.miniEditor.destroy();
        this.miniEditor = null;
      }

      // Restore main editor original width and scrollbar
      if (this.mainEditor && this.mainEditor.container) {
          this.mainEditor.container.style.width = this.originalEditorWidth || '100%';
          this.mainEditor.container.classList.remove('minimap-active');
          this.mainEditor.renderer.setScrollMargin(0, 0, 0, 0);
          this.mainEditor.resize(true);
      }

      this.isEnabled = false;
    }

    injectStyles() {
      if (document.getElementById('ace_minimap_styles')) return;
      var style = document.createElement('style');
      style.id = 'ace_minimap_styles';
      style.innerHTML =
        \".ace_minimap_wrapper {\\n\" +
        \"  position: absolute;\\n\" +
        \"  top: 0;\\n\" +
        \"  right: 0;\\n\" +
        \"  width: \" + CONFIG.minimapWidth + \"px;\\n\" +
        \"  height: 100%;\\n\" +
        \"  z-index: 100;\\n\" +
        \"  border-left: 1px solid rgba(255,255,255,0.2);\\n\" +
        \"  box-shadow: -2px 0 5px rgba(0,0,0,0.05);\\n\" +
        \"  background: inherit;\\n\" +
        \"  overflow: hidden !important;\\n\" +
        \"}\\n\" +
        \".ace_minimap_editor {\\n\" +
        \"  position: absolute;\\n\" +
        \"  top: 0; left: 0; bottom: 0;\\n\" +
        \"  width: 400px !important;\\n\" + /* Force wide width to prevent premature wrapping */
        \"  opacity: 0.9;\\n\" +
        \"  pointer-events: none;\\n\" +
        \"}\\n\" +
        \".ace_minimap_editor .ace_scrollbar {\\n\" +
        \"  display: none !important;\\n\" +
        \"}\\n\" +
        \".ace_minimap_editor .ace_scroller {\\n\" +
        \"  overflow: hidden !important;\\n\" +
        \"}\\n\" +
        \".ace_minimap_glass {\\n\" +
        \"  position: absolute;\\n\" +
        \"  top: 0; left: 0; right: 0; bottom: 0;\\n\" +
        \"  z-index: 12;\\n\" +
        \"  cursor: pointer;\\n\" +
        \"}\\n\" +
        \".ace_minimap_slider {\\n\" +
        \"  position: absolute;\\n\" +
        \"  top: 0; left: 0; right: 0;\\n\" +
        \"  background: \" + CONFIG.sliderColor + \";\\n\" +
        \"  z-index: 13;\\n\" +
        \"  cursor: grab;\\n\" +
        \"  box-sizing: border-box;\\n\" +
        \"  transition: background 0.1s;\\n\" +
        \"  border-radius: 0;\\n\" +
        \"  border: 0.5px solid rgba(0,0,0,0.05);\\n\" +
        \"  margin: 0 0 0 2px;\\n\" +
        \"  width: calc(100%-2px);\\n\" +
        \"}\\n\" +
        \".ace_minimap_slider:hover {\\n\" +
        \"  background: \" + CONFIG.sliderHover + \";\\n\" +
        \"}\\n\" +
        \".ace_minimap_slider.dragging {\\n\" +
        \"  background: \" + CONFIG.sliderActive + \";\\n\" +
        \"  cursor: grabbing;\\n\" +
        \"}\\n\" +
        \".minimap-active .ace_scrollbar-v {\\n\" +
        \"  display: none !important;\\n\" +
        \"  width: 0 !important;\\n\" +
        \"}\";
      document.head.appendChild(style);
    }

    buildDOM() {
      var container = this.mainEditor.container;
      var parent = container.parentElement;

      this.minimapWrapper = document.createElement('div');
      this.minimapWrapper.className = 'ace_minimap_wrapper';

      var editorDiv = document.createElement('div');
      editorDiv.className = 'ace_minimap_editor';

      this.glassPane = document.createElement('div');
      this.glassPane.className = 'ace_minimap_glass';

      this.slider = document.createElement('div');
      this.slider.className = 'ace_minimap_slider';

      this.glassPane.appendChild(this.slider);
      this.minimapWrapper.appendChild(editorDiv);
      this.minimapWrapper.appendChild(this.glassPane);

      // Place Minimap OUTSIDE the editor in the parent container
      parent.style.position = 'relative';
      parent.appendChild(this.minimapWrapper);

      // Shrink the main editor to make physical room (prevents text overlap)
      this.originalEditorWidth = container.style.width;
      container.style.width = 'calc(100% - ' + CONFIG.minimapWidth + 'px)';
    }

    setupMiniEditor() {
      var editorDiv = this.minimapWrapper.querySelector('.ace_minimap_editor');
      this.miniEditor = ace.edit(editorDiv);

      this.miniEditor.setOptions({
        fontSize: CONFIG.fontSize,
        showGutter: false,
        showPrintMargin: false,
        readOnly: true,
        highlightActiveLine: false,
        highlightGutterLine: false,
        scrollPastEnd: 0,
        tooltipFollowsMouse: false,
        hScrollBarAlwaysVisible: false,
        vScrollBarAlwaysVisible: false
      });

      this.miniEditor.renderer.scrollBarV.element.style.display = 'none';
      this.miniEditor.renderer.scrollBarH.element.style.display = 'none';
      this.miniEditor.renderer.$cursorLayer.element.style.display = 'none';

      this.syncDocument();
      this.onThemeChange();
    }

    attachListeners() {
      var mainSession = this.mainEditor.getSession();

      mainSession.on('changeScrollTop', this.syncScroll);
      this.mainEditor.on('changeSession', this.syncDocument);
      this.mainEditor.renderer.on('themeLoaded', this.onThemeChange);

      // Sync wrap limits dynamically
      this._wrapHandler = () => {
          if (this.miniEditor) {
              var limit = this.mainEditor.getSession().getWrapLimit();
              this.miniEditor.getSession().setWrapLimitRange(limit, limit);
              this.syncScroll();
          }
      };
      mainSession.on('changeWrapLimit', this._wrapHandler);
      mainSession.on('changeWrapMode', this.syncDocument);

      // Marker Sync Listeners
      this._syncMarkersHandler = () => this.syncMarkers();
      mainSession.on('changeAnnotation', this._syncMarkersHandler);
      mainSession.on('changeBackMarker', this._syncMarkersHandler);
      mainSession.on('changeFrontMarker', this._syncMarkersHandler);

      this._resizeHandler = () => {
          if(this.miniEditor) this.miniEditor.resize(true);
          this.syncScroll();
      };
      window.addEventListener('resize', this._resizeHandler);

      this.slider.addEventListener('mousedown', this.onDragStart);
      this.glassPane.addEventListener('mousedown', (e) => {
        if (e.target === this.slider) return;
        this.scrollToClick(e);
      });
      this.glassPane.addEventListener('wheel', this.onWheel, {passive: false});
    }

    detachListeners() {
      var mainSession = this.mainEditor.getSession();
      if (mainSession) {
        mainSession.off('changeScrollTop', this.syncScroll);
        mainSession.off('changeWrapLimit', this._wrapHandler);
        mainSession.off('changeWrapMode', this.syncDocument);
        mainSession.off('changeAnnotation', this._syncMarkersHandler);
        mainSession.off('changeBackMarker', this._syncMarkersHandler);
        mainSession.off('changeFrontMarker', this._syncMarkersHandler);
      }
      this.mainEditor.off('changeSession', this.syncDocument);
      this.mainEditor.renderer.off('themeLoaded', this.onThemeChange);
      window.removeEventListener('resize', this._resizeHandler);

      this.slider.removeEventListener('mousedown', this.onDragStart);
      this.glassPane.removeEventListener('wheel', this.onWheel);
    }

    onWheel(e) {
        e.preventDefault();
        var session = this.mainEditor.getSession();
        session.setScrollTop(session.getScrollTop() + e.deltaY);
    }

    syncDocument() {
      var mainSession = this.mainEditor.getSession();
      var miniSession = new ace.EditSession(mainSession.getDocument(), mainSession.getMode());

      // Force wrap syncing: makes the minimap break lines exactly where the main editor does
      miniSession.setUseWrapMode(mainSession.getUseWrapMode());
      var wrapLimit = mainSession.getWrapLimit();
      miniSession.setWrapLimitRange(wrapLimit, wrapLimit);

      this.miniEditor.setSession(miniSession);
      this.syncScroll();
      this.syncMarkers();
    }

    syncMarkers() {
      if (!this.miniEditor || !this.mainEditor) return;
      var mainSession = this.mainEditor.getSession();
      var miniSession = this.miniEditor.getSession();

      miniSession.setAnnotations(mainSession.getAnnotations());

      var mainMarkers = mainSession.getMarkers();
      var miniMarkers = miniSession.getMarkers();

      for (var m1 in miniMarkers) {
          miniSession.removeMarker(miniMarkers[m1].id);
      }

      for (var m2 in mainMarkers) {
          var marker = mainMarkers[m2];
          if (marker.clazz !== 'ace_active-line') {
              miniSession.addMarker(marker.range, marker.clazz, marker.type, marker.inFront);
          }
      }
    }

    onThemeChange() {
      var theme = this.mainEditor.getTheme();
      if (this.miniEditor) {
          this.miniEditor.setTheme(theme);
      }
      var scroller = this.mainEditor.renderer.scroller;
      var bgColor = window.getComputedStyle(scroller).backgroundColor;
      if (this.minimapWrapper) {
          this.minimapWrapper.style.backgroundColor = bgColor;
      }
    }

    syncScroll() {
      if (this.isDragging || !this.miniEditor) return;

      var mainSession = this.mainEditor.getSession();
      var mainRenderer = this.mainEditor.renderer;
      var miniSession = this.miniEditor.getSession();
      var miniRenderer = this.miniEditor.renderer;

      var mainTop = mainSession.getScrollTop();
      var mainHeight = mainRenderer.$size.scrollerHeight || this.mainEditor.container.clientHeight;
      var mainMax = Math.max(0, mainSession.getScreenLength() * mainRenderer.lineHeight - mainHeight);

      var scrollRatio = mainMax > 0 ? mainTop / mainMax : 0;

      var miniHeight = this.minimapWrapper.clientHeight;
      var miniMax = Math.max(0, miniSession.getScreenLength() * miniRenderer.lineHeight - miniHeight);

      var miniScrollTop = scrollRatio * miniMax;
      miniSession.setScrollTop(miniScrollTop);

      var visibleRatio = mainMax > 0 ? mainHeight / (mainSession.getScreenLength() * mainRenderer.lineHeight) : 1;
      visibleRatio = Math.max(0.05, Math.min(1, visibleRatio));

      var sliderHeightPixels = visibleRatio * miniHeight;
      var safeSliderHeight = Math.max(20, sliderHeightPixels);
      this.slider.style.height = safeSliderHeight + \"px\";

      var sliderTopMax = miniHeight - safeSliderHeight;
      var sliderTop = scrollRatio * sliderTopMax;

      this.slider.style.transform = \"translateY(\" + sliderTop + \"px)\";
    }

    scrollToClick(e) {
      var rect = this.glassPane.getBoundingClientRect();
      var clickY = e.clientY - rect.top;
      var sliderHeight = this.slider.offsetHeight;
      var targetTop = clickY - (sliderHeight / 2);
      this.mapSliderToMainEditor(targetTop);
    }

    onDragStart(e) {
      e.preventDefault();
      this.isDragging = true;
      this.slider.classList.add('dragging');

      this.startY = e.clientY;

      var transform = window.getComputedStyle(this.slider).transform;
      var matrixValues = transform.match(/matrix.*\\((.+)\\)/);
      this.startTop = 0;
      if (matrixValues && matrixValues[1]) {
          var values = matrixValues[1].split(', ');
          if (values.length >= 6) {
              this.startTop = parseFloat(values[5]);
          }
      }

      document.addEventListener('mousemove', this.onDragMove);
      document.addEventListener('mouseup', this.onDragEnd);
    }

    onDragMove(e) {
      if (!this.isDragging) return;
      var deltaY = e.clientY - this.startY;
      var newTop = this.startTop + deltaY;
      this.mapSliderToMainEditor(newTop);
    }

    onDragEnd() {
      this.isDragging = false;
      this.slider.classList.remove('dragging');
      document.removeEventListener('mousemove', this.onDragMove);
      document.removeEventListener('mouseup', this.onDragEnd);
      this.syncScroll();
    }

    mapSliderToMainEditor(sliderTop) {
      var maxSliderTop = this.minimapWrapper.clientHeight - this.slider.offsetHeight;
      var safeTop = Math.max(0, Math.min(sliderTop, maxSliderTop));
      var scrollRatio = maxSliderTop > 0 ? safeTop / maxSliderTop : 0;

      var mainSession = this.mainEditor.getSession();
      var mainRenderer = this.mainEditor.renderer;
      var mainMax = Math.max(0, mainSession.getScreenLength() * mainRenderer.lineHeight - mainRenderer.$size.scrollerHeight);

      mainSession.setScrollTop(scrollRatio * mainMax);

      var miniSession = this.miniEditor.getSession();
      var miniHeight = this.minimapWrapper.clientHeight;
      var miniMax = Math.max(0, miniSession.getScreenLength() * this.miniEditor.renderer.lineHeight - miniHeight);
      miniSession.setScrollTop(scrollRatio * miniMax);

      this.slider.style.transform = \"translateY(\" + safeTop + \"px)\";
    }
  }

  window.enableMinimap = () => {
      if(!window.minimapInstance) {
          window.minimapInstance = new AceMinimap(\"sourceEditor\");
      } else {
          window.minimapInstance.enable();
      }
      return window.minimapInstance;
  };

  window.disableMinimap = () => {
      if(window.minimapInstance) {
          window.minimapInstance.disable();
      }
  };

  if (typeof $ !== 'undefined') {
    $(document).ready(() => {
      window.enableMinimap();

      $(document).on('change', '#enableMinimapPanel', function() {
          if (this.checked) window.enableMinimap();
          else window.disableMinimap();
      });
    });
  }

})(window);

//========================Table Overlay================//

document.addEventListener('DOMContentLoaded', function() {

    // --- STATE & INIT ---
    window.openTableOverlay = function() {
      document.getElementById('tableOverlay').classList.add('show');
      const table = document.getElementById('visualTableGrid');
      // Only init if completely empty (Preserves state otherwise)
      if (table.rows.length === 0) window.initGrid();
    };

    window.closeTableOverlay = function() {
      document.getElementById('tableOverlay').classList.remove('show');
    };

    window.clearGrid = function() {
      if(confirm('Clear entire table?')) {
        window.initGrid();
      }
    };

    window.initGrid = function() {
      const table = document.getElementById('visualTableGrid');
      table.innerHTML = '';
      const row = table.insertRow();
      const cell = row.insertCell();
      setupCell(cell);
    };

    // --- CELL SETUP & EVENTS (The Magic) ---
    function setupCell(cell) {
      cell.contentEditable = true;

      // 1. Mouse Move: Detect Border Proximity
      cell.addEventListener('mousemove', function(e) {
        const rect = cell.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;
        const w = rect.width;
        const h = rect.height;
        const th = 8; // threshold in px

        // Reset classes
        cell.classList.remove('hover-top', 'hover-bottom', 'hover-left', 'hover-right');

        // Check edges
        if (y < th) cell.classList.add('hover-top');
        else if (y > h - th) cell.classList.add('hover-bottom');
        else if (x < th) cell.classList.add('hover-left');
        else if (x > w - th) cell.classList.add('hover-right');
      });

      // 2. Mouse Leave: Cleanup
      cell.addEventListener('mouseleave', function() {
        cell.classList.remove('hover-top', 'hover-bottom', 'hover-left', 'hover-right');
      });

      // 3. Click: Toggle Borders
      cell.addEventListener('mousedown', function(e) {
        // If we are hovering a border, toggle it and preventing typing focus
        if (cell.classList.contains('hover-top')) {
            e.preventDefault(); toggleBorder(cell, 'b-top');
        } else if (cell.classList.contains('hover-bottom')) {
            e.preventDefault(); toggleBorder(cell, 'b-bottom');
        } else if (cell.classList.contains('hover-left')) {
            e.preventDefault(); toggleBorder(cell, 'b-left');
        } else if (cell.classList.contains('hover-right')) {
            e.preventDefault(); toggleBorder(cell, 'b-right');
        }
      });
    }

    function toggleBorder(cell, cls) {
      // Toggle locally
      if (cell.classList.contains(cls)) {
        cell.classList.remove(cls);
      } else {
        cell.classList.add(cls);
      }

      // SYNC NEIGHBORS (Optional but good for visuals)
      // e.g., Toggling Right of Cell [0,0] should ideally affect Left of Cell [0,1]
      // For simplicity in this version, we treat cells independently to allow precise control
    }

    // --- FORMATTING TEXT ---
    window.formatCell = function(cmd, value) {
      document.execCommand(cmd, false, value);
      // Re-focus table to keep typing
      const table = document.getElementById('visualTableGrid');
      if (table) table.focus();
    };

    // --- GRID MODIFICATION ---
    window.modifyGrid = function(action, type) {
      const table = document.getElementById('visualTableGrid');
      const rowCount = table.rows.length;
      if (rowCount === 0) { initGrid(); return; }
      const colCount = table.rows[0].cells.length;

      if (type === 'row') {
        if (action === 'add' && rowCount < 50) {
            const newRow = table.insertRow();
            for(let i=0; i<colCount; i++) setupCell(newRow.insertCell());
        } else if (action === 'rem' && rowCount > 1) {
            table.deleteRow(-1);
        }
      } else if (type === 'col') {
        if (action === 'add' && colCount < 20) {
            for(let i=0; i<rowCount; i++) setupCell(table.rows[i].insertCell());
        } else if (action === 'rem' && colCount > 1) {
            for(let i=0; i<rowCount; i++) table.rows[i].deleteCell(-1);
        }
      }
    };

    // --- LATEX GENERATION ---
    window.insertGeneratedTable = function() {
      try {
        const table = document.getElementById('visualTableGrid');
        const rows = table.rows;
        if (rows.length === 0) return;

        let latex = '\\\\begin{table}[h]\\n  \\\\centering\\n  \\\\begin{tabular}{';

        // 1. Column Spec (Scan first row for vertical borders)
        // Default to 'c'. If cell has 'b-left' or 'b-right', we might need multicolumns.
        // For simplicity: We use standard 'c' columns and use \\multicolumn for borders.
        let colCount = rows[0].cells.length;
        let colSpec = '';
        for(let i=0; i<colCount; i++) colSpec += 'c';
        latex += colSpec + '}\\n';

        // 2. Iterate Rows
        for (let r = 0; r < rows.length; r++) {
          let row = rows[r];
          let cells = row.cells;
          let cellLatex = [];

          // Top Borders (\\cline)
          // We check which cells have 'b-top'. We group them (e.g., 1-1, 2-3)
          let clineSegments = [];
          let currentStart = -1;
          for (let c = 0; c < cells.length; c++) {
             if (cells[c].classList.contains('b-top')) {
                 if (currentStart === -1) currentStart = c + 1;
             } else {
                 if (currentStart !== -1) {
                     clineSegments.push(currentStart + '-' + c);
                     currentStart = -1;
                 }
             }
          }
          if (currentStart !== -1) clineSegments.push(currentStart + '-' + cells.length);

          clineSegments.forEach(seg => { latex += '    \\\\cline{' + seg + '}\\n'; });

          // Cell Content
          for (let c = 0; c < cells.length; c++) {
             let cell = cells[c];
             let content = parseCellContent(cell); // Handle Bold/Color

             // Vertical Borders (Left/Right)
             // We use \\multicolumn{1}{|c|}{...} if borders exist
             let hasL = cell.classList.contains('b-left');
             let hasR = cell.classList.contains('b-right');

             if (hasL || hasR) {
                 let spec = (hasL ? '|' : '') + 'c' + (hasR ? '|' : '');
                 content = '\\\\multicolumn{1}{' + spec + '}{' + content + '}';
             }

             cellLatex.push(content);
          }

          latex += '    ' + cellLatex.join(' & ') + ' \\\\\\\\';

          // Bottom Borders (Last Row only usually, but we check per row for completeness)
          // Actually, standard LaTeX is \\hline or \\cline AFTER the row.
          // So we check 'b-bottom' here.
          let blineSegments = [];
          let bStart = -1;
          for (let c = 0; c < cells.length; c++) {
             if (cells[c].classList.contains('b-bottom')) {
                 if (bStart === -1) bStart = c + 1;
             } else {
                 if (bStart !== -1) {
                     blineSegments.push(bStart + '-' + c);
                     bStart = -1;
                 }
             }
          }
          if (bStart !== -1) blineSegments.push(bStart + '-' + cells.length);

          if (blineSegments.length > 0) {
              latex += '\\n    ';
              blineSegments.forEach(seg => { latex += '\\\\cline{' + seg + '}'; });
          }

          latex += '\\n';
        }

        latex += '  \\\\end{tabular}\\n  \\\\caption{Caption}\\n\\\\end{table}';

        // Insert
        var editor = ace.edit('sourceEditor');
        if (editor) { editor.insert(latex); editor.focus(); }

        closeTableOverlay();

      } catch (e) {
        console.error(e);
        alert('Error generating table');
      }
    };

    // Helper: HTML to LaTeX Text
    function parseCellContent(cell) {
        // Clone to not mess up UI
        let div = document.createElement('div');
        div.innerHTML = cell.innerHTML;

        let text = div.innerText.trim();
        // Check computed style or tags
        // Simple Tag parsing
        if (div.querySelector('b, strong') || cell.style.fontWeight === 'bold') {
            text = '\\\\textbf{' + text + '}';
        }
        if (div.querySelector('i, em') || cell.style.fontStyle === 'italic') {
            text = '\\\\textit{' + text + '}';
        }
        // Color (font tag or style)
        let font = div.querySelector('font[color]');
        if (font) {
            let hex = font.getAttribute('color');
            // Remove #
            text = '\\\\textcolor[HTML]{' + hex.replace('#','') + '}{' + text + '}';
        }

        // Escape chars
        return text.replace(/([%&$#_])/g, '\\\\$1');
    }

  });



//================AI Assistant Beautify=============//

function beautifyChat() {
  // Use setTimeout to avoid blocking and ensure DOM is ready
  setTimeout(function() {
    try {
      // A. Render Math with KaTeX (only if available)
      if (typeof renderMathInElement !== 'undefined') {
        try {
          renderMathInElement(document.body, {
            delimiters: [
              {left: '$$', right: '$$', display: true},
              {left: '$', right: '$', display: false},
              {left: '\\(', right: '\\)', display: false},
              {left: '\\[', right: '\\]', display: true}
            ],
            throwOnError: false,
            ignoredTags: ['script', 'noscript', 'style', 'textarea', 'pre', 'code']
          });
        } catch(e) {
          showTablerAlert('warning', 'KaTeX rendering failed:', e);
        }
      }

      // B. Highlight Code & Add Copy Buttons
      var codeBlocks = document.querySelectorAll('.ai-message-card pre code');

      codeBlocks.forEach(function(block) {
        try {
          // 1. Highlight if hljs is available
          if (typeof hljs !== 'undefined' && !block.classList.contains('hljs')) {
            hljs.highlightElement(block);
          }

          // 2. Add Copy Button (if not already there)
          var preElement = block.parentNode;
          if (preElement.querySelector('.code-copy-btn')) return;

          // Detect language from class
          var language = 'code';
          var classes = block.className.split(' ');
          for (var i = 0; i < classes.length; i++) {
            var cls = classes[i];
            if (cls.startsWith('language-')) {
              language = cls.replace('language-', '');
              break;
            } else if (cls !== 'hljs' && cls !== '') {
              language = cls;
            }
          }

          // Create header with language label and copy button
          var header = document.createElement('div');
          header.className = 'code-header';

          var langLabel = document.createElement('span');
          langLabel.className = 'code-language';
          langLabel.textContent = language;

          var copyBtn = document.createElement('button');
          copyBtn.className = 'code-copy-btn';
          copyBtn.innerHTML = '<i class=\"fa-regular fa-copy\"></i>';
          copyBtn.title = 'Copy to clipboard';

          copyBtn.addEventListener('click', function() {
            var code = block.innerText;

            // Fallback for older browsers
            if (navigator.clipboard && navigator.clipboard.writeText) {
              navigator.clipboard.writeText(code).then(function() {
                copyBtn.innerHTML = '<i class=\"fa-solid fa-check\"></i>';
                copyBtn.classList.add('copied');
                setTimeout(function() {
                  copyBtn.innerHTML = '<i class=\"fa-regular fa-copy\"></i>';
                  copyBtn.classList.remove('copied');
                }, 2000);
              }).catch(function(err) {
                showTablerAlert('error', 'Failed to copy:', err);
                fallbackCopy(code, copyBtn);
              });
            } else {
              fallbackCopy(code, copyBtn);
            }
          });

          header.appendChild(langLabel);
          header.appendChild(copyBtn);

          // Insert header before code block
          preElement.insertBefore(header, preElement.firstChild);
          preElement.classList.add('code-block-enhanced');

        } catch(e) {
          showTablerAlert('warning', 'Code block enhancement failed:', e);
        }
      });

      // C. Scroll to bottom smoothly
      var container = document.getElementById('chat-scroll-container');
      if (container) {
        try {
          container.scrollTo({
            top: container.scrollHeight,
            behavior: 'smooth'
          });
        } catch(e) {
          // Fallback for older browsers
          container.scrollTop = container.scrollHeight;
        }
      }

    } catch(e) {
      showTablerAlert('error', 'beautifyChat error:', e);
    }
  }, 600); // Small delay to ensure DOM is ready
}

// Fallback copy function for older browsers
function fallbackCopy(text, button) {
  var textArea = document.createElement('textarea');
  textArea.value = text;
  textArea.style.position = 'fixed';
  textArea.style.left = '-999999px';
  document.body.appendChild(textArea);
  textArea.select();

  try {
    document.execCommand('copy');
    button.innerHTML = '<i class=\"fa-solid fa-check\"></i>';
    button.classList.add('copied');
    setTimeout(function() {
      button.innerHTML = '<i class=\"fa-regular fa-copy\"></i>';
      button.classList.remove('copied');
    }, 2000);
  } catch(err) {
    showTablerAlert('error','Copy failed. Please copy manually.');
  }

  document.body.removeChild(textArea);
}

//=====================Editor font family===============//
document.addEventListener(\"DOMContentLoaded\", function() {

  const fontPanel = document.getElementById('editorFontFamilyPanel');
  const editorId = \"sourceEditor\"; // Your Ace editor ID
  const storageKey = \"mudskipper_font_family\"; // Key to save preference

  // 1. Function to Apply Font
  function applyFont(fontFamily) {
    var ids = [editorId, 'dockerConsole', 'historyEditor'];
    ids.forEach(function(id) {
      try {
        var ed = ace.edit(id);
        if (ed) ed.setOption('fontFamily', fontFamily);
      } catch(e) {}
    });
  }

  // 2. Load Saved Font on Startup
  const savedFont = localStorage.getItem(storageKey);
  if (savedFont && fontPanel) {
    fontPanel.value = savedFont;
    // Wait slightly for Ace to initialize if running immediately on load
    setTimeout(() => applyFont(savedFont), 500);
  }

  // 3. Listen for Changes (Font Family)
  if (fontPanel) {
    fontPanel.addEventListener('change', function() {
      const selectedFont = this.value;
      applyFont(selectedFont);
      localStorage.setItem(storageKey, selectedFont);
    });
  }

  // 5. Listen for Changes (Theme & Font Size) - PROVIDES IMMEDIATE REACTIVITY
  const themePanel = document.getElementById('editorThemePanel');
  if (themePanel) {
    themePanel.addEventListener('change', function() {
      const theme = this.value;
      [editorId, 'dockerConsole', 'historyEditor'].forEach(id => {
        try {
          var ed = ace.edit(id);
          if (ed) ed.setTheme('ace/theme/' + theme);
        } catch(e) {}
      });
    });
  }

  const sizePanel = document.getElementById('editorFontSizePanel');
  if (sizePanel) {
    sizePanel.addEventListener('change', function() {
      const size = parseInt(this.value);
      [editorId, 'dockerConsole', 'historyEditor'].forEach(id => {
        try {
          var ed = ace.edit(id);
          if (ed) ed.setFontSize(size);
        } catch(e) {}
      });
    });
  }

  // 4. Fallback: Re-apply if Shiny re-initializes the editor
  $(document).on('shiny:value', function(event) {
    if (event.name === editorId) {
      const currentFont = localStorage.getItem(storageKey) || \"'Fira Code', monospace\";
      setTimeout(() => applyFont(currentFont), 100);
    }
  });

});



// NOTE: updateStatus handler is now registered in www/status_bar.js
// to avoid Shiny duplicate-handler warnings. The status bar JS
// forwards the message to #statusBar AND to the bottom status bar.

  "
  )),
  # ---- VS Code-style Status Bar: CSS injected inside fluidPage ----
  tags$style(HTML("
/* ============================================================
   Mudskipper Status Bar  —  Tabler-native colour scheme
   26px fixed bottom bar, visible only on the editor page
============================================================ */

/* Bar container */
#mudskipper-status-bar {
  position: fixed;
  bottom: 0; left: 0; right: 0;
  height: 26px;
  z-index: 9999;
  display: flex;
  align-items: stretch;
  background: var(--tblr-body-bg);
  color: var(--tblr-body-color);
  border-top: 1px solid var(--tblr-border-color);
  font-family: var(--tblr-font-sans-serif, 'Inter', sans-serif);
  font-size: 11.5px;
  font-weight: 400;
  line-height: 1;
  user-select: none;
  overflow: hidden;
}
[data-bs-theme=dark] #mudskipper-status-bar {
  background: var(--tblr-body-bg);
}

/* Sections */
.msb-section { display: flex; align-items: stretch; overflow: hidden; }
.msb-left    { justify-content: flex-start; flex-shrink: 0; }
.msb-center  { justify-content: center; flex: 1; }
.msb-right   { justify-content: flex-end; flex-shrink: 0; }

/* Separator */
.msb-sep {
  width: 1px;
  background: var(--tblr-border-color);
  margin: 4px 0;
  flex-shrink: 0;
}

/* Chip */
.msb-chip {
  display: flex; align-items: center;
  gap: 5px; padding: 0 9px;
  height: 100%; white-space: nowrap;
  cursor: default;
  transition: background 0.12s ease;
  color: var(--tblr-body-color);
}
.msb-chip svg   { flex-shrink: 0; opacity: 0.5; }
.msb-chip span  { overflow: hidden; text-overflow: ellipsis; }

/* ONLY the compile chip uses primary colour */
.msb-chip-primary {
  background: var(--tblr-primary) !important;
  color: #fff !important;
  padding: 0 12px;
  font-weight: 500;
}
.msb-chip-primary svg   { opacity: 0.88; color: #fff; }
.msb-chip-primary:hover { background: color-mix(in srgb, var(--tblr-primary) 82%, #000 18%) !important; }
.msb-chip-primary.msb-compiling { animation: msb-pulse 1s ease-in-out infinite; }
@keyframes msb-pulse { 0%,100%{opacity:1} 50%{opacity:.68} }

/* Clickable chips (non-primary) */
.msb-clickable { cursor: pointer; }
.msb-clickable:not(.msb-chip-primary):hover {
  background: color-mix(in srgb, var(--tblr-primary) 8%, transparent);
}

/* Auto-compile dot */
.msb-dot {
  width: 7px; height: 7px;
  border-radius: 50%; flex-shrink: 0;
  transition: background 0.3s;
}
.msb-dot-on  { background: var(--tblr-success, #2fb344); box-shadow: 0 0 4px var(--tblr-success, #2fb344); }
.msb-dot-off { background: var(--tblr-border-color); }

/* Save indicator */
.msb-saving     { color: var(--tblr-warning, #f59f00) !important; }
.msb-saving svg { opacity: 0.95; color: var(--tblr-warning, #f59f00) !important; }

/* Annotation severity */
.msb-has-errors,   .msb-has-errors   svg { color: var(--tblr-danger,  #d63939) !important; opacity: 1; }
.msb-has-warnings, .msb-has-warnings svg { color: var(--tblr-warning, #f59f00) !important; opacity: 1; }
.msb-has-infos,    .msb-has-infos    svg { color: var(--tblr-info,    #17a2b8) !important; opacity: 1; }

/* Spell errors */
.msb-has-errors.msb-spell-chip { color: var(--tblr-danger, #d63939) !important; }

/* Clock */
.msb-chip-clock { font-variant-numeric: tabular-nums; letter-spacing: 0.03em; }

/* Compile-option chips: highlight when non-default setting is active */
.msb-opt-active {
  color: var(--tblr-primary) !important;
}
.msb-opt-active svg { color: var(--tblr-primary) !important; opacity: 1; }

/* Stop-on-error: soft orange warning tint */
.msb-opt-warn {
  color: var(--tblr-warning, #f59f00) !important;
}
.msb-opt-warn svg { color: var(--tblr-warning, #f59f00) !important; opacity: 1; }

/* Pad body so bar does not overlap content */
body { padding-bottom: 26px !important; }
  ")),
  tags$script(src = "status_bar.js")
)
