<!-- badges: start -->

[![Travis build
status](https://app.travis-ci.com/jaytimm/pubmedr.svg?branch=main)](https://app.travis-ci.com/github/jaytimm/pubmedr)
[![R-CMD-check](https://github.com/jaytimm/pubmedr/workflows/R-CMD-check/badge.svg)](https://github.com/jaytimm/pubmedr/actions)
<!-- badges: end -->

# pubmedr

An R package for (1) querying the PubMed database & parsing retrieved
records; (2) extracting full text articles from the Open Access subset
of the PMC via ftp; (3) obtaining citation data from NIH’s Open Citation
Collection/[iCite](https://icite.od.nih.gov/); and (4) accessing
annotations of biomedical concepts from [PubTator
Central](https://www.ncbi.nlm.nih.gov/research/pubtator/).

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

    ## [1] "medical marijuana[TIAB] OR medical marijuana[MH]: 2657 records"

``` r
head(med_cannabis)
```

    ##          search_term     pmid
    ## 1: medical marijuana 36168342
    ## 2: medical marijuana 36147312
    ## 3: medical marijuana 36136010
    ## 4: medical marijuana 36122967
    ## 5: medical marijuana 36122285
    ## 6: medical marijuana 36076191

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
    ## [1] "medical marijuana[TIAB] OR medical marijuana[MH]: 2657 records"

``` r
UpSetR::upset(UpSetR::fromList(split(cannabis_etc$pmid,
                                     cannabis_etc$search_term 
                                     )), 
              nsets = 4, order.by = "freq")
```

![](README_files/figure-markdown_github/unnamed-chunk-6-1.png)

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
    ## [1] "35289010"
    ## 
    ## $year
    ## [1] "2022"
    ## 
    ## $journal
    ## [1] "Addiction (Abingdon, England)"
    ## 
    ## $articletitle
    ## [1] "The iCannToolkit: a tool to embrace measurement of"    
    ## [2] "medicinal and non-medicinal cannabis use across licit,"
    ## [3] "illicit and cross-cultural settings."                  
    ## 
    ## $abstract
    ##  [1] "NA" NA   NA   NA   NA   NA   NA   NA   NA   NA

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

| ID       | TYPE    | FORM                         |
|:---------|:--------|:-----------------------------|
| 36168342 | Keyword | attitudes                    |
| 36168342 | Keyword | beliefs                      |
| 36168342 | Keyword | education                    |
| 36168342 | Keyword | focus groups                 |
| 36168342 | Keyword | medical cannabis             |
| 36168342 | Keyword | medical education curriculum |
| 36168342 | Keyword | medical marijuana            |
| 36168342 | Keyword | medical students             |
| 36168342 | Keyword | qualitative                  |
| 36147312 | Keyword | CBD-cannabidiol              |

## Affiliations

The `pmed_get_affiliations` function extracts author and author
affiliation information from PubMed records.

``` r
pubmedr::pmed_get_affiliations(pmids = med_cannabis_df0$pmid) |>
  bind_rows() |>
  slice(1:10) |>
  knitr::kable()
```

| pmid     | Author            | Affiliation                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
|:--|:---|:-----------------------------------------------------------------|
| 36168342 | Jacobs, Robin J   | Medical and Behavioral Research, Health Informatics, and Medical Education, Nova Southeastern University, Fort Lauderdale, USA.                                                                                                                                                                                                                                                                                                                                                     |
| 36168342 | Colon, Jessica    | Medical School, Nova Southeastern University Dr. Kiran C. Patel College of Osteopathic Medicine, Fort Lauderdale, USA.                                                                                                                                                                                                                                                                                                                                                              |
| 36168342 | Kane, Michael N   | Social Work, Florida Atlantic University, Boca Raton, USA.                                                                                                                                                                                                                                                                                                                                                                                                                          |
| 36038457 | Kluger, Benzi M   | Departments of Neurology and Medicine, University of Rochester Medical Center, Rochester, NY, USA.                                                                                                                                                                                                                                                                                                                                                                                  |
| 36038457 | Huang, Andrew P   | Departments of Neurology and Medicine, University of Rochester Medical Center, Rochester, NY, USA.                                                                                                                                                                                                                                                                                                                                                                                  |
| 36038457 | Miyasaki, Janis M | Division of Neurology, Department of Medicine, University of Alberta, Edmonton, Alberta, Canada.                                                                                                                                                                                                                                                                                                                                                                                    |
| 35316689 | Montebello, Mark  | Drug and Alcohol Services, Northern Sydney Local Health District, Level 1, 2c Herbert Street, St Leonards, NSW 2065, Australia; Specialty of Addiction Medicine, Faculty of Medicine and Health, University of Sydney, City Road, Camperdown, NSW 2006, Australia; National Drug and Alcohol Research Centre, University of New South Wales, 22-32 King St, Randwick, NSW 2031, Australia; NSW Drug and Alcohol Clinical Research and Improvement Network (DACRIN), NSW, Australia. |
| 35316689 | Jefferies, Meryem | Drug Health, Western Sydney Local Health District, 5 Fleet St, North Parramatta, NSW 2151, Australia.                                                                                                                                                                                                                                                                                                                                                                               |
| 35316689 | Mills, Llewellyn  | Specialty of Addiction Medicine, Faculty of Medicine and Health, University of Sydney, City Road, Camperdown, NSW 2006, Australia; NSW Drug and Alcohol Clinical Research and Improvement Network (DACRIN), NSW, Australia; Drug and Alcohol Services, South Eastern Sydney Local Health District, The Langton Centre, 591 South Dowling St, Surry Hills, NSW 2010, Australia.                                                                                                      |
| 35316689 | Bruno, Raimondo   | National Drug and Alcohol Research Centre, University of New South Wales, 22-32 King St, Randwick, NSW 2031, Australia; School of Psychological Sciences, University of Tasmania, Private Bag 30, Hobart, Tasmania 7001, Australia.                                                                                                                                                                                                                                                 |

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

|                             | t.slice.select.citations…citation_net…4..    |
|:---------------------------|:-------------------------------------------|
| pmid                        | 34798780                                     |
| year                        | 2022                                         |
| title                       | A Survey of Topical Cannabis Use in Canada.  |
| authors                     | Farhan Mahmood, Megan M Lim, Mark G Kirchhof |
| journal                     | J Cutan Med Surg                             |
| is_research_article         | Yes                                          |
| relative_citation_ratio     | NA                                           |
| nih_percentile              | NA                                           |
| human                       | 0.67                                         |
| animal                      | 0.33                                         |
| molecular_cellular          | 0                                            |
| apt                         | 0.05                                         |
| is_clinical                 | No                                           |
| citation_count              | 1                                            |
| citations_per_year          | 1                                            |
| expected_citations_per_year | 1.379355                                     |
| field_citation_rate         | 6.295272                                     |
| provisional                 | No                                           |
| x_coord                     | 0.2886751                                    |
| y_coord                     | 0.5                                          |
| cited_by_clin               | NA                                           |
| doi                         | 10.1177/12034754211059025                    |
| ref_count                   | 25                                           |

> Referenced and cited-by PMIDs are returned by the function as a
> column-list of network edges.

``` r
citations$citation_net[[4]] |> head()
```

    ##        from       to
    ## 1: 34798780 33220620
    ## 2: 34798780 32148986
    ## 3: 34798780 31960125
    ## 4: 34798780  6620158
    ## 5: 34798780 32914659
    ## 6: 34798780 29356658

## Biomedical concepts via the Pubtator Central API

> Wei, C. H., Allot, A., Leaman, R., & Lu, Z. (2019). PubTator central:
> automated concept annotation for biomedical full text articles.
> Nucleic acids research, 47(W1), W587-W593.

``` r
pubtations <- unique(med_cannabis$pmid) |>
  pubmedr::pmed_get_entities(cores = 6) |>
  data.table::rbindlist()

pubtations |> na.omit() |> slice(1:20) |> knitr::kable()
```

| pmid     | tiab     | id  | text                   | identifier   | type     | offset | length |
|:--------|:--------|:---|:-------------------|:-----------|:--------|:------|:------|
| 36168342 | abstract | 2   | patients               | 9606         | Species  | 579    | 8      |
| 36168342 | abstract | 3   | patients               | 9606         | Species  | 2141   | 8      |
| 36147312 | title    | 1   | patient                | 9606         | Species  | 67     | 7      |
| 36147312 | abstract | 13  | child                  | 9606         | Species  | 646    | 5      |
| 36147312 | abstract | 14  | cannabidiol            | MESH:D002185 | Chemical | 685    | 11     |
| 36147312 | abstract | 15  | CBD                    | MESH:D002185 | Chemical | 698    | 3      |
| 36147312 | abstract | 16  | neurological disorders | MESH:D009422 | Disease  | 742    | 22     |
| 36147312 | abstract | 17  | pain                   | MESH:D010146 | Disease  | 774    | 4      |
| 36147312 | abstract | 18  | cannabinoids           | MESH:D002186 | Chemical | 1202   | 12     |
| 36147312 | abstract | 19  | pain                   | MESH:D010146 | Disease  | 1277   | 4      |
| 36147312 | abstract | 20  | seizure reduction      | MESH:D007022 | Disease  | 1315   | 17     |
| 36147312 | abstract | 21  | anxiety                | MESH:D001007 | Disease  | 1389   | 7      |
| 36147312 | abstract | 22  | participants           | 9606         | Species  | 1774   | 12     |
| 36147312 | abstract | 23  | cannabinoid            | MESH:D002186 | Chemical | 2103   | 11     |
| 36136010 | title    | 1   | Marijuana              | 3483         | Species  | 7      | 9      |
| 36122967 | title    | 3   | Alcohol                | MESH:D000438 | Chemical | 24     | 7      |
| 36122967 | title    | 4   | Alcohol                | MESH:D000438 | Chemical | 67     | 7      |
| 36122967 | title    | 5   | Patients               | 9606         | Species  | 115    | 8      |
| 36122967 | abstract | 27  | patient                | 9606         | Species  | 209    | 7      |
| 36122967 | abstract | 28  | marijuana              | 3483         | Species  | 354    | 9      |
