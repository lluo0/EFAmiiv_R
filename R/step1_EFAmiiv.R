

step1_EFAmiiv <- function(data,
                          sigLevel = .05,
                          scalingCrit = "sargan+factorloading_R2",
                          correlatedErrors = NULL){

  ##first get selected scaling indicator
  scalingindicator <- select_scalingind(data, sigLevel, scalingCrit,
                                        correlatedErrors = correlatedErrors)
  order_scalingind <- which(colnames(data)==scalingindicator)

  ##then create the first one factor model
  model <- paste0('f1=~', paste0(colnames(data)[order_scalingind]), '+',
                  paste0(colnames(data)[-order_scalingind], collapse = '+'))

  ##add in correlated errors when provided
  if(!is.null(correlatedErrors)){
    model <- paste0(model, '\n', correlatedErrors)
  }
  ##fit model using miivSEM
  fit <- miive(model, data, var.cov = T)

  ##get variables with significant sargans/nonsignificant factor loadings
  ##variables with significant sargans/nonsignificant factor loadings are referred to as 'bad variables'
  badvar <- getbadvar(fit, sigLevel)

  ##retain this one factor model if no more than one bad variable
  if(length(badvar) <=1){
    finalobj <- list(model = model,
                     fit  = fit,
                     num_factor = 1,
                     num_badvar = length(badvar),
                     nextstep = 'no')
  }else{ ##proceed to the next step when more than 1 bad variable present
    goodvarlist <- list()
    goodvar <- setdiff(colnames(data), badvar)
    ##goodvar is a list because it will contain the 'good variables' for each potential factors
    #reorder the good variables so the scaling indicator appears first
    goodvarlist[[1]] <- c(scalingindicator, goodvar[goodvar!=scalingindicator])
    #goodvar[[1]] <- goodvar[[1]][c(match(scalingindicator, goodvar[[1]]), setdiff(order(goodvar[[1]]),match(scalingindicator, goodvar[[1]])))]

    #this can be easily created using goodvar list hence deleted 11.1.2022
    #  #save the part of the model that is good and should be untouched as the first factor for the next step
    # goodmodelpart <- list()
    # goodmodelpart[[1]] <- paste("f1=~", paste(goodvarlist[[1]], collapse = "+"), sep = "")
    # ##this will become a list once we have multiple factors, so does the goodvarlist.

    ##same with badvar, make it a list, as later on different factors can have different bad variables
    # badvarlist <- list()
    # badvarlist[[1]] <- badvar

    finalobj <- list(model = model,
                     fit  = fit,
                     num_factor = 1,
                     num_badvar = length(badvar),
                     varPerFac = goodvarlist,
                     #badvarlist = badvarlist,
                     badvar = badvar,
                     #goodmodelpart = goodmodelpart,
                     nextstep = 'yes',
                     correlatedErrors = correlatedErrors)
  }
  return(finalobj)
}
