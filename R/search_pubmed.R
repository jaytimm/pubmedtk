#' Perform basic PubMed search.
#'
#' @name search_pubmed
#' @param x Query term as character string
#' @return A vector of PMIDs
#'
#' @export
#' @rdname search_pubmed
#'
#'
search_pubmed <- function(x) { # max_n

  ps <- rentrez::entrez_search(db = "pubmed",
                               term = x,
                               retmax = 0,
                               use_history = T)
  
  if(ps$count==0) {NULL} else {
    
    start <- seq(from = 0, to = ps$count, by = 90000)
    end <- c(start[-1], ps$count)
    chunk <- end - start
    idlist <- list()
    
    for(i in 1:length(start)){
      
      Sys.sleep(0.5)
      
      idlist[[i]] <- rentrez::entrez_search(db = "pubmed", 
                                            term = x, retstart=start[i],
                                            retmax = chunk[i],
                                            WebEnv = ps$web_history$WebEnv)$ids
    }
    
   unlist(idlist)
    
  }
  
}