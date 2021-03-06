library(SDEtransport)

boots = 500
type = "YZmis"
load("func_forms.RData")

if (type == "YMmis") {
  func_list = func_formsYM$func_listYMmis
  forms = func_formsYM$formsYMmis
}

if (type == "YSmis") {
  func_list = func_formsYS$func_listYSmis
  forms = func_formsYS$formsYMmis
}

if (type == "YZmis") {
  func_list = func_formsYZ$func_listYZmis
  forms = func_formsYZ$formsYMmis
}

system(paste0("mkdir -p ", paste0("results", type)))

  sim_kara = function(n, forms, truth, B = 500) {
    
    data = gendata.SDEtransport(n, 
                                f_W = truth$f_W, 
                                f_S = truth$f_S, 
                                f_A = truth$f_A, 
                                f_Z = truth$f_Z, 
                                f_M = truth$f_M, 
                                f_Y = truth$f_Y)
    SDE_glm4(data, truth = truth,
             truncate = list(lower =.0001, upper = .9999),
             B=B, forms = forms, RCT = 0.5)
  }
  
  library(parallel)
  
  B = 1000
  n=100

  res100_YMmis = mclapply(1:B, FUN = function(x) sim_kara(n=100, forms=forms, truth=func_list, B = boots),
                          mc.cores = getOption("mc.cores", 20L))

  save(res100_YMmis, func_list, forms, file = paste0("results",type ,"/res100_YMmis.RData"))

  B = 1000
  n=500

  res500_YMmis = mclapply(1:B, FUN = function(x) sim_kara(n=500, forms=forms, truth=func_list, B = boots),
                          mc.cores = getOption("mc.cores", 20L))

  save(res500_YMmis, func_list, forms, file = paste0("results",type ,"/res500_YMmis.RData"))

  rm("res100_YMmis", "res500_YMmis")
  
  B = 1000
  n=5000
  
  res5000_YMmis = mclapply(1:B, FUN = function(x) sim_kara(n=5000, forms=forms, truth=func_list, B = boots), 
                           mc.cores = getOption("mc.cores", 20L))
  
  save(res5000_YMmis, func_list, forms, file = paste0("results",type ,"/res5000_YMmis.RData"))
