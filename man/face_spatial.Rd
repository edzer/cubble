% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/face-spatial.R
\name{face_spatial}
\alias{face_spatial}
\title{Switch a cubble object into the nested form}
\usage{
face_spatial(data)
}
\arguments{
\item{data}{a long cubble object}
}
\value{
a cubble object in the nested form
}
\description{
\code{face_spatial()} turns a long cubble back into a nest cubble and can be seen as
the inverse operation of \code{face_temporal()}.
The nested cubble identifies each row by \code{key} and is suitable
for operations whose output doesn't involve a time index.
}
\examples{
cb_long <- climate_flat \%>\%
  as_cubble(key = id, index = date, coords = c(long, lat)) \%>\%
  face_temporal()

cb_long \%>\%  face_spatial()
}
