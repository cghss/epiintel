
set.seed(459)

library(tidyverse); library(magrittr)
don <- read_csv("~/Github/dons/Data/DONdatabase.csv")

don %>% pull(DONid) %>% unique() %>% sample(279) -> good

don %<>% 
  filter(DONid %in% good) %>% 
  select(DONid, Headline, ReportDate, Link, DiseaseLevel1, DiseaseLevel2, Country, ISO)

write_csv(don, "~/Github/epiintel/TenPercent.csv", na = "")
