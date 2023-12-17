


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
#############
util.get_pubtations <- function(x){
  
  ###
  con <- url(paste0("https://www.ncbi.nlm.nih.gov/research/pubtator-api/publications/export/biocjson?pmids=", paste(x, collapse = ',')))
  
  Sys.sleep(round(runif(1, min = 0, max = 2), digits = 1))
  mydata <- tryCatch(jsonlite::stream_in(gzcon(con)),error = function(e) NA)  
  
  
  if(length(mydata) == 1){jj0 <- NA} else{
    
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
  }
  jj0
}
