library("rstan")
# library("MASS")
library("dplyr")
library("RJSONIO")
library("ggplot2")
theme_set(theme_bw())
library("sp")

source("source_2017/common_2017.R")

# Set data length (LONG: 2005-2016; SHORT: 2010-2016)
DATA_LENGTH <- "SHORT"
# SHORT decided on 18.4.2017

# Read data object (updated 12.4.2017)
d <- readRDS("data_2017/d_20170412.rds")

# Shorten data if necessary
if (DATA_LENGTH == "SHORT")
  d <- d %>% filter(year >= 2010)

# Real model from 2017
s <- readRDS(paste0("data_2017/",DATA_LENGTH,"_model_samples_8chains_5000+5000t100_20170412.rds"))

if (F) {
  s
  traceplot(s, "LOmega", inc_warmup=F)
  traceplot(s, "LOmega2", inc_warmup=F)
  traceplot(s, "tau", inc_warmup=F)
  traceplot(s, "tau1", inc_warmup=F)
  traceplot(s, "tau2", inc_warmup=F)
  traceplot(s, "mean_beta", inc_warmup=F)
  traceplot(s, "df", inc_warmup=F)
  traceplot(s, "sigma", inc_warmup=F)
  traceplot(s, "ysigma", inc_warmup=F)
  #traceplot(s, "beta", inc_warmup=F)
  # etc.
}

# Low-level correlation matrix over price level, trend, etc.
# Is of general interest
Omega <- matrix(apply(apply(extract(s, "LOmega")[[1]], 1, function (m) m %*% t(m)), 1, mean), c(3, 3))
saveRDS(Omega, "data_2017/Omega.rds")
Omega1 <- matrix(apply(apply(extract(s, "LOmega1")[[1]], 1, function (m) m %*% t(m)), 1, mean), c(6, 6))
if (F) saveRDS(Omega1, "data_2017/Omega1.rds")

raise6 <- function (a) {
  dim.a <- dim(a); N <- length(dim.a)
  apply(a, 1:(N-1), function (v) c(v, rep(0, 6-dim.a[N]))) %>%
  aperm(c(2:N, 1))
} 
  
beta.prm.mean <- function (v) apply(extract(s, v)[[1]], c(2, 3), mean) %>% raise6
beta.prm <- function (v) extract(s, v)[[1]] %>% raise6

# For debugging 
if (F) {
  beta <- beta.prm.mean("beta")
  lhinta <- beta[,1]+6
  trendi <- beta[,2]/10
  quad <- beta[,3]
  hist(beta[,1], n=100)
  hist(beta[,2], n=100)
  hist(beta[,3], n=100)
  hist(beta[,4], n=100)
  hist(beta[,5], n=100)
  hist(beta[,6], n=100)
}

beta.names <- c("lprice", "trend", "quad", "k.lprice", "k.trend", "k.quad")

par.tbl <- function(d, v.name, b.name, name.postfix) 
  data.frame(levels(d[[v.name]]), beta.prm.mean(b.name)) %>% 
  setNames(c(v.name, 
             paste(beta.names, name.postfix, sep=""))) %>%
  tbl_df()

par.tbl.long <- function(d, v.name, b.name, name.postfix) {
  samples <- beta.prm(b.name)
  data.frame(expand.grid(1:dim(samples)[[1]], levels(d[[v.name]])), 
             array(samples, c(dim(samples)[[1]]*dim(samples)[[2]], dim(samples)[[3]]))) %>% 
  setNames(c("sample", v.name, 
             paste(beta.names, name.postfix, sep=""))) %>%
  tbl_df() }

mean.tbl.long <- function (name.postfix="4") 
  extract(s, "mean_beta")[[1]] %>% { 
    data.frame(sample=1:dim(.)[[1]], .) } %>% 
  setNames(c("sample", 
             paste(beta.names, name.postfix, sep=""))) %>%
  tbl_df() 

