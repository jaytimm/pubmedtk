
####################
util.get_affiliations <- function (x) {
  
  ### parse and xml -- 
  records <- util.fetch_records(x)
  
  #### -- 
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
  
  ## if(clean){
  
  return(x0)
}



#### clean -- 
util.clean_affiliations <- function(x){
  
  x[, Affiliation := sub('^.*?([A-Z])','\\1', Affiliation)]
  x[, Affiliation := trimws(Affiliation)]
  x[, Affiliation := gsub('(^.*[[:punct:] ])(.*@.*$)', '\\1', Affiliation)]
  x[, Affiliation := gsub('(^.*[[:punct:] ])(.*@.*$)', '\\1', Affiliation)]
  x[, Affiliation := gsub('electronic address.*$|email.*$', '', Affiliation, ignore.case = T)]
  x[, Affiliation := ifelse(nchar(Affiliation) < 10, NA, Affiliation)]
  return(x)
}
