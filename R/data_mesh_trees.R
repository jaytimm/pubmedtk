#' Load mesh trees from Git
#'
#' @return A data frame.
#' @export
#' @rdname data_mesh_trees
data_mesh_trees <- function(force_download = FALSE) {
  
  sf = 'https://github.com/jaytimm/mesh-builds/blob/main/data/data_mesh_trees.rds?raw=true'
  df = file.path(rappdirs::user_data_dir('pubmedr'), 'data_mesh_trees.rds')

  if (!file.exists(df)|force_download) {
    if (!dir.exists(rappdirs::user_data_dir('pubmedr'))) {
      dir.create(rappdirs::user_data_dir('pubmedr'), 
                 recursive = TRUE)
    }
    
    message('Downloading mesh trees ...')
    utils::download.file(sf, df)
  }
  
  a1 <- readRDS(df)
  return(a1)
}