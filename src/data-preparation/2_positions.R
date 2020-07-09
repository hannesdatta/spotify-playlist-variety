# Set up ------------------------------------------------------------------
library(data.table)
library(dplyr)
library(caTools)

# Importing data ----------------------------------------------------------
pos <- fread(file = "gen/data-preparation/input/playlist-placements-positions.csv", encoding = 'UTF-8', sep = '\t', quote = "", na.strings = c('NA', 'None'),
                   colClasses = c(playlist_id = 'character', track_id = 'character'))

# Data cleaning and preparation --------------------------------------------------------
setnames(pos, 'playlist_id', 'cm_playlist_id')
setnames(pos, 'position', 'track_position')
positions <- distinct(pos)
load('gen/data-preparation/temp/placements.Rda')
load('gen/data-preparation/temp/followers.Rda')
subset <- placements %>% select(track_id, key:loudness) %>% distinct(track_id, .keep_all = T)
datesList <- unique(followers$date[followers$date <= '2019-09-27'])
rm(placements)
rm(followers)

positions$added_at <- as.Date(positions$added_at, format = "%Y-%m-%d")
positions$removed_at <- as.Date(positions$removed_at, format = "%Y-%m-%d")

positions <- merge(positions, subset, by = 'track_id', all.x = T)
save(positions, file = 'gen/data-preparation/temp/positions.Rda')



# Data aggregation --------------------------------
acoustic_attributes <- c('key', 'mode', 'danceability', 'energy', 'speechiness', 'acousticness', 'instrumentalness', 'liveness', 'valence', 
                         'tempo', 'loudness')
ts_attributes <- append(acoustic_attributes, 'track_position')

calcDate <- function(current_date) {
  
  tracks=setorder(positions[added_at<=current_date&(is.na(removed_at)|removed_at>=current_date)], track_position)
  tracks = tracks[!(duplicated(tracks[,c('cm_playlist_id','track_id')])|duplicated(tracks[,c('cm_playlist_id','track_id')], fromLast = T))]
  out=tracks[, lapply(.SD, function(x) {abs(x-lag(x))}), keyby =c('cm_playlist_id'), .SDcols=ts_attributes]
  out=out[track_position == 1]
  out=out[, lapply(.SD, mean, na.rm = T), keyby = c('cm_playlist_id'), .SDcols = acoustic_attributes]
  for (var in acoustic_attributes) setnames(out, var, paste0('mad_',var))
  out = out[, date:=current_date]
  setcolorder(out, c('cm_playlist_id', 'date'))
  return(out)
  
}

a = Sys.time()
calcLine <- function(dates) rbindlist(lapply(dates, calcDate))
ts_dt <- calcLine(datesList)
b = Sys.time()
b-a #12 mins
save(ts_dt, file = 'gen/data-preparation/temp/ts_dt.Rda')

# Creating the training and test data sets -------------------------------------

set.seed(12345) # To enforce reproducibility
sample = sample.split(ts_dt$cm_playlist_id, SplitRatio = .8) #80/20 training/test split
ts_train = subset(ts_dt, sample == T)
ts_test = subset(ts_dt, sample == F)

rm(ts_dt)
# Data merging after aggregation) -------------------------------------------------

load('gen/data-preparation/temp/playlists.Rda')
setkey(ts_train, cm_playlist_id)
setkey(ts_test, cm_playlist_id)
setkey(playlists, cm_playlist_id)
ts_train[playlists, ':=' (curator_type = i.curator_type)]
ts_test[playlists, ':=' (curator_type = i.curator_type)]

rm(playlists)

load('gen/data-preparation/temp/followers.Rda')
setkey(ts_train, cm_playlist_id, date)
setkey(ts_test, cm_playlist_id, date)
setkey(followers, cm_playlist_id, date)
ts_train[followers, ':=' (nr_followers=i.nr_followers)]
ts_test[followers, ':=' (nr_followers=i.nr_followers)]

ts_train <- ts_train %>%
  group_by(cm_playlist_id) %>%
  mutate(mean_followers = mean(nr_followers, na.rm = TRUE)) %>%
  as.data.table()
ts_train$r_followers <- ts_train$nr_followers/ts_train$mean_followers

setkey(ts_train, cm_playlist_id)
setkey(ts_test, cm_playlist_id)
ts_test[ts_train, ':=' (mean_followers=i.mean_followers)]
ts_test$r_followers <- ts_test$nr_followers/ts_test$mean_followers

save(ts_train, file = 'gen/data-preparation/temp/ts_train.Rda')
save(ts_test, file = 'gen/data-preparation/temp/ts_test.Rda')

rm(list = ls())