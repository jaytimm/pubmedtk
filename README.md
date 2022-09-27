<!-- badges: start -->

[![Travis build
status](https://app.travis-ci.com/jaytimm/pubmedr.svg?branch=main)](https://app.travis-ci.com/github/jaytimm/pubmedr)
[![R-CMD-check](https://github.com/jaytimm/pubmedr/workflows/R-CMD-check/badge.svg)](https://github.com/jaytimm/pubmedr/actions)
<!-- badges: end -->

# pubmedr

An R package for (1) querying the PubMed database & parsing retrieved
records; (2) extracting full text articles from the Open Access subset
of the PMC via ftp; and (3) obtaianing citation data from NIH’s Open
Citation Collection.

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

    ## [1] "medical marijuana[TIAB] OR medical marijuana[MH]: 2654 records"

``` r
head(med_cannabis)
```

    ##          search_term     pmid
    ## 1: medical marijuana 36147312
    ## 2: medical marijuana 36122967
    ## 3: medical marijuana 36122285
    ## 4: medical marijuana 36076191
    ## 5: medical marijuana 36064621
    ## 6: medical marijuana 36055728

## Multiple search terms

``` r
cannabis_etc <- pubmedr::pmed_search_pubmed(
  search_term = c('marijuana chronic pain',
                  'marijuana legalization',
                  'marijuana policy',
                  'medical marijuana'),
  fields = c('TIAB','MH'))
```

    ## [1] "marijuana chronic pain[TIAB] OR marijuana chronic pain[MH]: 821 records"
    ## [1] "marijuana legalization[TIAB] OR marijuana legalization[MH]: 242 records"
    ## [1] "marijuana policy[TIAB] OR marijuana policy[MH]: 692 records"
    ## [1] "medical marijuana[TIAB] OR medical marijuana[MH]: 2654 records"

The `pmed_crosstab_query` can be used to build a cross-tab of PubMed
search results for multiple search terms.

``` r
cross <- pubmedr::pmed_crosstab_query(x = cannabis_etc) 
cross %>% knitr::kable()
```

| term1                  | term2                  |  n1 |   n2 | n1n2 |
|:-----------------------|:-----------------------|----:|-----:|-----:|
| marijuana chronic pain | marijuana legalization | 821 |  242 |    4 |
| marijuana chronic pain | marijuana policy       | 821 |  692 |    7 |
| marijuana chronic pain | medical marijuana      | 821 | 2654 |  339 |
| marijuana legalization | marijuana policy       | 242 |  692 |   33 |
| marijuana legalization | medical marijuana      | 242 | 2654 |   91 |
| marijuana policy       | medical marijuana      | 692 | 2654 |  201 |

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
med_cannabis_df <- pubmedr::pmed_get_records2(pmids = unique(med_cannabis$pmid), 
                                              with_annotations = T,
                                              cores = 5, 
                                              ncbi_key = key) 
```

``` r
med_cannabis_df0 <- data.table::rbindlist(med_cannabis_df)

n <- 10
list(pmid = med_cannabis_df0$pmid[n],
     year = med_cannabis_df0$year[n],
     journal = med_cannabis_df0$journal[n],
     articletitle = strwrap(med_cannabis_df0$articletitle[n], width = 60),
     abstract = strwrap(med_cannabis_df0$abstract[n], width = 60)[1:10])
```

    ## $pmid
    ## [1] "35267245"
    ## 
    ## $year
    ## [1] "2022"
    ## 
    ## $journal
    ## [1] "Annals of clinical and translational neurology"
    ## 
    ## $articletitle
    ## [1] "Observational study of medical marijuana as a treatment for"
    ## [2] "treatment-resistant epilepsies."                            
    ## 
    ## $abstract
    ##  [1] "Medical cannabis formulations with cannabidiol (CBD) and"   
    ##  [2] "delta-9-tetrahydrocannabinol (THC) are widely used to treat"
    ##  [3] "epilepsy. We studied the safety and efficacy of two"        
    ##  [4] "formulations. We prospectively observed 29 subjects (12 to" 
    ##  [5] "46 years old) with treatment-resistant epilepsies (11"      
    ##  [6] "Lennox-Gastaut syndrome; 15 with focal or multifocal"       
    ##  [7] "epilepsy; three generalized epilepsy) were treated with"    
    ##  [8] "medical cannabis (1THC:20CBD and/or 1THC:50CBD; maximum of" 
    ##  [9] "6 mg THC/day) for ≥24 weeks. The primary outcome was change"
    ## [10] "in convulsive seizure frequency from the pre-treatment"

## Full text from Open Acess PMC

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

``` r
med_cannabis_fulltexts <- pmc_med_cannabis$fpath[1:10] |> 
  pubmedr::pmed_get_fulltext()

samp <- med_cannabis_fulltexts |> filter(pmcid %in% pmc_med_cannabis$PMCID[6])

lapply(samp$text, function(x){strwrap(x, width = 60)[1:3]})
```

    ## [[1]]
    ## [1] "Debate about medical marijuana is challenging the basic"   
    ## [2] "foundations of the accepted practice in the medical, legal"
    ## [3] "and ethical communities. A major criticism of alternative" 
    ## 
    ## [[2]]
    ## [1] "The history of marijuana use for medicinal purposes extends"
    ## [2] "back through millennia. The medical use of marijuana can be"
    ## [3] "traced back to 2737 B.C., when Emperor Shen Neng was"       
    ## 
    ## [[3]]
    ## [1] "While the subject of medical marijuana is becoming an"      
    ## [2] "increasingly heated medical issue, it also continues to"    
    ## [3] "stir the embers of legal arguments. Advocates on both sides"
    ## 
    ## [[4]]
    ## [1] "As certain states seem to be backtracking, other states"    
    ## [2] "like Delaware, Pennsylvania, and nine others (Alabama,"     
    ## [3] "Connecticut, Idaho, Illinois, Massachusetts, New Hampshire,"
    ## 
    ## [[5]]
    ## [1] "The ethical dilemma at the core of this debate is whether"
    ## [2] "the federal ban on the use of medical marijuana violates" 
    ## [3] "the physician-patient relationship. The argument can be"  
    ## 
    ## [[6]]
    ## [1] "The main objection to the medical use of marijuana by the"
    ## [2] "federal government is largely attributable today to a"    
    ## [3] "national policy of zero-tolerance toward illicit drugs."  
    ## 
    ## [[7]]
    ## [1] "With regard to documenting the effectiveness of medical"    
    ## [2] "marijuana, the most comprehensive analysis to date in"      
    ## [3] "medical literature was issued on March 17, 1999, by a White"
    ## 
    ## [[8]]
    ## [1] "Attempts to reassign marijuana to a Schedule II drug"     
    ## [2] "classification have been rejected by the Drug Enforcement"
    ## [3] "Administration (DEA). The basis for rejection is the"     
    ## 
    ## [[9]]
    ## [1] "The purpose of this article, therefore, is fourfold: first,"
    ## [2] "to explore the medical aspect of marijuana by examining"    
    ## [3] "pertinent scientific research; second, to study the legal"  
    ## 
    ## [[10]]
    ## [1] "Medical Perspective Marijuana is taken from the leaves and" 
    ## [2] "flowering tops of the hemp plant, Cannabis sativa, which"   
    ## [3] "grows in most regions of the world. C. sativa contains over"
    ## 
    ## [[11]]
    ## [1] "Legal Perspective While a strong case may be made for the"  
    ## [2] "medical and ethical bases in support of the legalization of"
    ## [3] "medical marijuana, the United States’ strong anti-drug"     
    ## 
    ## [[12]]
    ## [1] "Ethical Perspective Society, in general, has always"       
    ## [2] "recognized that in our complex world there is the"         
    ## [3] "possibility that we may be faced with a situation that has"
    ## 
    ## [[13]]
    ## [1] "Conclusions After reviewing pertinent scientific data, it"
    ## [2] "is evident that there is ample evidence to warrant the"   
    ## [3] "Obama Administration to authorize the DEA to reclassify"

## Annotations

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

| ID       | TYPE    | FORM                     |
|:---------|:--------|:-------------------------|
| 36147312 | Keyword | CBD-cannabidiol          |
| 36147312 | Keyword | THC-tetrahydrocannabinol |
| 36147312 | Keyword | cannabis (marijuana)     |
| 36147312 | Keyword | medical marijuana        |
| 36147312 | Keyword | qualitative              |
| 36122967 | MeSH    | Adolescent               |
| 36122967 | MeSH    | Cannabis                 |
| 36122967 | MeSH    | Child                    |
| 36122967 | MeSH    | Ethanol                  |
| 36122967 | MeSH    | Humans                   |

## Affiliations

The `pmed_get_affiliations` function extracts author and author
affiliation information from PubMed records.

``` r
pubmedr::pmed_get_affiliations(pmids = med_cannabis_df0$pmid) |>
  bind_rows() |>
  slice(1:10) |>
  knitr::kable()
```

| pmid     | Author                   | Affiliation                                                                                                                                                            |
|:----|:---------|:---------------------------------------------------------|
| 36147312 | Garcia-Romeu, Albert     | Johns Hopkins University School of Medicine, Baltimore, MD, United States.                                                                                             |
| 36147312 | Elmore, Joshua           | University of Colorado Boulder, Boulder, CO, United States.                                                                                                            |
| 36147312 | Mayhugh, Rhiannon E      | Johns Hopkins University School of Medicine, Baltimore, MD, United States.                                                                                             |
| 36147312 | Schlienz, Nicolas J      | Roswell Park Comprehensive Cancer Center, Buffalo, NY, United States.                                                                                                  |
| 36147312 | Martin, Erin L           | Medical University of South Carolina, Charleston, SC, United States.                                                                                                   |
| 36147312 | Strickland, Justin C     | Johns Hopkins University School of Medicine, Baltimore, MD, United States.                                                                                             |
| 36147312 | Bonn-Miller, Marcel      | Canopy Growth Corporation, Smiths Falls, ON, Canada.                                                                                                                   |
| 36147312 | Jackson, Heather         | Realm of Caring Foundation, Colorado Springs, Colorado, CO, United States.                                                                                             |
| 36147312 | Vandrey, Ryan            | Johns Hopkins University School of Medicine, Baltimore, MD, United States.                                                                                             |
| 36011488 | Hallinan, Christine Mary | Department of General Practice, Faculty of Medicine, Dentistry and Health Sciences, Melbourne Medical School, University of Melbourne, Parkville, VIC 3010, Australia. |

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
citations <- pubmedr::pmed_get_icites(pmids = med_cannabis_df0$pmid, 
                                      cores = 6,
                                      ncbi_key = key)

citations |> select(-citation_net) |>
  slice(4) |>
  t() |> data.frame() |>
  knitr::kable()
```

|                             | t.slice.select.citations…citation_net…4..                                                                |
|:---------------|:-------------------------------------------------------|
| pmid                        | 34792923                                                                                                 |
| year                        | 2021                                                                                                     |
| title                       | Knowledge, Perception, and Use of Cannabis Therapy in Patients with Inflammatory Bowel Disease.          |
| authors                     | Luis A Muñiz-Camacho, Frances I Negrón-Quintana, Luis A Ramos-Burgos, Jorge J Cruz-Cruz, Esther A Torres |
| journal                     | P R Health Sci J                                                                                         |
| is_research_article         | Yes                                                                                                      |
| relative_citation_ratio     | NA                                                                                                       |
| nih_percentile              | NA                                                                                                       |
| human                       | 0.8                                                                                                      |
| animal                      | 0.2                                                                                                      |
| molecular_cellular          | 0                                                                                                        |
| apt                         | 0.05                                                                                                     |
| is_clinical                 | No                                                                                                       |
| citation_count              | 0                                                                                                        |
| citations_per_year          | 0                                                                                                        |
| expected_citations_per_year | NA                                                                                                       |
| field_citation_rate         | NA                                                                                                       |
| provisional                 | No                                                                                                       |
| x_coord                     | 0.1732051                                                                                                |
| y_coord                     | 0.7                                                                                                      |
| cited_by_clin               | NA                                                                                                       |
| doi                         |                                                                                                          |
| ref_count                   | 0                                                                                                        |

> Referenced and cited-by PMIDs are returned by the function as a
> column-list of network edges.

``` r
citations$citation_net[[4]] |> head()
```

    ##        from       to
    ## 1: 34792923     <NA>
    ## 2:     <NA> 34792923
