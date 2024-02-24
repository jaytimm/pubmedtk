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
recs_pubmed <- pmids |> 
  pubmedtk::get_records(endpoint = 'pubmed_abstracts', 
                        cores = 5, 
                        sleep = 1) 

recs_affs <- pmids |> 
  pubmedtk::get_records(endpoint = 'pubmed_affiliations', 
                        cores = 3, 
                        sleep = 0.5)

recs_icites <- pmids |> 
  pubmedtk::get_records(endpoint = 'icites',
                        cores = 1, 
                        sleep = 0.25)

recs_pubtations <- pmids |> 
  pubmedtk::get_records(endpoint = 'pubtations')
```

> When the endpoint is PMC, the \`get_records() function takes a vector
> of filepaths (from the PMC Open Access list) instead of PMIDs.

``` r
pmclist <- pubmedtk::data_pmc_list(force_install = F)
pmc_pmids <- pmclist[PMID %in% pmids]

recs_pmc <- pmc_pmids$fpath[1:20] |> 
  pubmedtk::get_records(endpoint = 'pmc_fulltext', cores = 2)
```

### `pubmed_abstracts`

``` r
pmid_eg <- 24781819
```

``` r
recs_pubmed |> 
  select(-annotations) |>
  filter(pmid == pmid_eg) |>
  mutate(abstract = stringr::str_sub(abstract, 1, 150) |>
                     paste0("...")) |>
  knitr::kable()
```

| pmid     | year | journal  | articletitle                                                                                                  | abstract                                                                                                                                                |
|:---|:--|:---|:--------------------------|:------------------------------------|
| 24781819 | 2014 | PloS one | Perceptions of others’ political affiliation are moderated by individual perceivers’ own political attitudes. | Previous research has shown that perceivers can accurately extract information about perceptually ambiguous group memberships from facial information … |

``` r
recs_pubmed |> 
  #select(-annotations) |>
  filter(pmid == pmid_eg) |>
  pull(annotations) |>
  bind_cols() |>
  knitr::kable()
```

| pmid     | type      | form              |
|:---------|:----------|:------------------|
| 24781819 | MeSH      | Attitude          |
| 24781819 | MeSH      | Humans            |
| 24781819 | MeSH      | Politics          |
| 24781819 | MeSH      | Social Perception |
| 24781819 | MeSH      | Stereotyping      |
| 24781819 | Chemistry | NA                |
| 24781819 | Keyword   | NA                |

### `pubmed_affiliates`

``` r
recs_affs |> 
  filter(pmid == pmid_eg) |>
  knitr::kable()
```

| pmid     | Author            | Affiliation                                                                |
|:-------|:-------------|:---------------------------------------------------|
| 24781819 | Wilson, John Paul | Department of Psychology, University of Toronto, Toronto, Ontario, Canada. |
| 24781819 | Rule, Nicholas O  | Department of Psychology, University of Toronto, Toronto, Ontario, Canada. |

### `icites`

``` r
citations <- recs_icites |> 
  filter(pmid == pmid_eg)

c0 <- citations |> select(-citation_net) 
setNames(data.frame(t(c0[,-1])), c0[,1]) |> knitr::kable()
```

|                             | 24781819                     |
|:----------------------------|:-----------------------------|
| is_research_article         | Yes                          |
| relative_citation_ratio     | 0.26                         |
| nih_percentile              | 13.6                         |
| human                       | 1                            |
| animal                      | 0                            |
| molecular_cellular          | 0                            |
| apt                         | 0.05                         |
| is_clinical                 | No                           |
| citation_count              | 5                            |
| citations_per_year          | 0.5                          |
| expected_citations_per_year | 1.905748                     |
| field_citation_rate         | 3.839488                     |
| provisional                 | No                           |
| x_coord                     | 0                            |
| y_coord                     | 1                            |
| cited_by_clin               |                              |
| doi                         | 10.1371/journal.pone.0095431 |
| last_modified               | 01/28/2024, 12:30:27         |
| ref_count                   | 16                           |

``` r
citations$citation_net[[1]] |> head() |> knitr::kable()
```

| from     | to       |
|:---------|:---------|
| 24781819 | 23070218 |
| 24781819 | 15659350 |
| 24781819 | 13174286 |
| 24781819 | 20424067 |
| 24781819 | 20090906 |
| 24781819 | 19186926 |

### `pubtations`

``` r
recs_pubtations |> 
  filter(pmid == pmid_eg) |>
  knitr::kable()
```

| pmid     | tiab     | id  | entity       | identifier | type    | start |  end |
|:---------|:---------|:----|:-------------|:-----------|:--------|------:|-----:|
| 24781819 | title    | NA  | NA           | NA         | NA      |    NA |   NA |
| 24781819 | abstract | 3   | people       | 9606       | Species |   280 |  286 |
| 24781819 | abstract | 4   | participants | 9606       | Species |   732 |  744 |
| 24781819 | abstract | 5   | participants | 9606       | Species |  1168 | 1180 |

### `pmc_fulltext`

``` r
samp <- recs_pmc |> filter(pmid == pmid_eg)

lapply(samp$text, function(x){strwrap(x, width = 60)[1:3]})
```

    ## [[1]]
    ## [1] "Introduction People can be quite accurate at extracting a"
    ## [2] "number of seemingly concealable social identities from"   
    ## [3] "facial information alone. Unlike categorizations based on"
    ## 
    ## [[2]]
    ## [1] "Study 1a The present study aimed to expand on previous work"
    ## [2] "showing that individuals are able to accurately perceive"   
    ## [3] "others' political affiliation [3], [4], [5], [6], [7], [8]."
    ## 
    ## [[3]]
    ## [1] "Study 1b Study 1b was designed to replicate Study 1a while" 
    ## [2] "addressing a few possible shortcomings. First, the"         
    ## [3] "relationship between conservatism and response bias did not"
    ## 
    ## [[4]]
    ## [1] "Study 2The results of Studies 1a and 1b showed that"        
    ## [2] "perceivers' method of categorizing targets as Democrats and"
    ## [3] "Republicans was influenced by their personal political"     
    ## 
    ## [[5]]
    ## [1] "General Discussion Perceptions of political group"     
    ## [2] "membership appear to be influenced by perceivers' own" 
    ## [3] "political leanings. First, we replicated past research"
