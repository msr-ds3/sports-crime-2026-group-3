library(cfbfastR)
library(tidyverse)
library(lubridate)
library(stringr)
library(knitr)

# College Football Data Extraction ------------------------------------------------------------------
# Pull schedule data from espn_cfb_schedule function
years = c(2000:2005)
data_func <- function(year) {
    espn_cfb_schedule(year = year)
}
schedule <- map_dfr(years, data_func)

# Crime Data Extraction -----------------------------------------------------------------------------
colleges <- read_csv("colleges.csv")
offenses <- read_csv("offenses.csv")
unfiltered_ori_and_team_names <- read_csv("unfiltered_ori_and_team_names.csv", col_names = c("ori", "team_name"))

# Filter Crime Data & College Data ------------------------------------------------------------------
# Crime Data
# only select certain columns
offenses <- offenses %>%
    select(ori,
           state_abb,
           incident_date,
           ucr_offense_code)

# add a field to identify the offense type
offenses <- offenses %>%
    mutate(offense_type = case_when(str_detect(ucr_offense_code, "assault") ~ "assault",
                                    str_detect(ucr_offense_code, "vandalism") ~ "vandalism")) %>%
    select(-ucr_offense_code) 

# College Data 
# only from our 26 schools/teams
filtered_schedule <- schedule %>%
    filter(home_team_full %in% colleges$NCAA_Team | 
           away_team_full %in% colleges$NCAA_Team)

filtered_schedule <- filtered_schedule %>% 
    select(game_id,
           game_date,
           home_team_full,
           home_team_name,
           away_team_full,
           away_team_name,
           home_win,
           away_win)

# Remove Duplicate ORIs ------------------------------------------------------------------------------
# Names of teams that have > 1 ORI value
duplicate_team_names <- unfiltered_ori_and_team_names %>%
    group_by(team_name) %>%
    summarise(count = n()) %>%
    filter(count > 1)%>%
    select(team_name)

# Names and ORIs of teams that have > 1 ORI value
duplicate_ori <- unfiltered_ori_and_team_names %>%
    filter(team_name %in% duplicate_team_names$team_name) 

# ORIs of teams that have > 1 ORI value with the associated number of offenses
offense_counts_by_duplicate_ori <- offenses %>% 
    filter(ori %in% duplicate_ori$ori)%>%
    group_by(ori)%>%
    summarise(count = n())

# Choose the ORI value with the highest number of offenses
filtered_duplicates <- left_join(duplicate_ori, offense_counts_by_duplicate_ori, by = 'ori') %>%
    filter(!is.na(count)) %>% # The NA values mean there're no offenses associated with that ORI
    group_by(team_name) %>% 
    filter(count == max(count))

# Create a new CSV file with no duplicates
unfiltered_ori_and_team_names %>%
    filter(!(ori %in% duplicate_ori$ori) | (ori %in% filtered_duplicates$ori) ) %>%  # Keep rows who don't have duplicates + Add the filtered duplicates
    write_csv("ori_and_team_names.csv")

# importing our ori and team mapping
ori_and_team_names <- read_csv("ori_and_team_names.csv")

# filter offense data with new requirements
offenses <- offenses %>%
    filter(!is.na(offense_type)) %>% #filtering offences where type == NA
    filter(ori %in% ori_and_team_names$ori) %>% # filter out duplicate ori offenses
    group_by(ori, incident_date, offense_type) %>% # find count of assault and vandalism for each day and ori combo
    summarize(count = n()) %>%
    pivot_wider(names_from = offense_type, values_from = count, values_fill = 0) %>% # get columns for assault and vandalism counts
    left_join(ori_and_team_names, by = c("ori")) # add team name


# Join Crime and College Football Data -----------------------------------------------------------------
# restructure data to have 1 column with the team name
filtered_schedule_long <- filtered_schedule %>% 
    rename(home_team = "home_team_full", away_team = "away_team_full") %>% # to simplify the values in home_or_away
    pivot_longer(names_to = 'home_or_away',
                 values_to = "team_name",
                 cols = c(home_team, away_team))

# attach ORIs to the game data
schedule_with_ori <- full_join(filtered_schedule_long, ori_and_team_names, by = "team_name") %>%
    filter(!is.na(ori)) %>% # filter out the rows where teams aren't on our list
    rename(incident_date = "game_date") # rename to join

# checking for duplicates in our schedlue data
duplicates <- schedule_with_ori %>%
    group_by(incident_date, ori) %>%
    summarise(count = n()) %>%
    filter(count != 1) %>%
    select(-count)

# creating duplicates that needed to be removed    
duplicate_table <- inner_join(duplicates, schedule_with_ori, by = c("incident_date", "ori")) %>%
    filter(home_team_name %in% c("Fighting Illini", "Falcons", "Hokies") == FALSE) # those were fake entries

# filtering those duplicates form our schedule data frame 
schedule_with_ori <- anti_join(schedule_with_ori, duplicate_table,
                               by = c("incident_date",
                                      "game_id",
                                      "home_team_name",
                                      "away_team_name","ori")) #removing entries that are in duplicates from schedule_with_ori table

# join the cfb and offenses data on ORI and date
test_frame <- full_join(offenses, schedule_with_ori, by = c('ori', 'incident_date', 'team_name')) %>%
    mutate(game_status = case_when((!is.na(ori)) & (home_or_away == "home_team") ~ "home_game", 
                                   (!is.na(ori)) & (home_or_away == "away_team") ~ "away_game",
                                    is.na(game_id) ~ "no_game"))

# Create Final Data Frame -----------------------------------------------------------------------------
# Creating final dataframe with cfb and crime data. 
# Each row represents a unique day and ORI combination 
# (n rows = 113 days * 6 years * 26 ORIs)

# function to build a dataframe with all dates within the football season across the 6 years
table_func <- function(year) {
                data.frame(day = seq(as.Date(paste0(year,"-08-20")), # aug 20
                                     as.Date(paste0(year,"-12-10")), # to dec 10
                                     by = 'day'))
             }

# assembling all dates dataframes into one table
dates_table <- map_dfr(years, table_func)

# creating a template df with 1 row for each date and ORI combo
template_table <- expand_grid(dates_table, ori_and_team_names$ori) %>%
    rename(ori = "ori_and_team_names$ori") %>% # renaming for joining purpose
    left_join(ori_and_team_names, by = "ori") # map team name to ori in template table               

test_frame <- test_frame %>% 
    rename(day = incident_date) # renaming for joining purpose

# populate template table with the data that we have
final_table <- left_join(template_table, test_frame, by = c("day", "ori", "team_name")) %>%
    replace_na(list(assault = 0, vandalism = 0, game_status = "no_game")) # filling in zeros for NAs in offense counts

write_csv(final_table, "final_table.csv")
