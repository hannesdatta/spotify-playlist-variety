# Set up ------------------------------------------------------------------
list.of.packages <- c("data.table", "dplyr", "ggplot2", "scales", "fastDummies", "gridExtra", "stargazer")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

library(ggplot2)
library(scales)
library(fastDummies)
library(gridExtra)
library(data.table)
library(stargazer)
library(dplyr)

load('gen/data-preparation/temp/playlists.Rda')
load('gen/data-preparation/temp/placements.Rda')
load('gen/data-preparation/temp/followers.Rda')
load('gen/data-preparation/temp/train.Rda')
load('gen/data-preparation/temp/ts_train.Rda')
#load('gen/data-preparation/temp/date_aggregated.Rda')

# General descriptives ------------------------------------------------------------
cat(capture.output(summary(playlists)), file = "gen/analysis/output/general_descriptives.txt", sep = "\n", append = TRUE)
cat(capture.output(summary(placements)), file = "gen/analysis/output/general_descriptives.txt", sep = "\n", append = TRUE)
cat(capture.output(summary(followers)), file = "gen/analysis/output/general_descriptives.txt", sep = "\n", append = TRUE)
train <- na.omit(train)
ts_train <- na.omit(ts_train)
cat(capture.output(summary(train)), file = "gen/analysis/output/aggregated_descriptives.txt", sep = "\n", append = TRUE)
cat(capture.output(summary(ts_train)), file = "gen/analysis/output/aggregated_descriptives.txt", sep = "\n", append = TRUE)

# Stargazer tables for the Thesis doc
tmp = distinct(placements, track_id, .keep_all = T)
a <- which(names(tmp)=='key')
b <- which(names(tmp)=='loudness')
stargazer(tmp[,a:b], type = 'html', summary.stat = c('mean', 'sd', 'min', 'max'))

playlists <- cbind(playlists, dummy_cols(playlists$content_type))
playlists <- cbind(playlists, dummy_cols(playlists$curator_type))
stargazer(playlists[,c(8, 23:25, 27:31)], type = 'html', summary.stat = c('mean', 'sd', 'min', 'max'))

train <- cbind(train, dummy_cols(train$curator_type))
stargazer(train[,c(14:25, 28, 31:35)], type = 'html', summary.stat = c('mean', 'sd', 'min', 'max'))

ts_train <- cbind(ts_train, dummy_cols(ts_train$curator_type))

stargazer(ts_train[,c(3:13, 17, 19:23)], type = 'html', summary.stat = c('mean', 'sd', 'min', 'max'))

track = distinct(placements, track_id, .keep_all = T)
lapply(track[,30:40], function(x) {round(sd(x, na.rm=T)/mean(x, na.rm=T), digits = 3)})

# Playlists ----------------------------------------------------------
# Genre
length(unique(playlists$genre))
tmp = playlists[playlist_position <= 1000]
length(unique(tmp$genre))

# Owners
length(unique(playlists$owner_id))
tmp = playlists[, list(nplaylists = length(unique(cm_playlist_id))), by=c('owner_id')]
summary(tmp$nplaylists)

tmp = playlists[playlist_position <= 1000, list(nplaylists = length(unique(cm_playlist_id))), by=c('owner_id')]
summary(tmp$nplaylists)
length(unique(tmp$owner_id))

# Follower data -----------------------------------------------------------
# Followers (cumulative marketshare)
playlists = playlists[order(playlist_position), ]
playlists$share = 100*cumsum(playlists$followers)/sum(playlists$followers, na.rm = TRUE)
points = c(10, 20, 50, 100, 200, 500, 1000, 5000, 10000, 15000)
subset_share = playlists[playlist_position %in% points, ]
subset_share %>% ggplot(aes(x = playlist_position, y = share)) +
  geom_point() +
  ylab("Cumulative share of followers (%)") +
  xlab("Position") +
  xlim(0, 16000) +
  geom_text(aes(label = paste0("(",playlist_position, ",", round(share, 0), ")"), vjust = -0.5), size = 3) +
  theme_light()