# This is used only to get pnro density info
load("data_2017/pnro_data_20170405.RData")
rm(pnro.sp, pnro.ashi.dat)
pnro.area <- pnro.dat %>% transmute(pnro=pnro, log.density = -log(density_per_km2)/10) # FIXME: this is in two places
pnro <- pnro.area$pnro
n.samples <- length(extract(s, "lp__")[[1]])
# For NA pnro's in the model, look for upper level in the hierarchy and take beta1 etc.
res.long <- data.frame(pnro.area, level1 = l1(pnro), level2 = l2(pnro), level3 = l3(pnro)) %>% 
  merge(data.frame(sample=1:n.samples)) %>% 
  filter(is.finite(log.density)) %>%
  left_join(par.tbl.long(d, "pnro",   "beta",  ""),  by=c("pnro",   "sample")) %>%
  left_join(par.tbl.long(d, "level1", "beta1", "1"), by=c("level1", "sample")) %>% 
  left_join(par.tbl.long(d, "level2", "beta2", "2"), by=c("level2", "sample")) %>% 
  left_join(mean.tbl.long(                     "4"), by=c(          "sample")) %>% 
  mutate(pnro=pnro, 
            log.density = log.density,
            lprice=sum.0na(lprice, lprice1, lprice2, lprice4) + 
              sum.0na(k.lprice, k.lprice1, k.lprice2,  k.lprice4) * log.density, 
            trend=sum.0na(trend, trend1, trend2,  trend4) +
              sum.0na(k.trend, k.trend1, k.trend2,  k.trend4) * log.density, 
            quad=sum.0na(quad, quad1, quad2,  quad4) +
              sum.0na(k.quad, k.quad1, k.quad2,  k.quad4) * log.density
  ) %>%
  # Original unit is decade, for vars below it is year. 
  # d/d.yr lprice = trend + 2*quad*yr
  # d/(10*d.yr) lprice = trend/10 + 2*quad*yr/10
  # d^2/(10*d.yr)^2 lprice = 2*quad/100
  # trendi is as percentage / 100.
  # trendimuutos is as percentage units / 100 / year.
  mutate(hinta = exp(6 + lprice), trendi = trend/7, trendimuutos = 2*quad/7/7, 
         hinta2018 = exp(6 + lprice + trend*year2yr(2018) + quad*year2yr(2018)**2),
         trendi2018 = (trend + 2*quad*year2yr(2018))/7) %>%
  tbl_df()
saveRDS(res.long, paste0("data_2017/",DATA_LENGTH,"_pnro-results_longformat_2017.rds"))

# Added 'trendi2018_luotettava'
res <- res.long %>% 
  group_by(pnro, log.density) %>% 
  summarise(lprice = mean(lprice),
            trendi2018_q25 = quantile(trendi2018, 0.25),
            trendi2018_q75 = quantile(trendi2018, 0.75), 
            hinta2018_q25 = quantile(hinta2018, 0.25),
            hinta2018_q75 = quantile(hinta2018, 0.75),
            hinta2018 = mean(hinta2018),
            trendi2018 = mean(trendi2018),
            trendimuutos = mean(trendimuutos)) %>%
  ungroup() %>%
  mutate(trendi2018_luotettava = (trendi2018_q25*trendi2018_q75 > 0))

saveRDS(res, paste0("data_2017/",DATA_LENGTH,"_pnro-hinnat_2017.rds"))
res <- readRDS("data_2017/SHORT_pnro-hinnat_2017.rds")

# UPDATE 25.4.2017: Use 25-75 quantiles everywhere, instead of 20-80. 
# res2080 <- res.long %>% group_by(pnro, log.density) %>% 
#   summarise(lprice = mean(lprice), 
#             hinta2018.20 = quantile(hinta2018, .2), 
#             trendi2018.20 = quantile(trendi2018, .2), 
#             trendimuutos.20 = quantile(trendimuutos, .2), 
#             hinta2018.80 = quantile(hinta2018, .8), 
#             trendi2018.80 = quantile(trendi2018, .8), 
#             trendimuutos.80 = quantile(trendimuutos, .8) 
#             ) %>%
#   ungroup()
# 
# 
# # was:
# # write.table(res %>% select(-log.density),  "data_2016/pnro-hinnat.txt", row.names=F, quote=F)
# write.table(res2080,  paste0("data_2017/",DATA_LENGTH,"_pnro-hinnat_20-80_2017.txt"), row.names=F, quote=F)
# saveRDS(res2080, paste0("data_2017/",DATA_LENGTH,"_pnro-hinnat_20-80_2017.rds"))

# FIXME: exp(6 + lprice + trend*year2yr(2016) + quad*year2yr(2016)**2) in two places, 
# make a function.





## COMPUTE PREDICTIONS ########

if (DATA_LENGTH == "SHORT")
  years <- 2010:2018
if (DATA_LENGTH == "LONG")
  years <- 2005:2018

predictions <- 
  expand.grid(sample=unique(res.long$sample), 
              year=years, 
              pnro=unique(res.long$pnro)) %>% tbl_df %>% #head(10000) %>%
  left_join(res.long %>% select(pnro, sample, lprice, trend, quad), by=c("sample", "pnro")) %>%
  mutate(hinta = exp(6 + lprice + trend*year2yr(year) + quad*year2yr(year)**2)) %>%
  group_by(pnro, year) %>% 
  do(data.frame(hinta = mean(.$hinta), #hinta_sd = sd(.$hinta), 
                hinta10 = quantile(.$hinta, .1), 
                hinta25 = quantile(.$hinta, .25), 
                hinta50 = quantile(.$hinta, .5), 
                hinta75 = quantile(.$hinta, .75), 
                hinta90 = quantile(.$hinta, .9))) %>%
  ungroup() %>%
  left_join(d %>% select(pnro, year, obs_hinta=price, n_kaupat=n), by=c("year", "pnro"))

