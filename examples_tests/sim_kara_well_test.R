# library(cateSurvival)
# devtools::install_github("jlstiles/SDE_transport")
# library(Simulations)
library(SDEtransport)
# Functions to generate data for transport:

# make W different for the two sites:
n=1e6

f_W = function(n) {
  W1 = rbinom(n, 1, 0.5)
  W2 = rbinom(n, 1, 0.4 + 0.2 * W1)
  data.frame(W1 = W1, W2 = W2)
}

W = f_W(n)
f_S = function(W) {
  with(W, plogis(W1 - W2 + 0.7))
}
# 
# W = f_W(n)
# f_S = function(W) {
#   with(W, plogis(W1 - W2 + 0.7))
# }

P_SW = f_S(W)
S = rbinom(n,1,P_SW)
mean(S)
hist(P_SW, breaks = 200)
max(P_SW)
min(P_SW)
# predict(glm(S~W1, data = W, family = binomial()), type = 'response')[S==1][1:100]/P_SW[S==1][1:100]
# predict(glm(S~W1, data = W, family = binomial()), type = 'response')[S==0][1:100]/P_SW[S==0][1:100]
# P_SW[S==1][1:100]
# make a pscore model

f_A = function(S,W) {
  df = cbind(S = S, W)
  with(df, plogis(-0.6 * S - 0.7 * W1 - W2 + 1))
}

pscores = f_A(S,W)
max(pscores)
min(pscores)
hist(pscores, 200)
A = rbinom(n, 1, pscores)
mean(A)
# make a intermediate confounder model

f_Z = function(A,S,W) {
  df = cbind(S=S, W, A = A)
  with(df, plogis(0.1 * S - 0.4 * W1 + 0.3 * W2 + 1 * A - 0.3))
}

pzscores = f_Z(A,S,W)
hist(pzscores,200)
Z = rbinom(n, 1, pzscores)
max(pzscores)
min(pzscores)
# make an M model according to the restrictions

f_M = function(Z,W,S) {
  df = cbind(S=S, W, Z = Z)
  # with(df, plogis(5*Z*S*W1 - 4))
  with(df, plogis(-0.14 * S - 1 * W1 + 0.5 * W2 + 1.2 * Z +  0.1))
}

Mscores = f_M(Z,W,S)
hist(Mscores, 200)
M = rbinom(n, 1, Mscores)
mean(M)
max(Mscores)
min(Mscores)

# make a Y model according to the restrictions
# f_Y = function(M,Z,W) {
#   df = cbind(M=M, Z = Z, W)
#   with(df, plogis(6*M - Z - 3-.2*W1))
# }

f_Y = function(M,Z,W) {
  df = cbind(M=M, Z = Z, W)
  with(df, plogis(1*M + 1.5*W1 - .37*W2 + 1*Z - 1))
}

Yscores = f_Y(M,Z,W)
Y = rbinom(n, 1, Yscores)
hist(Yscores, 200)
min(Y*log(Yscores)+(1-Y)*log(1-Yscores))
mean(Y)
max(Yscores)
# pack these functions into a DGP
func_list = list(f_W = f_W, f_S = f_S, f_A = f_A, f_Z = f_Z, f_M = f_M, f_Y = f_Y)


covariates = list(covariates_S = c("W1","W2"),
                  covariates_A = c("S","W1","W2"),
                  covariates_Z = c("S","A","W1","W2"),
                  covariates_M = c("Z","W1","W2"),
                  covariates_Y = c("M","Z","W1","W2"),
                  covariates_QZ = c("S","W1","W2"))


# p = sim_kara(100, covariates, truth = func_list, B=NULL)
# c(p$CI_SDE, p$CI_SDE_1s,p$CI_SDE_iptw,p$SDE_0, p$SE_SDE_0)
# c(p$CI_SDE, p$CI_SDE_1s,p$CI_SDE_iptw,p$SDE_0, p$SE_SDE_0)[3]-
#   c(p$CI_SDE, p$CI_SDE_1s,p$CI_SDE_iptw,p$SDE_0, p$SE_SDE_0)[2]
# 
# c(p$CI_SIE, p$CI_SIE_1s,p$CI_SIE_iptw,p$SIE_0, p$SE_SIE_0)
# c(p$CI_SIE, p$CI_SIE_1s,p$CI_SIE_iptw,p$SIE_0, p$SE_SIE_0)[3]-
#   c(p$CI_SIE, p$CI_SIE_1s,p$CI_SIE_iptw,p$SIE_0, p$SE_SIE_0)[2]

sim_kara = function(n, covariates, truth, B = NULL) {

  data = gendata.SDEtransport(n, 
                              f_W = truth$f_W, 
                              f_S = truth$f_S, 
                              f_A = truth$f_A, 
                              f_Z = truth$f_Z, 
                              f_M = truth$f_M, 
                              f_Y = truth$f_Y)
  SDE_tmle4(data, sl = NULL, covariates= covariates, truth = truth,
            truncate = list(lower =.0001, upper = .9999), glm_only = TRUE,
            B=B)
}

library(parallel)

B = 1000
n=100

res100_well = mclapply(1:B, FUN = function(x) sim_kara(n, covariates, func_list), 
                       mc.cores = getOption("mc.cores", 20L))

save(res100_well, func_list, covariates, file = "test/res100_well.RData")

B = 1000
n=500

res500_well = mclapply(1:B, FUN = function(x) sim_kara(n, covariates, func_list), 
                       mc.cores = getOption("mc.cores", 20L))

save(res500_well, func_list, covariates, file = "test/res500_well.RData")

B = 1000
n=5000

res5000_well = mclapply(1:B, FUN = function(x) sim_kara(n, covariates, func_list), 
                        mc.cores = getOption("mc.cores", 20L))

save(res5000_well, func_list, covariates, file = "test/res5000_well.RData")

B = 500
n=5000
