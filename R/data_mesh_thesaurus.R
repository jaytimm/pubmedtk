#' Load mesh thesaurus from Git
#'
#' @return A data frame.
#' @export
#' @rdname data_mesh_thesaurus
data_mesh_thesuarus <- function() {
  
  sf = 'https://github.com/jaytimm/mesh-builds/blob/main/data/data_mesh_thesaurus.rds?raw=true'
  sf2 = 'https://github.com/jaytimm/mesh-builds/blob/main/data/data_scr_thesaurus.rds?raw=true'
  df = file.path(rappdirs::user_data_dir('pubmedr'), 'data_mesh_thesuarus.rds')
  df2 = file.path(rappdirs::user_data_dir('pubmedr'), 'data_scr_thesuarus.rds')
  
  if (!file.exists(df)) {
    if (!dir.exists(rappdirs::user_data_dir('pubmedr'))) {
      dir.create(rappdirs::user_data_dir('pubmedr'), 
                 recursive = TRUE)
    }
    
    message('Downloading the mesh thesaurus ...')
    utils::download.file(sf, df)
  }
    
  if (!file.exists(df2)) {
    message('Downloading the supplemental concept thesaurus ...')
    utils::download.file(sf2, df2)
    }
  
  a1 <- readRDS(df)
  a2 <- readRDS(df2)
  data.table::rbindlist(list(a1, a2), fill = T)
  
}