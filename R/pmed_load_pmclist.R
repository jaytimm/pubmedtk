#' Get PMC OA list from NCMI ftp -- 
#'
#' @name pmed_load_pmclist
#' @return A dataframe
#'
#' @export
#' @rdname pmed_load_pmclist

pmed_load_pmclist <- function(){
  
  suppressWarnings(
    pmc <- data.table::fread('https://ftp.ncbi.nlm.nih.gov/pub/pmc/oa_file_list.txt', sep = '\t')
  )
  ## 'oa_comm_use_file_list.txt'
  
  colnames(pmc) <- c('fpath', 
                     'journal', 
                     'PMCID', 
                     'PMID', 
                     'license_type')
  
  # pmc0 <- subset(pmc, nchar(PMID) > 2) 
  
  pmc[, PMID := gsub('^PMID:', '', PMID)]
  pmc[, PMCID := gsub('^PMC', '', PMCID)]
  pmc[pmc==''] <- NA
  return(pmc)
}