setorderv(playlists, 'followers', order=-1L)
playlists[followers>0, cum:=cumsum(followers)/sum(followers)]
playlists[followers>0, perc:=.I/.N]
playlists[followers>0, N:=.I]
dt_fol = playlists[followers>0]
with(dt_fol, plot(perc, cum,type='l', xlab = 'Top x% playlists, ordered by followers', ylab= 'Cumulative share of followers'))

cutoff = .9
dt_set = dt_fol[cum<=cutoff]
ggplot(dt_set, aes(x=N, y =cum)) + geom_line() + xlab('Top X playlists, ordered by followers') + ylab('Cumulative share of followers') + theme_light() + scale_y_continuous(labels = function(x)paste0(x*100, "%"))

# Followers by curator_type
tmp = dt_set[, list(sum_followers=sum(followers)),by=c('curator_type')]
tmp[, ]

# Followers by content_type
tmp = dt_set[, list(sum_followers=sum(followers)),by=c('content_type')]
tmp[, ]

# Followers & playlists by curator_type over time
tmp=followers[, list(N=length(unique(cm_playlist_id)), sum_followers=sum(nr_followers,na.rm=T)),by=c('curator_type', 'date')]

ggplot(data=tmp, aes(x=date, y=N, col = curator_type)) +
  geom_line() +
  geom_point() + 
  ggtitle('Number of playlists in the Top 1000, by owner')

ggplot(data=tmp, aes(x=date, y=sum_followers, col = curator_type)) +
  geom_line() +
  geom_point() +
  ggtitle('Number of followers in the Top 1000, by owner')

# Followers & playlists by content_type over time
setkey(followers, 'cm_playlist_id')
setkey(playlists, 'cm_playlist_id')
followers[playlists, ':=' (content_type=i.content_type)]
tmp = followers[, list(N=length(unique(cm_playlist_id)), sum_followers=sum(nr_followers,na.rm=T)),by=c('content_type', 'date')]

ggplot(data=tmp, aes(x=date, y=N, col = content_type)) +
  geom_line()+
  geom_point() + ggtitle('Number of playlists in the Top 1000, by content type')

ggplot(data=tmp, aes(x=date, y=sum_followers, col = content_type)) +
  geom_line()+
  geom_point() + ggtitle('Number of followers in the Top 1000, by content type')

# Placements --------------------------------------------------------------
length(unique(placements$track_id))
length(unique(placements$track_genre))
length(unique(placements$cm_playlist_id))
tmp = placements[, list(ntracks = length(unique(track_id))), by=c('cm_playlist_id')]
summary(tmp$ntracks)

# Period of tracks on playlists (excl. removed tracks)
tmp = placements
tmp$ndays = tmp$removed_at-tmp$added_at
tmp$ndays = as.numeric(tmp$ndays)
summary(tmp$ndays)

# Tracks placement (in general)
tmp = placements[track_position <= 100,] %>% 
  group_by(cm_playlist_id) %>%
  mutate(mean_added_at = mean(added_at, na.rm = TRUE))
tmp$mean_difference = tmp$added_at - tmp$mean_added_at

tmp = tmp %>%
  group_by(track_position) %>%
  summarize(Mean = mean(mean_difference, na.rm = TRUE))

tmp %>% ggplot(aes(x = track_position, y = Mean)) +
  geom_line() +
  ylab("Days difference") +
  xlab("Position") +
  theme_light()

# Track placement by owner class
tmp = placements[track_position <= 100,] %>% 
  group_by(cm_playlist_id, curator_type) %>%
  mutate(mean_added_at = mean(added_at, na.rm = TRUE))
tmp$mean_difference = tmp$added_at - tmp$mean_added_at

tmp = tmp %>%
  group_by(track_position, curator_type) %>%
  summarize(Mean = mean(mean_difference, na.rm = TRUE))

tmp %>% ggplot(aes(x = track_position, y = Mean, color = curator_type)) +
  geom_line() +
  ylab("Days difference") +
  xlab("Position") +
  theme_light()

# Track placement by content type
placements[playlists, ':=' (content_type=i.content_type)]
tmp = placements[track_position <= 100,] %>% 
  group_by(cm_playlist_id, content_type) %>%
  mutate(mean_added_at = mean(added_at, na.rm = TRUE))
tmp$mean_difference = tmp$added_at - tmp$mean_added_at

