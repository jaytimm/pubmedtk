#' Get full text articles from Open Access subset of PMC --
#'
#' @name pmed_get_fulltext
#' @param x A character vector, namely, a file path included in OA list file
#' @return A dtaframe
#'
#' @export
#' @rdname pmed_get_fulltext
#'
pmed_get_fulltext <- function(x) {
  
  flist <- lapply(1:length(x), function(q){
    
    ## still downloads to working directory -- !! -- 
    fn <- paste0('https://ftp.ncbi.nlm.nih.gov/pub/pmc/', x[q])
    tmp <- tempfile()
    download.file(fn, destfile = tmp)
    xmls <- grep('xml$', untar(tmp, list = TRUE), value = T)
    untar(tmp, files = xmls, exdir = tempdir())
 
    x0 <- xml2::read_xml(paste0(tempdir(), '/', xmls))
    
    if(length(xml2::xml_children(x0)) == 1){} else{
      
      x1 <- xml2::xml_child(x0, 2)
      
      header_titles <- lapply(xml2::xml_children(x1),
                              function(x) {
                                xml2::xml_text(xml2::xml_find_first(x, ".//title"))}
      )
      
      # sub_titles <- lapply(xml2::xml_children(x1),
      #                      function(x) {
      #                        xml2::xml_text(xml2::xml_find_all(x, ".//title"))}
      # )
      # 
      # toc <- setNames(stack(setNames(sub_titles, header_titles)), c('sub', 'header'))
      # toc0 <- subset(toc, sub != header)
      # 
      text <- lapply(xml2::xml_children(x1), xml2::xml_text)
      pmcid <- gsub('(^.*)(PMC)([0-9]*)(\\.tar\\.gz$)', '\\3', x[q])
      section <- unlist(header_titles)
      
      df <- data.frame(doc_id = paste0(pmcid, '_', section),
                       pmcid, 
                       section,
                       text = unlist(text),
                       row.names = NULL)
      
      
      # heads <- paste0('^', df$section, collapse = '|')
      # heads <- gsub('\\(', '\\\\(', heads)
      # heads <- gsub('\\)', '\\\\)', heads)
      # 
      # df$text <- gsub(heads, '', df$text)
      
      df$text <- gsub('([a-z]+)([A-Z])', '\\1\n\\2', df$text)
      
      # if (nrow(toc0) > 0) {
      #   splits <- paste0(toc$sub, collapse = '|')
      #   # splits <- gsub('\\(', '\\\\(', splits)
      #   # splits <- gsub('\\)', '\\\\)', splits)
      #   
      #   #q <- paste0('(', splits, ')')
      #   
      #   df$text <- gsub(splits, '\n\n\\1: ', df$text)
      # }
      
      df }
  })
  
  flist |> data.table::rbindlist()
}