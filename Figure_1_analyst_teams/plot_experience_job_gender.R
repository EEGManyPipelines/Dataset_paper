rm(list = ls())

#load libraries
library(tidyverse)
library(ggplot2)
library(forcats)

#load data
data_age_job <- read.csv('/Users/ecesnaite/Desktop/BuschLab/EEGManyPipelines/Papers/Dataset paper/Data/final_data.csv')
data_country_gender <- read.csv('/demographic_country_gender.csv')
#----------------------
## Mean and standard deviation of sample characteristics ##
#----------------------

#average age
mean(data_age_job$age)
sd(data_age_job$age)

#job years
mean(data_age_job$job_years)
sd(data_age_job$job_years)

#EEG years
mean(data_age_job$eeg_years)
sd(data_age_job$eeg_years)

#EEG papers
mean(data_age_job$eeg_papers)
sd(data_age_job$eeg_papers)

#----------------------
## Barplots for categorical data ##
#----------------------

#job position
plot_data <- as.data.frame(table(data_age_job$job_position_edit))
plot_data$percent <- as.character(paste0(round(plot_data$Freq/396*100, 1), '%')) # to percentage
plot_data$Freq <- plot_data$Freq/396*100

sum(plot_data$Freq)

plot_data <- plot_data %>%
  arrange(desc(Freq))

# The colors
BLUE <- "#81B1D6"

png("/Figures/Dataset_figure_job_position.png", width = 1200, height = 400, res = 200)

ggplot(plot_data, aes(forcats::fct_reorder(Var1, Freq), Freq)) +
  geom_col(fill = BLUE, width = 0.6)  +
  geom_text(aes(label = forcats::fct_reorder(percent,Freq)), 
    ## make labels left-aligned
    hjust = -0.2, nudge_x = 0) + coord_flip() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(),axis.title.x=element_blank(),axis.text=element_text(size=12),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(), axis.title.y = element_blank()) + ylim(0,50)

dev.off()

#gender
table(data_country_gender$gender)
data_country_gender$gender[data_country_gender$gender=='NULL'] <- 'no-answer'

plot_gender <-  as.data.frame(table(data_country_gender$gender))
plot_gender$percent <- as.character(paste0(round(plot_gender$Freq/396*100, 1), '%')) 

PEACH <- "#FFCC9E"
png("/Figures/Dataset picture gender.png", width = 800, height = 200, res = 200)

ggplot(plot_gender, aes(forcats::fct_reorder(Var1, Freq), Freq)) +
  geom_col(fill = PEACH, width = 0.6)  +
  geom_text(aes(label = forcats::fct_reorder(percent,Freq)), 
            ## make labels left-aligned
            hjust = -0.2, nudge_x = 0) + coord_flip() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        panel.background = element_blank(),axis.title.x=element_blank(),axis.text=element_text(size=12),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(), axis.title.y = element_blank()) + ylim(0,400)
dev.off()

