# Set up ------------------------------------------------------------------
list.of.packages <- c("data.table", "dplyr", "caTools")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

library(data.table)
library(dplyr)
library(caTools)

# Importing data ----------------------------------------------------------

playlists <- fread(file = "gen/data-preparation/input/all-playlists.csv", encoding = 'UTF-8', sep = '\t', quote = "", na.strings = c('NA', 'None'), 
                   colClasses = c(id = 'character', owner_id = 'character', catalog = 'factor'))

followers <- fread(file = "gen/data-preparation/input/playlist-followers.csv", encoding = 'UTF-8', sep = '\t', quote = "", na.strings = c('NA', 'None'),
                   colClasses = c(playlist_id = 'character', id = 'character'))

placements <- fread("gen/data-preparation/input/playlist-placements.csv", encoding = 'UTF-8', sep = '\t', quote = "", na.strings = c('NA', 'None'),
                    colClasses = c(playlist_id = 'character', track_id = 'character', added_at = 'Date', 
                                   removed_at = 'Date', id = 'character', album_ids = 'character', release_dates = 'Date'))

lct <- Sys.getlocale("LC_TIME"); Sys.setlocale("LC_TIME", "C")

followers$timestp <- as.Date(followers$timestp, format = "%a %b %d %Y")

# Data cleaning and preparation --------------------------------------------------------

setorder(playlists, position)
playlists <- playlists[!duplicated(playlist_id)]
placements <- distinct(placements)

playlists[is.na(code2), code2:='global']

setnames(playlists, 'editorial', 'from_spotify')
setnames(playlists, 'code2', 'location')
setnames(playlists, 'catalog', 'content_type')
setnames(playlists, 'position', 'playlist_position')
setnames(playlists, 'playlist_id', 'spotify_playlist_id')
setnames(playlists, 'id', 'cm_playlist_id')
setnames(placements, 'position', 'track_position')
setnames(placements, 'playlist_id', 'cm_playlist_id')
setnames(followers, 'playlist_id', 'cm_playlist_id')
setnames(followers, 'value', 'nr_followers')
setnames(followers, 'timestp', 'date')

playlists[, from_majorlabel:=F]
playlists[grepl('^filtr|^digster|^topsify', owner_name, ignore.case=T), from_majorlabel:=T]
playlists[, AI:=F]
playlists[grepl('(^this is)|(top[ ][5][0]$)|(viral[ ][5][0]$)', name, ignore.case=T), AI:=T]
playlists[, curator_type:=as.factor('Independent')]
playlists[from_spotify==T, curator_type:='SpotifyHuman']
playlists[from_majorlabel ==T, curator_type:='MajorLabel']
playlists[AI==T & curator_type=='SpotifyHuman', curator_type:='SpotifyAI']
playlists[personalized==T & curator_type=='SpotifyHuman', curator_type:='SpotifyPersonalized']

cols <- grep('^fdiff', colnames(playlists),value=T)
for (col in cols) playlists[, (col):=NULL]

setkey(followers, cm_playlist_id)
setkey(playlists, cm_playlist_id)
setkey(placements, cm_playlist_id)
followers[playlists, ':=' (curator_type=i.curator_type)]
placements[playlists, ':=' (curator_type=i.curator_type)]

playlists$followers[is.na(playlists$followers)] <- 0
playlists$followers[playlists$followers == -1] <- 0
placements <- placements[!(placements$loudness > 0),]
a <- which(names(placements)=='key')
b <- which(names(placements)=='loudness')
placements <- placements[complete.cases(placements[,a:b]),]
followers <- followers %>% distinct(cm_playlist_id, date, .keep_all = TRUE)

save(playlists, file = 'gen/data-preparation/temp/playlists.Rda')
save(placements, file = 'gen/data-preparation/temp/placements.Rda')
save(followers, file = 'gen/data-preparation/temp/followers.Rda')

# Data aggregation -------------------------------------------------
acoustic_attributes <- c('key', 'mode', 'danceability', 'energy', 'speechiness', 'acousticness', 'instrumentalness', 'liveness', 'valence', 
                         'tempo', 'loudness')
setkey(placements, added_at, removed_at)

calcDate <- function(current_date) {
  
  tracks=placements[added_at<=current_date&(is.na(removed_at)|removed_at>current_date)]
  tracks=tracks[!(duplicated(tracks[,c('cm_playlist_id','track_id')])|duplicated(tracks[,c('cm_playlist_id','track_id')], fromLast = T))] #DOCUMENT IN THESIS
  out1=tracks[, lapply(.SD, mean, na.rm=T), keyby =c('cm_playlist_id'), .SDcols=acoustic_attributes]
  for (var in acoustic_attributes) setnames(out1, var, paste0('avg_',var))
  
  out2=tracks[, lapply(.SD, function(x) {sd(x,na.rm=T)/mean(x,na.rm=T)}), keyby =c('cm_playlist_id'), .SDcols=acoustic_attributes]
  for (var in acoustic_attributes) setnames(out2, var, paste0('cv_',var))
  
  out3=tracks[, length(unique(spotify_artist_ids)), keyby =c('cm_playlist_id')]
  colnames(out3)[2] <- 'nr_artists'
  
  out = merge(merge(out1,out2),out3)[, date:=current_date]
  setcolorder(out, c('cm_playlist_id', 'date'))
  return(out)
  
}

calcLine <- function(dates) rbindlist(lapply(dates, calcDate))

a=Sys.time()
dt <- calcLine(unique(followers$date[followers$date <= '2019-09-27'])) #after this date we do not have placements data anymore
b=Sys.time()
b-a #12 mins after filtering out duplicate tracks

save(dt, file = 'gen/data-preparation/temp/dt.Rda')
# Creating the training and test data sets --------------------------------
set.seed(12345) # To enforce reproducibility
sample = sample.split(dt$cm_playlist_id, SplitRatio = .8) #80/20 train/test split
train = subset(dt, sample == T)
test = subset(dt, sample == F)

# Data merging and transforming after aggregating -----------------------------------------------

setkey(train, cm_playlist_id, date)
setkey(test, cm_playlist_id, date)
setkey(followers, cm_playlist_id, date)
train[followers, ':=' (nr_followers=i.nr_followers)]
test[followers, ':=' (nr_followers=i.nr_followers)]

train <- train %>% 
  group_by(cm_playlist_id) %>%
  mutate(mean_followers = mean(nr_followers, na.rm = TRUE)) %>%
  as.data.table()
train$r_followers <- train$nr_followers/train$mean_followers

setkey(train, cm_playlist_id)
setkey(test, cm_playlist_id)
test[train, ':=' (mean_followers=i.mean_followers)]
test$r_followers <- test$nr_followers/test$mean_followers
train[playlists, ':=' (curator_type=i.curator_type)]
test[playlists, ':=' (curator_type=i.curator_type)]

save(train, file = 'gen/data-preparation/temp/train.Rda')
save(test, file = 'gen/data-preparation/temp/test.Rda')

rm(list=ls())