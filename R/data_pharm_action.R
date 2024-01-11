#' Download and Load Pharmacological Actions Data
#'
#' This function downloads and loads pharmacological actions data from a specified URL.
#' The data is stored locally in the user's data directory. If the data file does not 
#' exist locally or if `force_download` is TRUE, it will be downloaded. The function 
#' returns the data as a data frame.
#'
#' @param force_download A logical value indicating whether to force re-downloading 
#' of the data even if it already exists locally. Default is FALSE.
#' @return A data frame containing pharmacological actions data.
#' @importFrom rappdirs user_data_dir
#' @importFrom utils download.file
#' @examples
#' \donttest{
#' pharm_action_data <- data_pharm_action(force_download = FALSE)
#' }
#' @export
data_pharm_action <- function(force_download = FALSE) {
  
  # URL for the pharmacological actions data
  sf <- 'https://github.com/jaytimm/mesh-builds/blob/main/data/data_pharm_action.rds?raw=true'
  
  # Local file path for storing the data
  df <- file.path(rappdirs::user_data_dir('pubmedr'), 'data_pharm_action.rds')
  
  # Check if the data file exists, and download it if it doesn't or if forced
  if (!file.exists(df) | force_download) {
    # Create the directory if it doesn't exist
    if (!dir.exists(rappdirs::user_data_dir('pubmedr'))) {
      dir.create(rappdirs::user_data_dir('pubmedr'), recursive = TRUE)
    }
    
    # Download the pharmacological actions data
    message('Downloading pharmacological actions ...')
    utils::download.file(sf, df, mode = "wb")
  }
  
  # Read and return the downloaded RDS file
  a1 <- readRDS(df)
  return(a1)
}
