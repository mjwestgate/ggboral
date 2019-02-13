# function to return coefficients etc for a (single) specified predictor
calc_coefs <- function(
  x,
  covname,
  # labely = NULL,
  est = "median"
){

  if (!is.null(labely))
      if (!(length(labely) == nrow(x$X.coefs.median)))
          stop("If labely is not NULL, then it must be a vector as long as the number of rows in x$X.coefs.median (number of species). Thanks!")
  if (!(covname %in% colnames(x$X.coefs.mean)))
      stop("covname not found among the covariates in the boral object x")

  # new code
  lci <- x$hpdintervals$X.coefs[, covname, "lower"]
  uci <- x$hpdintervals$X.coefs[, covname, "upper"]

  data <- data.frame(
    labels = NA,
    x = x[[paste0("X.coefs.", est)]][, covname],
    x0 = lci,
    x1 = uci,
    y = rev(seq_len(nrow(x$X.coefs.median))),
    overlaps_zero = FALSE,
    stringsAsFactors = FALSE
  )
  rownames(data) <- NULL
  data$overlaps_zero[lci < 0 & uci > 0] <- TRUE
  # if(is.null(labely)) {
    data$labels <- rownames(x$X.coefs.mean)
  # }else{
  #   data$labels <- labely
  # }

  return(data)
}


# a user-called function to create a data.frame of predictions for 1+ variables
# this can then be passed to ggcoefs
boral_coefs <- function(
  x,
  covname,
  # labely = NULL,
  est = "median"
){

  if(missing(covname)){
    covname <- colnames(x$X.coefs.mean)
  }else{
    if(is.null(covname)){
      covname <- colnames(x$X.coefs.mean)
    }
  }

  if(length(covname) > 1){
    result_list <- lapply(covname, function(a){
      calc_coefs(a, x, labely, est)
    })
    result <- data.frame(
      covname = rep(
        covname,
        each = nrow(x$X.coefs.mean)
      ),
      do.call(rbind, result_list),
      stringsAsFactors = FALSE
    )
  }else{
    result <- calc_coefs(covname, x, labely, est)
  }
  return(result)
}


# function to draw ggplot versions of the caterpillar plots returned by boral::coefsplot
# note that ggplot is returned, so extra ggplot2 functions can be added
boral_coefsplot <- function (
  x,
  covname,
  # labely = NULL, # add in again later
  est = "median"
){

  if(missing(x)){
    stop("x is missing, with no default")
  }

  if(missing(covname)){
    covname <- colnames(x$X.coefs.mean)
  }else{
    if(is.null(covname)){
      covname <- colnames(x$X.coefs.mean)
    }
  }

  if(any(c("boral", "data.frame") %in% class(x))){
    if(class(x) == "data.frame"){
      data <- x
    }else{
      data <- boral_coefs(x, covname, est)
    }
  }else{
    stop("boral_coefsplot only accepts objects of class 'boral' or 'data.frame'.")
  }

  # draw plot
  object <- ggplot(data, aes(x = x, y = y, color = overlaps_zero)) +
    scale_y_continuous(
      breaks = data$y,
      labels = data$labels,
      name = ""
    ) +
    xlab(covname) +
    geom_vline(xintercept = 0, linetype = "dashed") +
    geom_errorbarh(aes(xmin = x0, xmax = x1)) +
    geom_point() +
    theme_bw()

  if(length(covname) > 1){
    return(object + facet_wrap( ~ covname, scales = "free_x"))
  }else{
    return(object)
  }
}