library(tidyverse)
library(MetBrewer)

df <- read_csv("~/Github/epiintel/ActivityList.csv")

df %>% select(Activity, `Category (from Function)`) %>%
  rename(Category = `Category (from Function)`) %>%
  mutate(Hlc = as.numeric(str_detect(Category, "Healthcare & IPC")),
         Sec = as.numeric(str_detect(Category, "Safety & security")),
         Log = as.numeric(str_detect(Category, "Logistics & support")),
         Gov = as.numeric(str_detect(Category, "Governance & coordination")),
         Hum = as.numeric(str_detect(Category, "Humanitarian assistance")),
         Epi = as.numeric(str_detect(Category, "Epidemiology & lab analysis"))) %>% 
  mutate(Sum = Hlc + Sec + Log + Gov + Hum + Epi) %>% 
  select(-Category) -> df2

table(df2$Hlc)
table(df2$Sec)
table(df2$Log)
table(df2$Gov)
table(df2$Hum)
table(df2$Epi)

table(df2$Sum)

df2 %>% filter(Hlc == 1, Sec == 1) %>% distinct() %>% nrow()
df2 %>% filter(Hlc == 1, Log == 1) %>% distinct() %>% nrow()
df2 %>% filter(Hlc == 1, Gov == 1) %>% distinct() %>% nrow()
df2 %>% filter(Hlc == 1, Hum == 1) %>% distinct() %>% nrow()
df2 %>% filter(Hlc == 1, Epi == 1) %>% distinct() %>% nrow()
df2 %>% filter(Sec == 1, Log == 1) %>% distinct() %>% nrow()
df2 %>% filter(Sec == 1, Gov == 1) %>% distinct() %>% nrow()
df2 %>% filter(Sec == 1, Hum == 1) %>% distinct() %>% nrow()
df2 %>% filter(Sec == 1, Epi == 1) %>% distinct() %>% nrow()
df2 %>% filter(Log == 1, Gov == 1) %>% distinct() %>% nrow()
df2 %>% filter(Log == 1, Hum == 1) %>% distinct() %>% nrow()
df2 %>% filter(Log == 1, Epi == 1) %>% distinct() %>% nrow()
df2 %>% filter(Gov == 1, Hum == 1) %>% distinct() %>% nrow()
df2 %>% filter(Gov == 1, Epi == 1) %>% distinct() %>% nrow()
df2 %>% filter(Hum == 1, Epi == 1) %>% distinct() %>% nrow()

# Taylor Swift phases tour

df %>% 
  select(Activity, Phases) %>%
  mutate(p1 = as.numeric(str_detect(Phases, "Surveillance & preparedness")),
         p2 = as.numeric(str_detect(Phases, "Detection")),
         p3 = as.numeric(str_detect(Phases, "Early response")),
         p4 = as.numeric(str_detect(Phases, "Intervention")),
         p5 = as.numeric(str_detect(Phases, "Post-intervention & recovery"))) %>% 
  mutate(Sum = p1 + p2 + p3 + p4 + p5) -> df2

table(df2$p1)
table(df2$p2)
table(df2$p3)
table(df2$p4)
table(df2$p5)
table(df2$Sum)


# Scale

df %>% 
  select(Activity, `Geographic scale(s)`) %>%
  rename(Geography = `Geographic scale(s)`) %>%
  mutate(p1 = as.numeric(str_detect(Geography, "Subnational")),
         p2 = as.numeric(str_detect(Geography, "National")),
         p3 = as.numeric(str_detect(Geography, "International"))) %>% 
  mutate(Sum = p1 + p2 + p3) -> df2

table(df2$p1)
table(df2$p2)
table(df2$p3)
table(df2$Sum)

# Cross-table scale 


