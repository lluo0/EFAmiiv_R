#
#
# stepN_EFAmiiv <- function(data,
#                           sigLevel,
#                           scalingCrit,
#                           stepPrev){
#
#   ##first read in relevant info from the last step
#   badvarlist <- stepPrev$badvarlist
#   goodvarlist <- stepPrev$goodvarlist
#   goodmodelpart <- stepPrev$goodmodelpart
#   correlatedErrors <- stepPrev$correlatedErrors
#   num_factor_new <- stepPrev$num_factor+1
#
#   ##then select the scaling indicator for potential new factor
#   scalingindicator <- select_scalingind_stepN(data,
#                                               sigLevel = sigLevel,
#                                               scalingCrit = scalingCrit,
#                                               stepPrev = stepPrev)
#   #order of the new scaling indicator in the BADVAR
#   badvar_unlist <- unique(unlist(badvarlist))
#   order_scalingind <- which(badvar_unlist==scalingindicator)
#
#   ##then create new model
#   ##all badvars are CROSSLOADED on ALL factors
#   model <- paste0(paste0(sapply(goodmodelpart,
#                          function(x)  #crossload all badvars on all past factors
#                            paste0(x, '+',paste0(badvar_unlist[-order_scalingind], collapse = '+'))),collapse = ' \n '), ' \n ',
#                   #then create a new factor and load all badvars
#                   paste0('f',num_factor_new, '=~', scalingindicator, '+', paste0(badvar_unlist[-order_scalingind], collapse = '+')))
#   ##add in correlated errors when provided
#   if(!is.null(correlatedErrors)){
#     model <- paste0(model, '\n', correlatedErrors)
#   }
#
#   ##fit model using miivSEM
#   ##catch error when model is overidentified!
#   fit <- tryCatch( miive(model = model, data, var.cov = T),
#                    error = function(e)
#                      return(0)) #0 for error
#
#   #####NEED TO DOUBLE CHECK HERE######
#   ###HOW TO BEST HANDLE THIS? RETURN THE MODEL FROM THE PREVIOUS STEP?
#   if(class(fit)!='miive'){
#     stop('Model is overidentified.')
#   }
#
#
#   ##then get new badvars after crossloading
#   newbadvarlist <- getbadvar_crossload(fit, sigLevel, num_factor = num_factor_new)
#
#
#
#
#
#
#
#
# }



stepN_EFAmiiv <- function(data,
                          sigLevel,
                          scalingCrit,
                          stepPrev){

  ##first read in relevant info from the last step
  #badvarlist <- stepPrev$badvarlist
  varPerFac <- stepPrev$varPerFac
  #goodmodelpart <- stepPrev$goodmodelpart
  correlatedErrors <- stepPrev$correlatedErrors
  num_factor_new <- stepPrev$num_factor+1

  ##then select the scaling indicator for potential new factor
  scalingindicator <- select_scalingind_stepN(data,
                                              sigLevel = sigLevel,
                                              scalingCrit = scalingCrit,
                                              stepPrev = stepPrev)
  #order of the new scaling indicator in the BADVAR
  #badvar_unlist <- unique(unlist(badvarlist))
  badvar_unlist <- stepPrev$badvar
  order_scalingind <- which(badvar_unlist==scalingindicator)

  ##then create new model
  ##all badvars first loaded on this new factor
  varPerFac[[num_factor_new]] <- c(scalingindicator, badvar_unlist[-order_scalingind])
  modelpart <- list()
  for(n in 1:num_factor_new){
    modelpart[[n]] <- paste0('f', n, '=~', paste0(varPerFac[[n]], collapse = '+'))
  }
  model <- paste0(modelpart, collapse = '\n')

  # model <- paste0(paste0(goodmodelpart,collapse = ' \n '), ' \n ',
  #                 #then create a new factor and load all badvars
  #                 paste0('f',num_factor_new, '=~', paste0(varPerFac[[num_factor_new]], collapse = '+')))
  ##add in correlated errors when provided
  if(!is.null(correlatedErrors)){
    model <- paste0(model, '\n', correlatedErrors)
  }

  ##fit model using miivSEM
  ##catch error when model is overidentified!
  fit <- tryCatch( miive(model = model, data, var.cov = T),
                   error = function(e)
                     return(0)) #0 for error

  #####NEED TO DOUBLE CHECK HERE######
  ###HOW TO BEST HANDLE THIS? RETURN THE MODEL FROM THE PREVIOUS STEP?
  #kmg: I agree that's probably the best way to handle this, with a warning that this is the last identifiable model.
  if(class(fit)!='miive'){
    stop('Model is overidentified.')
  }

  ##then get new badvars after creating the new factor
  newbadvarlist <- getbadvar_multi(fit, sigLevel, num_factor = num_factor_new, varPerFac)

  ##and new goodvar list
  newgoodvarlist <- Map(setdiff, varPerFac, newbadvarlist)

  ##if newgoodvar contains all variables in the data, then return the model after removing these badvars
  #kmg: just a quick note on the documentation above: are badvars removed if alll vars are good vars? I didn't understand this.
  if(length(unique(unlist(newgoodvarlist))) == ncol(data)){
    modelpart <- list()
    for(n in 1:length(newgoodvarlist)){
      modelpart[[n]] <- paste0('f', n, '=~', paste0(newgoodvarlist[[n]], collapse = '+'))
    }
    model <- paste0(modelpart, collapse = '\n')
    fit <- miive(model = model, data = data, var.cov = T)
    finalobj <- list(model = model,
                     fit = fit,
                     nextstep = 'no')
  } else{
    finalobj <- list(varPerFac = newgoodvarlist,
                     #badvarlist = newbadvarlist,
                     badvar = unique(unlist(newbadvarlist)),
                     correlatedErrors = correlatedErrors,
                     nextstep = 'yes')
  }
  return(finalobj)


}