tmp = tmp %>%
  group_by(track_position, content_type) %>%
  summarize(Mean = mean(mean_difference, na.rm = TRUE))

tmp %>% ggplot(aes(x = track_position, y = Mean, color = content_type)) +
  geom_line() +
  ylab("Days difference") +
  xlab("Position") +
  theme_light()

# Track placement by newness of the song
placements[release_dates >= "2019-08-27", track_age:= 'less than 1 month old'] #max date = '2019-09-27'
placements[release_dates < "2019-08-27" & release_dates >= "2019-02-27", track_age:= 'between 1 and 6 months old']
placements[release_dates < "2019-02-27" & release_dates >= "2018-08-27", track_age:= 'between 6 and 12 months old']
placements[release_dates < "2018-08-27", track_age:= 'older than 1 year']
placements$track_age = as.factor(placements$track_age)
summary(placements$track_age)

tmp = placements[track_position <= 100,] %>% 
  group_by(cm_playlist_id, track_age) %>%
  mutate(mean_added_at = mean(added_at, na.rm = TRUE))
tmp$mean_difference = tmp$added_at - tmp$mean_added_at

tmp = tmp %>%
  group_by(track_position, track_age) %>%
  summarize(Mean = mean(mean_difference, na.rm = TRUE))

subset(tmp, !is.na(track_age)) %>% ggplot(aes(x = track_position, y = Mean, color = track_age)) +
  geom_line() +
  ylab("Days difference") +
  xlab("Position") +
  theme_light()

# Plots with aggregated data ----------------------------------------------

date_aggregated <- aggregate(train[,2:25], by = list(train$date), FUN=mean, na.rm = T)
date_aggregated$Group.1 <- NULL
save(date_aggregated, file = 'gen/analysis/temp/date_aggregated.Rda')

date_ts_aggregated <- aggregate(ts_train[,2:13], by = list(ts_train$date), FUN=mean, na.rm = T)
date_ts_aggregated$Group.1 <- NULL
save(date_ts_aggregated, file = 'gen/analysis/temp/date_ts_aggregated.Rda')

# Percentage difference from mean scale:
tmp = date_aggregated
tmp$week = as.Date(cut(tmp$date, breaks = "week"))
tmp <- tmp %>% group_by(week) %>%
  summarise_all(mean)
tmp$date <- NULL

cols = append(grep('^avg', colnames(tmp),value=T), 'nr_artists')
for (col in cols) tmp[[col]] = ((tmp[[col]]-mean(tmp[[col]]))/mean(tmp[[col]]))*100
tmp %>% ggplot(aes(week)) +
  geom_line(aes(y = avg_danceability, color = "danceability")) +
  geom_line(aes(y = avg_energy, color = "energy")) +
  geom_line(aes(y = avg_acousticness, color = "acousticness")) +
  geom_line(aes(y = avg_instrumentalness, color = "instrumentalness")) +
  geom_line(aes(y = avg_liveness, color = "liveness")) +
  geom_line(aes(y = avg_key, color = "key")) +
  ylab("Percentage difference") +
  xlab("Date") +
  scale_x_date(breaks = "3 months", labels = date_format("%Y-%m")) +
  theme_light() +
  theme(axis.text.x = element_text(angle = 60, hjust = 1)) +
  labs(color = '')

tmp %>% ggplot(aes(week)) +
  geom_line(aes(y = avg_mode, color = "mode")) +
  geom_line(aes(y = avg_valence, color = "valence")) +
  geom_line(aes(y = avg_speechiness, color = "speechiness")) +
  geom_line(aes(y = avg_loudness, color = "loudness")) +
  geom_line(aes(y = avg_tempo, color = "tempo")) +
  ylab("Percentage difference") +
  xlab("Date") +
  scale_x_date(breaks = "3 months", labels = date_format("%Y-%m")) +
  theme_light() +
  theme(axis.text.x = element_text(angle = 60, hjust = 1)) +
  labs(color = '')

tmp %>% ggplot(aes(week)) +
  geom_line(aes(y = nr_artists)) +
  ylab("Percentage difference") +
  xlab("Date") +
  scale_x_date(breaks = "3 months", labels = date_format("%Y-%m")) +
  theme_light() +
  theme(axis.text.x = element_text(angle = 60, hjust = 1))