df %>% 
  select(Activity, `Geographic scale(s)`, Phases) %>%
  rename(Geography = `Geographic scale(s)`) %>%
  mutate(Subnational = as.numeric(str_detect(Geography, "Subnational")),
         National = as.numeric(str_detect(Geography, "National")),
         International = as.numeric(str_detect(Geography, "International"))) %>% 
  mutate(Surveillance = as.numeric(str_detect(Phases, "Surveillance & preparedness")),
         Detection = as.numeric(str_detect(Phases, "Detection")),
         Early = as.numeric(str_detect(Phases, "Early response")),
         Intervention = as.numeric(str_detect(Phases, "Intervention")),
         Recovery = as.numeric(str_detect(Phases, "Post-intervention & recovery")))  %>% 
  pivot_longer(cols = c("Subnational", "National", "International"), names_to = "Scale", values_to = "ScaleVal")  %>% 
  pivot_longer(cols = c("Surveillance", "Detection", "Early", "Intervention", "Recovery"), names_to = "Phase", values_to = "PhaseVal") %>%
  select(-Geography) %>% select(-Phases) %>% 
  filter(ScaleVal == 1, PhaseVal == 1) %>% 
  select(Scale, Phase) %>% table() # %>% chisq.test()


df %>% 
  select(Activity, `Category (from Function)`, Phases) %>%
  rename(Category = `Category (from Function)`) %>%
  mutate(Surveillance = as.numeric(str_detect(Phases, "Surveillance & preparedness")),
         Detection = as.numeric(str_detect(Phases, "Detection")),
         Early = as.numeric(str_detect(Phases, "Early response")),
         Intervention = as.numeric(str_detect(Phases, "Intervention")),
         Recovery = as.numeric(str_detect(Phases, "Post-intervention & recovery")))  %>% 
  mutate(Hlc = as.numeric(str_detect(Category, "Healthcare & IPC")),
         Sec = as.numeric(str_detect(Category, "Safety & security")),
         Log = as.numeric(str_detect(Category, "Logistics & support")),
         Gov = as.numeric(str_detect(Category, "Governance & coordination")),
         Hum = as.numeric(str_detect(Category, "Humanitarian assistance")),
         Epi = as.numeric(str_detect(Category, "Epidemiology & lab analysis")))  %>% 
  pivot_longer(cols = c("Hlc", "Sec", "Log", "Gov", "Hum", "Epi"), names_to = "Cat", values_to = "CategoryVal")  %>% 
  pivot_longer(cols = c("Surveillance", "Detection", "Early", "Intervention", "Recovery"), names_to = "Phase", values_to = "PhaseVal") %>%
  select(-Category) %>% select(-Phases) %>% 
  filter(CategoryVal == 1, PhaseVal == 1) %>% 
  select(Cat, Phase) %>% table() -> t; t # %>% chisq.test()

t %>%
  data.frame() %>% 
  mutate(Phase = factor(Phase, levels = c('Surveillance', 'Detection', 'Early', 'Intervention', 'Recovery'))) %>%
  mutate(Cat = factor(Cat, levels = c("Epi", "Log", "Hlc", "Gov", "Sec", "Hum"))) %>% 
  ggplot(aes(x = Phase, y = Cat, colour = Cat, size = Freq)) + 
  geom_point() + 
  theme_minimal() +
  geom_text(aes(label = Freq), 
            colour = "white", 
            size = 3) +
  scale_size_continuous(range = c(5, 20)) + # Adjust as required. + 
  scale_color_manual(values = met.brewer("Nizami", 6)) +
  labs(x = NULL, y = NULL) +
  theme(legend.position = "none",
        panel.background = element_blank(),
        panel.grid.major.y = element_line(linewidth = .3, color="grey75"), 
        panel.grid = element_blank(),
        axis.ticks = element_blank()) + 
  scale_x_discrete(position = "top", labels=c("Surveillance & \n preparedness", "Detection", "Early response", "Intervention", "Post-intervention \n & recovery")) + 
  scale_y_discrete(limits = rev, labels = rev(c("Epidemiology & \n lab analysis", "Logistics & \n support", "Healthcare \n & IPC", "Governance & \n coordination", "Safety & \n security", "Humanitarian \n assistance")))















