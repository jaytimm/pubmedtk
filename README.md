<!-- badges: start -->

[![Travis build
status](https://app.travis-ci.com/jaytimm/pubmedtk.svg?branch=main)](https://app.travis-ci.com/github/jaytimm/pubmedtk)
[![R-CMD-check](https://github.com/jaytimm/pubmedtk/workflows/R-CMD-check/badge.svg)](https://github.com/jaytimm/pubmedtk/actions)
<!-- badges: end -->

*Updated: 2023-11-19*

# pubmedtk

An R package for (1) querying the PubMed database & parsing retrieved
records; (2) extracting full text articles from the Open Access subset
of the PMC via ftp; (3) obtaining citation data from NIH’s Open Citation
Collection/[iCite](https://icite.od.nih.gov/); and (4) accessing
annotations of biomedical concepts from [PubTator
Central](https://www.ncbi.nlm.nih.gov/research/pubtator/).

-   [pubmedtk](#pubmedtk)
    -   [Installation](#installation)
    -   [PubMed search](#pubmed-search)
        -   [Basic search](#basic-search)
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
        -   [Pharmacological Actions](#pharmacological-actions)
        -   [Embeddings](#embeddings)

## Installation

You can download the development version from GitHub with:

``` r
devtools::install_github("jaytimm/pubmedtk")
```

## PubMed search

### Basic search

The `pmed_search_pubmed()` function is meant for record-matching
searches typically performed using the [PubMed online
interface](https://pubmed.ncbi.nlm.nih.gov/).

``` r
yrs <- 2010:2023
pubmed_query <- paste0('("medical marijuana"[MeSH Terms]) AND (',
                       yrs, ':', yrs,  
                       '[pdat])')

med_cannabis <- lapply(pubmed_query, pubmedtk::pmed_search_pubmed)
med_cannabis <- med_cannabis |> unlist() |> unique()
```

``` r
head(med_cannabis)
```

    ## [1] "24645219" "24564006" "24439711" "24439710" "24412475" "24329652"

## Retrieve and parse abstract data

### Record details

``` r
med_cannabis_df0 <- pubmedtk::pmed_get_records2(pmids = med_cannabis[1:300], 
                                              with_annotations = T,
                                              verbose = F,
                                              cores = 3) |>
  data.table::rbindlist() |> filter(!is.na(abstract))
```

``` r
n <- 1
list(pmid = med_cannabis_df0$pmid[n],
     year = med_cannabis_df0$year[n],
     journal = med_cannabis_df0$journal[n],
     articletitle = strwrap(med_cannabis_df0$articletitle[n], width = 60),
     abstract = strwrap(med_cannabis_df0$abstract[n], width = 60)[1:10])
```

    ## $pmid
    ## [1] "24977967"
    ## 
    ## $year
    ## [1] "2014"
    ## 
    ## $journal
    ## [1] "Neuro endocrinology letters"
    ## 
    ## $articletitle
    ## [1] "Clinical endocannabinoid deficiency (CECD) revisited: can"
    ## [2] "this concept explain the therapeutic benefits of cannabis"
    ## [3] "in migraine, fibromyalgia, irritable bowel syndrome and"  
    ## [4] "other treatment-resistant conditions?"                    
    ## 
    ## $abstract
    ##  [1] "Ethan B. Russo's paper of December 1, 2003 explored the"  
    ##  [2] "concept of a clinical endocannabinoid deficiency (CECD)"  
    ##  [3] "underlying the pathophysiology of migraine, fibromyalgia,"
    ##  [4] "irritable bowel syndrome and other functional conditions" 
    ##  [5] "alleviated by clinical cannabis. Available literature was"
    ##  [6] "reviewed, including searches via the National Library of" 
    ##  [7] "medicine database and other sources. A review of the"     
    ##  [8] "literature indicates that significant progress has been"  
    ##  [9] "made since Dr. Ethan B. Russo's landmark paper, just ten" 
    ## [10] "years ago (February 2, 2004). Investigation at that time"

### MeSH Annotations

> Annotations are included as a list-column (in ouput from
> `pmed_get_records2`), and can be easily extracted:

``` r
annotations <- data.table::rbindlist(med_cannabis_df0$annotations)
```

``` r
annotations |>
  filter(!is.na(FORM)) |>
  slice(1:10) |>
  knitr::kable()
```

| ID       | TYPE      | FORM                                  |
|:---------|:----------|:--------------------------------------|
| 24439711 | MeSH      | Canada                                |
| 24439711 | MeSH      | Community Health Services             |
| 24439711 | MeSH      | Health Knowledge, Attitudes, Practice |
| 24439711 | MeSH      | Health Policy                         |
| 24439711 | MeSH      | Holistic Health                       |
| 24439711 | MeSH      | Humans                                |
| 24439711 | MeSH      | Medical Marijuana                     |
| 24439711 | Chemistry | Medical Marijuana                     |
| 24439711 | Keyword   | Drug policy                           |
| 24439711 | Keyword   | Embodied health movement              |

### Affiliations

The `pmed_get_affiliations` function extracts author and author
affiliation information from PubMed records. This is functionally the
same call as `pmed_get_records2` – presented here as an independent
function for simplicity in output.

``` r
pubmedtk::pmed_get_affiliations(pmids = med_cannabis_df0$pmid) |>
  bind_rows() |>
  slice(1:10) |>
  knitr::kable()
```

| pmid     | Author               | Affiliation                                                                                                                                                     |
|:----|:--------|:----------------------------------------------------------|
| 24977967 | Smith, Steele Clarke | NA                                                                                                                                                              |
| 24977967 | Wagner, Mark S       | NA                                                                                                                                                              |
| 24949839 | Rylander, Melanie    | Departments of Behavioral Health .                                                                                                                              |
| 24949839 | Valdez, Carolyn      | NA                                                                                                                                                              |
| 24949839 | Nussbaum, Abraham M  | NA                                                                                                                                                              |
| 24947993 | Belle-Isle, Lynne    | Canadian AIDS Society, Ottawa, Ontario, Canada; Centre for Addictions Research of British Columbia, University of Victoria, Victoria, British Columbia, Canada. |
| 24947993 | Walsh, Zach          | Department of Psychology, University of British Columbia, Kelowna, British Columbia, Canada.                                                                    |
| 24947993 | Callaway, Robert     | Medical Cannabis Advocate, Vancouver, British Columbia, Canada.                                                                                                 |
| 24947993 | Lucas, Philippe      | Centre for Addictions Research of British Columbia, University of Victoria, Victoria, British Columbia, Canada.                                                 |
| 24947993 | Capler, Rielle       | Canadian Association of Medical Cannabis Dispensaries, Vancouver, British Columbia, Canada.                                                                     |

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
citations <- pubmedtk::pmed_get_icites(pmids = med_cannabis_df0$pmid)

c0 <- citations |> select(-citation_net) |> slice(4)
setNames(data.frame(t(c0[,-1])), c0[,1]) |> knitr::kable()
```

|                             | 23844955                                                                           |
|:------------------|:----------------------------------------------------|
| year                        | 2013                                                                               |
| title                       | Trends in detection rates of risky marijuana use in Colorado health care settings. |
| authors                     | Melissa K Richmond, Katie Page, Laura S Rivera, Brie Reimann, Leigh Fischer        |
| journal                     | Subst Abus                                                                         |
| is_research_article         | Yes                                                                                |
| relative_citation_ratio     | 0.16                                                                               |
| nih_percentile              | 8.2                                                                                |
| human                       | 1                                                                                  |
| animal                      | 0                                                                                  |
| molecular_cellular          | 0                                                                                  |
| apt                         | 0.25                                                                               |
| is_clinical                 | No                                                                                 |
| citation_count              | 3                                                                                  |
| citations_per_year          | 0.3                                                                                |
| expected_citations_per_year | 1.825729                                                                           |
| field_citation_rate         | 3.145084                                                                           |
| provisional                 | No                                                                                 |
| x_coord                     | 0                                                                                  |
| y_coord                     | 1                                                                                  |
| cited_by_clin               |                                                                                    |
| doi                         | 10.1080/08897077.2012.755146                                                       |
| last_modified               | 10/31/2023, 06:53:47                                                               |
| ref_count                   | 25                                                                                 |

### Network data

> Referenced and cited-by PMIDs are returned by the function as a
> column-list of network edges.

``` r
citations$citation_net[[1]] |> head()
```

    ##        from       to
    ## 1: 23471521 19357281
    ## 2: 23471521 16612464
    ## 3: 23471521  4879547
    ## 4: 23471521 16288682
    ## 5: 23471521  7760148
    ## 6: 23471521 14517981

## Biomedical concepts via the Pubtator Central API

> Wei, C. H., Allot, A., Leaman, R., & Lu, Z. (2019). PubTator central:
> automated concept annotation for biomedical full text articles.
> Nucleic acids research, 47(W1), W587-W593.

``` r
pubtations <- med_cannabis[1:10] |>
  pubmedtk::pmed_get_entities(cores = 2) |>
  data.table::rbindlist()

pubtations |> na.omit() |> slice(1:20) |> knitr::kable()
```

| pmid     | tiab     | id  | text                    | identifier   | type     | start |  end |
|:--------|:--------|:---|:--------------------|:-----------|:--------|-----:|-----:|
| 24564006 | title    | 1   | marijuana               | 3483         | Species  |    25 |   34 |
| 24564006 | abstract | 7   | marijuana               | 3483         | Species  |   149 |  158 |
| 24564006 | abstract | 8   | marijuana               | 3483         | Species  |   338 |  347 |
| 24564006 | abstract | 9   | marijuana               | 3483         | Species  |   370 |  379 |
| 24564006 | abstract | 10  | Legalizing recreational | MESH:D001766 | Disease  |   483 |  506 |
| 24564006 | abstract | 11  | marijuana               | 3483         | Species  |   507 |  516 |
| 24439710 | abstract | 3   | alcohol                 | MESH:D000438 | Chemical |   380 |  387 |
| 24439710 | abstract | 4   | alcohol                 | MESH:D000438 | Chemical |  1074 | 1081 |
| 24439710 | abstract | 5   | alcohol                 | MESH:D000438 | Chemical |  1585 | 1592 |
| 24412475 | title    | 1   | PTSD                    | MESH:D013313 | Disease  |    96 |  100 |
| 24412475 | abstract | 15  | PTSD                    | MESH:D013313 | Disease  |   189 |  193 |
| 24412475 | abstract | 16  | people                  | 9606         | Species  |   303 |  309 |
| 24412475 | abstract | 17  | PTSD                    | MESH:D013313 | Disease  |   315 |  319 |
| 24412475 | abstract | 18  | alcohol                 | MESH:D000438 | Chemical |   662 |  669 |
| 24412475 | abstract | 19  | patients                | 9606         | Species  |   723 |  731 |
| 24412475 | abstract | 20  | PTSD                    | MESH:D013313 | Disease  |   813 |  817 |
| 24412475 | abstract | 21  | PTSD                    | MESH:D013313 | Disease  |   944 |  948 |
| 24412475 | abstract | 22  | PTSD                    | MESH:D013313 | Disease  |  1014 | 1018 |
| 24412475 | abstract | 23  | PTSD                    | MESH:D013313 | Disease  |  1093 | 1097 |
| 24412475 | abstract | 24  | PTSD                    | MESH:D013313 | Disease  |  1341 | 1345 |

## Full text from Open Acess PMC

### Load list of Open Access PMC articles

``` r
pmclist <- pubmedtk::data_pmc_list()
pmc_med_cannabis <- pmclist |> filter(PMID %in% med_cannabis)
pmc_med_cannabis |> head() |> knitr::kable()
```

| fpath                              | journal                                        | PMCID   | PMID     | license_type |
|:---------------------|:----------------------------|:-----|:------|:--------|
| oa_package/e8/71/PMC3966811.tar.gz | PLoS One. 2014 Mar 26; 9(3):e92816             | 3966811 | 24671103 | CC BY        |
| oa_package/73/a8/PMC3995798.tar.gz | PLoS One. 2014 Apr 22; 9(4):e95569             | 3995798 | 24755942 | CC BY        |
| oa_package/d5/c5/PMC4374299.tar.gz | BMC Med Educ. 2015 Mar 19; 15:52               | 4374299 | 25888752 | CC BY        |
| oa_package/c6/b5/PMC4410963.tar.gz | J Occup Environ Med. 2015 May 8; 57(5):518-525 | 4410963 | 25951421 | NO-CC CODE   |
| oa_package/a3/13/PMC4473732.tar.gz | Neuroimage Clin. 2015 Apr 9; 8:140-147         | 4473732 | 26106538 | CC BY-NC-ND  |
| oa_package/97/40/PMC4553645.tar.gz | Yale J Biol Med. 2015 Sep 3; 88(3):257-264     | 4553645 | 26339208 | CC BY-NC     |

### Extract full text articles

``` r
med_cannabis_fulltexts <- pmc_med_cannabis$fpath[1] |> 
  pubmedtk::pmed_get_fulltext()
  #pubmedtk::pmed_get_fulltext()

samp <- med_cannabis_fulltexts |> 
  filter(pmcid %in% pmc_med_cannabis$PMCID[1])

lapply(samp$text, function(x){strwrap(x, width = 60)[1:3]})
```

    ## [[1]]
    ## [1] "Introduction The social ramifications of marijuana"      
    ## [2] "legalization have been hotly debated for at least four"  
    ## [3] "decades [1]. Despite a long history of marijuana use for"
    ## 
    ## [[2]]
    ## [1] "Methods Data & Measures Dependent Variables Data on all" 
    ## [2] "seven Part I offenses—homicide, rape, robbery, assault," 
    ## [3] "burglary, larceny, and auto theft—for each state between"
    ## 
    ## [[3]]
    ## [1] "Results Primary Findings Before consulting the results from"
    ## [2] "the fixed effects regression models, a series of"           
    ## [3] "unconditioned crime rates for each offense type were"       
    ## 
    ## [[4]]
    ## [1] "Discussion and Conclusion The effects of legalized medical"
    ## [2] "marijuana have been passionately debated in recent years." 
    ## [3] "Empirical research on the direct relationship between"

## MeSH extensions

### Thesauri

``` r
mesh <- pubmedtk::data_mesh_thesuarus() 
mesh |> head() |> knitr::kable()
```

| DescriptorUI | DescriptorName | ConceptUI | TermUI  | TermName           | ConceptPreferredTermYN | IsPermutedTermYN | LexicalTag | RecordPreferredTermYN |
|:------|:-------|:-----|:----|:---------|:-----------|:--------|:-----|:----------|
| D000001      | Calcimycin     | M0000001  | T000002 | Calcimycin         | Y                      | N                | NON        | Y                     |
| D000001      | Calcimycin     | M0353609  | T000001 | A-23187            | Y                      | N                | LAB        | N                     |
| D000001      | Calcimycin     | M0353609  | T000001 | A 23187            | N                      | Y                | LAB        | N                     |
| D000001      | Calcimycin     | M0353609  | T000004 | A23187             | N                      | N                | LAB        | N                     |
| D000001      | Calcimycin     | M0353609  | T000003 | Antibiotic A23187  | N                      | N                | NON        | N                     |
| D000001      | Calcimycin     | M0353609  | T000003 | A23187, Antibiotic | N                      | Y                | NON        | N                     |

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

``` r
embeddings <- pubmedtk::data_mesh_embeddings()

pubmedtk::pmed_get_neighbors(x = embeddings,
                            target = 'Rituximab') |>
  knitr::kable()
```

| rank | term1     | term2                | value |
|-----:|:----------|:---------------------|------:|
|    1 | Rituximab | Rituximab            | 1.000 |
|    2 | Rituximab | fludarabine          | 0.568 |
|    3 | Rituximab | Alemtuzumab          | 0.562 |
|    4 | Rituximab | obinutuzumab         | 0.554 |
|    5 | Rituximab | Lymphoma, B-Cell     | 0.549 |
|    6 | Rituximab | galiximab            | 0.542 |
|    7 | Rituximab | tocilizumab          | 0.534 |
|    8 | Rituximab | ibritumomab tiuxetan | 0.530 |
|    9 | Rituximab | belimumab            | 0.528 |
|   10 | Rituximab | Prednisone           | 0.511 |
