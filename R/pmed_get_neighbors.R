#' Measure cosine similarity.
#'
#' @name pmed_get_neighbors
#' @param x A matrix
#' @param target A character, or numeric vector.
#' @param n Integer
#' @return A data frame.
#'
#' @export
#' @rdname pmed_get_neighbors
#'
pmed_get_neighbors <- function(x,
                               target,
                               n = 10) {
  
  if(is.character(target)){
    t0 <- x[target, , drop = FALSE]} else{
      ## a vector -- in theory -- 
      t0 <- target}
  
  cos_sim <- text2vec::sim2(x = x,
                            y = t0,
                            method = "cosine",
                            norm = "l2")
  
  x1 <- head(sort(cos_sim[,1], decreasing = TRUE), n)
  
  data.frame(rank = 1:n,
             term1 = rownames(t0),
             term2 = names(x1),
             value = round(x1, 3),
             row.names = NULL)
}