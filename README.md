# College Football Games and Crime

## Project Overview

This project replicates portions of the paper [*"College Football Games and Crime"*](https://jvlone.com/sportsdocs/footballGamesCrime2009.pdf) by Daniel Rees and Kevin Schnepel (2009), which examined whether college football games are associated with increases in crime in college towns.

The original study analyzed daily crime data from 26 Division I-A (now FBS) college towns between 2000 and 2005 and found that home football games were associated with increases in assaults and vandalism, while away games had little effect.

Our goal was to reproduce these findings using publicly available data sources and create visualizations that explore the relationship between football games and crime.

---

## Research Question

Do college football games influence crime rates in college towns?

Specifically, we investigate:

- Are assaults and vandalism more common on home game days?
- Do away games have any impact on crime?
- How do crime patterns differ between schools?
- Can we reproduce the findings of Rees & Schnepel (2009)?

---

## Data Sources

### 1. FBI National Incident-Based Reporting System (NIBRS)

Crime data was obtained from OpenICPSR's cleaned NIBRS dataset.

We extracted data from 2000–2005 and focused on:

- Assault offenses
- Vandalism offenses

### 2. College Football Schedules

Football schedules were retrieved using the `cfbfastR` package, which accesses ESPN schedule data.

### 3. Team-to-Agency Mapping

We matched each of the 26 college football programs from the original paper to their corresponding police agencies (ORI codes) using the NIBRS batch header file.

---

## Repository Structure

### `01_format_NIBRS_data.sh`

Shell script used to prepare the raw NIBRS data.

Tasks performed:

- Extract offense segment files for years 2000–2005
- Extract batch header data
- Match college towns to ORI codes
- Filter offenses to assault and vandalism
- Restrict observations to football season dates (August 20 – December 10)
- Generate `offenses.csv`

---

### `02_create_dataframe.R`

R script used to build the final analysis dataset.

Tasks performed:

- Download college football schedules
- Clean crime data
- Remove duplicate ORI assignments
- Match football teams to police agencies
- Join football schedules and crime data
- Create `final_table.csv`

The final dataset contains one row for every:

- Day
- Police agency (ORI)
- College football team

during each football season from 2000–2005.

---

### `03_final_analysis.Rmd`

R Markdown notebook containing all analyses, visualizations, and replications.

This notebook reproduces several components of the original paper.

## Results

### Table 2: Distribution of Games by Day of the Week

We reproduced the distribution of games throughout the week by calculating:

- Number of games played
- Number of observations per weekday

---

### Saturday Crime Analysis

We created figures showing the mean number of offenses on Saturdays (with standard errors), separated by:

- Home game days
- Away game days
- No game days

---

### Per-Team Analysis

We extended the analysis by creating individual visualizations for each school to compare offense patterns across teams.

---

### Appendix: Descriptive Statistics

We reproduced descriptive statistics for assault and vandalism counts, including:

- Mean
- Standard deviation
- 25th percentile
- Median
- 75th percentile
- 90th percentile

Statistics were computed for:

- All days
- Home game days
- Away game days
- No game days

---
### Regression Analysis
We estimate the relationship between college football games and daily crime (assault and vandalism) in college towns from 2000–2005.

#### Models

We estimate three specifications:

- Linear regression model with game indicators + time and agency fixed effects  
- Negative binomial regression for count data  
- Win/loss models separating game outcomes  

#### Key Results

- Linear model: no statistically significant effects for home or away games  
- Negative binomial: home games increase crime, especially vandalism (significant at 5%)  
- Assault effects are positive but weakly significant  
- Away games show no consistent effect  
- Win/loss outcomes are not statistically significant  

#### Summary

- Evidence of a modest home game effect on crime in count models  
- No support for away game effects or game outcomes  
- Results partially align with Rees & Schnepel (2009), but are smaller and less robust

---

## How to Reproduce the Project

### 1. Download the NIBRS files

Download:

- Offense segment CSV files
- Batch header CSV file

from [OpenICPSR](https://www.openicpsr.org/openicpsr/project/118281/version/V11/view).

### 2. Format the raw data
Run in a terminal (Git Bash):

```bash
bash 01_format_NIBRS_data.sh
```

### 3. Build the final dataset
Open RStudio (or an R session) and run:

```r
source("02_create_dataframe.R")
```

### 4. Render the analysis notebook
Open `03_final_analysis.Rmd` in RStudio and click **Knit**, or run:

```r
rmarkdown::render("03_final_analysis.Rmd")
```

### Alternatively
After downloading NIBRS file you can view full build configuration in [Makefile](Makefile) and run following on your terminal:

```makefile 
make all
```

---

## Technologies Used

- R
- Bash
- tidyverse
- cfbfastR
- lubridate
- knitr
- Makefile
---

## References

Rees, D. I., & Schnepel, K. T. (2009). *College Football Games and Crime*. Journal of Sports Economics, 10(1), 68–87.

OpenICPSR NIBRS Data Repository

ESPN schedule data via `cfbfastR`
