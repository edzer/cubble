#' Australia climate data - 639 stations
#'
#' Daily measure on precipitation (prcp) maximum temperature (tmax), and
#' minimum temperature (tmin) in 2020 for 639 stations. \code{stations} and
#' \code{climate} are the separate spatial and temporal objects while
#' \code{climate_aus} is the combined cubble object.
#' @details
#' \describe{
#'   \item{id}{station id}
#'   \item{lat}{latitude of the station}
#'   \item{long}{longitude of the station}
#'   \item{elev}{elevation of the station}
#'   \item{name}{station name}
#'   \item{wmo_id}{the world meteorological organisation (WMO) station number}
#'   \item{ts}{a list-column that nests all the time-wise measures: date, prcp, tmax, and tmin}
#' }
#' @examples
#' climate_aus %>% face_temporal() %>% face_spatial()
#' @seealso climate_subset climate_flat
"climate_aus"

#' Australia climate data - 30 stations
#'
#' Daily measure on precipitation (prcp) maximum temperature (tmax), and
#' minimum temperature (tmin) in 2020 for 30 stations.
#' @format A cubble object
#' \describe{
#'   \item{id}{station id}
#'   \item{lat}{latitude of the station}
#'   \item{long}{longitude of the station}
#'   \item{elev}{elevation of the station}
#'   \item{name}{station name}
#'   \item{wmo_id}{the world meteorological organisation (WMO) station number}
#'   \item{ts}{a list-column that nests all the time-wise measures: date, prcp, tmax, and tmin}
#' }
#' @examples
#' climate_subset %>% face_temporal()
#' @seealso climate_aus climate_flat
"climate_subset"


#' Australia climate data - 5 stations
#'
#' Daily measure on precipitation (prcp) maximum temperature (tmax), and
#' minimum temperature (tmin) in 2020 for 5 stations.
#'
#' @format A tibble object with 155 rows and 10 columns
#' \describe{
#'   \item{id}{station id}
#'   \item{lat}{latitude of the station}
#'   \item{long}{longitude of the station}
#'   \item{elev}{elevation of the station}
#'   \item{name}{station name}
#'   \item{wmo_id}{the world meteorological organisation (WMO) station number}
#'   \item{date}{the date that prcp, tmax, and tmin recorded}
#'   \item{prcp}{precipitation}
#'   \item{tmax}{maximum temperature}
#'   \item{tmin}{minimum temperature}
#' }
#' @seealso climate_aus climate_subset
#' @rdname climate_flat
#' @examples
#' climate_flat %>% as_cubble(key = id, index = date, coords = c(long, lat))
"climate_flat"

#'@rdname climate_flat
"stations"

#'@rdname climate_flat
"climate"



#' Australia river data
"river"


#' Daily precipitation data from 2016 to 2020
"prcp_aus"

#' Victoria and Tasmania daily maximum temperature for 1970 - 1975 and 2016 - 2020
"tmax_hist"
