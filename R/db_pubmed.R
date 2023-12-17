
#' @param x A string containing the URL of the website to be scraped.
#' @return A data frame with columns 'url', 'type', and 'text', containing the URL,
#'         type of HTML node, and the extracted text, respectively. Returns an empty
#'         data frame with these columns if scraping fails.
#' @keywords internal
#' @import xml2
#' @import rvest
#' @importFrom httr GET timeout
#' @examples
#' get_site("http://example.com")
#' @noRd

util.get_records <- function (x) { #}, with_annotations) {
  
  ### parse and xml -- 
  records <- util.fetch_records(x)
  
  parsed_records <- lapply(records, function(x){
    
    basic_info <- util.extract_basic(x)
    annotations <- util.extract_annotations(x)
    
    out1 <- list('basic_info' = basic_info, 'annotations' = annotations)
    return(out1)
    
  })
  
  sum0 <- textshape::tidy_list(x = lapply(parsed_records, '[[', 1),
                               id.name = 'id',
                               content.name = 'varx')
  
  sum1 <- data.table::dcast(data = sum0,
                            formula = id ~ attribute,
                            value.var = 'varx')
  
  sum1 <- sum1[, c('pmid',
                   # 'doi',
                   'year',
                   'journal',
                   'articletitle',
                   'abstract')]
  
  #if(with_annotations){
  sum1[, annotations := list(lapply(parsed_records, '[[', 2))] 
   # }
  
  ## lastly
  Encoding(rownames(sum1)) <- 'UTF-8'
  cols <- colnames(sum1)
  sum1[, c(cols) := lapply(.SD, util.clean_nas), .SDcols = cols]
  
  return(sum1)
  
}





#' @param x A string containing the URL of the website to be scraped.
#' @return A data frame with columns 'url', 'type', and 'text', containing the URL,
#'         type of HTML node, and the extracted text, respectively. Returns an empty
#'         data frame with these columns if scraping fails.
#' @keywords internal
#' @import xml2
#' @import rvest
#' @importFrom httr GET timeout
#' @examples
#' get_site("http://example.com")
#' @noRd
#' 
util.extract_basic <- function(g){
  
  ## pmid
  pm <- xml2::xml_text(
    xml2::xml_find_all(g, ".//MedlineCitation/PMID"))
  
  ## journal title
  a1 <- xml2::xml_text(xml2::xml_find_all(g, ".//Title"))
  a1a <- a1[1]
  
  ## article tite
  a2 <- xml2::xml_text(
    xml2::xml_find_all(g, ".//ArticleTitle"))
  
  # doi <- xml2::xml_text(
  #   xml2::xml_find_all(g, ".//ELocationID"))
  #   if(length(doi) == 0){doi <- NA}
  
  ## Year
  year <- xml2::xml_text(
    xml2::xml_find_all(g, ".//PubDate/Year"))
  
  if(length(year) == 0){ ## -- ??? --
    year <- xml2::xml_text(
      xml2::xml_find_all(g, ".//PubDate/MedlineDate"))}
  
  year <- gsub(" .+", "", year)
  year <- gsub("-.+", "", year)
  
  ## Abstract
  abstract <- xml2::xml_text(
    xml2::xml_find_all(g, ".//Abstract/AbstractText"))
  if(length(abstract) > 1){
    abstract <- paste(abstract, collapse = ' ')}
  if(length(abstract) == 0){abstract <- NA}
  
  out <- c('pmid' = pm,
           # 'doi' = doi,
           'journal' = a1a,
           'articletitle' = a2,
           'year' = year,
           'abstract' = abstract)
  
  return(out)
}




#' @param x A string containing the URL of the website to be scraped.
#' @return A data frame with columns 'url', 'type', and 'text', containing the URL,
#'         type of HTML node, and the extracted text, respectively. Returns an empty
#'         data frame with these columns if scraping fails.
#' @keywords internal
#' @import xml2
#' @import rvest
#' @importFrom httr GET timeout
#' @examples
#' get_site("http://example.com")
#' @noRd
#' 
util.extract_annotations <- function(g){
  
  ## pmid
  pm <- xml2::xml_text(
    xml2::xml_find_all(g, ".//MedlineCitation/PMID"))
  
  ## descriptor
  meshes <- xml2::xml_text(
    xml2::xml_find_all(g, ".//DescriptorName"))
  
  ## chemicals
  chems <- xml2::xml_text(
    xml2::xml_find_all(g, ".//NameOfSubstance"))
  
  ## keywords
  keys <- xml2::xml_text(
    xml2::xml_find_all(g, ".//Keyword"))
  
  
  df0 <- rbind(
    data.frame(pmid = pm,
               type = 'MeSH',
               form = if(length(meshes) > 0){meshes} else{NA}),
    data.frame(pmid = pm,
               type = 'Chemistry',
               form = if(length(chems) > 0){chems} else{NA}),
    data.frame(pmid = pm,
               type = 'Keyword',
               form = if(length(keys) > 0){keys} else{NA})
  )
  
}




#' @param x A string containing the URL of the website to be scraped.
#' @return A data frame with columns 'url', 'type', and 'text', containing the URL,
#'         type of HTML node, and the extracted text, respectively. Returns an empty
#'         data frame with these columns if scraping fails.
#' @keywords internal
#' @import xml2
#' @import rvest
#' @importFrom httr GET timeout
#' @examples
#' get_site("http://example.com")
#' @noRd

util.fetch_records <- function(x){
  
  ## try and fetch
  for (i in 1:15) {
    message(i)
    x1 <- try({
      rentrez::entrez_fetch(db = "pubmed",
                            id = x,
                            rettype = "xml",
                            parsed = F)
    })
    
    Sys.sleep(5)
    if (class(x1) != "try-error") {
      break
    }
  }
  
  ## parse XML --
  doc <- xml2::read_xml(x1)
  xml2::xml_find_all(doc, "//PubmedArticle")
}




#' @param x A string containing the URL of the website to be scraped.
#' @return A data frame with columns 'url', 'type', and 'text', containing the URL,
#'         type of HTML node, and the extracted text, respectively. Returns an empty
#'         data frame with these columns if scraping fails.
#' @keywords internal
#' @import xml2
#' @import rvest
#' @importFrom httr GET timeout
#' @examples
#' get_site("http://example.com")
#' @noRd

util.clean_nas <- function(x) {
  ifelse(x %in% c(' ', 'NA', 'n/a', 'n/a.') | is.na(x), NA, x) 
}


