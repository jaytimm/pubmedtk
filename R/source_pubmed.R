#' Get PubMed Records
#'
#' Processes XML records obtained from PubMed. It extracts basic bibliographic information and annotations for each record.
#' @param x A character vector with search terms or IDs for fetching records from PubMed.
#' @return A data.table with columns for PubMed IDs, publication year, journal name, article title, abstract, and annotations.
#' @keywords internal


.get_records <- function (x) { 
  
  # Fetch records using .fetch_records function and parse XML content
  records <- .fetch_records(x)
  
  # Process each record to extract basic information and annotations
  parsed_records <- lapply(records, function(x){
    # Extract basic bibliographic information from the record
    basic_info <- .extract_basic(x)
    # Extract annotations (like MeSH terms) from the record
    annotations <- .extract_annotations(x)
    
    # Combine basic information and annotations into a list
    out1 <- list('basic_info' = basic_info, 'annotations' = annotations)
    return(out1)
  })
  
  # Convert the list of basic information into a tidy format
  sum0 <- textshape::tidy_list(x = lapply(parsed_records, '[[', 1),
                               id.name = 'id',
                               content.name = 'varx')
  
  # Reshape the data into a wide format using data.table
  sum1 <- data.table::dcast(data = sum0,
                            formula = id ~ attribute,
                            value.var = 'varx')
  
  # Select and reorder columns for the final output
  sum1 <- sum1[, c('pmid', 'year', 'journal', 'articletitle', 'abstract')]
  
  # Add annotations to the data table
  sum1[, annotations := list(lapply(parsed_records, '[[', 2))] 
  
  # Ensure proper encoding for compatibility
  Encoding(rownames(sum1)) <- 'UTF-8'
  
  # Clean up NA values and return the final data table
  cols <- colnames(sum1)
  sum1[, c(cols) := lapply(.SD, .clean_nas), .SDcols = cols]
  
  return(sum1)
}



#' Extract Basic Information from PubMed Records
#'
#' An internal function that parses XML records from PubMed. It extracts essential bibliographic information such as PubMed ID, journal title, article title, publication year, and abstract.
#' @param g An XML node set representing a single PubMed record.
#' @return A named vector with basic bibliographic information from a PubMed record.
#' @keywords internal
#' 
.extract_basic <- function(g){
  
  # Extract the PubMed ID (PMID) from the XML
  pm <- xml2::xml_find_all(g, ".//MedlineCitation/PMID") |> xml2::xml_text()
  
  # Extract the journal title
  a1 <- xml2::xml_find_all(g, ".//Title") |> xml2::xml_text()
  a1a <- a1[1]  # In case there are multiple titles, use the first one
  
  # Extract the article title
  a2 <- xml2::xml_find_all(g, ".//ArticleTitle") |> xml2::xml_text()
  
  # Extract the publication year. If 'Year' is not available, use 'MedlineDate' as a fallback
  year <- xml2::xml_find_all(g, ".//PubDate/Year") |> xml2::xml_text()
  if(length(year) == 0){ 
    year <- xml2::xml_find_all(g, ".//PubDate/MedlineDate") |> xml2::xml_text()
  }
  # Clean up the year to remove any extra characters or ranges
  year <- gsub(" .+", "", year)
  year <- gsub("-.+", "", year)
  
  # Extract the abstract text, combining multiple parts if necessary
  abstract <- xml2::xml_find_all(g, ".//Abstract/AbstractText") |> xml2::xml_text()
  if(length(abstract) > 1){
    abstract <- paste(abstract, collapse = ' ')}
  if(length(abstract) == 0){abstract <- NA}
  
  # Construct the output with the extracted information
  out <- c('pmid' = pm,
           'journal' = a1a,
           'articletitle' = a2,
           'year' = year,
           'abstract' = abstract)
  
  return(out)
}




#' Extract Annotations from PubMed Records
#'
#' Parses XML records from PubMed to extract annotations such as MeSH terms, chemical names, and keywords. 
#' @param g An XML node set representing a single PubMed record.
#' @return A data frame with annotations extracted from a PubMed record.
#' @keywords internal

.extract_annotations <- function(g){
  
  # Extract the PubMed ID (PMID) from the XML record
  pm <- xml2::xml_find_all(g, ".//MedlineCitation/PMID") |> xml2::xml_text()
  
  # Extract MeSH terms (Medical Subject Headings)
  meshes <- xml2::xml_find_all(g, ".//DescriptorName") |> xml2::xml_text()
  
  # Extract chemical substances names
  chems <- xml2::xml_find_all(g, ".//NameOfSubstance") |> xml2::xml_text()
  
  # Extract keywords from the record
  keys <- xml2::xml_find_all(g, ".//Keyword") |> xml2::xml_text()
  
  # Combine the extracted data into a single data frame
  # Create separate data frames for MeSH terms, chemical substances, and keywords, and then bind them together
  df0 <- rbind(
    data.frame(pmid = pm, type = 'MeSH', form = if(length(meshes) > 0){meshes} else{NA}),
    data.frame(pmid = pm, type = 'Chemistry', form = if(length(chems) > 0){chems} else{NA}),
    data.frame(pmid = pm, type = 'Keyword', form = if(length(keys) > 0){keys} else{NA})
  )
  
  # Return the combined annotations data frame
  return(df0)
}