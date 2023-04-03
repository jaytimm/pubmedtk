<!-- badges: start -->

[![Travis build
status](https://app.travis-ci.com/jaytimm/pubmedr.svg?branch=main)](https://app.travis-ci.com/github/jaytimm/pubmedr)
[![R-CMD-check](https://github.com/jaytimm/pubmedr/workflows/R-CMD-check/badge.svg)](https://github.com/jaytimm/pubmedr/actions)
<!-- badges: end -->

*Updated: 2023-04-03*

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
        -   [Pharmacological Actions](#pharmacological-actions)
        -   [Embeddings](#embeddings)
    -   [Odds ends NLP](#odds-ends-nlp)

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

    ## [1] "medical marijuana[TIAB] OR medical marijuana[MH]: 2808 records"

``` r
head(med_cannabis)
```

    ##          search_term     pmid
    ## 1: medical marijuana 36986714
    ## 2: medical marijuana 36982049
    ## 3: medical marijuana 36979881
    ## 4: medical marijuana 36978185
    ## 5: medical marijuana 36961722
    ## 6: medical marijuana 36961701

### Multiple search terms

``` r
cannabis_etc <- pubmedr::pmed_search_pubmed(
  search_term = c('marijuana chronic pain',
                  'marijuana legalization',
                  'marijuana policy',
                  'medical marijuana'),
  fields = c('TIAB','MH'))
```

    ## [1] "marijuana chronic pain[TIAB] OR marijuana chronic pain[MH]: 894 records"
    ## [1] "marijuana legalization[TIAB] OR marijuana legalization[MH]: 256 records"
    ## [1] "marijuana policy[TIAB] OR marijuana policy[MH]: 936 records"
    ## [1] "medical marijuana[TIAB] OR medical marijuana[MH]: 2808 records"

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
    ## [1] "36986714"
    ## 
    ## $year
    ## [1] "2023"
    ## 
    ## $journal
    ## [1] "Pharmaceutics"
    ## 
    ## $articletitle
    ## [1] "Pharmacokinetics of Orally Applied Cannabinoids and Medical"
    ## [2] "Marijuana Extracts in Mouse Nervous Tissue and Plasma:"     
    ## [3] "Relevance for Pain Treatment."                              
    ## 
    ## $abstract
    ##  [1] "Cannabis sativa plants contain a multitude of bioactive"   
    ##  [2] "substances, which show broad variability between different"
    ##  [3] "plant strains. Of the more than a hundred naturally"       
    ##  [4] "occurring phytocannabinoids, Δ9-Tetrahydrocannabinol"      
    ##  [5] "(Δ9-THC) and cannabidiol (CBD) have been the most"         
    ##  [6] "extensively studied, but whether and how the lesser"       
    ##  [7] "investigated compounds in plant extracts affect"           
    ##  [8] "bioavailability or biological effects of Δ9-THC or CBD is" 
    ##  [9] "not known. We therefore performed a first pilot study to"  
    ## [10] "assess THC concentrations in plasma, spinal cord and brain"

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

| ID       | TYPE    | FORM                 |
|:---------|:--------|:---------------------|
| 36986714 | Keyword | CBD                  |
| 36986714 | Keyword | THC                  |
| 36986714 | Keyword | bioavailability      |
| 36986714 | Keyword | cannabidiol          |
| 36986714 | Keyword | medical marijuana    |
| 36986714 | Keyword | neuropathic pain     |
| 36986714 | Keyword | spared nerve injury  |
| 36986714 | Keyword | tetrahydrocannabinol |
| 36982049 | MeSH    | Male                 |
| 36982049 | MeSH    | Adult                |

### Affiliations

The `pmed_get_affiliations` function extracts author and author
affiliation information from PubMed records. This is functionally the
same call as `pmed_get_records2` – presented here as an independent
function for simplicity in output.

``` r
pubmedr::pmed_get_affiliations(pmids = med_cannabis_df0$pmid) |>
  bind_rows() |>
  slice(1:10) |>
  knitr::kable()
```

| pmid     | Author                 | Affiliation                                                                                                                                                           |
|:----|:--------|:----------------------------------------------------------|
| 36986714 | Dumbraveanu, Cristiana | Institute of Physiology, Medical University of Innsbruck, 6020 Innsbruck, Austria.                                                                                    |
| 36986714 | Dumbraveanu, Cristiana | Bionorica Research GmbH, 6020 Innsbruck, Austria.                                                                                                                     |
| 36986714 | Strommer, Katharina    | Bionorica Research GmbH, 6020 Innsbruck, Austria.                                                                                                                     |
| 36986714 | Wonnemann, Meinolf     | Independent Researcher, 92318 Neumarkt, Germany.                                                                                                                      |
| 36986714 | Choconta, Jeiny Luna   | Institute of Physiology, Medical University of Innsbruck, 6020 Innsbruck, Austria.                                                                                    |
| 36986714 | Neumann, Astrid        | Bionorica Research GmbH, 6020 Innsbruck, Austria.                                                                                                                     |
| 36986714 | Kress, Michaela        | Institute of Physiology, Medical University of Innsbruck, 6020 Innsbruck, Austria.                                                                                    |
| 36986714 | Kalpachidou, Theodora  | Institute of Physiology, Medical University of Innsbruck, 6020 Innsbruck, Austria.                                                                                    |
| 36986714 | Kummer, Kai K          | Institute of Physiology, Medical University of Innsbruck, 6020 Innsbruck, Austria.                                                                                    |
| 36924465 | Lake, Stephanie        | CLA Center for Cannabis and Cannabinoids, Jane and Terry Semel Institute for Neuroscience and Human Behavior, University of California, Los Angeles, California, USA. |

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

|                             | 36219744                                                                                     |
|:----------------|:------------------------------------------------------|
| year                        | 2022                                                                                         |
| title                       | Assessing Increases in Cannabis-Related Diagnoses in US Hospitals by Regional Policy Status. |
| authors                     | Michael Pottieger, Leslie Rowland, Katherine I DiSantis                                      |
| journal                     | Popul Health Manag                                                                           |
| is_research_article         | Yes                                                                                          |
| relative_citation_ratio     | NA                                                                                           |
| nih_percentile              | NA                                                                                           |
| human                       | 0.5                                                                                          |
| animal                      | 0.5                                                                                          |
| molecular_cellular          | 0                                                                                            |
| apt                         | 0.05                                                                                         |
| is_clinical                 | No                                                                                           |
| citation_count              | 0                                                                                            |
| citations_per_year          | 0                                                                                            |
| expected_citations_per_year | NA                                                                                           |
| field_citation_rate         | NA                                                                                           |
| provisional                 | No                                                                                           |
| x_coord                     | 0.4330127                                                                                    |
| y_coord                     | 0.25                                                                                         |
| cited_by_clin               | NA                                                                                           |
| doi                         | 10.1089/pop.2022.0122                                                                        |
| ref_count                   | 13                                                                                           |

### Network data

> Referenced and cited-by PMIDs are returned by the function as a
> column-list of network edges.

``` r
citations$citation_net[[1]] |> head()
```

    ##        from       to
    ## 1: 36200224     <NA>
    ## 2:     <NA> 36200224

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

| pmid     | tiab     | id  | text                        | identifier   | type     | start | end |
|:--------|:--------|:---|:----------------------|:-----------|:--------|-----:|----:|
| 36986714 | title    | 3   | Marijuana                   | 3483         | Species  |    60 |  69 |
| 36986714 | title    | 4   | Mouse                       | 10090        | Species  |    82 |  87 |
| 36986714 | title    | 5   | Pain                        | MESH:D010146 | Disease  |   129 | 133 |
| 36986714 | abstract | 26  | Cannabis sativa             | 3483         | Species  |   145 | 160 |
| 36986714 | abstract | 27  | Delta9-Tetrahydrocannabinol | MESH:D013759 | Chemical |   341 | 368 |
| 36986714 | abstract | 28  | Delta9-THC                  | MESH:D013759 | Chemical |   370 | 380 |
| 36986714 | abstract | 29  | cannabidiol                 | MESH:D002185 | Chemical |   386 | 397 |
| 36986714 | abstract | 30  | CBD                         | MESH:C546797 | Chemical |   399 | 402 |
| 36986714 | abstract | 31  | Delta9-THC                  | MESH:D013759 | Chemical |   564 | 574 |
| 36986714 | abstract | 32  | CBD                         | MESH:C546797 | Chemical |   578 | 581 |
| 36986714 | abstract | 33  | THC                         | MESH:D013759 | Chemical |   649 | 652 |
| 36986714 | abstract | 34  | THC                         | MESH:D013759 | Chemical |   730 | 733 |
| 36986714 | abstract | 35  | marijuana                   | 3483         | Species  |   754 | 763 |
| 36986714 | abstract | 36  | THC                         | MESH:D013759 | Chemical |   781 | 784 |
| 36986714 | abstract | 37  | THC                         | MESH:D013759 | Chemical |   800 | 803 |
| 36986714 | abstract | 38  | Delta9-THC                  | MESH:D013759 | Chemical |   805 | 815 |
| 36986714 | abstract | 39  | mice                        | 10090        | Species  |   838 | 842 |
| 36986714 | abstract | 40  | THC                         | MESH:D013759 | Chemical |   857 | 860 |
| 36986714 | abstract | 41  | CBD                         | MESH:C546797 | Chemical |   909 | 912 |
| 36986714 | abstract | 42  | THC                         | MESH:D013759 | Chemical |   921 | 924 |

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

``` r
mesh <- pubmedr::data_mesh_thesuarus() 
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
pubmedr::data_mesh_trees() |> head() |> knitr::kable()
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
pubmedr::data_pharm_action() |> 
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

Includes embeddings for the \~30K MeSH descriptors, as well as \~15K
embeddings for Supplementary Concept Records (SCR).

``` r
embeddings <- pubmedr::data_mesh_embeddings()

pubmedr::pmed_get_neighbors(x = embeddings,
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

## Odds ends NLP

``` r
library(dplyr)

multiword_dictionary <- pubmedr::data_mesh_thesuarus() |>
  select(TermName) |>         
  filter(grepl(' ', TermName)) |>
  filter(!grepl(',', TermName)) |>
  filter(grepl('^[a-zA-Z0-9 -]*$', TermName)) |>
  pull(TermName) |> tolower()

tif <- pubmedr::pmed_search_pubmed('Medical marijuana') |>
  pull(pmid) |>
  pubmedr::pmed_get_records2() |>
  bind_rows()
```

``` r
dtm_corpus <- tif |>
  rename(doc_id = pmid, text = abstract) |>
  text2df::tif2sentence() |>
  text2df::tif2token() |>
  text2df::token2mwe(mwe = multiword_dictionary) |> 
  text2df::token2df() |>
  mutate(TermName = gsub('_', ' ', tolower(token))) |>
  left_join(pubmedr::data_mesh_thesuarus() |> 
              mutate(TermName = tolower(TermName)), 
            by = c('TermName'))
```

``` r
dtm_mesh <- tif |>
  pull(annotations) |>
  bind_rows() |>
  filter(!is.na(FORM))

df <- dtm_mesh
  
pubtations <- pubmedr::pmed_search_pubmed('Medical marijuana') |>
  pull(pmid) |>
  pubmedr::pmed_get_entities(cores = 3) |>
  data.table::rbindlist() |>
  mutate(DescriptorUI = gsub('MESH:', '', identifier)) |>
  
  left_join(pubmedr::data_mesh_thesuarus() |> 
               filter(RecordPreferredTermYN == 'Y'),
             by = 'DescriptorUI')

## aggregate pubatations and mesh -- just to see -- 
```

``` r
##x <- topics
topics <- dtm_mesh |>
  text2df::df2dtm(document = 'ID', term = 'FORM') |>
  text2df::dtm2topic(n_topics = 30, 
            label_n = 15,
            perplexity = 5)

x1 <- topics |> topic2html(title = 'Medical Marijuana in PubMed') 
```

``` r
knitr::include_graphics("README_files/figure-markdown_github/demo1.png") 
```

<img src="README_files/figure-markdown_github/demo1.png" width="695" />
