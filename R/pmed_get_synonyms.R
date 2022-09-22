#' Get synonyms from MeSH.
#'
#' @name pmed_get_synonyms
#' @param x A character vector
#' @param mesh A data frame
#' @return A character vector
#'
#' @export
#' @rdname pmed_get_synonyms
#'
pmed_get_synonyms <- function(x, mesh = pmed_tbl_mesh){

  syns <- mesh[, if(any(TermName %in% x)) .SD,
               by = list(DescriptorName)]

  list_syn <- unique(c(x, syns$TermName))
  list_syn <- subset(list_syn, !grepl(',', list_syn))

  if(length(list_syn) < 2){return(x)}
  if(length(list_syn) > 1){

    dist_mat <- stringdist::stringdistmatrix(list_syn, list_syn, method = "lv")
    dtm <- as(dist_mat, 'dgCMatrix')
    m <- Matrix::summary(dtm)

    comps <- data.table::data.table(term1 = as.character(list_syn[m$i]),
                                    term2 = as.character(list_syn[m$j]),
                                    lv_dist = m$x)

    comps$dups <- mapply(duples, comps$term1, comps$term2)
    comps <- comps[!duplicated(comps[,c('dups')]),]
    comps[, paste0("term", 1:2) := data.table::tstrsplit(dups, "_")]

    k1 <- subset(comps, lv_dist < 3)
    k1 <- subset(k1, !term1 %in% term2)
    k2 <- subset(comps, lv_dist > 2)
    k3 <- subset(k2, !term1 %in% c(k1$term1, k1$term2)&
                   !term2 %in% c(k1$term1, k1$term2))

    unique(c(x, k1$term1, k3$term1, k3$term2))
  }
}
