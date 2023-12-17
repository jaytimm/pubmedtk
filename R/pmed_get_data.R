#' Aggregate and Process News Articles Based on a Search Query
#'
#' This function serves as the primary interface for aggregating news data.
#' It first builds an RSS feed URL based on a given search query, then parses
#' the RSS feed to extract news articles. Each article is then scraped and processed
#' to produce a consolidated dataset containing the article contents along with
#' associated metadata.
#'
#' @param x A string containing the URL of the website to be scraped.
#' @return A data frame with columns 'url', 'type', and 'text', containing the URL,
#'         type of HTML node, and the extracted text, respectively. Returns an empty
#'         data frame with these columns if scraping fails.
#' @import xml2
#' @import rvest
#' @importFrom httr GET timeout
#' @examples
#' get_site("http://example.com")

#' @export
#' 
## task_params = list()
pmed_get_data <- function(pmids, 
                          task_type, 
                          cores = 3, 
                          ncbi_key = NULL) {
  
  
  # Determine the number of cores to use
  cores <- ifelse(cores > 3, min(parallel::detectCores() - 1, 3), cores)
  
  # Set the NCBI API key if provided
  if (!is.null(ncbi_key)) rentrez::set_entrez_key(ncbi_key)
  
  # Define the batch size and task function based on task_type
  batch_size <- if (task_type == "pubtations") 100 else 199
  task_function <- switch(task_type,
                          "icites" = util.get_icites,
                          "pubtations" = util.get_pubtations,
                          "affiliations" = util.get_affiliations,
                          "pubmed" = util.get_records,
                          stop("Invalid task type"))
  
  # Split PMIDs into batches
  batches <- split(pmids, ceiling(seq_along(pmids) / batch_size))
  
  # Set up a parallel cluster
  clust <- parallel::makeCluster(cores)
  parallel::clusterExport(cl = clust, varlist = c("task_function"), envir = environment())
  
  # Execute the task function in parallel
  results <- pbapply::pblapply(X = batches, FUN = task_function, cl = clust)
  
  # Stop the cluster
  parallel::stopCluster(clust)
  
  # Combine the results
  combined_results <- data.table::rbindlist(results)
  return(combined_results)
}

