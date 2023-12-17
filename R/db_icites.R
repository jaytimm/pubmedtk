#' Aggregate and Process News Articles Based on a Search Query
#'
#' This function serves as the primary interface for aggregating news data.
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

util.fetch_icites <- function(x){
  
  url0 <- httr::GET(paste0("https://icite.od.nih.gov/api/pubs?pmids=",
                           paste(x, collapse = ","),
                           "&format=csv"))
  
  ## no error handling here
  csv_ <- utils::read.csv(textConnection(
    httr::content(url0,
                  "text",
                  encoding = "UTF-8")),
    encoding = "UTF-8")
  
  return(csv_)
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
util.get_icites <- function(x){
  
  pmiddf <- util.fetch_icites(x)
  
  ### BUILD
  gots <- pmiddf$pmid
  
  data.table::setDT(pmiddf)
  pmiddf[, ref_count := ifelse(is.null(references)|is.na(references), NULL, references)]
  
  pmiddf[, references := ifelse(nchar(references) == 0|is.na(references), '99', references)]
  pmiddf[, cited_by := ifelse(nchar(cited_by) == 0|is.na(cited_by), '99', cited_by)]
  
  cited_by <- strsplit(pmiddf$cited_by, split = " ")
  references <- strsplit(pmiddf$references, split = " ")
  rs <- strsplit(pmiddf$ref_count, split = " ")
  
  refs <- data.frame(doc_id = rep(gots,
                                  sapply(references, length)),
                     from = rep(gots,
                                sapply(references, length)),
                     to = unlist(references))
  refs[refs == 99] <- NA
  refs0 <- data.table::setDT(refs)[, list(references = .N), by = .(from)]
  
  cited <- data.frame(doc_id = rep(gots,
                                   sapply(cited_by, length)),
                      from = unlist(cited_by),
                      to = rep(gots,
                               sapply(cited_by, length)))
  cited[cited == 99] <- NA
  
  f1 <- rbind(refs, cited)
  f2 <-data.table::setDT(f1)[, list(references = list(.SD)), by = doc_id]
  pmiddf[, citation_net := f2$references]
  pmiddf[, ref_count := sapply(rs, length)]
  pmiddf[, c('cited_by', 'references') := NULL]
  return(pmiddf)
}

