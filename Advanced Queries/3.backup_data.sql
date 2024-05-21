-- Import data 
COPY "US Election".backup FROM 
'F:\Programs\PostGRE SQL\US Election Analysis_Github\countypres_results_2000_2020.csv'
with csv header;