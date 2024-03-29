% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data_mesh_trees.R
\name{data_mesh_trees}
\alias{data_mesh_trees}
\title{Download and Load MeSH Trees Data}
\usage{
data_mesh_trees(force_download = FALSE)
}
\arguments{
\item{force_download}{A logical value indicating whether to force re-downloading 
of the data even if it already exists locally.}
}
\value{
A data frame containing the MeSH Trees data.
}
\description{
This function downloads and loads the MeSH (Medical Subject Headings) Trees data
from a specified URL. The data is stored locally for future use. If the data already 
exists locally, the download can be skipped unless `force_download` is set to `TRUE`.
}
\examples{
\donttest{
if (interactive()) {
  # Code that downloads data or performs other interactive-only operations
  data <- data_mesh_embeddings()
}
}
}
