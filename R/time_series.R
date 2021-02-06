
.baseurl <- "https://api.twelvedata.com/time_series"

.get_apikey <- function() {
    ## could add checks but ensure on
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
##' respect to \emph{multiple} symbols in one request. We expect to expand the function.
##'
##' @title Time Series Data Accessor for \sQuote{twelvedata}
##' @param sym (character) A symbol understood as the backend such a stock symbol, foreign
##' exchange pair, or more. See the \sQuote{twelvedata} documentation.
##' @param interval (character) A valid interval designator ranging form \dQuote{1min} to
##' \dQuote{1month}. Currently supported are 1, 5, 15, 30 and 45 minutes, 1, 2, 4 hours (using
##' suffix \sQuote{h}, as well as \dQuote{1day}, \dQuote{1week} and \dQuote{1month}.
##' @param outputsize (numeric) The requested number of data points, defaults to 30, and bounded
##' by 1 and 500.
##' @param as (character) A selector for the desired output format: one of \dQuote{data.frame}
##' (the default), \dQuote{xts} (requiring the package to be installed), or \dQuote{raw}.
##' @param apikey (optional character) An API key override, if missing a value cached from
##' package startup is used. The startup looks for either a file in the per-package config
##' directory provided by \code{tools::R_user_dir}, or the \code{TWELVEDATA_API_KEY} variable.
##' @return The requested data is returned in the requested format containing columns for
##' data(time), open, high, low, close, and volume. If the request was unsuccessful,
##' an error message is returned. The date or datetime column is returned parsed using
##' \code{anytime} if the package is installed.
##' @seealso \url{https://twelvedata.com/docs}
##' @examples
##' \dontrun{  # requires API key
##' data <- time_series("SPY", "5min", 500, "xts")
##' if (requireNamespace("quantmod", quietly=TRUE))
##'    chartSeries(data)  # convenient plot function for OHLCV data
##' }
##' @author Dirk Eddelbuettel
time_series <- function(sym,
                        interval=c("1min", "5min", "15min", "30min", "45min",
                                   "1h", "2h", "4h", "1day", "1week", "1month"),
                        outputsize=30,
                        as=c("data.frame", "xts", "raw"),
                        apikey) {

    if (missing(apikey)) apikey <- .get_apikey()
    interval <- match.arg(interval)
    as <- match.arg(as)

    qry <- paste0(.baseurl, "?",
                  "symbol=", sym,
                  "&interval=", interval,
                  "&outputsize=", outputsize,
                  "&apikey=", apikey)
    res <- RcppSimdJson::fload(qry)
    if (res$status != "ok") stop(res$message, call. = FALSE)

    if (as == "raw") return(res)

    df <- res$value
    print(class(df))
    if (requireNamespace("anytime", quietly=TRUE)) {
        if (grepl(".*(min|h)$", interval)) {
            df[, 1] <- anytime::anytime(df[, 1])
        } else {
            df[, 1] <- anytime::anydate(df[, 1])
        }
    }
    for (i in seq(2, ncol(df))) {
        df[, i] <- as.numeric(df[,i])
    }
    for (n in names(res$meta)) attr(df, n) <- res$meta[[n]]
    attr(df, "accessed") <- format(Sys.time())
    if (as == "xts" && requireNamespace("xts", quietly=TRUE)) {
        xts::xts(df[,-1], order.by=df[,1])
    } else {
        df
    }
}