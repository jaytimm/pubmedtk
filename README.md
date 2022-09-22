<!-- badges: start -->

[![Travis build
status](https://app.travis-ci.com/jaytimm/pubmedr.svg?branch=main)](https://app.travis-ci.com/github/jaytimm/pubmedr)
[![R-CMD-check](https://github.com/jaytimm/pubmedr/workflows/R-CMD-check/badge.svg)](https://github.com/jaytimm/pubmedr/actions)
<!-- badges: end -->

# pubmedr

An R package for querying the PubMed database & parsing retrieved
records. Toolkit facilitates batch API requests & the creation of custom
corpora for NLP.

## Installation

You can download the development version from GitHub with:

``` r
devtools::install_github("jaytimm/pubmedr")
```

## Usage

## PubMed search

The `pmtk_search_pubmed()` function is meant for record-matching
searches typically performed using the [PubMed online
interface](https://pubmed.ncbi.nlm.nih.gov/). The `search_term`
parameter specifies the query term; the `fields` parameter can be used
to specify which fields to query.

``` r
s0 <- pubmedr::pmed_search_pubmed(search_term = 'medical marijuana', 
                                  fields = c('TIAB','MH'))
```

    ## [1] "medical marijuana[TIAB] OR medical marijuana[MH]: 2652 records"

> Sample output:

``` r
head(s0)
```

    ##          search_term     pmid
    ## 1: medical marijuana 36122967
    ## 2: medical marijuana 36076191
    ## 3: medical marijuana 36064621
    ## 4: medical marijuana 36055728
    ## 5: medical marijuana 36040775
    ## 6: medical marijuana 36036345

## Multiple search terms

``` r
ps <- pubmedr::pmed_search_pubmed(
  search_term = c('political ideology',
                  'marijuana legalization',
                  'political theory',
                  'medical marijuana'),
  fields = c('TIAB','MH'))
```

    ## [1] "political ideology[TIAB] OR political ideology[MH]: 599 records"
    ## [1] "marijuana legalization[TIAB] OR marijuana legalization[MH]: 242 records"
    ## [1] "political theory[TIAB] OR political theory[MH]: 124 records"
    ## [1] "medical marijuana[TIAB] OR medical marijuana[MH]: 2652 records"

The `pmtk_crosstab_query` can be used to build a cross-tab of PubMed
search results for multiple search terms.

``` r
ps0 <- pubmedr::pmed_crosstab_query(x = ps) 

ps0 %>% knitr::kable()
```

| term1                  | term2              |   n1 |   n2 | n1n2 |
|:-----------------------|:-------------------|-----:|-----:|-----:|
| marijuana legalization | medical marijuana  |  242 | 2652 |   91 |
| marijuana legalization | political ideology |  242 |  599 |    1 |
| marijuana legalization | political theory   |  242 |  124 |    0 |
| medical marijuana      | political ideology | 2652 |  599 |    2 |
| medical marijuana      | political theory   | 2652 |  124 |    1 |
| political ideology     | political theory   |  599 |  124 |    2 |

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
    ## [1] "35254218"
    ## 
    ## $year
    ## [1] "2022"
    ## 
    ## $journal
    ## [1] "Substance abuse"
    ## 
    ## $articletitle
    ## [1] "Clinical documentation of patient-reported medical cannabis"
    ## [2] "use in primary care: Toward scalable extraction using"      
    ## [3] "natural language processing methods."                       
    ## 
    ## $abstract
    ##  [1] "Background: Most states have legalized medical cannabis,"  
    ##  [2] "yet little is known about how medical cannabis use is"     
    ##  [3] "documented in patients' electronic health records (EHRs)." 
    ##  [4] "We used natural language processing (NLP) to calculate the"
    ##  [5] "prevalence of clinician-documented medical cannabis use"   
    ##  [6] "among adults in an integrated health system in Washington" 
    ##  [7] "State where medical and recreational use are legal."       
    ##  [8] "Methods: We analyzed EHRs of patients ≥18 years old"       
    ##  [9] "screened for past-year cannabis use (November 1,"          
    ## [10] "2017-October 31, 2018), to identify clinician-documented"

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

| ID       | TYPE    | FORM                         |
|:---------|:--------|:-----------------------------|
| 36122967 | Keyword | Adolescent                   |
| 36122967 | Keyword | Alcohol                      |
| 36122967 | Keyword | Chronic medical conditions   |
| 36122967 | Keyword | Marijuana                    |
| 36122967 | Keyword | Screening                    |
| 36122967 | Keyword | Subspecialty care            |
| 36122967 | Keyword | Substance use                |
| 36076191 | MeSH    | Attitude of Health Personnel |
| 36076191 | MeSH    | COVID-19                     |
| 36076191 | MeSH    | Canada                       |

## Citation data

The `pmtk_get_icites` function can be used to obtain citation data per
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

|                             | .                                                                                                         |
|:---------------|:-------------------------------------------------------|
| pmid                        | 33143508                                                                                                  |
| year                        | 2021                                                                                                      |
| title                       | A First Step, a Second Chance: Public Support for Restoring Rights of Individuals with Prior Convictions. |
| authors                     | Christina Mancini, Robyn McDougle, Brittany Keegan                                                        |
| journal                     | Int J Offender Ther Comp Criminol                                                                         |
| is_research_article         | Yes                                                                                                       |
| relative_citation_ratio     | NA                                                                                                        |
| nih_percentile              | NA                                                                                                        |
| human                       | 1                                                                                                         |
| animal                      | 0                                                                                                         |
| molecular_cellular          | 0                                                                                                         |
| apt                         | 0.05                                                                                                      |
| is_clinical                 | No                                                                                                        |
| citation_count              | 1                                                                                                         |
| citations_per_year          | 1                                                                                                         |
| expected_citations_per_year | NA                                                                                                        |
| field_citation_rate         | 2.209809                                                                                                  |
| provisional                 | No                                                                                                        |
| x_coord                     | 0                                                                                                         |
| y_coord                     | 1                                                                                                         |
| cited_by_clin               | NA                                                                                                        |
| doi                         | 10.1177/0306624X20969948                                                                                  |
| ref_count                   | 4                                                                                                         |

> Referenced and cited-by PMIDs are returned by the function as a
> column-list of network edges.

``` r
citations$citation_net[[4]]
```

    ##        from       to
    ## 1: 33143508 28402828
    ## 2: 33143508 30767582
    ## 3: 33143508 18268079
    ## 4: 33143508 25816814
    ## 5: 35473457 33143508

## Affiliations

The `pmtk_get_affiliations` function extracts author and author
affiliation information from PubMed records.

``` r
afffs <- pubmedr::pmed_get_affiliations(pmids = s0$pmid)

afffs |>
  bind_rows() |>
  slice(1:10) |>
  knitr::kable()
```

| pmid     | Author             | Affiliation                                                                                                                                                                                                                                                           |
|:---|:-----|:--------------------------------------------------------------|
| 36122967 | Levy, Sharon       | Adolescent Substance Use and Addiction Program, Boston Children’s Hospital, Boston, Massachusetts; Division of Developmental Medicine, Boston Children’s Hospital, Boston, Massachusetts; Department of Pediatrics, Harvard Medical School, Boston, Massachusetts.    |
| 36122967 | Wisk, Lauren E     | Division of General Internal Medicine & Health Services Research, David Geffen School of Medicine at the University of California, Los Angeles, California.                                                                                                           |
| 36122967 | Minegishi, Machiko | Division of Adolescent/Young Adult Medicine, Boston Children’s Hospital, Boston, Massachusetts.                                                                                                                                                                       |
| 36122967 | Lunstead, Julie    | Adolescent Substance Use and Addiction Program, Boston Children’s Hospital, Boston, Massachusetts; Division of Developmental Medicine, Boston Children’s Hospital, Boston, Massachusetts.                                                                             |
| 36122967 | Weitzman, Elissa R | Department of Pediatrics, Harvard Medical School, Boston, Massachusetts; Division of Adolescent/Young Adult Medicine, Boston Children’s Hospital, Boston, Massachusetts; Computational Health Informatics Program, Boston Children’s Hospital, Boston, Massachusetts. |
| 36076191 | Hachem, Yasmina    | Medical Cannabis Program in Oncology, Cedars Cancer Center, McGill University Health Centre, 1001 boulevard Decarie, Montreal, QC, H3A 3J1, Canada.                                                                                                                   |
| 36076191 | Abdallah, Sara J   | Division of Infectious Diseases, Department of Medicine, The Ottawa Hospital and Ottawa Hospital Research Institute, 501 Smyth Road, Ottawa, ON, K1H 8L6, Canada.                                                                                                     |
| 36076191 | Rueda, Sergio      | Centre for Addiction and Mental Health, Institute for Mental Health Policy Research, 33 Ursula Franklin St, Toronto, ON, M5S 2S1, Canada.                                                                                                                             |
| 36076191 | Rueda, Sergio      | Campbell Family Mental Health Research Institute, Centre for Addiction and Mental Health, 250 College Street, Toronto, ON, M5T 1R8, Canada.                                                                                                                           |
| 36076191 | Rueda, Sergio      | Department of Psychiatry, University of Toronto, 250 College Street, Toronto, ON, M5T 1R8, Canada.                                                                                                                                                                    |
