#' Download/load list of PMC full text articles.
#'
#' @return A data frame.
#' @export
#' @rdname data_pmc_list
#' 
#' 
data_pmc_list <- function(force_install = F) {
  
  sf = 'https://ftp.ncbi.nlm.nih.gov/pub/pmc/oa_file_list.txt'
  
  df = file.path(rappdirs::user_data_dir('pubmedr'), 
                 'oa_file_list.rds')
  
  if (!file.exists(df) | force_install) {
    if (!dir.exists(rappdirs::user_data_dir('pubmedr'))) {
      dir.create(rappdirs::user_data_dir('pubmedr'), 
                 recursive = TRUE)
    }
    
    message('Downloading "pub/pmc/oa_file_list.txt" ...')
    suppressWarnings(
      pmc <- data.table::fread(sf, sep = '\t')
    )
    
    colnames(pmc) <- c('fpath', 
                       'journal', 
                       'PMCID', 
                       'PMID', 
                       'license_type')
    
    # pmc0 <- subset(pmc, nchar(PMID) > 2) 
    
    pmc[, PMID := gsub('^PMID:', '', PMID)]
    pmc[, PMCID := gsub('^PMC', '', PMCID)]
    pmc[pmc==''] <- NA
    
    setwd(rappdirs::user_data_dir('pubmedr'))
    saveRDS(pmc, 'oa_file_list.rds')
  }
  
  pmc <- readRDS(df)
  return(pmc)
}