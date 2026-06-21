# Final Target file 
all: 03_final_analysis.html

# Make sure you have offense_segment_csv_1991_2024.zip, batch_header_csv_1991_2024.zip
# You can download from:
# batch header file
# https://www.openicpsr.org/openicpsr/project/118281/version/V11/download/terms?path=/openicpsr/118281/fcr:versions/V11/batch_header_csv_1991_2024.zip&type=file
# offense segments files
# https://www.openicpsr.org/openicpsr/project/118281/version/V11/download/terms?path=/openicpsr/118281/fcr:versions/V11/offense_segment_csv_1991_2024.zip&type=file

unfiltered_ori_and_team_names.csv offenses.csv:offense_segment_csv_1991_2024.zip batch_header_csv_1991_2024.zip
	01_format_NIBRS_data.sh # bash script to format and unzip 

# Filtering duplicate ORI's and creating final csv for further analysis
final_table.csv	ori_and_team_names.csv:unfiltered_ori_and_team_names.csv offenses.csv
	Rscript 02_create_dataframe.R # R file that produces final dataframe
	touch final_table.csv # updating timestamp 

# Final Report 
03_final_analysis.html:final_table.csv # final_table.csv from 02_create_dataframe.R is required
	Rscript -e "rmarkdown::render('03_final_analysis.Rmd')"