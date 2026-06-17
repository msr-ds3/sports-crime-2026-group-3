#!/bin/bash

# There was no direct link to download the NIBSR data, but these are the ones we followed:

# batch header file
# https://www.openicpsr.org/openicpsr/project/118281/version/V11/download/terms?path=/openicpsr/118281/fcr:versions/V11/batch_header_csv_1991_2024.zip&type=file

# offense segments files
# https://www.openicpsr.org/openicpsr/project/118281/version/V11/download/terms?path=/openicpsr/118281/fcr:versions/V11/offense_segment_csv_1991_2024.zip&type=file

#-------------------------------------------------------------------------------------
# format of file names in offense segment zip: "nibrs_offense_segment_year.csv"

unzip -n offense_segment_csv_1991_2024.zip '*200[0-5]*' # we only want 2000 - 2005
unzip -n batch_header_csv_1991_2024.zip

# second column of batch_header is the year. filter to only 2000 - 2015
cat nibrs_batch_header_1991_2024.csv | awk -F, 'NR == 1 || $2 ~ /^200[0-5]$/' > batch_header_2000_2005.csv # keep the header row

#-------------------------------------------------------------------------------------
# colleges.csv has $1 = 'State' (uppercase), $2 = 'City', $3 = 'College' etc.
# batch_header_2000_2005.csv has $1 = 'ori', $7 = 'city', $8 = 'state (abbr)' lowercase

# find city matches from colleges list (returns ORI and Team name)
awk -F, '
    NR==FNR {
        key[tolower($1) "," tolower($2)] = $4
        next
    }
    {
        k = tolower($8) "," tolower($7)
        if(k in key)
            print $1 "," key[k]
    }
    ' colleges.csv batch_header_2000_2005.csv | sort -u > ori_and_team_names.csv

#-------------------------------------------------------------------------------------
#PSEUDOCODE
# read each file nibrs_offense_segment_year.csv (where year is 2000-2005),
# filter where col 1 (ori) is in the list in ori_values.txt AND the 7th column (ucr_offense_code) 
# contains "*assault*" or "*vandalism*". store those rows in a file called offenses.csv

> offenses.csv # creates or empties the file before the loop

head -n 1 nibrs_offense_segment_2000.csv > offenses.csv

for year in {2000..2005}
do
    awk -F, '
        NR==FNR {
            ori[$1]
            next
        }

        ($1 in ori) && (tolower($7) ~ /assault/ || tolower($7) ~ /vandalism/)
        ' ori_and_team_names.csv nibrs_offense_segment_${year}.csv >> offenses.csv
done