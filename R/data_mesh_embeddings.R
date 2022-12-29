#' Load mesh embeddings and thesaurus from Git
#'
#' @return A matrix of mesh embeddings.
#' @export
#' @rdname data_mesh_embeddings
data_mesh_embeddings <- function() {
  
  sf = 'https://github.com/jaytimm/mesh-builds/blob/main/data/data_mesh_embeddings.rds?raw=true'
  sf2 = 'https://github.com/jaytimm/mesh-builds/blob/main/data/data_scr_embeddings.rds?raw=true'
  df = file.path(rappdirs::user_data_dir('pubmedr'), 'data_mesh_emeddings.rds')
  df2 = file.path(rappdirs::user_data_dir('pubmedr'), 'data_scr_emeddings.rds')
  
  
  if (!file.exists(df)) {
    if (!dir.exists(rappdirs::user_data_dir('pubmedr'))) {
      dir.create(rappdirs::user_data_dir('pubmedr'), 
                 recursive = TRUE)
    }
  }
  
  if (!file.exists(df)) {
      
      out <- tryCatch(
        
        {
          message('Downloading the mesh embeddings ...')
          utils::download.file(sf, df)
          },
        
        error = function(e) paste("Error"))
      
      if(out == 'Error'){
        message('Download not completed ... Try options(timeout = 600)')
        file.remove(df)
        }
      }
  
  if (!file.exists(df2)) {
    
    out <- tryCatch(
      
      {
        message('Downloading the scr embeddings ...')
        utils::download.file(sf2, df2)
      },
      
      error = function(e) paste("Error"))
    
    if(out == 'Error'){
      message('Download not completed ... Try options(timeout = 600)')
      file.remove(df2)
    }
  }
  
  if (all(file.exists(df), file.exists(df2))){
    
    a1 <- readRDS(df)
    a2 <- readRDS(df2)
    data.table::rbindlist(list(a1, a2), fill = T)
    }
  }
