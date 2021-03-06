
.baseurl <- "https://api.twelvedata.com/time_series"

.get_apikey <- function() {
    ## could add checks but ensure on what values to check for
    apikey <- .pkgenv[["api"]]
    if (apikey == "") stop("No query without key.", call. = FALSE)
    apikey
}

##' Retrieve Time Series Data from \sQuote{twelvedata}
##'
##' This function access time series data from \sQuote{twelvedata}. It requires an API key
##' to be registered and to be supplied either in user-config file (TODO: add simple
##' writer) or an environment variable.
##'
##' The supported API is richer than what the function currently supports, notably with
##' respect to \emph{multiple} symbols in one request. We expect to expand the function to return
##' a list.
##'
##' All suitable optional parameters of the API are now supported. We excluded return as csv as
##' this downloader encompasses that functionality by returning a parsed object.
##'
##' @title Time Series Data Accessor for \sQuote{twelvedata}
##' @param sym (character) A symbol understood as the backend such a stock symbol, foreign
##' exchange pair, or more. See the \sQuote{twelvedata} documentation.
##' @param interval (character) A valid interval designator ranging form \dQuote{1min} to
##' \dQuote{1month}. Currently supported are 1, 5, 15, 30 and 45 minutes, 1, 2, 4 hours (using
##' suffix \sQuote{h}, as well as \dQuote{1day}, \dQuote{1week} and \dQuote{1month}.
##' @param as (optional, character) A selector for the desired output format: one of
##' \dQuote{data.frame} (the default), \dQuote{xts} (requiring the package to be installed),
##' or \dQuote{raw}.
##' @param exchange (optional, character) A selection of the exchange for which data for
##' \dQuote{sym} is requested, default value is unset.
##' @param country (optional, character) A selection of the country exchange for which data
##' for \dQuote{sym} is requested, default value is unset.
##' @param type (optional, character) A valid security type selection, if set it must be one of
##' \dQuote{Stock} (the default), \dQuote{Index}, \dQuote{ETF} or \dQuote{REIT}. Default is
##' unset via the \code{NA} character value. This field may require the premium subscription.
##' @param outputsize (optional, numeric) The requested number of data points with an
##' internal default value of 30 if unset, and a valid range of 1 to 5000; we use \code{NA}
##' as a default argument to signify leaving it unset.
##' @param dp (optional, numeric) The number of decimal places returned on floating point
##' numbers. The value can be between 0 and 11, with a default value of 5.
##' @param order (optional, character) The sort order for the returned time series, must be
##' one of \dQuote{ASC} (the default) or \dQuote{DESC}.
##' @param timezone (optional, character) The timezone of the returned time stamp. This parameter
##' is optional. Possible values are \dQuote{Exchange} (the default) to return the
##' exchange-supplied value, \dQuote{UTC} to use UTC, or a value IANA timezone name such as
##' \dQuote{America/New_York} (see \code{link{OlsonNames}} to see the values R knows). Note
##' that the IANA timezone values are case-sensitive. Note that intra-day data is converted to
##' an R datetime object (the standard \code{POSIXct} type) using the exchange timestamp in
##' the returned metadata, if present.
##' @param start_date (optional, character) The beginning of the time window for which data
##' is requested, can be used with or without \code{end_date}. The format must be a standard
##' ISO 8601 format such as \dQuote{2020-12-31} or \dQuote{2020-12-31T08:30:00}. If an
##' intra-day datetime is specified, use the \code{T} separator, not a space.
##' @param end_date (optional, character) The end of the time window for which data
##' is requested, can be used with or without \code{start_date}. The format must be a standard
##' ISO 8601 format such as \dQuote{2020-12-31} or \dQuote{2020-12-31T08:30:00}. If an
##' intra-day datetime is specified, use the \code{T} separator, not a space.
##' @param previous_close (optional, boolean) A logical switch to select inclusion of the
##' previous close value, defaults to \code{FALSE}.
##' @param apikey (optional character) An API key override, if missing a value cached from
##' package startup is used. The startup looks for either a file in the per-package config
##' directory provided by \code{tools::R_user_dir}, or the \code{TWELVEDATA_API_KEY} variable.
##' @return The requested data is returned in the requested format containing columns for
##' data(time), open, high, low, close, and volume. If the request was unsuccessful,
##' an error message is returned. The date or datetime column is returned parsed as either
##' a \code{Date} or \code{Datetime} where the latter is parsed under the exchange timezone
##' if present. Additional meta data returned from the query is also provided as attributes.
##' @seealso \url{https://twelvedata.com/docs}
##' @examples
##' \dontrun{  # requires API key
##' Sys.setenv(`_R_S3_METHOD_REGISTRATION_NOTE_OVERWRITES_`="false") # suppress load noise
##' data <- time_series("SPY", "5min", 500, "xts")
##' if (requireNamespace("quantmod", quietly=TRUE))
##'    suppressMessages(library(quantmod))   # suppress some noise
##'    chartSeries(data, name=attr(data, "symbol"), theme="white")  # convenient plot for OHLCV
##'    str(data) # compact view of data and meta data
##'
##'    cadusd <- time_series(sym="CAD/USD", interval="1week", outputsize=52.25*20, as="xts")
##'    chart_Series(cadusd, name=attr(data, "symbol"))
##' }
##' @author Dirk Eddelbuettel
time_series <- function(sym,
                        interval = c("1min", "5min", "15min", "30min", "45min",
                                     "1h", "2h", "4h", "1day", "1week", "1month"),
                        as = c("data.frame", "xts", "raw"),
                        exchange = "",
                        country = "",
                        type = c(NA_character_, "Stock", "Index", "ETF", "REIT"),
                        outputsize = NA_character_,
                        dp = 5,
                        order = c("ASC", "DESC"),
                        timezone = NA_character_,
                        start_date = NA_character_,
                        end_date = NA_character_,
                        previous_close = FALSE,
                        apikey) {

    if (missing(apikey)) apikey <- .get_apikey()
    interval <- match.arg(interval)
    as <- match.arg(as)
    type <- match.arg(type)
    order <- match.arg(order)

    qry <- paste0(.baseurl, "?",
                  "symbol=", sym,
                  "&interval=", interval,
                  "&apikey=", apikey)
    if (exchange != "") qry <- paste0(qry, "&exchange=", exchange)
    if (country != "") qry <- paste0(qry, "&country=", country)
    if (!is.na(type)) qry <- paste0(qry, "&type=", type)
    if (!is.na(outputsize)) qry <- paste0(qry, "&outputsize=", outputsize)
    if (dp != 5) qry <- paste0(qry, "&dp=", dp)
    if (order != "ASC") qry <- paste0(qry, "&order=", order)
    if (!is.na(timezone)) qry <- paste0(qry, "&timezone=", timezone)
    if (!is.na(start_date)) qry <- paste0(qry, "&start_date=", start_date)
    if (!is.na(end_date)) qry <- paste0(qry, "&end_date=", end_date)
    if (previous_close) qry <- paste0(qry, "&previous_close=true")

    res <- RcppSimdJson::fload(qry)

    if (res$status != "ok") stop(res$message, call. = FALSE)

    if (as == "raw") return(res)

    dat <- res$values
    if (grepl(".*(min|h)$", interval)) {
        if ("exchange_timezone" %in% names(res$meta))
            dat[, 1] <- as.POSIXct(dat[, 1], tz=res$meta$exchange_timezone)
        else
            dat[, 1] <- as.POSIXct(dat[, 1])
    } else {
        dat[, 1] <- as.Date(dat[, 1])
    }
    for (i in seq(2, ncol(dat))) {
        dat[, i] <- as.numeric(dat[,i])
    }
    if (as == "xts" && requireNamespace("xts", quietly=TRUE)) {
        dat <- xts::xts(dat[,-1], order.by=dat[,1])
    }
    for (n in names(res$meta)) attr(dat, n) <- res$meta[[n]]
    attr(dat, "accessed") <- format(Sys.time())
    dat
}
