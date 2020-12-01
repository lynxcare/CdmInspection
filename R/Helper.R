# @file CdmInspection
#
# Copyright 2020 European Health Data and Evidence Network (EHDEN)
#
# This file is part of CatalogueExport
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# @author European Health Data and Evidence Network
# @author Peter Rijnbeek

executeQuery <- function(outputFolder,sqlFileName, successMessage, connectionDetails, sqlOnly, cmdDatabaseSchema, vocabDatabaseSchema=NULL, resultsDatabaseSchema=NULL){
  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = file.path("checks",sqlFileName),
                                           packageName = "CdmInspection",
                                           dbms = connectionDetails$dbms,
                                           warnOnMissingParameters = FALSE,
                                           vocabDatabaseSchema = vocabDatabaseSchema,
                                           cdmDatabaseSchema = cdmDatabaseSchema,
                                           resultsDatabaseSchema = resultsDatabaseSchema)

  duration = -1
  result = NULL
  if (sqlOnly) {
    SqlRender::writeSql(sql = sql, targetFile = file.path(outputFolder, sqlFileName))
  } else {

    tryCatch({
      start_time <- Sys.time()
      connection <- DatabaseConnector::connect(connectionDetails = connectionDetails,)
      result<- DatabaseConnector::querySql(connection = connection, sql = sql, errorReportFile = file.path(outputFolder, paste0(tools::file_path_sans_ext(sqlFileName),"Err.txt")))
      duration <- as.numeric(difftime(Sys.time(),start_time), units="secs")
      ParallelLogger::logInfo(paste("> ",successMessage, "in", sprintf("%.2f", duration),"secs"))
    },
    error = function (e) {
      ParallelLogger::logError(paste0("> Failed see ",file.path(outputFolder,paste0(tools::file_path_sans_ext(sqlFileName),"Err.txt"))," for more details"))
    }, finally = {
      DatabaseConnector::disconnect(connection = connection)
      rm(connection)
    })

  }


  return(list(result=result,duration=duration))
}
prettyHr <- function(x) {
  result <- sprintf("%.2f", x)
  result[is.na(x)] <- "NA"
  result <- suppressWarnings(format(as.numeric(result), big.mark=",")) # add thousands separator
  return(result)
}

addCheckListItem <- function(doc,message) {
  doc <- doc %>% body_add_par(" ", style = "Normal") %>%
    slip_in_xml(paste0('<w:sdt>
                       <w:sdtPr>
                       <w:id w:val="-990252438"/>
                       <w14:checkbox>
                       <w14:checked w14:val="0"/>
                       <w14:checkedState w14:val="2612" w14:font="Calibri"/>
                       <w14:uncheckedState w14:val="2610" w14:font="Calibri"/>
                       </w14:checkbox>
                       </w:sdtPr>
                       <w:sdtContent>
                       <w:r>
                       <w:rPr>
                       <w:rFonts w:ascii="Calibri" w:eastAsia="Calibri" w:hAnsi="Calibri" w:hint="no hint"/>
                       </w:rPr>
                       <w:t>☐</w:t>
                       </w:r>
                       </w:sdtContent>
                       </w:sdt>'), pos = 'after') %>%
    slip_in_text(paste0(" ",message))
  return(doc)
}

my_body_add_table <- function (x, value, style = NULL, pos = "after", header = TRUE,
          alignment = NULL, stylenames = table_stylenames(), first_row = TRUE,
          first_column = FALSE, last_row = FALSE, last_column = FALSE,
          no_hband = FALSE, no_vband = TRUE, align = "left")
{
  pt <- prop_table(style = style, layout = table_layout(),
                   width = table_width(), stylenames = stylenames, tcf = table_conditional_formatting(first_row = first_row,
                                                                                                      first_column = first_column, last_row = last_row,
                                                                                                      last_column = last_column, no_hband = no_hband, no_vband = no_vband), align = align)
  bt <- block_table(x = value, header = header, properties = pt,
                    alignment = alignment)
  xml_elt <- to_wml(bt, add_ns = TRUE, base_document = x)
  body_add_xml(x = x, str = xml_elt, pos = pos)
}