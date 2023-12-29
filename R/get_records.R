#' Retrieve Data from PubMed Based on PMIDs
#'
#' This function retrieves different types of data (like PubMed records, affiliations, iCites data, etc.) from PubMed based on provided PMIDs. It supports parallel processing for efficiency.
#' @param pmids A vector of PMIDs for which data is to be retrieved.
#' @param endpoint A character vector specifying the type of data to retrieve ('pubtations', 'icites', 'affiliations', 'pubmed', 'pmc').
#' @param cores Number of cores to use for parallel processing (default is 3).
#' @param ncbi_key (Optional) NCBI API key for authenticated access.
#' @return A data.table containing combined results from the specified endpoint.
#' @importFrom parallel makeCluster stopCluster detectCores clusterExport
#' @importFrom pbapply pblapply
#' @importFrom data.table rbindlist
#' @export
#' @rdname get_records
#' 
get_records <- function(pmids, 
                          endpoint = c('pubtations', 
                                       'icites', 
                                       'pubmed_affiliations', 
                                       'pubmed_abstracts', 
                                       'pmc'), 
                          cores = 3, 
                          ncbi_key = NULL) {
  
  # Determine the appropriate number of cores to use, with a maximum of 3
  cores <- ifelse(cores > 3, min(parallel::detectCores() - 1, 3), cores)
  
  # Set the NCBI API key for authenticated access if provided
  if (!is.null(ncbi_key)) rentrez::set_entrez_key(ncbi_key)
  
  # Define batch size and the specific task function based on the chosen endpoint
  batch_size <- if (endpoint == "pmc") {20} else if (endpoint == "pubtations") {99} else {199}
  task_function <- switch(endpoint,
                          "icites" = .get_icites,
                          "pubtations" = .get_pubtations,
                          "pubmed_affiliations" = .get_affiliations,
                          "pubmed_abstracts" = .get_records,
                          "pmc_fulltext" = .get_pmc,
                          stop("Invalid endpoint"))
  
  # Split the PMIDs into batches for parallel processing
  batches <- split(pmids, ceiling(seq_along(pmids) / batch_size))
  
  # Set up a parallel cluster using the specified number of cores
  clust <- parallel::makeCluster(cores)
  parallel::clusterExport(cl = clust, varlist = c("task_function"), envir = environment())
  
  # Execute the task function on each batch in parallel
  results <- pbapply::pblapply(X = batches, FUN = task_function, cl = clust)
  
  # Stop the parallel cluster
  parallel::stopCluster(clust)
  
  # Combine results from all batches into a single data.table
  combined_results <- data.table::rbindlist(results)
  return(combined_results)
}
