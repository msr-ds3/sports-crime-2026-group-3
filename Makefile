# Final Target file 
all: 03_final_analysis.html 03_final_analysis.pdf

# Make sure you have offense_segment_csv_1991_2024.zip, batch_header_csv_1991_2024.zip
# You can download from:
	# batch header file
		# https://www.openicpsr.org/openicpsr/project/118281/version/V11/download/terms?path=/openicpsr/118281/fcr:versions/V11/batch_header_csv_1991_2024.zip&type=file
	# offense segments files
		# https://www.openicpsr.org/openicpsr/project/118281/version/V11/download/terms?path=/openicpsr/118281/fcr:versions/V11/offense_segment_csv_1991_2024.zip&type=file

# 1. Build raw data
data/unfiltered_ori_and_team_names.csv data/offenses.csv: data/offense_segment_csv_1991_2024.zip data/batch_header_csv_1991_2024.zip
	./01_format_NIBRS_data.sh 

# 2. Build final data set
data/final_table.csv: data/unfiltered_ori_and_team_names.csv data/offenses.csv
	Rscript 02_create_dataframe.R 

# 3. Render HTML
03_final_analysis.html: data/final_table.csv 03_final_analysis.Rmd
	Rscript -e "rmarkdown::render('03_final_analysis.Rmd')"

# 4. Render PDF
03_final_analysis.pdf: data/final_table.csv 03_final_analysis.Rmd
	Rscript -e "rmarkdown::render('03_final_analysis.Rmd', output_format='pdf_document', output_file='03_final_analysis.pdf')"

GENERATED = \
data/batch_header_2000_2005.csv \
data/final_table.csv \
data/nibrs_batch_header_1991_2024.csv \
data/nibrs_offense_segment_2000.csv \
data/nibrs_offense_segment_2001.csv \
data/nibrs_offense_segment_2002.csv \
data/nibrs_offense_segment_2003.csv \
data/nibrs_offense_segment_2004.csv \
data/nibrs_offense_segment_2005.csv \
data/offenses.csv \
data/ori_and_team_names.csv \
data/unfiltered_ori_and_team_names.csv \
03_final_analysis.html \
03_final_analysis.pdf

clean:
	rm -f $(GENERATED)