tmp = train[, list(nplaylists = length(unique(cm_playlist_id))), by=c('date')]
tmp %>% ggplot(aes(date)) +
  geom_line(aes(y=nplaylists)) +
  ylab("Number of playlists") +
  xlab("Date") +
  scale_x_date(breaks = "3 months", labels = date_format("%Y-%m")) +
  theme_light() +
  theme(axis.text.x = element_text(angle = 60, hjust = 1))

# Percentage difference from mean scale for cv
tmp = date_aggregated
tmp$week = as.Date(cut(tmp$date, breaks = "week"))
tmp <- tmp %>% group_by(week) %>%
  summarise_all(mean)
tmp$date <- NULL

cols = grep('^cv', colnames(tmp),value=T)
for (col in cols) tmp[[col]] = ((tmp[[col]]-mean(tmp[[col]]))/mean(tmp[[col]]))*100
tmp %>% ggplot(aes(week)) +
  geom_line(aes(y = cv_danceability, color = "danceability")) +
  geom_line(aes(y = cv_energy, color = "energy")) +
  geom_line(aes(y = cv_acousticness, color = "acousticness")) +
  geom_line(aes(y = cv_instrumentalness, color = "instrumentalness")) +
  geom_line(aes(y = cv_liveness, color = "liveness")) +
  geom_line(aes(y = cv_key, color = "key")) +
  ylab("Percentage difference") +
  xlab("Date") +
  scale_x_date(breaks = "3 months", labels = date_format("%Y-%m")) +
  theme_light() +
  theme(axis.text.x = element_text(angle = 60, hjust = 1)) +
  labs(color = '')

tmp %>% ggplot(aes(week)) +
  geom_line(aes(y = cv_mode, color = "mode")) +
  geom_line(aes(y = cv_valence, color = "valence")) +
  geom_line(aes(y = cv_speechiness, color = "speechiness")) +
  geom_line(aes(y = cv_loudness, color = "loudness")) +
  geom_line(aes(y = cv_tempo, color = "tempo")) +
  ylab("Percentage difference") +
  xlab("Date") +
  scale_x_date(breaks = "3 months", labels = date_format("%Y-%m")) +
  theme_light() +
  theme(axis.text.x = element_text(angle = 60, hjust = 1)) +
  labs(color = '')

# Percentage difference from mean scale for mad
tmp = date_ts_aggregated
tmp$week = as.Date(cut(tmp$date, breaks = "week"))
tmp <- tmp %>% group_by(week) %>%
  summarise_all(mean)
tmp$date <- NULL

cols = grep('^mad', colnames(tmp),value=T)
for (col in cols) tmp[[col]] = ((tmp[[col]]-mean(tmp[[col]]))/mean(tmp[[col]]))*100
tmp %>% ggplot(aes(week)) +
  geom_line(aes(y = mad_danceability, color = "danceability")) +
  geom_line(aes(y = mad_energy, color = "energy")) +
  geom_line(aes(y = mad_acousticness, color = "acousticness")) +
  geom_line(aes(y = mad_instrumentalness, color = "instrumentalness")) +
  geom_line(aes(y = mad_liveness, color = "liveness")) +
  geom_line(aes(y = mad_key, color = "key")) +
  ylab("Percentage difference") +
  xlab("Date") +
  scale_x_date(breaks = "3 months", labels = date_format("%Y-%m")) +
  theme_light() +
  theme(axis.text.x = element_text(angle = 60, hjust = 1)) +
  labs(color = '')

tmp %>% ggplot(aes(week)) +
  geom_line(aes(y = mad_mode, color = "mode")) +
  geom_line(aes(y = mad_valence, color = "valence")) +
  geom_line(aes(y = mad_speechiness, color = "speechiness")) +
  geom_line(aes(y = mad_loudness, color = "loudness")) +
  geom_line(aes(y = mad_tempo, color = "tempo")) +
  ylab("Percentage difference") +
  xlab("Date") +
  scale_x_date(breaks = "3 months", labels = date_format("%Y-%m")) +
  theme_light() +
  theme(axis.text.x = element_text(angle = 60, hjust = 1)) +
  labs(color = '')
