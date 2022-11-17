<!-- badges: start -->

[![Travis build
status](https://app.travis-ci.com/jaytimm/pubmedr.svg?branch=main)](https://app.travis-ci.com/github/jaytimm/pubmedr)
[![R-CMD-check](https://github.com/jaytimm/pubmedr/workflows/R-CMD-check/badge.svg)](https://github.com/jaytimm/pubmedr/actions)
<!-- badges: end -->

*Updated: 2022-11-17*

# pubmedr

An R package for (1) querying the PubMed database & parsing retrieved
records; (2) extracting full text articles from the Open Access subset
of the PMC via ftp; (3) obtaining citation data from NIH’s Open Citation
Collection/[iCite](https://icite.od.nih.gov/); and (4) accessing
annotations of biomedical concepts from [PubTator
Central](https://www.ncbi.nlm.nih.gov/research/pubtator/).

-   [pubmedr](#pubmedr)
    -   [Installation](#installation)
    -   [Usage](#usage)
    -   [PubMed search](#pubmed-search)
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
med_cannabis <- pubmedr::pmed_search_pubmed(search_term = 'medical marijuana', 
                                            fields = c('TIAB','MH'))
```

    ## [1] "medical marijuana[TIAB] OR medical marijuana[MH]: 2694 records"

``` r
head(med_cannabis)
```

    ##          search_term     pmid
    ## 1: medical marijuana 36367871
    ## 2: medical marijuana 36367574
    ## 3: medical marijuana 36342719
    ## 4: medical marijuana 36335085
    ## 5: medical marijuana 36305815
    ## 6: medical marijuana 36296511

## Multiple search terms

``` r
cannabis_etc <- pubmedr::pmed_search_pubmed(
  search_term = c('marijuana chronic pain',
                  'marijuana legalization',
                  'marijuana policy',
                  'medical marijuana'),
  fields = c('TIAB','MH'))
```

    ## [1] "marijuana chronic pain[TIAB] OR marijuana chronic pain[MH]: 839 records"
    ## [1] "marijuana legalization[TIAB] OR marijuana legalization[MH]: 245 records"
    ## [1] "marijuana policy[TIAB] OR marijuana policy[MH]: 700 records"
    ## [1] "medical marijuana[TIAB] OR medical marijuana[MH]: 2694 records"

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
med_cannabis_df <- pubmedr::pmed_get_records2(pmids = unique(med_cannabis$pmid)[1:10], 
                                              with_annotations = T,
                                              #cores = 5, 
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
    ## [1] "36367871"
    ## 
    ## $year
    ## [1] "2022"
    ## 
    ## $journal
    ## [1] "PloS one"
    ## 
    ## $articletitle
    ## [1] "From growers to patients: Multi-stakeholder views on the"
    ## [2] "use of, and access to medicinal cannabis in Australia."  
    ## 
    ## $abstract
    ##  [1] "Patient interest in the use of cannabis-based medicines"    
    ##  [2] "(CBMs) has increased in Australia. While recent policy and" 
    ##  [3] "legislative changes have enabled health practitioners to"   
    ##  [4] "prescribe CBMs for their patients, many patients still"     
    ##  [5] "struggle to access CBMs. This paper employed a thematic"    
    ##  [6] "analysis to submissions made to a 2019 Australian"          
    ##  [7] "government inquiry into current barriers of patient access" 
    ##  [8] "to medical cannabis. We identified 121 submissions from"    
    ##  [9] "patients or family members (n = 63), government bodies (n ="
    ## [10] "5), non-government organisations (i.e., professional health"

## MeSH Annotations

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

| ID       | TYPE      | FORM                     |
|:---------|:----------|:-------------------------|
| 36367871 | MeSH      | Humans                   |
| 36367871 | MeSH      | Medical Marijuana        |
| 36367871 | MeSH      | Australia                |
| 36367871 | MeSH      | Cannabis                 |
| 36367871 | MeSH      | Family                   |
| 36367871 | MeSH      | Drug Industry            |
| 36367871 | Chemistry | Medical Marijuana        |
| 36367574 | Keyword   | diffusion tensor imaging |
| 36367574 | Keyword   | fractional anisotropy    |
| 36367574 | Keyword   | mean diffusivity         |

## Affiliations

The `pmed_get_affiliations` function extracts author and author
affiliation information from PubMed records.

``` r
pubmedr::pmed_get_affiliations(pmids = med_cannabis_df0$pmid) |>
  bind_rows() |>
  slice(1:10) |>
  knitr::kable()
```

| pmid     | Author                   | Affiliation                                                                                                                            |
|:----|:----------|:-------------------------------------------------------|
| 36367871 | Erku, Daniel             | Centre for Applied Health Economics, School of Medicine, Griffith University, Brisbane, Australia.                                     |
| 36367871 | Erku, Daniel             | Menzies Health Institute Queensland, Griffith University, Gold Coast, Australia.                                                       |
| 36367871 | Greenwood, Lisa-Marie    | Research School of Psychology, The Australian National University, Canberra, ACT, Australia.                                           |
| 36367871 | Graham, Myfanwy          | Australian Centre for Cannabinoid Clinical and Research Excellence, University of Newcastle, Newcastle, Australia.                     |
| 36367871 | Graham, Myfanwy          | Centre for Drug Repurposing & Medicines Research, School of Medicine and Public Health, University of Newcastle, Newcastle, Australia. |
| 36367871 | Hallinan, Christine Mary | Department of General Practice, Faculty Dentistry Medicine and Health Science, University of Melbourne, Melbourne, Australia.          |
| 36367871 | Bartschi, Jessica G      | Australian Centre for Cannabinoid Clinical and Research Excellence, University of Newcastle, Newcastle, Australia.                     |
| 36367871 | Bartschi, Jessica G      | School of Psychology, Faculty of the Arts, Social Sciences and Humanities, University of Wollongong, Wollongong, Australia.            |
| 36367871 | Bartschi, Jessica G      | Illawarra Health and Medical Research Institute, University of Wollongong, Wollongong, Australia.                                      |
| 36367871 | Renaud, Elianne          | Australian Centre for Cannabinoid Clinical and Research Excellence, University of Newcastle, Newcastle, Australia.                     |

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
                                      cores = 6,
                                      ncbi_key = key)

c0 <- citations |> select(-citation_net) |> slice(4)
setNames(data.frame(t(c0[,-1])), c0[,1]) |> knitr::kable()
```

|                             | 36292471                                                                                                                                                                 |
|:----------|:------------------------------------------------------------|
| year                        | 2022                                                                                                                                                                     |
| title                       | Paroxysmal Sustained Ventricular Tachycardia with Cardiac Arrest and Myocardial Infarction in 29-Year-Old Man Addicted to Medical Marijuana-It Never Rains but It Pours. |
| authors                     | Jerzy Wiliński, Anna Skwarek, Iwona Chrzan, Aleksander Zeliaś, Radosław Borek, Dominika Elżbieta Dykla, Maria Bober-Fotopoulos, Dariusz Dudek                            |
| journal                     | Healthcare (Basel)                                                                                                                                                       |
| is_research_article         | Yes                                                                                                                                                                      |
| relative_citation_ratio     | NA                                                                                                                                                                       |
| nih_percentile              | NA                                                                                                                                                                       |
| human                       | 0.67                                                                                                                                                                     |
| animal                      | 0.33                                                                                                                                                                     |
| molecular_cellular          | 0                                                                                                                                                                        |
| apt                         | 0.05                                                                                                                                                                     |
| is_clinical                 | No                                                                                                                                                                       |
| citation_count              | 0                                                                                                                                                                        |
| citations_per_year          | 0                                                                                                                                                                        |
| expected_citations_per_year | NA                                                                                                                                                                       |
| field_citation_rate         | NA                                                                                                                                                                       |
| provisional                 | No                                                                                                                                                                       |
| x_coord                     | 0.2886751                                                                                                                                                                |
| y_coord                     | 0.5                                                                                                                                                                      |
| cited_by_clin               | NA                                                                                                                                                                       |
| doi                         | 10.3390/healthcare10102024                                                                                                                                               |
| ref_count                   | 0                                                                                                                                                                        |

### Network data

> Referenced and cited-by PMIDs are returned by the function as a
> column-list of network edges.

``` r
citations$citation_net[[1]] |> head()
```

    ##        from       to
    ## 1: 36226444 12648025
    ## 2: 36226444 33008420
    ## 3: 36226444 27001005
    ## 4: 36226444 31207470
    ## 5: 36226444 34676347
    ## 6: 36226444 21858958

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

| pmid     | tiab     | id  | text                         | identifier   | type     | offset | length |
|:-------|:-------|:---|:----------------------|:----------|:-------|:------|:------|
| 36367871 | title    | 1   | patients                     | 9606         | Species  | 16     | 8      |
| 36367871 | abstract | 11  | Patient                      | 9606         | Species  | 124    | 7      |
| 36367871 | abstract | 12  | patients                     | 9606         | Species  | 321    | 8      |
| 36367871 | abstract | 13  | patients                     | 9606         | Species  | 336    | 8      |
| 36367871 | abstract | 14  | patient                      | 9606         | Species  | 501    | 7      |
| 36367871 | abstract | 15  | patients                     | 9606         | Species  | 581    | 8      |
| 36367871 | abstract | 16  | patient                      | 9606         | Species  | 1040   | 7      |
| 36367871 | abstract | 17  | patients                     | 9606         | Species  | 1410   | 8      |
| 36367871 | abstract | 18  | patients                     | 9606         | Species  | 1693   | 8      |
| 36367871 | abstract | 19  | patient                      | 9606         | Species  | 2086   | 7      |
| 36367574 | abstract | 13  | abnormal white matter        | MESH:D056784 | Disease  | 142    | 21     |
| 36367574 | abstract | 14  | patients                     | 9606         | Species  | 626    | 8      |
| 36367574 | abstract | 15  | anterior corona radiata      | MESH:C537775 | Disease  | 1078   | 23     |
| 36367574 | abstract | 16  | patients                     | 9606         | Species  | 1191   | 8      |
| 36367574 | abstract | 17  | patients                     | 9606         | Species  | 1558   | 8      |
| 36367574 | abstract | 18  | patients                     | 9606         | Species  | 1638   | 8      |
| 36367574 | abstract | 19  | cannabidiol                  | MESH:D002185 | Chemical | 1790   | 11     |
| 36367574 | abstract | 20  | CBD                          | MESH:C546797 | Chemical | 1803   | 3      |
| 36367574 | abstract | 21  | Delta-9-tetrahydrocannabinol | MESH:D013759 | Chemical | 1825   | 28     |
| 36367574 | abstract | 22  | patients                     | 9606         | Species  | 2099   | 8      |

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

samp <- med_cannabis_fulltexts |> filter(pmcid %in% pmc_med_cannabis$PMCID[1])

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
