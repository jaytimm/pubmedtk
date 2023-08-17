#' Perform basic PubMed search.
#'
#' @name pmed_search_pubmed
#' @param query Query term as character string
#' @return A vector of PMIDs
#'
#' @export
#' @rdname pmed_search_pubmed
#'
#'
pmed_search_pubmed <- function(query) { # max_n

  
  ps <- rentrez::entrez_search(db="pubmed",
                               term = query,
                               retmax=0,
                               use_history = T)
  
  if(ps$count==0) {
    
    stop("No Pubmed search results")
    
  } else {
    
    start <- seq(from=0,to=ps$count,by=90000)
    end <- c(start[-1],ps$count)
    chunk <- end - start
    idlist <- list()
    
    for(i in 1:length(start)){
      
      # print(paste0("Chunk ",i,": ",start[i]+1,"-",end[i]))
      
      Sys.sleep(0.5)
      
      idlist[[i]] <- rentrez::entrez_search(db="pubmed", 
                                            term=query, retstart=start[i],
                                            retmax=chunk[i],
                                            WebEnv=ps$web_history$WebEnv)$ids
    }
    
   unlist(idlist)
    
  }
  
}