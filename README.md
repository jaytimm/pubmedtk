<!-- badges: start -->

[![Travis build
status](https://app.travis-ci.com/jaytimm/pubmedr.svg?branch=main)](https://app.travis-ci.com/github/jaytimm/pubmedr)
[![R-CMD-check](https://github.com/jaytimm/pubmedr/workflows/R-CMD-check/badge.svg)](https://github.com/jaytimm/pubmedr/actions)
<!-- badges: end -->

*Updated: 2022-12-28*

# pubmedr

An R package for (1) querying the PubMed database & parsing retrieved
records; (2) extracting full text articles from the Open Access subset
of the PMC via ftp; (3) obtaining citation data from NIH’s Open Citation
Collection/[iCite](https://icite.od.nih.gov/); and (4) accessing
annotations of biomedical concepts from [PubTator
Central](https://www.ncbi.nlm.nih.gov/research/pubtator/).

-   [pubmedr](#pubmedr)
    -   [Installation](#installation)
    -   [PubMed search](#pubmed-search)
        -   [Basic search](#basic-search)
        -   [Multiple search terms](#multiple-search-terms)
    -   [Retrieve and parse abstract
        data](#retrieve-and-parse-abstract-data)
        -   [MeSH Annotations](#mesh-annotations)
        -   [Affiliations](#affiliations)
    -   [Citation data](#citation-data)
        -   [Summary data](#summary-data)
        -   [Network data](#network-data)
    -   [Biomedical concepts via the Pubtator Central
        API](#biomedical-concepts-via-the-pubtator-central-api)
    -   [Full text from Open Acess PMC](#full-text-from-open-acess-pmc)
        -   [Load list of Open Access PMC
            articles](#load-list-of-open-access-pmc-articles)
        -   [Extract full text articles](#extract-full-text-articles)
    -   [MeSH extensions](#mesh-extensions)
        -   [Thesauri](#thesauri)
        -   [Trees](#trees)
        -   [Embeddings](#embeddings)

## Installation

You can download the development version from GitHub with:

``` r
devtools::install_github("jaytimm/pubmedr")
```

## PubMed search

### Basic search

The `pmed_search_pubmed()` function is meant for record-matching
searches typically performed using the [PubMed online
interface](https://pubmed.ncbi.nlm.nih.gov/). The `search_term`
parameter specifies the query term; the `fields` parameter can be used
to specify which fields to query.

``` r
med_cannabis <- pubmedr::pmed_search_pubmed(search_term = 'medical marijuana', 
                                            fields = c('TIAB','MH'))
```

    ## [1] "medical marijuana[TIAB] OR medical marijuana[MH]: 2733 records"

``` r
head(med_cannabis)
```

    ##          search_term     pmid
    ## 1: medical marijuana 36555842
    ## 2: medical marijuana 36535680
    ## 3: medical marijuana 36529730
    ## 4: medical marijuana 36514481
    ## 5: medical marijuana 36484587
    ## 6: medical marijuana 36484580

### Multiple search terms

``` r
cannabis_etc <- pubmedr::pmed_search_pubmed(
  search_term = c('marijuana chronic pain',
                  'marijuana legalization',
                  'marijuana policy',
                  'medical marijuana'),
  fields = c('TIAB','MH'))
```

    ## [1] "marijuana chronic pain[TIAB] OR marijuana chronic pain[MH]: 857 records"
    ## [1] "marijuana legalization[TIAB] OR marijuana legalization[MH]: 252 records"
    ## [1] "marijuana policy[TIAB] OR marijuana policy[MH]: 927 records"
    ## [1] "medical marijuana[TIAB] OR medical marijuana[MH]: 2733 records"

``` r
UpSetR::upset(UpSetR::fromList(split(cannabis_etc$pmid,
                                     cannabis_etc$search_term 
                                     )), 
              nsets = 4, order.by = "freq")
```

![](README_files/figure-markdown_github/unnamed-chunk-7-1.png)

## Retrieve and parse abstract data

For quicker abstract retrieval, be sure to get an [API
key](https://support.nlm.nih.gov/knowledgebase/article/KA-03521/en-us).

``` r
med_cannabis_df <- pubmedr::pmed_get_records2(pmids = unique(med_cannabis$pmid)[1:100], 
                                              with_annotations = T,
                                              # cores = 5, 
                                              ncbi_key = key) 
```

``` r
med_cannabis_df0 <- data.table::rbindlist(med_cannabis_df)

n <- 1
list(pmid = med_cannabis_df0$pmid[n],
     year = med_cannabis_df0$year[n],
     journal = med_cannabis_df0$journal[n],
     articletitle = strwrap(med_cannabis_df0$articletitle[n], width = 60),
     abstract = strwrap(med_cannabis_df0$abstract[n], width = 60)[1:10])
```

    ## $pmid
    ## [1] "36555842"
    ## 
    ## $year
    ## [1] "2022"
    ## 
    ## $journal
    ## [1] "International journal of molecular sciences"
    ## 
    ## $articletitle
    ## [1] "Dysmenorrhoea: Can Medicinal Cannabis Bring New Hope for a"
    ## [2] "Collective Group of Women Suffering in Pain, Globally?"    
    ## 
    ## $abstract
    ##  [1] "Dysmenorrhoea effects up to 90% of women of reproductive"   
    ##  [2] "age, with medical management options including"             
    ##  [3] "over-the-counter analgesia or hormonal contraception. There"
    ##  [4] "has been a recent surge in medicinal cannabis research and" 
    ##  [5] "its analgesic properties. This paper aims to critically"    
    ##  [6] "investigate the current research of medicinal cannabis for" 
    ##  [7] "pain relief and to discuss its potential application to"    
    ##  [8] "treat dysmenorrhoea. Relevant keywords, including medicinal"
    ##  [9] "cannabis, pain, cannabinoids, tetrahydrocannabinol,"        
    ## [10] "dysmenorrhoea, and clinical trial, have been searched in"

### MeSH Annotations

> Annotations are included as a list-column, and can be easily
> extracted:

``` r
annotations <- data.table::rbindlist(med_cannabis_df0$annotations)
```

``` r
annotations |>
  filter(!is.na(FORM)) |>
  slice(1:10) |>
  knitr::kable()
```

| ID       | TYPE      | FORM              |
|:---------|:----------|:------------------|
| 36555842 | MeSH      | Female            |
| 36555842 | MeSH      | Humans            |
| 36555842 | MeSH      | Dysmenorrhea      |
| 36555842 | MeSH      | Medical Marijuana |
| 36555842 | MeSH      | Cannabinoids      |
| 36555842 | MeSH      | Dronabinol        |
| 36555842 | MeSH      | Analgesics        |
| 36555842 | MeSH      | Cannabis          |
| 36555842 | Chemistry | Medical Marijuana |
| 36555842 | Chemistry | Cannabinoids      |

### Affiliations

The `pmed_get_affiliations` function extracts author and author
affiliation information from PubMed records.

``` r
pubmedr::pmed_get_affiliations(pmids = med_cannabis_df0$pmid) |>
  bind_rows() |>
  slice(1:10) |>
  knitr::kable()
```

| pmid     | Author              | Affiliation                                                                                                                            |
|:----|:---------|:--------------------------------------------------------|
| 36555842 | Seifalian, Amelia   | Department of Urogynaecology, St. Mary’s Hospital, Imperial College London, London W2 1NY, UK.                                         |
| 36555842 | Kenyon, Julian      | The Dove Clinic for Integrated Medicine, Winchester SO21 1RG, UK.                                                                      |
| 36555842 | Khullar, Vik        | Department of Urogynaecology, St. Mary’s Hospital, Imperial College London, London W2 1NY, UK.                                         |
| 36455395 | Smart, Rosanna      | AND Corporation, United States of America.                                                                                             |
| 36455395 | Doremus, Jacqueline | California Polytechnic State University, San Luis Obispo, United States of America.                                                    |
| 36454553 | Bao, Yuhua          | Department of Population Health Sciences, Weill Cornell Medicine, New York, New York.                                                  |
| 36454553 | Bao, Yuhua          | Department of Psychiatry, Weill Cornell Medicine, New York, New York.                                                                  |
| 36454553 | Zhang, Hao          | Department of Population Health Sciences, Weill Cornell Medicine, New York, New York.                                                  |
| 36454553 | Bruera, Eduardo     | Department of Palliative, Rehabilitation, and Integrative Medicine, The University of Texas MD Anderson Cancer Center, Houston, Texas. |
| 36454553 | Portenoy, Russell   | JHS Institute for Innovation in Palliative Care, New York, New York.                                                                   |

## Citation data

The `pmed_get_icites` function can be used to obtain citation data per
PMID using NIH’s Open Citation Collection and
[iCite](https://icite.od.nih.gov/).

> Hutchins BI, Baker KL, Davis MT, Diwersy MA, Haque E, Harriman RM, et
> al. (2019) The NIH Open Citation Collection: A public access, broad
> coverage resource. PLoS Biol 17(10): e3000385.
> <https://doi.org/10.1371/journal.pbio.3000385>

### Summary data

The iCite API returns a host of descriptive/derived citation details per
record.

``` r
citations <- pubmedr::pmed_get_icites(pmids = med_cannabis_df0$pmid, 
                                      #cores = 6,
                                      ncbi_key = key)

c0 <- citations |> select(-citation_net) |> slice(4)
setNames(data.frame(t(c0[,-1])), c0[,1]) |> knitr::kable()
```

|                             | 35866679                                                                                                                                                       |
|:-----------|:-----------------------------------------------------------|
| year                        | 2022                                                                                                                                                           |
| title                       | Incidence and Predictors of Cannabis-Related Poisoning and Mental and Behavioral Disorders among Patients with Medical Cannabis Authorization: A Cohort Study. |
| authors                     | Arsene Zongo, Cerina Lee, Jason R B Dyck, Jihane El-Mourad, Elaine Hyshka, John G Hanlon, Dean T Eurich                                                        |
| journal                     | Subst Use Misuse                                                                                                                                               |
| is_research_article         | Yes                                                                                                                                                            |
| relative_citation_ratio     | NA                                                                                                                                                             |
| nih_percentile              | NA                                                                                                                                                             |
| human                       | 0.5                                                                                                                                                            |
| animal                      | 0.5                                                                                                                                                            |
| molecular_cellular          | 0                                                                                                                                                              |
| apt                         | 0.05                                                                                                                                                           |
| is_clinical                 | No                                                                                                                                                             |
| citation_count              | 0                                                                                                                                                              |
| citations_per_year          | 0                                                                                                                                                              |
| expected_citations_per_year | NA                                                                                                                                                             |
| field_citation_rate         | NA                                                                                                                                                             |
| provisional                 | No                                                                                                                                                             |
| x_coord                     | 0.4330127                                                                                                                                                      |
| y_coord                     | 0.25                                                                                                                                                           |
| cited_by_clin               | NA                                                                                                                                                             |
| doi                         | 10.1080/10826084.2022.2102193                                                                                                                                  |
| ref_count                   | 27                                                                                                                                                             |

### Network data

> Referenced and cited-by PMIDs are returned by the function as a
> column-list of network edges.

``` r
citations$citation_net[[1]] |> head()
```

    ##        from       to
    ## 1: 35821596 30010351
    ## 2: 35821596 29349253
    ## 3: 35821596 35196883
    ## 4: 35821596 35618659
    ## 5: 35821596 31786435
    ## 6: 35821596 31296507

## Biomedical concepts via the Pubtator Central API

> Wei, C. H., Allot, A., Leaman, R., & Lu, Z. (2019). PubTator central:
> automated concept annotation for biomedical full text articles.
> Nucleic acids research, 47(W1), W587-W593.

``` r
pubtations <- unique(med_cannabis$pmid)[1:10] |>
  pubmedr::pmed_get_entities(cores = 2) |>
  data.table::rbindlist()

pubtations |> na.omit() |> slice(1:20) |> knitr::kable()
```

| pmid     | tiab     | id  | text                 | identifier      | type     | start |  end |
|:--------|:--------|:---|:-----------------|:-------------|:--------|-----:|-----:|
| 36555842 | title    | 4   | Women                | 9606            | Species  |    79 |   84 |
| 36555842 | title    | 5   | Pain                 | MESH:D010146    | Disease  |    98 |  102 |
| 36555842 | abstract | 21  | women                | 9606            | Species  |   149 |  154 |
| 36555842 | abstract | 22  | analgesia            | MESH:D000699    | Disease  |   235 |  244 |
| 36555842 | abstract | 23  | pain                 | MESH:D010146    | Disease  |   452 |  456 |
| 36555842 | abstract | 25  | pain                 | MESH:D010146    | Disease  |   578 |  582 |
| 36555842 | abstract | 26  | tetrahydrocannabinol | MESH:D013759    | Chemical |   598 |  618 |
| 36555842 | abstract | 28  | pain                 | MESH:D010146    | Disease  |  1026 | 1030 |
| 36555842 | abstract | 29  | pain                 | MESH:D010146    | Disease  |  1126 | 1130 |
| 36555842 | abstract | 30  | nausea               | MESH:D009325    | Disease  |  1390 | 1396 |
| 36555842 | abstract | 31  | drowsiness           | MESH:D006970    | Disease  |  1398 | 1408 |
| 36555842 | abstract | 32  | dry mouth            | MESH:D014987    | Disease  |  1414 | 1423 |
| 36529730 | abstract | 12  | patient              | 9606            | Species  |  1042 | 1049 |
| 36529730 | abstract | 13  | patients             | 9606            | Species  |  1153 | 1161 |
| 36529730 | abstract | 14  | cancer pain          | MESH:D000072716 | Disease  |  1276 | 1287 |
| 36529730 | abstract | 15  | nausea               | MESH:D009325    | Disease  |  1310 | 1316 |
| 36529730 | abstract | 16  | vomiting             | MESH:D014839    | Disease  |  1321 | 1329 |
| 36529730 | abstract | 17  | epilepsy             | MESH:D004827    | Disease  |  1335 | 1343 |
| 36529730 | abstract | 18  | depression           | MESH:D000275    | Disease  |  1426 | 1436 |
| 36529730 | abstract | 19  | anxiety              | MESH:D001007    | Disease  |  1438 | 1445 |

## Full text from Open Acess PMC

### Load list of Open Access PMC articles

``` r
pmclist <- pubmedr::pmed_load_pmclist()
pmc_med_cannabis <- pmclist |> filter(PMID %in% unique(med_cannabis$pmid))
pmc_med_cannabis |> head() |> knitr::kable()
```

| fpath                              | journal                                          | PMCID   | PMID     | license_type |
|:---------------------|:-----------------------------|:-----|:------|:--------|
| oa_package/06/f8/PMC2267789.tar.gz | Harm Reduct J. 2008 Jan 28; 5:5                  | 2267789 | 18226254 | CC BY        |
| oa_package/b1/ba/PMC2848643.tar.gz | Harm Reduct J. 2010 Mar 5; 7:3                   | 2848643 | 20202221 | CC BY        |
| oa_package/7c/37/PMC2990823.tar.gz | Indian J Psychiatry. 2010 Jul-Sep; 52(3):236-242 | 2990823 | 21180408 | CC BY        |
| oa_package/6f/9a/PMC3358713.tar.gz | Open Neurol J. 2012 May 4; 6:18-25               | 3358713 | 22629287 | CC BY-NC     |
| oa_package/38/6d/PMC3507655.tar.gz | Addict Sci Clin Pract. 2012 Apr 19; 7(1):5       | 3507655 | 23186143 | CC BY        |
| oa_package/cb/ad/PMC3628147.tar.gz | Med Sci Monit. 2011 Dec 1; 17(12):RA249-RA261    | 3628147 | 22129912 | NO-CC CODE   |

### Extract full text articles

``` r
med_cannabis_fulltexts <- pmc_med_cannabis$fpath[1] |> 
  pubmedr::pmed_get_fulltext()
  #pubmedr::pmed_get_fulltext()

samp <- med_cannabis_fulltexts |> 
  filter(pmcid %in% pmc_med_cannabis$PMCID[1])

lapply(samp$text, function(x){strwrap(x, width = 60)[1:3]})
```

    ## [[1]]
    ## [1] "1. Introduction Although modern medicine has only recently"
    ## [2] "begun to rediscover the therapeutic potential of cannabis,"
    ## [3] "written records of medical use date back thousands of"     
    ## 
    ## [[2]]
    ## [1] "2. Health Canada's Marihuana Medical Access Division The"   
    ## [2] "federal government's own polling and research suggests that"
    ## [3] "there are currently over 290,000 medical users in the"      
    ## 
    ## [[3]]
    ## [1] "3. The Canadian Institute of Health Research and the"      
    ## [2] "Medical Marihuana Research Program Since the court-ordered"
    ## [3] "implementation of a federal medical cannabis policy in"    
    ## 
    ## [[4]]
    ## [1] "4. Health Canada's Production and Supply Policy and"     
    ## [2] "Practice In December 2000 Health Canada awarded a"       
    ## [3] "five-year, $5.7 million contract for the production of a"
    ## 
    ## [[5]]
    ## [1] "5. Community-Based Alternatives to a Centralized Medical"    
    ## [2] "Cannabis Program\"As far as the distribution of marijuana to"
    ## [3] "qualified users is concerned, the government might consider" 
    ## 
    ## [[6]]
    ## [1] "6. Discussion and Conclusion Since 1999 the Canadian"       
    ## [2] "government has spent over $30 million in funding for the"   
    ## [3] "research, production and distribution of medicinal cannabis"
    ## 
    ## [[7]]
    ## [1] "Competing interests The author is the founder and director"
    ## [2] "of the Vancouver Island Compassion Society, and receives a"
    ## [3] "salary from this organization for research, communications"

## MeSH extensions

### Thesauri

### Trees

### Embeddings

> Noh, J., & Kavuluru, R. (2021). Improved biomedical word embeddings in
> the transformer era. Journal of Biomedical Informatics, 120, 103867.

<https://www.sciencedirect.com/science/article/pii/S1532046421001969>

> @article{noh2020improved, title={Improved Biomedical Word Embeddings
> in the Transformer Era}, author={Noh, Jiho and Kavuluru, Ramakanth},
> journal={arXiv preprint arXiv:2012.11808}, year={2020} }

<https://zenodo.org/record/4383195>

Includes embeddings for the \~30K MeSH descriptors, as well as \~15K
embeddings for Supplementary Concept Records (SCR).
