#' Perform basic PubMed search.
#'
#' @name pmed_search_pubmed
#' @param search_term Query term as character string
#' @param fields PubMed fields to query
#' @param sleep In seconds.
#' @param verbose Boolean
#' @param retmax Max records
#' @return A data frame of PMIDs
#'
#' @export
#' @rdname pmed_search_pubmed
#'
#'
pmed_search_pubmed <- function (search_term,
                                fields = c('TIAB','MH'),
                                verbose = TRUE,
                                sleep = 1,
                                retmax = 5000000,
                                is_pubmed_syntax = F) { # max_n

  
  ## https://pubmed.ncbi.nlm.nih.gov/?term=Cranberry&filter=pubt.clinicaltrial
  
  fout <- list()
  for(i in 1:length(search_term)){

    pre_url1 <- "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?"
    pre_url2 <- paste0("db=pubmed&retmax=",
                       format(retmax, scientific = FALSE),
                       "&term=")
    strip_part <- 'https://pubmed.ncbi.nlm.nih.gov/\\?term='

    
    if(is_pubmed_syntax){
      full_url <- paste0(pre_url1, pre_url2, gsub(strip_part, '', search_term))
      out_search = gsub(strip_part, '', search_term)}else{
        
        url_term_query <- gsub(" ", "+", search_term[i], fixed = TRUE)
    
        if(is.null(fields)) {
          fields3 <- url_term_query
          out_search <- search_term[i]} else{
    
            fields0 <- paste0('%5B', fields, '%5D')
            fields1 <- paste0(url_term_query, fields0)
            fields2 <- paste0(fields1, sep = '+OR+', collapse = '')
            fields3 <- gsub('\\+OR\\+$', '', fields2)
    
            out_search <- paste0(search_term[i],
                                 paste0('[', fields, ']'),
                                 collapse = ' OR ')
            }
        
        full_url <- paste0 (pre_url1, pre_url2, fields3)
        
        }

    
    x <- httr::GET(full_url)
    x1 <- xml2::read_xml(x)
    x2 <- xml2::xml_find_all(x1, './/Id')
    x3 <- xml2::xml_text(x2)

    if (length(x3) == 0) {x3 <- NA}

    fout[[i]] <- data.table::data.table(search_term = search_term[i], pmid = x3)

    Sys.sleep(sleep)
    if(verbose){
      finally =  print(paste0(out_search, ': ', nrow(fout[[i]]), ' records'))
    }
  }
  return(data.table::rbindlist(fout))
}
