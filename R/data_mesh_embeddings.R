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
  }
  
  if (!file.exists(destination_file)) {
      
      out <- tryCatch(
        
        {
          message('Downloading the mesh_embeddings dataset...')
          utils::download.file(source_file, destination_file)
          },
        
        error = function(e) paste("Error"))
      
      if(out == 'Error'){
        message('Download not completed ... Try options(timeout = 600)')
        file.remove(destination_file)
        }
      }else{
        readRDS(destination_file)
      }
  }
