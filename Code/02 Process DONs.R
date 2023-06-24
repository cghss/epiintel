library(tidyverse)
library(lubridate)
library(patchwork)

df <- read_csv("~/Github/epiintel/DONs.csv")

df %>% pull(DONid) %>% unique() %>% length()
df %>% filter(!is.na(`Master coding fixed names`)) %>% pull(DONid) %>% unique() %>% length()


df %>% mutate(Year = year(mdy(ReportDate))) %>% 
  select(Link, Year, DiseaseLevel1, Country, `Master coding fixed names`) %>%
  mutate(Activities = `Master coding fixed names`) %>%
  select(-`Master coding fixed names`) %>%
  group_by(Link, Year) %>% summarize(Country = toString(Country), Activities = toString(Activities)) %>% 
  separate_rows(Activities, sep = ", ") %>% 
  group_by(Link, Year, Country) %>% distinct() %>% 
  filter(!Activities=='NA') -> df2

df2 %>% ungroup() %>% select(Activities) %>% distinct() %>% nrow()

df2 %>%
  ungroup() %>%
  select(Link, Year, Activities) %>% 
  distinct() %>% 
  group_by(Activities) %>% 
  summarize(nDON = n()) %>% View() # this is the 138 check too


df2 %>%
  ungroup() %>%
  select(Link, Year) %>% 
  distinct() %>% 
  group_by(Year) %>% 
  summarize(nDON = n()) %>% 
  ggplot(aes(x = Year, y= nDON)) + geom_bar(stat = "identity") + theme_bw() + 
  xlim(1996,2019) + labs(subtitle = "(A) Total number of reports") + ylab("Reports") -> g1

df2 %>%
  ungroup() %>%
  select(Link, Year, Activities) %>% 
  distinct() %>%
  group_by(Link, Year) %>% 
  summarize(nAct = n()) %>% 
  ungroup() %>% group_by(Year) %>%
  summarize(nAct = mean(nAct)) %>% 
  ggplot(aes(x = Year, y= nAct)) + geom_bar(stat = "identity") + theme_bw() + 
  xlim(1996,2019) + labs(subtitle = "(B) Average number of activities per report") + ylab("Activities") -> g2

df2 %>%
  ungroup() %>%
  filter(Activities == "WHO/WOAH notification") %>%
  select(Link, Year) %>% 
  distinct() %>% 
  group_by(Year) %>% 
  summarize(nDON = n()) %>% 
  ggplot(aes(x = Year, y= nDON)) + geom_bar(stat = "identity") + theme_bw() + 
  xlim(1996,2019) + labs(subtitle = "(C) Reports that record \"WHO/WOAH notification\"") + ylab("Reports") -> g3

df2 %>%
  ungroup() %>%
  filter(Activities == "Genetically sequence samples") %>%
  select(Link, Year) %>% 
  distinct() %>% 
  group_by(Year) %>% 
  summarize(nDON = n()) %>% 
  ggplot(aes(x = Year, y= nDON)) + geom_bar(stat = "identity") + theme_bw() + 
  xlim(1996,2019) + labs(subtitle = "(D) Reports that record \"Genetically sequence samples\"") + ylab("Reports") -> g4

g1 / g2 / g3 / g4

## Try to do the PCA stuff

df %>% mutate(Year = year(mdy(ReportDate))) %>% 
  select(Link, Year, DiseaseLevel1, Country, `Master coding fixed names`) %>%
  mutate(Activities = `Master coding fixed names`) %>%
  select(-`Master coding fixed names`) %>%
  group_by(Link, DiseaseLevel1, Year) %>% summarize(Country = toString(Country), Activities = toString(Activities)) %>% 
  separate_rows(Activities, sep = ", ") %>% 
  group_by(Link, DiseaseLevel1, Year, Country) %>% distinct() %>% 
  filter(!Activities=='NA') -> df2

df2 %>% 
  mutate(one = 1) %>%
  pivot_wider(names_from = Activities, values_from = one, values_fill = 0) -> df3

pca <- princomp(df3[,5:142])

interesting <- c("Ebola virus", "SARS-CoV", "Zika virus disease", "Influenza A")

library(MetBrewer)
met.brewer("Hokusai1", n=5)[2:5]

cols <- c("#df7e66", "#edc775", "#94b594", "#224b5e","grey70")
bind_cols(df3[,1:4], pca$scores) %>%
  mutate(Disease = ifelse(DiseaseLevel1 %in% interesting, DiseaseLevel1, "Other")) %>% 
  mutate(Disease = factor(Disease, levels = c("Ebola virus", "Influenza A", "SARS-CoV", "Zika virus disease", "Other"))) %>% 
  ggplot(aes(x = Comp.1, y = Comp.2, color = Disease)) + geom_point(size = 2.5) + theme_bw() + 
  xlab("Summarized outbreak activities (principal component 1)") + ylab("Summarized outbreak activities (principal component 2)") + scale_colour_manual(values = cols) + 
  stat_ellipse(linetype = 3)

####################

act <- read_csv("~/Github/epiintel/ActivityListDONs.csv")

table(is.na(act$`HR: Textually explicit activities`))

act %>% 
  mutate(inDON = (`Activity fixed name` %in% df2$Activities)) %>%
  select(`Activity fixed name`, `Category (from Function)`, inDON) %>%
  dplyr::rename(Activity = `Activity fixed name`) %>% 
  dplyr::rename(Category = `Category (from Function)`) %>% 
  separate_rows(Category, sep = ', ') %>%
  select(Category, inDON) %>% table()

act %>% 
  mutate(inDON = (`Activity fixed name` %in% df2$Activities)) %>%
  select(`Activity fixed name`, `Category (from Function)`, inDON) %>%
  dplyr::rename(Activity = `Activity fixed name`) %>% 
  dplyr::rename(Category = `Category (from Function)`) %>% 
  separate_rows(Category, sep = ', ') %>%
  select(Category, inDON) %>% table() %>% prop.table(margin = 1)
