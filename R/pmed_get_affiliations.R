#' Download author/affiliation data from PubMed.
#'
#' @name pmed_get_affiliations
#' @param pmids A vector of PMIDs
#' @param cores Numeric specifying number of cores to use
#' @param ncbi_key API key
#' @param clean Boolean
#' @return A list of data frames
#'
#' @export
#' @rdname pmed_get_affiliations
#'
#'
pmed_get_affiliations <- function (pmids,
                                   cores = 3,
                                   ncbi_key = NULL,
                                   clean = T) {

  if(is.null(ncbi_key) & cores > 3) cores <- min(parallel::detectCores() - 1, 3)
  if(!is.null(ncbi_key)) rentrez::set_entrez_key(ncbi_key)

  batches <- split(pmids, ceiling(seq_along(pmids)/199))

  clust <- parallel::makeCluster(cores)
  parallel::clusterExport(cl = clust,
                          varlist = c('batches'),
                          envir = environment())

  mess2 <- pbapply::pblapply(X = batches,
                             FUN = function(x)
                               get_affs(x, clean = clean),
                             cl = clust
  )

  parallel::stopCluster(clust)
  return(mess2)
}


######
get_affs <- function (x, clean) {

  x1 <- rentrez::entrez_fetch(db = "pubmed",
                              id = x,
                              rettype = "xml",
                              parsed = F)

  Sys.sleep(0.25)
  doc <- xml2::read_xml(x1)
  records <- xml2::xml_find_all(doc, ".//PubmedArticle")

  z <- lapply(records, function(g){

    pm <- xml2::xml_text(xml2::xml_find_all(g, ".//MedlineCitation/PMID"))
    auts <- xml2::xml_find_all(g, ".//Author")

    cache <- lapply(auts, function(k){
      Author <- paste(
        xml2::xml_text(xml2::xml_find_all(k, ".//LastName")),
        xml2::xml_text(xml2::xml_find_all(k, ".//ForeName")),
        sep = ', ')
      if(length(Author) == 0){Author <- NA}

      Affiliation <- xml2::xml_text(xml2::xml_find_all(k,  ".//Affiliation"))
      if(length(Affiliation) == 0){Affiliation <- NA}
      data.frame(pmid = pm, Author, Affiliation)
    })

    data.table::rbindlist(cache)
  })
  x0 <- data.table::rbindlist(z)

  if(clean){
    x0[, Affiliation := sub('^.*?([A-Z])','\\1', Affiliation)]
    x0[, Affiliation := trimws(Affiliation)]
    x0[, Affiliation := gsub('(^.*[[:punct:] ])(.*@.*$)', '\\1', Affiliation)]
    x0[, Affiliation := gsub('(^.*[[:punct:] ])(.*@.*$)', '\\1', Affiliation)]
    x0[, Affiliation := gsub('electronic address.*$|email.*$', '', Affiliation, ignore.case = T)]
    x0[, Affiliation := ifelse(nchar(Affiliation) < 10, NA, Affiliation)]}

  return(x0)
}
