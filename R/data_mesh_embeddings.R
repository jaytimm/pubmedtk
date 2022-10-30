#' Load mesh embeddings and thesaurus from Git
#'
#' @return A matrix of mesh embeddings.
#' @export
#' @rdname data_mesh_embeddings
data_mesh_embeddings <- function() {
  
  source_file = 'https://github.com/jaytimm/pubmedr/blob/main/download/mesh_embeddings.rds?raw=true'
  destination_file = file.path(rappdirs::user_data_dir('pubmedr'), 'mesh_embeddings.rds')
  
  if (!file.exists(destination_file)) {
    if (!dir.exists(rappdirs::user_data_dir('pubmedr'))) {
      dir.create(rappdirs::user_data_dir('pubmedr'), recursive = TRUE)
    }
    
    message('Downloading the mesh_embeddings dataset...')
    utils::download.file(source_file, destination_file)
  }
  
  readRDS(destination_file)
}


#' @return A data frame.
#' @export
#' @rdname data_mesh_thesaurus
data_mesh_thesuarus <- function() {
  
  source_file = 'https://github.com/jaytimm/pubmedr/blob/main/download/mesh_thesaurus.rds?raw=true'
  destination_file = file.path(rappdirs::user_data_dir('pubmedr'), 'mesh_thesuarus.rds')
  
  if (!file.exists(destination_file)) {
    if (!dir.exists(rappdirs::user_data_dir('pubmedr'))) {
      dir.create(rappdirs::user_data_dir('pubmedr'), recursive = TRUE)
    }
    
    message('Downloading the mesh_thesaurus dataset...')
    utils::download.file(source_file, destination_file)
  }
  
  readRDS(destination_file)
}