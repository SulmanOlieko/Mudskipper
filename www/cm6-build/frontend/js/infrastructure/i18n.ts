import i18next from 'i18next'
import { initReactI18next } from 'react-i18next'

const resources = {
  en: {
    translation: {
      "alignment": "Alignment",
      "left": "Left",
      "center": "Center",
      "right": "Right",
      "justify": "Justify",
      "merge_cells": "Merge cells",
      "unmerge_cells": "Unmerge cells",
      "delete_row_or_column": "Delete row or column",
      "insert": "Insert",
      "delete_table": "Delete table",
      "help": "Help",
      "no_caption": "No caption",
      "caption_above": "Caption above",
      "caption_below": "Caption below",
      "all_borders": "All borders",
      "no_borders": "No borders",
      "booktabs": "Booktabs",
      "custom_borders": "Custom borders",
      "fixed_width": "Fixed width",
      "fixed_width_wrap_text": "Fixed width (wrap text)",
      "set_column_width": "Set column width",
      "stretch_width_to_text": "Stretch width to text",
      "view_code": "View code",
      "sorry_your_table_cant_be_displayed_at_the_moment": "Sorry, your table can't be displayed at the moment",
      "this_could_be_because_we_cant_support_some_elements_of_the_table": "This could be because we can't support some elements of the table",
      "insert_column_left": "Insert column left",
      "insert_column_right": "Insert column right",
      "insert_row_above": "Insert row above",
      "insert_row_below": "Insert row below",
      "insert_x_columns_left": "Insert {{columns}} columns left",
      "insert_x_columns_right": "Insert {{columns}} columns right",
      "insert_x_rows_above": "Insert {{rows}} rows above",
      "insert_x_rows_below": "Insert {{rows}} rows below",
      "adjust_column_width": "Adjust column width",
      "select_a_column_to_adjust_column_width": "Select a column to adjust column width",
      "select_a_column_or_a_merged_cell_to_align": "Select a column or a merged cell to align",
      "select_cells_in_a_single_row_to_merge": "Select cells in a single row to merge",
      "select_a_row_or_a_column_to_delete": "Select a row or a column to delete",
      "to_insert_or_move_a_caption_make_sure_tabular_is_directly_within_table": "To insert or move a caption, make sure tabular is directly within table",
      "loading": "Loading...",
      "add": "Add",
      "delete_forever": "Delete",
      "format_align_left": "Align Left",
      "format_align_center": "Align Center",
      "format_align_right": "Align Right",
      "format_align_justify": "Justify",
      "expand_more": "More",
      "show_document_preamble": "Show Preamble",
      "column_width_is_custom_click_to_resize": "Column width is custom, click to resize",
      "column_width_is_x_click_to_resize": "Column width is {{width}}, click to resize",
    }
  }
}

i18next
  .use(initReactI18next)
  .init({
    resources,
    lng: 'en',
    fallbackLng: 'en',
    interpolation: {
      escapeValue: false
    },
    react: {
      useSuspense: false
    }
  })

// Force add resources in case init was already called
i18next.addResourceBundle('en', 'translation', resources.en.translation, true, true);

export default i18next
