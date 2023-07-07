#' Get full text articles from Open Access subset of PMC --
#'
#' @name pmed_get_fulltext
#' @param x A character vector, namely, a file path included in OA list file
#' @param output_dir A file path
#' @return A dtaframe
#'
#' @export
#' @rdname pmed_get_fulltext
#'
pmed_get_fulltext <- function(x, output_dir = NULL) {
  
  flist <- list()

  for(q in 1:length(x)){
    
    
    fn <- paste0('https://ftp.ncbi.nlm.nih.gov/pub/pmc/', x[q])
  
    tmp <- tempfile()
    dd <- tryCatch(download.file(fn, destfile = tmp), error = function(e) 'error')  
    
    if(dd == 'error'){} else{
    
        xmls <- grep('xml$', untar(tmp, list = TRUE), value = T)
        untar(tmp, files = xmls, exdir = tempdir())
        
        x0 <- xml2::read_xml(paste0(tempdir(), '/', xmls)[1])
        

        if(length(xml2::xml_children(x0)) == 1){} else{
          
            x1 <- xml2::xml_child(x0, 2)
            
            header_titles <- lapply(xml2::xml_children(x1),
                                    function(x) {
                                      xml2::xml_text(xml2::xml_find_first(x, ".//title"))}
            )
            
            text <- lapply(xml2::xml_children(x1), xml2::xml_text)
            pmcid <- gsub('(^.*)(PMC)([0-9]*)(\\.tar\\.gz$)', '\\3', x[q])
            section <- unlist(header_titles)
            
            df <- data.frame(doc_id = paste0(pmcid, '_', section),
                             pmcid, 
                             section,
                             text = unlist(text),
                             row.names = NULL)
            
            df$text <- gsub('([a-z]+)([A-Z])', '\\1\n\\2', df$text)
            
            if(!is.null(output_dir)){

              saveRDS(df, paste0(output_dir, '/', pmcid, '.rds'))
              
            } else{ flist[[q]] <- df }}
            
            
        }
    }
  
  if(is.null(output_dir)){flist |> data.table::rbindlist()}
  
}