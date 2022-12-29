<!-- badges: start -->

[![Travis build
status](https://app.travis-ci.com/jaytimm/pubmedr.svg?branch=main)](https://app.travis-ci.com/github/jaytimm/pubmedr)
[![R-CMD-check](https://github.com/jaytimm/pubmedr/workflows/R-CMD-check/badge.svg)](https://github.com/jaytimm/pubmedr/actions)
<!-- badges: end -->

*Updated: 2022-12-29*

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
        -   [Record details](#record-details)
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
    -   [Utility functions](#utility-functions)
        -   [Navigating the MeSH
            ontology](#navigating-the-mesh-ontology)

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

    ## [1] "medical marijuana[TIAB] OR medical marijuana[MH]: 2735 records"

``` r
head(med_cannabis)
```

    ##          search_term     pmid
    ## 1: medical marijuana 36576970
    ## 2: medical marijuana 36576904
    ## 3: medical marijuana 36555842
    ## 4: medical marijuana 36535680
    ## 5: medical marijuana 36529730
    ## 6: medical marijuana 36514481

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
    ## [1] "medical marijuana[TIAB] OR medical marijuana[MH]: 2735 records"

``` r
UpSetR::upset(UpSetR::fromList(split(cannabis_etc$pmid,
                                     cannabis_etc$search_term 
                                     )), 
              nsets = 4, order.by = "freq")
```

![](README_files/figure-markdown_github/unnamed-chunk-7-1.png)

## Retrieve and parse abstract data

### Record details

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
    ## [1] "36576970"
    ## 
    ## $year
    ## [1] "2022"
    ## 
    ## $journal
    ## [1] "Journal of palliative medicine"
    ## 
    ## $articletitle
    ## [1] "A Case Report of Treatment-Resistant Agitation in Dementia"
    ## [2] "with Lewy Bodies: Medical Marijuana as an Alternative to"  
    ## [3] "Antipsychotics."                                           
    ## 
    ## $abstract
    ##  [1] "Palliative care teams are often consulted to assist in"     
    ##  [2] "treating persistent dementia-related behavioral issues."    
    ##  [3] "Delta-9-tetrahydrocannabinol (THC) offers an alternative to"
    ##  [4] "traditional antipsychotic drugs in the long-term management"
    ##  [5] "of dementia with behavioral change. We present the case of" 
    ##  [6] "an 85-year-old man with dementia with Lewy bodies with"     
    ##  [7] "worsening aggression refractory to antipsychotic"           
    ##  [8] "management. Multiple regimens of antipsychotics failed both"
    ##  [9] "in the outpatient and inpatient settings. After exhausting" 
    ## [10] "other options and in the setting of worsening agitation, a"

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

| ID       | TYPE    | FORM                      |
|:---------|:--------|:--------------------------|
| 36576970 | Keyword | dementia                  |
| 36576970 | Keyword | medical cannabis          |
| 36576970 | Keyword | neurodegenerative disease |
| 36576904 | Keyword | cannabidiol               |
| 36576904 | Keyword | cannabis-based substances |
| 36576904 | Keyword | medical cannabis          |
| 36576904 | Keyword | medical marijuana         |
| 36576904 | Keyword | pain management           |
| 36576904 | Keyword | symptom management        |
| 36555842 | MeSH    | Female                    |

### Affiliations

The `pmed_get_affiliations` function extracts author and author
affiliation information from PubMed records.

``` r
pubmedr::pmed_get_affiliations(pmids = med_cannabis_df0$pmid) |>
  bind_rows() |>
  slice(1:10) |>
  knitr::kable()
```

| pmid     | Author                | Affiliation                                                                                                                                 |
|:----|:---------|:--------------------------------------------------------|
| 36576970 | Ramm, Rebecca M       | Department of Medicine, Tulane University School of Medicine, New Orleans, Louisiana, USA.                                                  |
| 36576970 | Lerner, Zachary I     | Department of Medicine, Tulane University School of Medicine, New Orleans, Louisiana, USA.                                                  |
| 36576970 | Levy-Meeks, Garrett S | Division of Geriatric and Palliative Medicine, Department of Medicine, University of Texas Houston School of Medicine, Houston, Texas, USA. |
| 36576970 | Burke, Rebecca V      | Department of Medicine, Tulane University School of Medicine, New Orleans, Louisiana, USA.                                                  |
| 36576970 | Raven, Mary C         | Medical Director, Palliative Medicine Program, Our Lady of the Lake Regional Medical Center, Baton Rouge, Louisiana, USA.                   |
| 36576970 | Song, Amanda          | Department of Medicine, University of Texas Medical Branch, Galveston, Texas, USA.                                                          |
| 36576970 | Glass, Marcia H       | Department of Medicine, Tulane University School of Medicine, New Orleans, Louisiana, USA.                                                  |
| 36467782 | Smolinski, Nicole E   | Pharmaceutical Outcomes and Policy, University of Florida, Gainesville, Florida, USA.                                                       |
| 36467782 | Smolinski, Nicole E   | Center for Drug Evaluation and Safety (CoDES), University of Florida, Gainesville, Florida, USA.                                            |
| 36467782 | Smolinski, Nicole E   | Consortium for Medical Marijuana Clinical Outcomes Research, University of Florida, Gainesville, Florida, USA.                              |

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

|                             | 35868317                                                                           |
|:------------------|:----------------------------------------------------|
| year                        | 2022                                                                               |
| title                       | \[Cannabis in oncology - much ado about nothing?\]                                 |
| authors                     | Anton Burkhard-Meier, Constanze Rémi, Lars H Lindner, Michael von Bergwelt-Baildon |
| journal                     | Dtsch Med Wochenschr                                                               |
| is_research_article         | Yes                                                                                |
| relative_citation_ratio     | NA                                                                                 |
| nih_percentile              | NA                                                                                 |
| human                       | 1                                                                                  |
| animal                      | 0                                                                                  |
| molecular_cellular          | 0                                                                                  |
| apt                         | 0.05                                                                               |
| is_clinical                 | No                                                                                 |
| citation_count              | 0                                                                                  |
| citations_per_year          | 0                                                                                  |
| expected_citations_per_year | NA                                                                                 |
| field_citation_rate         | NA                                                                                 |
| provisional                 | No                                                                                 |
| x_coord                     | 0                                                                                  |
| y_coord                     | 1                                                                                  |
| cited_by_clin               | NA                                                                                 |
| doi                         | 10.1055/a-1872-2749                                                                |
| ref_count                   | 32                                                                                 |

### Network data

> Referenced and cited-by PMIDs are returned by the function as a
> column-list of network edges.

``` r
citations$citation_net[[1]] |> head()
```

    ##        from       to
    ## 1: 35856517     <NA>
    ## 2:     <NA> 35856517

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
| 36576904 | title    | 5   | Marijuana            | 3483            | Species  |    76 |   85 |
| 36576904 | title    | 6   | Cannabidiol          | MESH:D002185    | Chemical |    90 |  101 |
| 36576904 | title    | 7   | Pain                 | MESH:D010146    | Disease  |   123 |  127 |
| 36576904 | title    | 8   | Cancer               | MESH:D009369    | Disease  |   150 |  156 |
| 36576904 | title    | 9   | Patients             | 9606            | Species  |   157 |  165 |
| 36576904 | abstract | 18  | marijuana            | 3483            | Species  |   187 |  196 |
| 36576904 | abstract | 19  | cannabidiol          | MESH:D002185    | Chemical |   206 |  217 |
| 36576904 | abstract | 20  | pain                 | MESH:D010146    | Disease  |   269 |  273 |
| 36576904 | abstract | 21  | cancer               | MESH:D009369    | Disease  |   461 |  467 |
| 36576904 | abstract | 22  | pain                 | MESH:D010146    | Disease  |   479 |  483 |
| 36576904 | abstract | 23  | cancer pain          | MESH:D000072716 | Disease  |   760 |  771 |
| 36576904 | abstract | 24  | cancer pain          | MESH:D000072716 | Disease  |   876 |  887 |
| 36576904 | abstract | 25  | pain                 | MESH:D010146    | Disease  |  1056 | 1060 |
| 36555842 | title    | 4   | Women                | 9606            | Species  |    79 |   84 |
| 36555842 | title    | 5   | Pain                 | MESH:D010146    | Disease  |    98 |  102 |
| 36555842 | abstract | 21  | women                | 9606            | Species  |   149 |  154 |
| 36555842 | abstract | 22  | analgesia            | MESH:D000699    | Disease  |   235 |  244 |
| 36555842 | abstract | 23  | pain                 | MESH:D010146    | Disease  |   452 |  456 |
| 36555842 | abstract | 25  | pain                 | MESH:D010146    | Disease  |   578 |  582 |
| 36555842 | abstract | 26  | tetrahydrocannabinol | MESH:D013759    | Chemical |   598 |  618 |

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

``` r
embeddings <- pubmedr::data_mesh_embeddings()

pubmedr::pmed_get_neighbors(x = embeddings,
                            target = 'Rituximab') |>
  
  left_join(pubmedr::data_mesh_thesuarus() |>
              select(DescriptorName, DescriptorUI) |>
              distinct(), 
            by = c('term2' = 'DescriptorName'))|>
  knitr::kable()
```

| rank | term1     | term2                | value | DescriptorUI |
|-----:|:----------|:---------------------|------:|:-------------|
|    1 | Rituximab | Rituximab            | 1.000 | D000069283   |
|    2 | Rituximab | fludarabine          | 0.568 | C024352      |
|    3 | Rituximab | Alemtuzumab          | 0.562 | D000074323   |
|    4 | Rituximab | obinutuzumab         | 0.554 | C543332      |
|    5 | Rituximab | Lymphoma, B-Cell     | 0.549 | D016393      |
|    6 | Rituximab | galiximab            | 0.542 | C437823      |
|    7 | Rituximab | tocilizumab          | 0.534 | C502936      |
|    8 | Rituximab | ibritumomab tiuxetan | 0.530 | C422802      |
|    9 | Rituximab | belimumab            | 0.528 | C511911      |
|   10 | Rituximab | Prednisone           | 0.511 | D011241      |

## Utility functions

### Navigating the MeSH ontology
