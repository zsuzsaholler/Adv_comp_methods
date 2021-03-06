# define kNN function
# if type = "train", features = x-vars, labels = y-vars, memory = NULL
# if type = "predict", features = new x-vars, labels = y-var (training), memory = x-var (training)

kNN.predict <- function(features, labels, memory = NULL, k = 1, p = 2, type='train') {
  
  # test the inputs
  library(plyr)
  library(assertthat)
  not_empty(features) 
  not_empty(labels)
  if (type == "train") {
    assert_that(nrow(features) == length(labels))
  }
  is.string(type)
  assert_that(type %in% c("train", "predict"))
  is.count(k)
  assert_that(p %in% c(1, 2, Inf))
  if (type == "predict") {
    assert_that(not_empty(memory) & 
                  ncol(memory) == ncol(features) & 
                  nrow(memory) == length(labels))
  }
  
  # Compute the distance between each point and all others 
  noObs <- nrow(features)
  noVars <- ncol(features)
  
  # if we are making predictions on the test set based on the memory, 
  # we compute distances between each test observation and observations
  # in our memory
  if (type == "train") {
    distMatrix <- matrix(NA, noObs, noObs)
    for (obs in 1:noObs) {
      
      # getting the probe for the current observation
      probe <- as.numeric(features[obs,])
      probeExpanded <- matrix(probe, nrow = noObs, ncol = noVars, byrow = TRUE)
      
      # computing distances between the probe and exemplars in the
      # training X
      if (p %in% c(1,2)) {
        distMatrix[obs, ] <- (rowSums((abs(features -  probeExpanded))^p) )^(1/p)
      } else if (p==Inf) {
        distMatrix[obs, ] <- apply(abs(features - probeExpanded), 1, max)
      }  
    }
  } else if (type == "predict") {
    noMemory <- nrow(memory) 
    distMatrix <- matrix(NA, noObs, noMemory)
    for (obs in 1:noObs) {
      
      # getting the probe for the current observation
      probe <- as.numeric(features[obs,])
      probeExpanded <- matrix(probe, nrow = noMemory, ncol = noVars, byrow = TRUE)
      
      # computing distances between the probe and exemplars in the memory
      if (p %in% c(1,2)) {
        distMatrix[obs, ] <- (rowSums((abs(memory - probeExpanded))^p) )^(1/p)
      } else if (p==Inf) {
        distMatrix[obs, ] <- apply(abs(memory - probeExpanded), 1, max)
      }  
    }
  }
  # Sort the distances in increasing numerical order and pick the first 
  # neighbours for point 1 are in COLUMN 1
  neighbors <- apply(distMatrix, 1, order) 
  
  # Compute and return the most frequent class in the k nearest neighbors - ties broken randomly
  predictedClasses <- rep(NA, noObs)
  prob <- rep(NA, noObs)
  for (obs in 1:noObs) {
    classCounts <- plyr::count(labels[neighbors[1:k, obs]])
    possiblePredClasses <- classCounts[classCounts$freq == max(classCounts$freq),1]
    predictedClasses[obs] <- possiblePredClasses[sample(length(possiblePredClasses),1)] #for ties (which is possible with >2 classes)   
    prob[obs] <- max(classCounts$freq)/k
  }
  
  # examine the performance
  if (type == "train") {
    errorCount <- table(predictedClasses, labels)
    accuracy <- mean(predictedClasses == labels)
  } else if (type == "predict") {
    errorCount <- NA
    accuracy <- NA
  }
  
  # return the results
  return(list(predLabels = predictedClasses, 
              prob = prob,
              accuracy = accuracy,
              errorCount = errorCount))
}

dist.predict <- function(features, memory = NULL, p = 2, type='train') {
  
  # test the inputs
  library(plyr)
  library(assertthat)
  not_empty(features) 
  is.string(type)
  assert_that(type %in% c("train", "predict"))
  assert_that(p %in% c(1, 2, Inf))
  if (type == "predict") {
    assert_that(not_empty(memory) & 
                  ncol(memory) == ncol(features))
  }
  
  # Compute the distance between each point and all others 
  noObs <- nrow(features)
  noVars <- ncol(features)
  
  # if we are making predictions on the test set based on the memory, 
  # we compute distances between each test observation and observations
  # in our memory
  if (type == "train") {
    distMatrix <- matrix(NA, noObs, noObs)
    for (obs in 1:noObs) {
      
      # getting the probe for the current observation
      probe <- as.numeric(features[obs,])
      probeExpanded <- matrix(probe, nrow = noObs, ncol = noVars, byrow = TRUE)
      # computing distances between the probe and exemplars in the
      # training X
      if (p %in% c(1,2)) {
        distMatrix[obs, ] <- (rowSums((abs(features -  probeExpanded))^p) )^(1/p)
      } else if (p==Inf) {
        distMatrix[obs, ] <- apply(abs(features - probeExpanded), 1, max)
      }  
    }
  } else if (type == "predict") {
    noMemory <- nrow(memory) 
    distMatrix <- matrix(NA, noObs, noMemory)
    for (obs in 1:noObs) {
      
      # getting the probe for the current observation
      probe <- as.numeric(features[obs,])
      probeExpanded <- matrix(probe, nrow = noMemory, ncol = noVars, byrow = TRUE)
      
      # computing distances between the probe and exemplars in the memory
      if (p %in% c(1,2)) {
        distMatrix[obs, ] <- (rowSums((abs(memory - probeExpanded))^p) )^(1/p)
      } else if (p==Inf) {
        distMatrix[obs, ] <- apply(abs(memory - probeExpanded), 1, max)
      }  
    }
  }
  
  # return the results
  return(distMatrix)
}

kNN2.predict <- function( distMatrix, labels, k = 1) {
  
  # test the inputs
  library(plyr)
  library(assertthat)
  not_empty(labels)
  assert_that(ncol(distMatrix) == length(labels))
  is.count(k)
  
  # Compute the distance between each point and all others 
  noObs <- nrow(distMatrix)
  
  # Sort the distances in increasing numerical order and pick the first 
  # neighbours for point 1 are in COLUMN 1
  neighbors <- apply(distMatrix, 1, order) 
  
  # Compute and return the most frequent class in the k nearest neighbors - ties broken randomly
  predictedClasses <- rep(NA, noObs)
  prob <- rep(NA, noObs)
  for (obs in 1:noObs) {
    classCounts <- plyr::count(labels[neighbors[1:k, obs]])
    possiblePredClasses <- classCounts[classCounts$freq == max(classCounts$freq),1]
    predictedClasses[obs] <- possiblePredClasses[sample(length(possiblePredClasses),1)] #for ties (which is possible with >2 classes)   
    prob[obs] <- max(classCounts$freq)/k
  }

  # return the results
  return(list(predLabels = predictedClasses, 
              prob = prob))
}