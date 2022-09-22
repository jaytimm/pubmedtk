#' Extract citation info from NIH's iCite API.
#'
#' @name pmed_get_icites
#' @param pmids A character vector (of PMIDs)
#' @param cores An integer (specifying number of cores to use)
#' @param ncbi_key A character string (API key)
#' @return A list of data frames
#'
#' @export
#' @rdname pmed_get_icites
#'
#'
pmed_get_icites <- function(pmids,
                            cores = 3,
                            ncbi_key = NULL){

  if(is.null(ncbi_key) & cores > 3) cores <- min(parallel::detectCores() - 1, 3)
  if(!is.null(ncbi_key)) rentrez::set_entrez_key(ncbi_key)

  batches <- split(pmids, ceiling(seq_along(pmids)/199))

  clust <- parallel::makeCluster(cores)
  parallel::clusterExport(cl = clust,
                          varlist = c('batches'),
                          envir = environment())

  icite <- pbapply::pblapply(X = batches,
                             FUN = get_icites,
                             cl = clust
  )

  parallel::stopCluster(clust)
  icite0 <- data.table::rbindlist(icite)
  return(icite0)
}


### x <- batches[[1]]
get_icites <- function(x){

  url0 <- httr::GET(paste0("https://icite.od.nih.gov/api/pubs?pmids=",
                           paste(x, collapse = ","),
                           "&format=csv")
  )

  pmiddf <- utils::read.csv(textConnection(
    httr::content(url0,
                  "text",
                  encoding = "UTF-8")),
    encoding = "UTF-8")

  gots <- pmiddf$pmid

  data.table::setDT(pmiddf)
  pmiddf[, ref_count := ifelse(is.null(references)|is.na(references), NULL, references)]

  pmiddf[, references := ifelse(nchar(references) == 0|is.na(references), '99', references)]
  pmiddf[, cited_by := ifelse(nchar(cited_by) == 0|is.na(cited_by), '99', cited_by)]

  cited_by <- strsplit(pmiddf$cited_by, split = " ")
  references <- strsplit(pmiddf$references, split = " ")
  rs <- strsplit(pmiddf$ref_count, split = " ")

  refs <- data.frame(doc_id = rep(gots,
                                  sapply(references, length)),
                     from = rep(gots,
                                sapply(references, length)),
                     to = unlist(references))
  refs[refs == 99] <- NA
  refs0 <- data.table::setDT(refs)[, list(references = .N), by = .(from)]

  cited <- data.frame(doc_id = rep(gots,
                                   sapply(cited_by, length)),
                      from = unlist(cited_by),
                      to = rep(gots,
                               sapply(cited_by, length)))
  cited[cited == 99] <- NA

  f1 <- rbind(refs, cited)
  f2 <-data.table::setDT(f1)[, list(references = list(.SD)), by = doc_id]
  pmiddf[, citation_net := f2$references]
  pmiddf[, ref_count := sapply(rs, length)]
  pmiddf[, c('cited_by', 'references') := NULL]
  return(pmiddf)
}
