cumul.rma.peto <- function(x, order, digits, transf, targs, progbar=FALSE, ...) {

   mstyle <- .get.mstyle("crayon" %in% .packages())

   if (!inherits(x, "rma.peto"))
      stop(mstyle$stop("Argument 'x' must be an object of class \"rma.peto\"."))

   na.act <- getOption("na.action")

   if (!is.element(na.act, c("na.omit", "na.exclude", "na.fail", "na.pass")))
      stop(mstyle$stop("Unknown 'na.action' specified under options()."))

   if (missing(order))
      order <- NULL

   if (missing(digits))
      digits <- x$digits

   if (missing(transf))
      transf <- FALSE

   if (missing(targs))
      targs <- NULL

   #########################################################################

   if (is.null(order))
      order <- seq_len(x$k.f)

   ai.f   <- x$ai.f[order]
   bi.f   <- x$bi.f[order]
   ci.f   <- x$ci.f[order]
   di.f   <- x$di.f[order]
   yi.f   <- x$yi.f[order]
   vi.f   <- x$vi.f[order]
   not.na <- x$not.na[order]
   slab   <- x$slab[order]

   beta  <- rep(NA_real_, x$k.f)
   se    <- rep(NA_real_, x$k.f)
   zval  <- rep(NA_real_, x$k.f)
   pval  <- rep(NA_real_, x$k.f)
   ci.lb <- rep(NA_real_, x$k.f)
   ci.ub <- rep(NA_real_, x$k.f)
   QE    <- rep(NA_real_, x$k.f)
   QEp   <- rep(NA_real_, x$k.f)

   ### note: skipping NA cases

   if (progbar)
      pbar <- txtProgressBar(min=0, max=x$k.f, style=3)

   for (i in seq_len(x$k.f)) {

      if (progbar)
         setTxtProgressBar(pbar, i)

      if (!not.na[i])
         next

      res <- try(suppressWarnings(rma.peto(ai=ai.f, bi=bi.f, ci=ci.f, di=di.f, add=x$add, to=x$to, drop00=x$drop00, subset=seq_len(i))), silent=TRUE)

      if (inherits(res, "try-error"))
         next

      beta[i]  <- res$beta
      se[i]    <- res$se
      zval[i]  <- res$zval
      pval[i]  <- res$pval
      ci.lb[i] <- res$ci.lb
      ci.ub[i] <- res$ci.ub
      QE[i]    <- res$QE
      QEp[i]   <- res$QEp

   }

   if (progbar)
      close(pbar)

   #########################################################################

   ### if requested, apply transformation function

   if (.isTRUE(transf)) ### if transf=TRUE, apply exp transformation to ORs
      transf <- exp

   if (is.function(transf)) {
      if (is.null(targs)) {
         beta  <- sapply(beta, transf)
         se    <- rep(NA,x$k.f)
         ci.lb <- sapply(ci.lb, transf)
         ci.ub <- sapply(ci.ub, transf)
      } else {
         beta  <- sapply(beta, transf, targs)
         se    <- rep(NA,x$k.f)
         ci.lb <- sapply(ci.lb, transf, targs)
         ci.ub <- sapply(ci.ub, transf, targs)
      }
      transf <- TRUE
   }

   ### make sure order of intervals is always increasing

   tmp <- .psort(ci.lb, ci.ub)
   ci.lb <- tmp[,1]
   ci.ub <- tmp[,2]

   #########################################################################

   if (na.act == "na.omit") {
      out <- list(estimate=beta[not.na], se=se[not.na], zval=zval[not.na], pval=pval[not.na], ci.lb=ci.lb[not.na], ci.ub=ci.ub[not.na], Q=QE[not.na], Qp=QEp[not.na])
      out$slab <- slab[not.na]
   }

   if (na.act == "na.exclude" || na.act == "na.pass") {
      out <- list(estimate=beta, se=se, zval=zval, pval=pval, ci.lb=ci.lb, ci.ub=ci.ub, Q=QE, Qp=QEp)
      out$slab <- slab
   }

   if (na.act == "na.fail" && any(!x$not.na))
      stop(mstyle$stop("Missing values in results."))

   out$digits    <- digits
   out$transf    <- transf
   out$slab.null <- x$slab.null
   out$level     <- x$level
   out$measure   <- x$measure
   out$test      <- x$test

   attr(out$estimate, "measure") <- x$measure

   class(out) <- c("list.rma", "cumul.rma")
   return(out)

}
