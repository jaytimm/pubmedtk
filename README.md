[![R build
status](https://github.com/jaytimm/pubmedtk/workflows/R-CMD-check/badge.svg)](https://github.com/jaytimm/pubmedtk/actions)

# pubmedtk

The package provides a single interface for accessing a range of
NLM/PubMed databases, including
[PubMed](https://pubmed.ncbi.nlm.nih.gov/) abstract records,
[iCite](https://icite.od.nih.gov/) bibliometric data,
[PubTator](https://www.ncbi.nlm.nih.gov/research/pubtator/) named entity
annotations, and full-text entries from [PubMed
Central](https://www.ncbi.nlm.nih.gov/pmc/) (PMC). This unified
interface simplifies the data retrieval process, allowing users to
interact with multiple PubMed services/APIs/output formats through a
single R function.

The package also includes MeSH ontology resources as simple data frames,
including Descriptor Terms, Descriptor Tree Structures, Supplementary
Concept Terms, and Pharmacological Actions; it also includes
descriptor-level word embeddings [(Noh & Kavuluru
2021)](https://www.sciencedirect.com/science/article/pii/S1532046421001969).
Via the [mesh-resources](https://github.com/jaytimm/mesh-resources)
library.

## Installation

You can download the development version from GitHub with:

``` r
devtools::install_github("jaytimm/pubmedtk")
```

## Usage

## PubMed search

The package has two basic functions: `search_pubmed` and `get_records`.
The former fetches PMIDs from the PubMed API based on user search; the
latter scrapes PMID records from a user-specified PubMed endpoint –
`pubmed_abstracts`, `pubmed_affiliations`, `pubtations`, `icites`, or
`pmc_fulltext`.

Search syntax is the same as that implemented in standard [PubMed
search](https://pubmed.ncbi.nlm.nih.gov/advanced/).

``` r
pmids <- pubmedtk::search_pubmed('("political ideology"[TiAb])',
                                 use_pub_years = F)

# pmids <- pubmedtk::search_pubmed('immunity', 
#                                  use_pub_years = T,
#                                  start_year = 2022,
#                                  end_year = 2024) 
```

## Get record-level data

``` r
pubmed <- pmids |> 
  pubmedtk::get_records(endpoint = 'pubmed_abstracts', 
                        cores = 3, 
                        sleep = 1) 

affiliationss <- pmids |> 
  pubmedtk::get_records(endpoint = 'pubmed_affiliations', 
                        cores = 3, 
                        sleep = 0.5)

icites <- pmids |> 
  pubmedtk::get_records(endpoint = 'icites',
                        cores = 4, 
                        sleep = 0.25)

pubtations <- pmids |> 
  pubmedtk::get_records(endpoint = 'pubtations')
```

> When the endpoint is PMC, the \`get_records() function takes a vector
> of filepaths (from the PMC Open Access list) instead of PMIDs.

``` r
pmclist <- pubmedtk::data_pmc_list(force_install = F)
pmc_pmids <- pmclist[PMID %in% pmids]

pmc_fulltext <- pmc_pmids$fpath[1:20] |> 
  pubmedtk::get_records(endpoint = 'pmc_fulltext', cores = 2)
```
