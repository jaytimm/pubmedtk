#' Load pharmacological actions from Git
#'
#' @return A data frame.
#' @export
#' @rdname data_pharm_action
data_pharm_action <- function() {
  
  sf = 'https://github.com/jaytimm/mesh-builds/blob/main/data/data_pharm_action.rds?raw=true'
  df = file.path(rappdirs::user_data_dir('pubmedr'), 'data_pharm_action.rds')

  if (!file.exists(df)) {
    if (!dir.exists(rappdirs::user_data_dir('pubmedr'))) {
      dir.create(rappdirs::user_data_dir('pubmedr'), 
                 recursive = TRUE)
    }
    
    message('Downloading pharmacological actions ...')
    utils::download.file(sf, df)
  }
  
  a1 <- readRDS(df)
  return(a1)
}