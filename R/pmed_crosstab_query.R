#' Cross-tab search results for multiple calls to pmtk_search_pubmed().
#'
#' @name pmed_crosstab_query
#' @param x A df or list of dfs returned from pmtk_search_pubmed()
#' @param remove_duplicates Boolean
#' @return A data frame
#'
#' @export
#' @rdname pmed_crosstab_query
#'

## could rebuild as build-network -- !! --

pmed_crosstab_query <- function(x,
                                remove_duplicates = T
                                ){

  if(any(class(x) == 'list')) {
    x <- data.table::rbindlist(x)
    }

  x$value = 1
  pmatrix <- tidytext::cast_sparse(data = x,
                                   row = pmid,
                                   column = search_term,
                                   value = value)

  pmatrix0 <- pmatrix > 0

  v0 <- Matrix::t(pmatrix0) %*% pmatrix0

  v1 <- cbind('search' = unique(x$search_term),
              data.table::data.table(as.matrix(v0)))

  v2 <- data.table::melt.data.table(v1, 'search', c(2:ncol(v1)))
  colnames(v2) <- c('term1', 'term2', 'n1n2')

  v3 <- subset(v2, term1 == term2)
  v4 <- merge(v2, data.frame(term1 = v3$term1, n1 = v3$n),
              by = 'term1')

  v5 <- merge(v4, data.frame(term2 = v3$term1, n2 = v3$n),
              by = "term2")

  v5$term2 <- as.character(v5$term2)
  v5 <- v5[order(v5$term1),]
  v5 <- subset(v5, term1 != term2)
  v5 <- v5[, c('term1',
               'term2',
               'n1',
               'n2',
               'n1n2')]

  if(remove_duplicates){
    v5$dups <- mapply(duples, v5$term1, v5$term2)
    v5 <- v5[!duplicated(v5[,c('dups')]),]
    v5 <- v5[, -c('dups')]
  }

  ## for some numbers for full PubMed citations:
  ## https://www.nlm.nih.gov/bsd/licensee/2021_stats/2021_LO.html

  # if(include_pmi){
  #   ## pmi_denom <- 2.1e7 # citations with text abstract --
  #   v5$pmi <- round(log2(((v5$n1n2 + 0.01)/pmi_denom) /
  #                          ((v5$n1/pmi_denom) * (v5$n2/pmi_denom))), 2)
  # }

  v5
}


duples <- function(x, y){
  paste(sort(c(x, y)), collapse = '_', sep = '_')
}