df %>% 
  select(Activity, `Geographic scale(s)`, `Category (from Function)`) %>%
  rename(Category = `Category (from Function)`) %>%
  rename(Geography = `Geographic scale(s)`) %>%
  mutate(Subnational = as.numeric(str_detect(Geography, "Subnational")),
         National = as.numeric(str_detect(Geography, "National")),
         International = as.numeric(str_detect(Geography, "International"))) %>% 
  mutate(Hlc = as.numeric(str_detect(Category, "Healthcare & IPC")),
         Sec = as.numeric(str_detect(Category, "Safety & security")),
         Log = as.numeric(str_detect(Category, "Logistics & support")),
         Gov = as.numeric(str_detect(Category, "Governance & coordination")),
         Hum = as.numeric(str_detect(Category, "Humanitarian assistance")),
         Epi = as.numeric(str_detect(Category, "Epidemiology & lab analysis")))  %>% 
  pivot_longer(cols = c("Hlc", "Sec", "Log", "Gov", "Hum", "Epi"), names_to = "Cat", values_to = "CategoryVal")  %>% 
  pivot_longer(cols = c("Subnational", "National", "International"), names_to = "Scale", values_to = "ScaleVal")  %>% 
  select(-Category) %>% select(-Geography) %>% 
  filter(CategoryVal == 1, ScaleVal == 1) %>% 
  select(Cat, Scale) %>% table() # %>% chisq.test()


### This is where the etiology stuff starts, and folks: this is where I remembered that it's actually okay to use separate_rows()

# DBE stuff

df %>% 
  select(Activity, `Event origin(s)`) %>%
  rename(Etiology = `Event origin(s)`) %>%
  separate_rows(Etiology, sep = ',') %>% 
  mutate(Value = 1) -> df2

df2 %<>% 
  complete(Activity, Etiology, fill = list(Value = 0)) %>% 
  left_join(df2)

df2 %>% group_by(Activity) %>% summarize(Val = sum(Value)) %>% pull() -> f
table(f == 4)

df2 %>% group_by(Etiology) %>% summarize(Val = sum(Value)) %>% View()

# Actual etiologies

df %>% 
  select(Activity, `Disease Outbreak News (DONs) categories`) %>%
  rename(Etiology = `Disease Outbreak News (DONs) categories`) %>%
  separate_rows(Etiology, sep = ',') %>% 
  mutate(Value = 1) -> df2

df2 %<>% 
  complete(Activity, Etiology, fill = list(Value = 0)) %>% 
  left_join(df2)

df2 %>% group_by(Activity) %>% summarize(Val = sum(Value)) %>% pull() -> f
table(f == 10)

df2 %>% group_by(Etiology) %>% summarize(Val = sum(Value)) %>% View()

# Silly bit

df2 %>% group_by(Activity) %>% summarize(Val = sum(Value)) %>% filter(Val < 10) %>% pull(Activity) -> special

df %>%
  filter(Activity %in% special) %>% 
  select(Activity, Phases) %>%
  separate_rows(Phases, sep = ",") %>% 
  pull(Phases) %>% table()

df %>%
  filter(Activity %in% special) %>% 
  select(Activity, Phases) %>%
  separate_rows(Phases, sep = ",") %>%
  filter(Phases %in% c("Early response", "Intervention", "Post-intervention & recovery")) %>% 
  pull(Activity) %>% unique() %>% length()

df %>%
  filter(Activity %in% special) %>% 
  select(Activity, Phases) %>%
  separate_rows(Phases, sep = ",") %>%
  filter(Phases %in% c("Detection", "Surveillance & preparedness")) %>% 
  pull(Activity) %>% unique() %>% length()


df %>%
  filter(Activity %in% special) %>% 
  select(Activity, `Geographic scale(s)`) %>%
  separate_rows( `Geographic scale(s)`, sep = ",") %>% 
  pull( `Geographic scale(s)`) %>% table()


df %>%
  filter(Activity %in% special) %>% 
  select(Activity, `Category (from Function)`) %>%
  separate_rows( `Category (from Function)`, sep = ", ") %>% 
  pull( `Category (from Function)`) %>% table()
