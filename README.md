<!-- badges: start -->

[![Travis build
status](https://app.travis-ci.com/jaytimm/pubmedtk.svg?branch=main)](https://app.travis-ci.com/github/jaytimm/pubmedtk)
[![R-CMD-check](https://github.com/jaytimm/pubmedtk/workflows/R-CMD-check/badge.svg)](https://github.com/jaytimm/pubmedtk/actions)
<!-- badges: end -->

# pubmedtk

The package provides a single interface for accessing a range of PubMed
endpoints, including [PubMed](https://pubmed.ncbi.nlm.nih.gov/) abstract
records, [iCite](https://icite.od.nih.gov/) bibliometric data,
[PubTator](https://www.ncbi.nlm.nih.gov/research/pubtator/) named entity
annotations, and full-text entries from [PubMed
Central](https://www.ncbi.nlm.nih.gov/pmc/) (PMC).

This unified interface simplifies the data retrieval process for
end-users, who can interact with multiple PubMed services through a
single R function rather than having to individually handle the
different APIs and data formats of each service.

The package also includes MeSH ontology resources as simple data frames,
including Descriptor Terms, Descriptor Tree Structures, Supplementary
Concept Terms, and Pharmacological Actions; it also features
descriptor-level word embeddings [(Noh & Kavuluru
2021)](https://www.sciencedirect.com/science/article/pii/S1532046421001969).
Via the [mesh-extensions](https://github.com/jaytimm/mesh-extensions)
Git project.

## Installation

You can download the development version from GitHub with:

``` r
devtools::install_github("jaytimm/pubmedtk")
```

## PubMed search

The package has two basic functions: `search_pubmed` and `get_records`.
The former fetches PMIDs from the PubMed API based on user search; the
latter scrapes PMID records from a user-specified PubMed endpoint –
`pubmed_abstracts`, `pubmed_affiliations`, `pubtations`, `icites`, or
`pmc_fulltext`.

Search syntax is the same as that implemented in standard [PubMed
search](https://pubmed.ncbi.nlm.nih.gov/advanced/).

``` r
yrs <- 2010:2023
pubmed_query <- paste0('("political ideology"[TiAb]) AND (', 
                       yrs, ':', yrs,  
                       '[pdat])')
## [MeSH Terms]

pmids <- lapply(pubmed_query, pubmedtk::search_pubmed)
pmids <- pmids |> unlist() |> unique() |> sort()
```

## Get record-level data

``` r
recs_pubmed <- pmids |> 
  pubmedtk::get_records(endpoint = 'pubmed_abstracts') 

recs_affs <- pmids |> 
  pubmedtk::get_records(endpoint = 'pubmed_affiliations')

recs_icites <- pmids |> 
  pubmedtk::get_records(endpoint = 'icites')

recs_pubtations <- pmids |> 
  pubmedtk::get_records(endpoint = 'pubtations')
```

``` r
pmclist <- pubmedtk::data_pmc_list(force_install = F)
pmc_pmids <- pmclist[PMID %in% pmids]

recs_pmc <- pmc_pmids$fpath |> 
  pubmedtk::get_records(endpoint = 'pmc_fulltext')
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
| citations_per_year          | 0.5555556                    |
| expected_citations_per_year | 2.113739                     |
| field_citation_rate         | 3.840726                     |
| provisional                 | No                           |
| x_coord                     | 0                            |
| y_coord                     | 1                            |
| cited_by_clin               |                              |
| doi                         | 10.1371/journal.pone.0095431 |
| last_modified               | 11/25/2023, 16:54:50         |
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

## MeSH extensions

### Thesauri

``` r
mesh <- pubmedtk::data_mesh_thesuarus() 
mesh |> head() |> knitr::kable()
```

| DescriptorUI | DescriptorName | ConceptUI | TermUI     | TermName                                                                                                                                                                                               | ConceptPreferredTermYN | IsPermutedTermYN | LexicalTag | RecordPreferredTermYN |
|:---|:---|:--|:---|:---------------------------------------|:-----|:----|:---|:-----|
| D000001      | Calcimycin     | M0000001  | T000002    | Calcimycin                                                                                                                                                                                             | Y                      | N                | NON        | Y                     |
| D000001      | Calcimycin     | M0000001  | T001124965 | 4-Benzoxazolecarboxylic acid, 5-(methylamino)-2-((3,9,11-trimethyl-8-(1-methyl-2-oxo-2-(1H-pyrrol-2-yl)ethyl)-1,7-dioxaspiro(5.5)undec-2-yl)methyl)-, (6S-(6alpha(2S*,3S*),8beta(R\*),9beta,11alpha))- | N                      | N                | NON        | N                     |
| D000001      | Calcimycin     | M0353609  | T000001    | A-23187                                                                                                                                                                                                | Y                      | N                | LAB        | N                     |
| D000001      | Calcimycin     | M0353609  | T000001    | A 23187                                                                                                                                                                                                | N                      | Y                | LAB        | N                     |
| D000001      | Calcimycin     | M0353609  | T000004    | A23187                                                                                                                                                                                                 | N                      | N                | LAB        | N                     |
| D000001      | Calcimycin     | M0353609  | T000003    | Antibiotic A23187                                                                                                                                                                                      | N                      | N                | NON        | N                     |

### Trees

``` r
pubmedtk::data_mesh_trees() |> head() |> knitr::kable()
```

| DescriptorUI | DescriptorName | tree_location           | code | cats                                  | mesh1                                     | mesh2                                   | tree1 | tree2   |
|:-----|:-----|:--------|:--|:-------------|:--------------|:-------------|:--|:---|
| D000001      | Calcimycin     | D03.633.100.221.173     | D    | Chemicals and Drugs                   | Heterocyclic Compounds                    | Heterocyclic Compounds, Fused-Ring      | D03   | D03.633 |
| D000002      | Temefos        | D02.705.400.625.800     | D    | Chemicals and Drugs                   | Organic Chemicals                         | Organophosphorus Compounds              | D02   | D02.705 |
| D000002      | Temefos        | D02.705.539.345.800     | D    | Chemicals and Drugs                   | Organic Chemicals                         | Organophosphorus Compounds              | D02   | D02.705 |
| D000002      | Temefos        | D02.886.300.692.800     | D    | Chemicals and Drugs                   | Organic Chemicals                         | Sulfur Compounds                        | D02   | D02.886 |
| D000003      | Abattoirs      | J01.576.423.200.700.100 | J    | Technology, Industry, and Agriculture | Technology, Industry, and Agriculture     | Industry                                | J01   | J01.576 |
| D000003      | Abattoirs      | J03.540.020             | J    | Technology, Industry, and Agriculture | Non-Medical Public and Private Facilities | Manufacturing and Industrial Facilities | J03   | J03.540 |

### Pharmacological Actions

``` r
pubmedtk::data_pharm_action() |> 
  filter(DescriptorName == 'Rituximab') |>
  knitr::kable()
```

| DescriptorUI | DescriptorName | PharmActionUI | PharmActionName                      |
|:------------|:-------------|:------------|:--------------------------------|
| D000069283   | Rituximab      | D000074322    | Antineoplastic Agents, Immunological |
| D000069283   | Rituximab      | D007155       | Immunologic Factors                  |
| D000069283   | Rituximab      | D018501       | Antirheumatic Agents                 |

### Embeddings

> Noh, J., & Kavuluru, R. (2021). Improved biomedical word embeddings in
> the transformer era. Journal of Biomedical Informatics, 120, 103867.

<https://www.sciencedirect.com/science/article/pii/S1532046421001969>

<https://zenodo.org/record/4383195>

Includes embeddings for the ~30K MeSH descriptors, as well as ~15K
embeddings for Supplementary Concept Records (SCR).
