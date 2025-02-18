% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data.R
\docType{data}
\name{climate_aus}
\alias{climate_aus}
\title{Australia climate data - 639 stations}
\format{
An object of class \code{cubble_df} (inherits from \code{rowwise_df}, \code{tbl_df}, \code{tbl}, \code{data.frame}) with 639 rows and 7 columns.
}
\usage{
climate_aus
}
\description{
Daily measure on precipitation (prcp) maximum temperature (tmax), and
minimum temperature (tmin) in 2020 for 639 stations. \code{stations} and
\code{climate} are the separate spatial and temporal objects while
\code{climate_aus} is the combined cubble object.
}
\details{
\describe{
\item{id}{station id}
\item{lat}{latitude of the station}
\item{long}{longitude of the station}
\item{elev}{elevation of the station}
\item{name}{station name}
\item{wmo_id}{the world meteorological organisation (WMO) station number}
\item{ts}{a list-column that nests all the time-wise measures: date, prcp, tmax, and tmin}
}
}
\examples{
climate_aus \%>\% face_temporal() \%>\% face_spatial()
}
\seealso{
climate_subset climate_flat
}
\keyword{datasets}
