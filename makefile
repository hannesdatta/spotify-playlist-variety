all: initiation parsing_alldata prep_aggregate positions  exploration models


# summary of workflow
initiation: src/data-preparation/init.py
	python src/data-preparation/init.py
parsing_alldata: gen/data-preparation/input/all-playlists.csv gen/data-preparation/input/playlist-followers.csv gen/data-preparation/input/playlist-placements.csv gen/data-preparation/input/playlist-placements-positions.csv
prep_aggregate: gen/data-preparation/temp/playlists.Rda gen/data-preparation/temp/placements.Rda gen/data-preparation/temp/followers.Rda gen/data-preparation/temp/dt.Rda gen/data-preparation/temp/train.Rda gen/data-preparation/temp/test.Rda
positions: gen/data-preparation/temp/positions.Rda gen/data-preparation/temp/ts_dt.Rda gen/data-preparation/temp/ts_train.Rda gen/data-preparation/temp/ts_test.Rda
exploration: gen/analysis/output/general_descriptives.txt gen/analysis/output/aggregated_descriptives.txt gen/analysis/temp/date_aggregated.Rda gen/analysis/temp/date_ts_aggregated.Rda gen/analysis/output/Rplots.pdf
models: gen/analysis/output/model_output.txt 


# parsing all data
gen/data-preparation/input/all-playlists.csv gen/data-preparation/input/playlist-followers.csv gen/data-preparation/input/playlist-placements.csv: src/data-preparation/parsing_alldata.py data/all-playlists.json data/playlist-followers.json data/playlist-placements.json
	python src/data-preparation/parsing_alldata.py

# prepare aggregation
gen/data-preparation/temp/playlists.Rda gen/data-preparation/temp/placements.Rda gen/data-preparation/temp/followers.Rda gen/data-preparation/temp/dt.Rda gen/data-preparation/temp/train.Rda gen/data-preparation/temp/test.Rda: src/data-preparation/1_prep_aggregate.R gen/data-preparation/input/all-playlists.csv gen/data-preparation/input/playlist-followers.csv gen/data-preparation/input/playlist-placements.csv
	Rscript "src/data-preparation/1_prep_aggregate.R"

# positions
gen/data-preparation/temp/positions.Rda gen/data-preparation/temp/ts_dt.Rda gen/data-preparation/temp/ts_train.Rda gen/data-preparation/temp/ts_test.Rda: src/data-preparation/2_positions.R gen/data-preparation/input/playlist-placements-positions.csv gen/data-preparation/temp/placements.Rda gen/data-preparation/temp/followers.Rda gen/data-preparation/temp/playlists.Rda gen/data-preparation/temp/followers.Rda 
	Rscript "src/data-preparation/2_positions.R"

# exploration
gen/analysis/output/general_descriptives.txt gen/analysis/output/aggregated_descriptives.txt gen/analysis/temp/date_aggregated.Rda gen/analysis/temp/date_ts_aggregated.Rda gen/analysis/output/Rplots.pdf: src/analysis/3_exploration.R gen/data-preparation/temp/playlists.Rda gen/data-preparation/temp/placements.Rda gen/data-preparation/temp/followers.Rda gen/data-preparation/temp/train.Rda gen/data-preparation/temp/ts_train.Rda
	Rscript "src/analysis/3_exploration.R"
	mv Rplots.pdf "gen/analysis/output/Rplots.pdf"

# models 
gen/analysis/output/model_output.txt : src/analysis/4_models.R gen/data-preparation/temp/train.Rda gen/data-preparation/temp/test.Rda gen/data-preparation/temp/ts_train.Rda gen/data-preparation/temp/ts_test.Rda
	Rscript "src/analysis/4_models.R"

.PHONY: clean
clean:
	RM -f -r "gen"
	# RM -f -r "data"