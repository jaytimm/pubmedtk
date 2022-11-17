#' Download PubTator Central NER annotations.
#'
#' @name pmed_get_entities
#' @param pmids A vector of PMIDs
#' @param cores Numeric specifying number of cores to use
#' @param verbose Boolean
#' @return A list of data frames
#'
#' @export
#' @rdname pmed_get_entities

pmed_get_entities <- function (pmids,
                               cores = 3,
                               # ncbi_key = NULL,
                               verbose = T) {
  
  
  if(!verbose){
    pbo <- pbapply::pboptions(type = "none")
    on.exit(pbapply::pboptions(pbo), add = TRUE)
  }
  
  # if(is.null(ncbi_key) & cores > 3) cores <- min(parallel::detectCores() - 1, 3)
  # if(!is.null(ncbi_key)) rentrez::set_entrez_key(ncbi_key)
  # Sys.setenv(ENTREZ_KEY = ncbi_key)
  
  batches <- split(pmids, ceiling(seq_along(pmids)/100))
  
  clust <- parallel::makeCluster(cores)
  parallel::clusterExport(cl = clust,
                          varlist = c('batches'),
                          envir = environment())
  
  annotations <- pbapply::pblapply(cl = clust,
                                   X = batches,
                                   FUN = get_annotations)
  
  parallel::stopCluster(clust)
  return(annotations)
}


round(runif(1, min = 1, max = 3), digits = 1)


get_annotations <- function(x){
  
  con <- url(paste0("https://www.ncbi.nlm.nih.gov/research/pubtator-api/publications/export/biocjson?pmids=", paste(x, collapse = ',')))
  
  Sys.sleep(round(runif(1, min = 0, max = 2), digits = 1))
  ## REQUEST
  mydata <- jsonlite::stream_in(gzcon(con)) 
  
  jj <- list()
  
  for(i in 1:nrow(mydata)){
    
    ## q <- mydata$passages[[i]]
    pb1 <- mydata$passages[[i]]$annotations
    names(pb1) <- c('title', 'abstract')
    
    if(any(nrow(pb1$title) == 0, is.null(nrow(pb1$title)))) {
      pb1$title <- data.frame(tiab = 'title', 
                              id = NA, 
                              text = NA, 
                              locations = NA, 
                              identifier = NA, 
                              type = NA)
    } else{
      
      pb1$title <- cbind(tiab = 'title',
                         pb1$title[, c('id', 'text', 'locations')],
                         identifier = pb1$title$infons$identifier,
                         type = pb1$title$infons$type)
      
    }
    
    
    if(any(nrow(pb1$abstract) == 0, is.null(nrow(pb1$abstract)))) {
      pb1$abstract <- data.frame(tiab = 'abstract',
                                 id = NA, 
                                 text = NA, 
                                 locations = NA, 
                                 identifier = NA, 
                                 type = NA)
    } else{
      
      pb1$abstract <- cbind(tiab = 'abstract',
                            pb1$abstract[, c('id', 'text', 'locations')],
                            identifier = pb1$abstract$infons$identifier,
                            type = pb1$abstract$infons$type)
    }
    
    jj[[i]] <- rbind(pb1$title, pb1$abstract)
  }
  
  names(jj) <- mydata$id
  jj0 <- jj |> data.table::rbindlist(idcol = 'pmid')
  jj0$locations <- jj0$locations |> as.character()
  jj0$locations <- gsub("[^[:digit:],]", "", jj0$locations)
  
  jj0[, c('start', 'length') := data.table::tstrsplit(locations, ",", fixed=TRUE)]
  jj0[, start := as.integer(start)]
  jj0[, end := start + as.integer(length)]

  jj0[, length := NULL]
  jj0[, locations := NULL]
  return(jj0)
}
