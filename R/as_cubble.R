#' @param by only used in `as_cubble.list()` to specify the linking key between spatial and temporal data
#' @rdname cubble-class
#' @importFrom tidyr unchop
#' @importFrom tsibble key_vars index
#' @export
#' @return a cubble object
#' @examples
#' # Declaimer: to make the examples easier, here we first `climate_flat` into
#' # different classes and show how they can be casted into a cubble. This is to
#' # demonstrate if your data come in one of the classes, it can be directly cast
#' # into a cubble. By no mean you need to first transform your data into any of
#' # the following class and then cast it to cubble.
#'
#' # If the data is in a tibble:
#' climate_flat %>%  as_cubble(key = id, index = date, coords = c(long, lat))
#'
#' # If the spatial and temporal information are in two separate tables:
#' library(dplyr)
#' spatial <- climate_flat %>%  select(id:wmo_id) %>%  distinct()
#' temporal <- climate_flat %>%  select(id, date: tmin) %>%  filter(id != "ASN00009021")
#' as_cubble(data = list(spatial = spatial, temporal = temporal),
#'           key = id, index = date, coords = c(long, lat))
#'
#' # If the data is already in a rowwise_df:
#' dt <- climate_flat %>%
#'   tidyr::nest(ts = date:tmin) %>%
#'   dplyr::rowwise()
#' dt %>%  as_cubble(key = id, index = date, coords = c(long, lat))
#'
#' # If the data is already in a tsibble, only need to supply `coords`
#' dt <- climate_flat %>%  tsibble::as_tsibble(key = id, index = date)
#' dt %>%  as_cubble(coords = c(long, lat))
#'
#' # If the data is in netcdf:
#' path <- system.file("ncdf/era5-pressure.nc", package = "cubble")
#' raw <- ncdf4::nc_open(path)
#' dt <- as_cubble(raw, vars = c("q", "z"))
#'
#' # sftime object - example 1
#' if (! requireNamespace("sftime", quietly = TRUE))
#'     stop("package sftime required, please install it first")
#' x_sfc <- sf::st_sfc(
#'   sf::st_point(1:2),
#'   sf::st_point(c(1,3)),
#'   sf::st_point(2:3),
#'   sf::st_point(c(2,1))
#' )
#' x_sftime1 <- sftime::st_sftime(a = 1:4, x_sfc, time = Sys.time()- 0:3 * 3600 * 24)
#' x_sftime1 %>% as_cubble(key = a, index = time)
#'
#' # sftime object - example 2
#' dt <- climate_flat %>%
#'   filter(lubridate::day(date) <= 5, lubridate::month(date) == 1) %>%
#'   sf::st_as_sf(coords = c("long", "lat"), remove = FALSE) %>%
#'   sftime::st_as_sftime()
#' dt %>%
#'   as_cubble(key = id, index = date, coords = c(long, lat))
as_cubble <- function(data, key, index, coords, ...) {
  UseMethod("as_cubble")
}

