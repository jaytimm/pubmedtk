#' Download abstract and meta data from PubMed.
#'
#' @name pmed_get_records2
#' @param pmids A vector of PMIDs
#' @param with_annotations Boolean
#' @param cores Numeric specifying number of cores to use
#' @param ncbi_key API key
#' @param verbose Boolean
#' @return A list of data frames
#'
#' @export
#' @rdname pmed_get_records2
#'
#'
pmed_get_records2 <- function (pmids,
                               cores = 3,
                               ncbi_key = NULL,
                               with_annotations = T,
                               verbose = T) {


  if(!verbose){
    pbo <- pbapply::pboptions(type = "none")
    on.exit(pbapply::pboptions(pbo), add = TRUE)
  }

  if(is.null(ncbi_key) & cores > 3) cores <- min(parallel::detectCores() - 1, 3)
  if(!is.null(ncbi_key)) rentrez::set_entrez_key(ncbi_key)
  #Sys.setenv(ENTREZ_KEY = ncbi_key)
  batches <- split(pmids, ceiling(seq_along(pmids)/199))

  clust <- parallel::makeCluster(cores)
  parallel::clusterExport(cl = clust,
                          varlist = c('batches'),
                          envir = environment())

  mess2 <- pbapply::pblapply(X = batches,
                             FUN = function(x)
                               # this works --
                               pmed_get_records1(x,
                                                 with_annotations = with_annotations),
                             cl = clust
  )


  parallel::stopCluster(clust)
  return(mess2)
}


#######
pmed_get_records1 <- function (x,
                               with_annotations) {

  x1 <- rentrez::entrez_fetch(db = "pubmed",
                              id = x,
                              rettype = "xml",
                              parsed = F)
  Sys.sleep(0.25)

  ## main
  doc <- xml2::read_xml(x1)
  records <- xml2::xml_find_all(doc, "//PubmedArticle")

  ## basic info
  summaryt <- lapply(records, function(g){
    pm <- xml2::xml_text(
      xml2::xml_find_all(g, ".//MedlineCitation/PMID"))
    a1 <- xml2::xml_text(xml2::xml_find_all(g, ".//Title"))
    a1a <- a1[1]
    a2 <- xml2::xml_text(
      xml2::xml_find_all(g, ".//ArticleTitle"))

    year <- xml2::xml_text(
      xml2::xml_find_all(g, ".//PubDate/Year"))

    if(length(year) == 0){ ## -- ??? --
      year <- xml2::xml_text(
        xml2::xml_find_all(g, ".//PubDate/MedlineDate"))}

    year <- gsub(" .+", "", year)
    year <- gsub("-.+", "", year)

    abstract <- xml2::xml_text(
      xml2::xml_find_all(g, ".//Abstract/AbstractText"))
    if(length(abstract) > 1){
      abstract <- paste(abstract, collapse = ' ')}
    if(length(abstract) == 0){abstract <- NA}

    out <- c('pmid' = pm,
             'journal' = a1a,
             'articletitle' = a2,
             'year' = year,
             'abstract' = abstract)

    out1 <- list('gen' = out,
                 'annotations' = NULL)

    if(with_annotations){
      meshes <- xml2::xml_text(
        xml2::xml_find_all(g, ".//DescriptorName"))
      chems <- xml2::xml_text(
        xml2::xml_find_all(g, ".//NameOfSubstance"))
      keys <- xml2::xml_text(
        xml2::xml_find_all(g, ".//Keyword"))


      df0 <- rbind(
        data.frame(ID = pm,
                   TYPE = 'MeSH',
                   FORM = if(length(meshes) > 0){meshes} else{NA}),
        data.frame(ID = pm,
                   TYPE = 'Chemistry',
                   FORM = if(length(chems) > 0){chems} else{NA}),
        data.frame(ID = pm,
                   TYPE = 'Keyword',
                   FORM = if(length(keys) > 0){keys} else{NA})

        )

      out1 <- list('gen' = out,
                   'annotations' = df0)
      }
    return(out1)

  })


  ## aggregate --
  sum0 <- textshape::tidy_list(x = lapply(summaryt, '[[', 1),
                               id.name = 'id',
                               content.name = 'varx')

  sum1 <- data.table::dcast(data = sum0,
                            formula = id ~ attribute,
                            value.var = 'varx')

  sum1 <- sum1[, c('pmid',
                   'year',
                   'journal',
                   'articletitle',
                   'abstract')]

  if(with_annotations){
    sum1[, annotations := list(lapply(summaryt, '[[', 2))] }

  ## lastly
  Encoding(rownames(sum1)) <- 'UTF-8'
  cols <- colnames(sum1)
  sum1[, c(cols) := lapply(.SD, clean_nas), .SDcols = cols]
  return(sum1)
}




clean_nas <- function(x) {
  ifelse(x %in% c(' ', 'NA', 'n/a', 'n/a.') | is.na(x), NA, x) }
