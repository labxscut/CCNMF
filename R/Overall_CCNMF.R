# whole progress of running CCNMF

Integrate_CCNMF <- function(CNVmatrix_input, RNAmatrix_input, ncluster){
  # Remove all 0 rows in CNVmatrix and RNAmatrix
  label_mean1 <- apply(CNVmatrix_input, 1, mean)
  index_mean1 <- which(label_mean1 != 0)
  CNVmatrix_input <- CNVmatrix_input[index_mean1, ]
  RNAmatrix_input <- RNAmatrix_input[index_mean1, ]
  label_mean2 <- apply(RNAmatrix_input, 1, mean)
  index_mean2 <- which(label_mean2 != 0)
  CNVmatrix_input <- CNVmatrix_input[index_mean2, ]
  RNAmatrix_input <- RNAmatrix_input[index_mean2, ]
  
  # Run NMF on scDNA matrix and scRNA matrix respectively, cost much time for large matrix
  resCNV <- nmf(CNVmatrix_input, ncluster)
  W10 <- resCNV@fit@W
  H10 <- resCNV@fit@H
  
  resRNA <- nmf(RNAmatrix_input, ncluster)
  W20 <- resRNA@fit@W
  H20 <- resRNA@fit@H
  
  # Construct the identy matrix as copuled matrix, or use an informative matrix 
  CoupledMatrix <- as.matrix(diag(dim(CNVmatrix_input)[1]))
  
  # Initialize lambda1 and lambda2 by seting the items in object function in the same order
  par <- default_parameters_order(CNVmatrix_input, W10, H10, RNAmatrix_input, W20, H20, CoupledMatrix)
  lambda1 <- par[1]
  lambda2 <- par[2]
  
  ResultsCCNMF <- run_CCNMF(ncluster, RNAmatrix_input, CNVmatrix_input, CoupledMatrix, lambda1, lambda2)
  
  H1 <- ResultsCCNMF[[1]]
  H2 <- ResultsCCNMF[[2]]
  
  ## Normalize the H1 and H2
  m1 <- matrix(0, nrow <- ncluster, ncol <- ncluster)
  m2 <- matrix(0, nrow <- ncluster, ncol <- ncluster)
  for (i in 1:ncluster){
    m1[i, i] <- sqrt(sum(H1[, i]^2))
    m2[i, i] <- sqrt(sum(H2[, i]^2))
  }
  
  H1 <- solve(m1) %*% H1
  H2 <- solve(m2) %*% H2
  S1 <- apply(H1, 2, function(x){which(x == max(x))})
  S2 <- apply(H2, 2, function(x){which(x == max(x))})
  
  table(S1)
  table(S2)
  ResultsCCNMF[[5]] <- S1
  ResultsCCNMF[[6]] <- S2
  
  saveRDS(S1, file='S1.rds')
  saveRDS(S2, file='S2.rds')
  
  RNADE <- DiffExp(RNAmatrix_input, S2)
  commonDE <- RNADE[[3]][1:10]
  # DNADE <- DiffExp(CNVmatrix_input, S1)
  # commonDE <- DNADE[[3]][1:10]
  X <- CNVmatrix_input
  D <- CNVmatrix_input[commonDE, ]
  a <- median(D)
  b <- max(D)
  c <- min(D)
  X1 <- (CNVmatrix_input-a)/(b - a)
  X2 <- (CNVmatrix_input-a)/(a- c)
  
  X[which(CNVmatrix_input > a)] <- X1[which(CNVmatrix_input > a)] * 2
  X[which(CNVmatrix_input <= a)] <- X2[which(CNVmatrix_input <= a)] * 2
  
  RNAmatrix_input <- as.matrix(RNAmatrix_input)
  PlotMainResult(X, RNAmatrix_input, ResultsCCNMF, commonDE)
  ResultsCCNMF[[7]] <- commonDE
  return(ResultsCCNMF)
}