#' @rdname cubble-class
#' @export
as_cubble.list <- function(data, key, index, coords, by = NULL,
                           output = "auto-match", ...){
  key <- enquo(key)
  index <- enquo(index)
  coords <- enquo(coords)

  test_missing(quo = key, var = "key")
  key_nm <- as_name(key)
  test_missing(quo = index, var = "index")
  # parse coords from a quosure to a string vector
  coords <- as.list(quo_get_expr(coords))[-1]
  coords <- unlist(map(coords, as_string))

  if (!output %in% c("unmatch", "auto-match")){
    cli::cli_abort('Please choose one of the two outputs: "unmatch" and "auto-match"')
  }

  if (length(data) > 2){
    cli::cli_abort("Currently cubble can only take two elements for the list input.")
  }

  # find the common "key" column between spatial and temporal
  # if no shared, parse the `by` argument
  spatial <- data$spatial
  temporal <- data$temporal
  shared <- do.call("intersect", map(data, colnames) %>% setNames(c("x", "y")))

  # if the `by` argument is used,
  # align the joined column in spatial and temporal to the name in spatial
  # correct the key to the name in spatial, if name in temporal is used
  if (!is_null(by)){
    if (by %in% names(temporal) && names(by) %in% names(spatial)){
      # rename the join column to have the same name
      names(temporal)[names(temporal) == by] <- names(by)
    }
    if (key_nm == by) key_mn <- names(by)
    shared <- names(by)
  }

  if (length(shared) == 0){
    cli::cli_abort(
      "Input data need to have either common column or the {.code by} argument specified.")
  }

  if (!key_nm %in% shared){
    cli::cli_abort(
      "Please make sure key is the common column of spatial and temporal data.
      In case the {.code by} argument is used, {.field key} should be either side of the {.code by} argument")
    # shared, key_nm and by should point to the same variable name now
    # use key_nm from now on
  }


  matched_tbl <-  tibble::tibble(
    spatial = intersect(unique(temporal[[key_nm]]), spatial[[key_nm]])
    ) %>%
    mutate(temporal = spatial)
  if (nrow(matched_tbl) == 0) {matched_tbl <- tibble::tibble()}

  # find whether there are unmatched spatial and temporal key level
  slvl <- spatial[[key_nm]]
  tlvl <- temporal[[key_nm]]
  only_spatial <- setdiff(slvl, tlvl)
  only_temporal <- setdiff(tlvl, slvl)
  has_unmatch <- length(only_temporal) != 0 | length(only_spatial) != 0

  if (has_unmatch){
    # construct the unmatching summary
    matching_res <- cubble_automatch(
      spatial = spatial, temporal = temporal,
      key_nm = key_nm, matched_tbl = matched_tbl,
      only_spatial = only_spatial, only_temporal = only_temporal
      )

    # return early with the unmatch summary
    if (output == "unmatch") return(matching_res)

    # inform users about the unmatch
    others <- matching_res$others
    has_t_unmatched <- length(others$temporal) != 0
    has_s_unmatched <- length(others$spatial) != 0
    has_either_unmatched <- has_t_unmatched | has_s_unmatched
    if (has_t_unmatched){
      cli::cli_alert_warning(
        "Some sites in the temporal table don't have spatial information"
        )
    }

    if (has_s_unmatched){
      cli::cli_alert_warning(
        "Some sites in the spatial table don't have temporal information"
        )
    }

    if (has_either_unmatched){
      cli::cli_alert_warning(
        'Use argument {.code output = "unmatch"} to check on the unmatched key'
        )
    }
  }

  out <- suppressMessages(
    dplyr::inner_join(spatial, temporal %>% nest(ts = -key_nm))
  )

  new_cubble(out,
             key = key_nm, index = as_name(index), coords = coords,
             spatial = NULL, form = "nested")
}

#' @rdname cubble-class
#' @export
as_cubble.tbl_df <- function(data, key, index, coords, ...) {
  if (inherits(data, "tbl_ts")){
    key <- sym(tsibble::key_vars(data))
    index <- sym(tsibble::index(data))
  } else{
    key <- enquo(key)
    index <- enquo(index)
  }
  coords <- enquo(coords)
  coords <- names(data)[tidyselect::eval_select(coords, data)]
  # - check lat between -90 to 90
  # - check long between -180 to 180?
  # - give it an attribution on the range? 0 to 360 or -180 to 180

  # check if date is already nested in the list-column
  col_type <- map(data, class)
  listcol_var <- names(col_type)[col_type == "list"]

  if (length(listcol_var) == 0){
    all_vars <- find_invariant(data, !!key)

    out <- data %>%
      tidyr::nest(ts = c(!!!all_vars$variant)) %>%
      dplyr::rowwise()

  } else{
    listcol_var <- listcol_var[1]
    invariant_var <- names(col_type)[col_type != "list"]
    chopped <- data %>%  tidyr::unchop(listcol_var)
    already <- as_name(index) %in% names(chopped$ts)

    out <- data
    variant <- chopped$ts %>%  map_chr(pillar::type_sum)
  }

  new_cubble(out,
             key = as_name(key), index = as_name(index), coords = coords,
             spatial = NULL, form = "nested")
}

#' @rdname cubble-class
#' @export
as_cubble.rowwise_df <- function(data, key, index, coords, ...) {
  key <- enquo(key)
  index <- enquo(index)
  coords <- enquo(coords)

  test_missing(quo = key, var = "key")
  test_missing(quo = index, var = "index")
  test_missing(quo = coords, var = "coords")

  # check presents in the data
  # checks for key
  # checks for index
  # checks for coords
  coords <- names(data)[tidyselect::eval_select(coords, data)]

  # if (any(duplicated(data[[as_name(key)]]))){
  #   abort("Make sure each row identifies a key!")
  # }

  # compute leaves
  #leaves <- as_tibble(data) %>%  tidyr::unnest() %>%  new_leaves(!!key)
  list_col <- get_listcol(data)

  if (length(list_col) == 0){
    abort("Can't identify the list-column, prepare the data as a rowwise_df with a list column")
  } else if (length (list_col) > 2){
    abort("Cubble currently can only deal with at most two list columns")
  } else{
    nested_names <- Reduce(union, map(data[[as_name(list_col)]], names))
    if (any(nested_names == as_name(key))){
      data <- data %>%
        mutate(!!list_col := list(!!ensym(list_col) %>%  select(-!!key)))
    }
  }

  new_cubble(data,
             key = as_name(key), index = as_name(index), coords = coords,
             spatial = NULL, form = "nested")
}

#' @export
as_cubble.sf = function(x, key, index,...) {
	cc = st_coordinates(st_centroid(x))
	colnames(cc) = if (st_is_longlat(x))
			c("long", "lat")
		else
			c("x", "y")
	sf_column = attr(x, "sf_column")
	x = cbind(x, cc)
	x = as_tibble(x)
	key = enquo(key)
	index = enquo(index)
	cu = as_cubble(x, key = !!key, index = !!index, coords = colnames(cc))
	structure(cu, class = c("cubble_df", "sf", setdiff(class(cu), "cubble_df")),
              sf_column = sf_column)
}


#' @export
as_cubble.ncdf4 <- function(data, key, index, coords, vars,
                            lat_range = NULL, long_range = NULL, ...){

  # extract variables
  lat_raw <- extract_longlat(data)$lat
  long_raw <- extract_longlat(data)$long
  time_raw <- extract_time(data)
  var <- extract_var(data, vars)
  lat_idx <- 1:length(lat_raw)
  long_idx <- 1:length(long_raw)

  # subset long lat if applicable
  if (!is.null(lat_range)) {
    lat_idx <- which(lat_raw %in% lat_range)
    lat_raw <- as.vector(lat_raw[which(lat_raw %in% lat_range)])
  }
  if (!is.null(long_range)) {
    long_idx <- which(long_raw %in% long_range)
    long_raw <- as.vector(long_raw[which(long_raw %in% long_range)])
  }
  raw_data <- var$var %>%  map(~.x[long_idx, lat_idx,])

  # define dimension and grid
  dim_order <- c(length(long_raw), length(lat_raw) , length(time_raw), length(var$name))
  latlong_grid <- tidyr::expand_grid(lat = lat_raw, long = long_raw) %>%
    dplyr::mutate(id = dplyr::row_number())
  mapping <- tidyr::expand_grid(var = var$name, time = time_raw) %>%
    tidyr::expand_grid(latlong_grid)

  # restructure data into flat
  data <- array(unlist(raw_data), dim = dim_order) %>%
    as.data.frame.table() %>%
    as_tibble() %>%
    dplyr::bind_cols(mapping) %>%
    dplyr::select(.data$id, .data$long, .data$lat, .data$time, .data$var, .data$Freq) %>%
    dplyr::arrange(.data$id) %>%
    tidyr::pivot_wider(names_from = .data$var, values_from = .data$Freq)

  key <- "id"
  all_vars <- find_invariant(data, !!key)

  out <- data %>%
    tidyr::nest(ts = c(!!!all_vars$variant)) %>%
    dplyr::rowwise()

  new_cubble(out,
             key = key, index = "time", coords = c("long", "lat"),
             spatial = NULL, form = "nested")
}

#' @export
as_cubble.stars <- function(data, key, index, coords, ...){

  # making the assumption that long/lat are the first two dimensions
  # time is the third
  if (is.na(st_raster_type(data))) { # vector data cube
	stopifnot(is.null(data$id), inherits(st_get_dimension_values(data, 1), "sfc"))
    data$id = seq_len(dim(data)[1]) # recycles
    data = st_as_sf(data, long = TRUE)
    key = enquo(key)
    index = enquo(index)
	as_cubble(data, key=!!key, index=!!index)
  } else { # raster data cube
    longlat <- names(stars::st_dimensions(data))[1:2]
    time <- names(stars::st_dimensions(data))[3]

    as_tibble(data) %>%
      mutate(id = as_integer(interaction(x, y))) %>%
      as_cubble(key = id, index = time, coords = longlat)
  }
}


parse_dimension <- function(obj){

    if (!is.null(obj$value)) {
      out <- obj$value
    } else if (is.numeric(obj$from) & is.numeric(obj$to) & inherits(obj$delta, "numeric")){
      out <- seq(obj$offset, obj$offset + (obj$to - 1) * obj$delta, by = obj$delta)
    } else if (!is.na(obj$refsys)){
      if (obj$refsys == "udunits"){
      tstring <- attr(obj$offset, "units")$numerator
      origin <- parse_time(tstring)

      if (is.null(origin))
        cli::cli_abort("The units is currently too complex for {.field cubble} to parse.")

      tperiod <- sub(" .*", "\\1", tstring)
      time <- seq(obj$from,obj$to, as.numeric(obj$delta))
      out <- origin %m+% do.call(tperiod, list(x = floor(time)))
      } else if (obj$refsys == "POSIXct"){
        out <- obj$value
      }
    } else{
      cli::cli_abort("The units is currently too complex for {.field cubble} to parse.")
    }

  out
}

#' @export
as_cubble.sftime <- function(data, key, index, coords, ...){
  #browser()

  key <- enquo(key)
  index <- enquo(index)
  coords <- enquo(coords)

  # here assume the geometry column in an sftime object is always sfc_POINT
  data <- data %>%
    mutate(long = st_coordinates(.)[,1], lat = st_coordinates(.)[,2])

  if (quo_is_missing(coords)){
    coords = quo(c("long", "lat"))
  }

  all_vars <- data %>% find_invariant(!!key)
  spatial <- data %>% select(all_vars$invariant, -!!index) %>% distinct()
  temporal <- as_tibble(data) %>% select(!!key, all_vars$variant, !!index)

  as_cubble(
    list(spatial = spatial, temporal = temporal),
    key = !!key, index = !!index, coords = !!coords)

}





