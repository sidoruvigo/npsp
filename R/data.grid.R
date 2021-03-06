#--------------------------------------------------------------------
#   data.grid.R (npsp package)
#--------------------------------------------------------------------
#   data.grid   S3 class and methods
#       coords.data.grid(x)
#       coordvalues.data.grid(x)
#       dimnames.data.grid(x)
#       dim.data.grid(x)
#   interp.data.grid()
#   as.data.frame.data.grid(x, data.ind = NULL, coords = FALSE, sp = FALSE, 
#                           row.names = NULL, check.names = coords,  ...) 
#
# PENDENTE:
#   - exemplos
#   - as.data.grid()
#
#   (c) R. Fernandez-Casal         Last revision: Aug 2017
#--------------------------------------------------------------------

#--------------------------------------------------------------------
# data.grid(..., grid = NULL)
# 'Equivalent' to SpatialGridDataFrame-class of sp package
#--------------------------------------------------------------------
#' Gridded data (S3 class "data.grid")
#' 
#' Defines data on a full regular (spatial) grid. 
#' Constructor function of the \code{data.grid}-\code{\link{class}}.
#' @aliases data.grid-class
#' @param  ... vectors or arrays of data with length equal to \code{prod(grid$n)}. 
#' @param  grid a \code{\link{grid.par}}-\code{\link{class}} object (optional).
#' @details If parameter \code{grid.par} is not specified it is set from first argument.
#'
#' S3 "version" of the \code{\link[sp]{SpatialGridDataFrame}}-\code{\link{class}} 
#' of the \pkg{sp} package.
#' @return Returns an object of \code{\link{class}} \code{data.grid}, a list with 
#' the arguments as components.
#' @seealso \code{\link{grid.par}}, \code{\link{binning}}, \code{\link{locpol}}.
#' @export
data.grid <- function(..., grid = NULL) {
#-------------------------------------------------------------------- 
    args <- list(...)
    nargs <- length(args)
    if ( is.null(grid) ) {
        n <- dim( args[[1]] )
        if (is.null(n))
          stop("argument 'grid' (or array data) must be provided.")
          # stop("cannot derive grid parameters from data!")
        grid <- grid.par(n, min = rep(1,length(n)), max = n)
    }
    if (!inherits(grid, "grid.par"))
      stop("argument 'grid' must be of class (or extending) 'grid.par'.")
    # Let's go ...
    n <- grid$n
    index <- which(sapply(args, length) == prod(n))
    if(length(index)==0) 
      stop("no data with length equal to 'prod(grid$n)'")  
    if(length(index)!=nargs)          # "not all arguments have the same length"
      warning("some data with length not equal to 'prod(grid$n)' (ignored)") 
    # NOTA: Seguramente hai unha forma mellor de facer o seguinte...
    dimres <- if(grid$nd > 1) n else NULL  # drop dimension for 1d grid
    result <- args[index]
    seqres <- seq_along(result)
    if (is.null(names(result))) names(result) <- paste("y", seqres, sep="")	
    for (i in seqres) dim(result[[i]]) <- dimres
    # Rematar de construir o obxeto
    result$grid <- grid
    oldClass(result) <- "data.grid"
    return(result)
#--------------------------------------------------------------------
} # data.grid


#' @rdname data.grid
#' @method as.data.frame data.grid
#' @param x a \code{data.grid} object.
#' @param data.ind integer or character vector with the indexes or names of the components.
#' @param coords logical; if \code{TRUE}, the (spatial) coordinates of the object are added. 
#' @param sp logical; if \code{TRUE}, the second dimension of the data is reversed 
#' (as it is stored in \pkg{sp} package). 
#' @param row.names \code{NULL}, column to be used as row names, or vector giving the row names for the data frame.
#' @param check.names logical; if \code{TRUE}, the names of the variables in the data 
#' frame are checked and adjusted if necessary.
#       coords = TRUE, ns <- names(coords) if(any(ns %in% names) ns <- paste("coord", ns, sep=".")
as.data.frame.data.grid <- function(x, data.ind = NULL, coords = FALSE, sp = FALSE, row.names = NULL, check.names = coords,  ...){
  # A botch...
  index <- !sapply(x, is.list) & (sapply(x, length) == prod(dim(x)))
  # verificar dimensiones...
  if (is.null(data.ind)) {
    data.ind <- which(index)
  } else {
    if (!all(index[data.ind], na.rm = TRUE))  stop("Invalid argument 'data.ind'")
  }
  res <- x[data.ind]
  if(sp && (length(dim(x)) > 1)) 
    res <- lapply(res, function(d) revdim(array(d, dim = dim(x)),2))
  res <- lapply(res, as.vector)
  
  if (coords) 
    res <- data.frame(coords(x), res, row.names = row.names, check.names = check.names)
  else  
    res <- data.frame(res, row.names = row.names)
  return(res)        
}


# [R] Reversing one dimension of an array, in a generalized case
# https://stat.ethz.ch/pipermail/r-help/2017-June/thread.html#447298
# Jeff Newmiller jdnewmil at dcn.davis.ca.us 
#' @rdname npsp-internals
#' @keywords internal
revdim <- function(a, d) {
  dims <- attr(a, "dim")
  idxs <- lapply(seq_along(dims),
                 function(dd) {
                   if (d == dd) seq.int(dims[dd], 1, -1)
                   else seq.int(dims[dd])
                 })
  do.call(`[`, c(list(a), idxs))
}