saveRDS(predictions, paste0("data_2017/",DATA_LENGTH,"_predictions_2017.rds"))


## VALIDATION ########

# Compare predictions to those from year 2016
predictions %>%
  select(pnro, year, hinta_2017 = hinta) %>%
  inner_join(readRDS("data_2016/predictions_2016.rds") %>%
              select(pnro, year, hinta_2016 = hinta),
            by = c("pnro", "year")) %>%
  ggplot(aes(x=hinta_2016, y=hinta_2017)) + geom_point(aes(colour=factor(year)), alpha=0.5) 
# ggplot(aes(x=hinta_2017-hinta_2016)) + geom_histogram()
# Looks similar enough

# Plot comparison between 2015 and 2016
readRDS("data_2015/predictions.rds") %>%
  select(pnro, year, hinta_2015 = hinta) %>%
  inner_join(readRDS("data_2016/predictions_2016.rds") %>%
               select(pnro, year, hinta_2016 = hinta),
             by = c("pnro", "year")) %>%
  ggplot(aes(x=hinta_2016, y=hinta_2015)) + geom_point(aes(colour=factor(year)), alpha=0.5)

# For urbanisation analysis
res.long.narrow <- res.long %>% select(pnro, lprice, trend, quad, sample) #%>% head(10)
#saveRDS(res.long.narrow, file="res-long-narrow.rds")

yearly.trends <- 
  expand.grid(sample=unique(res.long.narrow$sample), 
              year=years, 
              pnro=unique(res.long.narrow$pnro)) %>% tbl_df %>%
#   res.long.narrow %>% 
#   tidyr::expand(pnro, year=years) %>% 
  left_join(res.long.narrow) %>%
  mutate(trend.y = (trend + 2*quad*year2yr(year))/7) %>%
  group_by(pnro, year) %>%
  summarise(trend.y.mean=mean(trend.y), trend.y.median=median(trend.y))
saveRDS(yearly.trends, "data_2017/yearly-trends_2017.rds")


## JSONs #############

res %>% plyr::dlply("pnro", function (i) list(hinta2018=i$hinta2018, 
                                              trendi2018=i$trendi2018, 
                                              #trendimuutos=i$trendimuutos,
                                              #trendi2018_luotettava=i$trendi2018_luotettava,
                                              trendi2018_min=i$trendi2018_q25,
                                              trendi2018_max=i$trendi2018_q75)) %>% 
  toJSON %>% writeLines(paste0("json_2017/trends_",DATA_LENGTH,".json"))

predictions %>% group_by(pnro) %>% # filter(pnro %in% c("02940", "00100")) %>%
  plyr::d_ply("pnro", function (i) list(year=i$year, 
                                        hinta10=i$hinta10, 
                                        hinta25=i$hinta25, 
                                        hinta50=i$hinta50, 
                                        hinta75=i$hinta75, 
                                        hinta90=i$hinta90, 
                                        obs_hinta=i$obs_hinta, 
                                        n_kaupat=i$n_kaupat) %>% toJSON %>%
                writeLines(., paste("json_2017/predictions_",DATA_LENGTH,"/", i$pnro[[1]], ".json",  sep=""))
  )

d %>% select(pnro, year, n) %>%
  tidyr::spread(year, n, fill=0) %>% 
  tidyr::gather(year, n, -pnro) %>% 
  { .[order(.$n),]} %>% 
  mutate(i=row_number()) %>% 
  ggplot(aes(x=i, y=n)) + 
  geom_line() + 
  scale_y_continuous(trans = "log1p", breaks=c(0, 6, 10, 100, 1000))

d %>% select(pnro, year, n)  %>% 
  group_by(pnro) %>% 
  summarise(n=sum(n))  %>% 
  { .[order(.$n),]} %>% 
  mutate(i=row_number()) %>% 
  ggplot(aes(x=i, y=n)) + 
  geom_line() + 
  scale_y_continuous(trans = "log1p", breaks=c(0, 6, 10, 100, 1000))

# Tällä kannattaa tarkistella että prediktion osuvat yhteen datan kanssa. 
# Postinumeroita: parikkala 59130, haaga 00320, espoo lippajärvi 02940, pieksämäki 76100, tapiola 02100
predictions %>% filter(pnro=="02100") %>% tidyr::gather(q, y, -pnro, -year,  -n_kaupat) %>% ggplot(aes(x=year, y=y, color=q)) + geom_line()

