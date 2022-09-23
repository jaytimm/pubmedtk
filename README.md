<!-- badges: start -->

[![Travis build
status](https://app.travis-ci.com/jaytimm/pubmedr.svg?branch=main)](https://app.travis-ci.com/github/jaytimm/pubmedr)
[![R-CMD-check](https://github.com/jaytimm/pubmedr/workflows/R-CMD-check/badge.svg)](https://github.com/jaytimm/pubmedr/actions)
<!-- badges: end -->

# pubmedr

An R package for querying the PubMed database & parsing retrieved
records.

## Installation

You can download the development version from GitHub with:

``` r
devtools::install_github("jaytimm/pubmedr")
```

## Usage

## PubMed search

The `pmed_search_pubmed()` function is meant for record-matching
searches typically performed using the [PubMed online
interface](https://pubmed.ncbi.nlm.nih.gov/). The `search_term`
parameter specifies the query term; the `fields` parameter can be used
to specify which fields to query.

``` r
s0 <- pubmedr::pmed_search_pubmed(search_term = 'medical marijuana', 
                                  fields = c('TIAB','MH'))
```

    ## [1] "medical marijuana[TIAB] OR medical marijuana[MH]: 2653 records"

> Sample output:

``` r
head(s0)
```

    ##          search_term     pmid
    ## 1: medical marijuana 36122967
    ## 2: medical marijuana 36122285
    ## 3: medical marijuana 36076191
    ## 4: medical marijuana 36064621
    ## 5: medical marijuana 36055728
    ## 6: medical marijuana 36040775

## Multiple search terms

``` r
ps <- pubmedr::pmed_search_pubmed(
  search_term = c('marijuana chronic pain',
                  'marijuana legalization',
                  'marijuana policy',
                  'medical marijuana'),
  fields = c('TIAB','MH'))
```

    ## [1] "marijuana chronic pain[TIAB] OR marijuana chronic pain[MH]: 821 records"
    ## [1] "marijuana legalization[TIAB] OR marijuana legalization[MH]: 242 records"
    ## [1] "marijuana policy[TIAB] OR marijuana policy[MH]: 692 records"
    ## [1] "medical marijuana[TIAB] OR medical marijuana[MH]: 2653 records"

The `pmed_crosstab_query` can be used to build a cross-tab of PubMed
search results for multiple search terms.

``` r
ps0 <- pubmedr::pmed_crosstab_query(x = ps) 

ps0 %>% knitr::kable()
```

| term1                  | term2                  |  n1 |   n2 | n1n2 |
|:-----------------------|:-----------------------|----:|-----:|-----:|
| marijuana chronic pain | marijuana legalization | 821 |  242 |    4 |
| marijuana chronic pain | marijuana policy       | 821 |  692 |    7 |
| marijuana chronic pain | medical marijuana      | 821 | 2653 |  339 |
| marijuana legalization | marijuana policy       | 242 |  692 |   33 |
| marijuana legalization | medical marijuana      | 242 | 2653 |   91 |
| marijuana policy       | medical marijuana      | 692 | 2653 |  201 |

``` r
UpSetR::upset(UpSetR::fromList(split(ps$pmid,
                                     ps$search_term 
                                     )), 
              nsets = 4, order.by = "freq")
```

![](README_files/figure-markdown_github/unnamed-chunk-7-1.png)

## Retrieve and parse abstract data

For quicker abstract retrieval, be sure to get an [API
key](https://support.nlm.nih.gov/knowledgebase/article/KA-03521/en-us).

``` r
sen_df <- pubmedr::pmed_get_records2(pmids = unique(s0$pmid), 
                                      with_annotations = T,
                                      cores = 5, 
                                      ncbi_key = key) 
```

> Sample record from output:

``` r
sen_df <- data.table::rbindlist(sen_df)

n <- 10
list(pmid = sen_df$pmid[n],
     year = sen_df$year[n],
     journal = sen_df$journal[n],
     articletitle = strwrap(sen_df$articletitle[n], width = 60),
     abstract = strwrap(sen_df$abstract[n], width = 60)[1:10])
```

    ## $pmid
    ## [1] "35258504"
    ## 
    ## $year
    ## [1] "2022"
    ## 
    ## $journal
    ## [1] "Journal of clinical gastroenterology"
    ## 
    ## $articletitle
    ## [1] "The Effectiveness of Common Cannabis Products for Treatment"
    ## [2] "of Nausea."                                                 
    ## 
    ## $abstract
    ##  [1] "We measure for the first time how a wide range of cannabis" 
    ##  [2] "products affect nausea intensity in actual time. Even"      
    ##  [3] "though the Cannabis plant has been used to treat nausea for"
    ##  [4] "millennia, few studies have measured real-time effects of"  
    ##  [5] "common and commercially available cannabis-based products." 
    ##  [6] "Using the Releaf App, 886 people completed 2220 cannabis"   
    ##  [7] "self-administration sessions intended to treat nausea"      
    ##  [8] "between June 6, 2016 and July 8, 2019. They recorded the"   
    ##  [9] "characteristics of self-administered cannabis products and" 
    ## [10] "baseline symptom intensity levels before tracking real-time"

## Annotations

> Annotations are included as a list-column, and can be easily
> extracted:

``` r
annotations <- data.table::rbindlist(sen_df$annotations)
```

``` r
annotations |>
  filter(!is.na(FORM)) |>
  slice(1:10) |>
  knitr::kable()
```

| ID       | TYPE      | FORM                        |
|:---------|:----------|:----------------------------|
| 36122967 | MeSH      | Adolescent                  |
| 36122967 | MeSH      | Cannabis                    |
| 36122967 | MeSH      | Child                       |
| 36122967 | MeSH      | Ethanol                     |
| 36122967 | MeSH      | Humans                      |
| 36122967 | MeSH      | Marijuana Smoking           |
| 36122967 | MeSH      | Marijuana Use               |
| 36122967 | MeSH      | Medical Marijuana           |
| 36122967 | MeSH      | Substance-Related Disorders |
| 36122967 | Chemistry | Medical Marijuana           |

## Citation data

The `pmed_get_icites` function can be used to obtain citation data per
PMID using NIH’s Open Citation Collection and
[iCite](https://icite.od.nih.gov/).

> Hutchins BI, Baker KL, Davis MT, Diwersy MA, Haque E, Harriman RM, et
> al. (2019) The NIH Open Citation Collection: A public access, broad
> coverage resource. PLoS Biol 17(10): e3000385.
> <https://doi.org/10.1371/journal.pbio.3000385>

The iCite API returns a host of descriptive/derived citation details per
record.

``` r
citations <- pubmedr::pmed_get_icites(pmids = ps$pmid, 
                                      cores = 6,
                                      ncbi_key = key)

citations %>% select(-citation_net) %>%
  slice(4) %>%
  t() %>% data.frame() %>%
  knitr::kable()
```

|                             | .                                                                                                                                                                                                                                             |
|:--------|:--------------------------------------------------------------|
| pmid                        | 33998895                                                                                                                                                                                                                                      |
| year                        | 2022                                                                                                                                                                                                                                          |
| title                       | A Multicriteria Decision Analysis Comparing Pharmacotherapy for Chronic Neuropathic Pain, Including Cannabinoids and Cannabis-Based Medical Products.                                                                                         |
| authors                     | David J Nutt, Lawrence D Phillips, Michael P Barnes, Brigitta Brander, Helen Valerie Curran, Alan Fayaz, David P Finn, Tina Horsted, Julie Moltke, Chloe Sakal, Haggai Sharon, Saoirse E O’Sullivan, Tim Williams, Gregor Zorn, Anne K Schlag |
| journal                     | Cannabis Cannabinoid Res                                                                                                                                                                                                                      |
| is_research_article         | Yes                                                                                                                                                                                                                                           |
| relative_citation_ratio     | NA                                                                                                                                                                                                                                            |
| nih_percentile              | NA                                                                                                                                                                                                                                            |
| human                       | 0.67                                                                                                                                                                                                                                          |
| animal                      | 0.33                                                                                                                                                                                                                                          |
| molecular_cellular          | 0                                                                                                                                                                                                                                             |
| apt                         | 0.75                                                                                                                                                                                                                                          |
| is_clinical                 | No                                                                                                                                                                                                                                            |
| citation_count              | 7                                                                                                                                                                                                                                             |
| citations_per_year          | 7                                                                                                                                                                                                                                             |
| expected_citations_per_year | 1.161836                                                                                                                                                                                                                                      |
| field_citation_rate         | 3.738451                                                                                                                                                                                                                                      |
| provisional                 | No                                                                                                                                                                                                                                            |
| x_coord                     | 0.2886751                                                                                                                                                                                                                                     |
| y_coord                     | 0.5                                                                                                                                                                                                                                           |
| cited_by_clin               | NA                                                                                                                                                                                                                                            |
| doi                         | 10.1089/can.2020.0129                                                                                                                                                                                                                         |
| ref_count                   | 35                                                                                                                                                                                                                                            |

> Referenced and cited-by PMIDs are returned by the function as a
> column-list of network edges.

``` r
citations$citation_net[[4]] |> head()
```

    ##        from       to
    ## 1: 33998895 31356363
    ## 2: 33998895 27025332
    ## 3: 33998895 16095934
    ## 4: 33998895 20805210
    ## 5: 33998895 25635955
    ## 6: 33998895 31529092

## Affiliations

The `pmed_get_affiliations` function extracts author and author
affiliation information from PubMed records.

``` r
afffs <- pubmedr::pmed_get_affiliations(pmids = s0$pmid)

afffs |>
  bind_rows() |>
  slice(1:10) |>
  knitr::kable()
```

| pmid     | Author                        | Affiliation                                                                                                                                                                                                                                                           |
|:---|:-------|:------------------------------------------------------------|
| 36122967 | Levy, Sharon                  | Adolescent Substance Use and Addiction Program, Boston Children’s Hospital, Boston, Massachusetts; Division of Developmental Medicine, Boston Children’s Hospital, Boston, Massachusetts; Department of Pediatrics, Harvard Medical School, Boston, Massachusetts.    |
| 36122967 | Wisk, Lauren E                | Division of General Internal Medicine & Health Services Research, David Geffen School of Medicine at the University of California, Los Angeles, California.                                                                                                           |
| 36122967 | Minegishi, Machiko            | Division of Adolescent/Young Adult Medicine, Boston Children’s Hospital, Boston, Massachusetts.                                                                                                                                                                       |
| 36122967 | Lunstead, Julie               | Adolescent Substance Use and Addiction Program, Boston Children’s Hospital, Boston, Massachusetts; Division of Developmental Medicine, Boston Children’s Hospital, Boston, Massachusetts.                                                                             |
| 36122967 | Weitzman, Elissa R            | Department of Pediatrics, Harvard Medical School, Boston, Massachusetts; Division of Adolescent/Young Adult Medicine, Boston Children’s Hospital, Boston, Massachusetts; Computational Health Informatics Program, Boston Children’s Hospital, Boston, Massachusetts. |
| 36122285 | Gómez-García, Diego Mauricio  | Departamento de Medicina Familiar, Escuela de Medicina, Universidad del Valle, Cali, Colombia. diego.mauricio.                                                                                                                                                        |
| 36122285 | García-Perdomo, Herney Andrés | Unidad de Urología/Urooncología, Grupo de Investigación UROGIV, Departamento de Cirugía, Escuela de Medicina, Universidad del Valle, Cali, Colombia. herney.                                                                                                          |
| 36076191 | Hachem, Yasmina               | Medical Cannabis Program in Oncology, Cedars Cancer Center, McGill University Health Centre, 1001 boulevard Decarie, Montreal, QC, H3A 3J1, Canada.                                                                                                                   |
| 36076191 | Abdallah, Sara J              | Division of Infectious Diseases, Department of Medicine, The Ottawa Hospital and Ottawa Hospital Research Institute, 501 Smyth Road, Ottawa, ON, K1H 8L6, Canada.                                                                                                     |
| 36076191 | Rueda, Sergio                 | Centre for Addiction and Mental Health, Institute for Mental Health Policy Research, 33 Ursula Franklin St, Toronto, ON, M5S 2S1, Canada.                                                                                                                             |
