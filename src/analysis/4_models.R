# Set up ------------------------------------------------------------------

library(stargazer)

load('gen/data-preparation/temp/train.Rda')
load('gen/data-preparation/temp/test.Rda')
load('gen/data-preparation/temp/ts_train.Rda')
load('gen/data-preparation/temp/ts_test.Rda')

# For the model, we only take into account complete cases
train <- na.omit(train)
test <- na.omit(test)
ts_train <- na.omit(ts_train)
ts_test <- na.omit(ts_test)

# Model (within-playlist variety) -------------------------------------------------------------------

model <- lm(r_followers ~ date + cv_key + cv_mode + cv_danceability + cv_energy + cv_speechiness + cv_acousticness + cv_instrumentalness + 
              cv_liveness + cv_valence + cv_tempo + cv_loudness + nr_artists + curator_type, data = train)
car::vif(model) #packages rms and DAAG give the same results, all VIFS < 5

model <- lm(r_followers ~ date + cv_key + cv_mode + cv_danceability + cv_energy + cv_speechiness + cv_acousticness + cv_instrumentalness + 
              cv_liveness + cv_valence + cv_tempo + cv_loudness + nr_artists + curator_type +
              I(cv_key^2) + I(cv_mode^2) + I(cv_danceability^2) + I(cv_energy^2) + I(cv_speechiness^2) + I(cv_acousticness^2) + I(cv_instrumentalness^2) + 
              I(cv_liveness^2) + I(cv_valence^2) + I(cv_tempo^2) + I(cv_loudness^2) + I(nr_artists^2) +
              cv_key*curator_type + cv_mode*curator_type + cv_danceability*curator_type + cv_energy*curator_type + cv_speechiness*curator_type + 
              cv_acousticness*curator_type + cv_instrumentalness*curator_type + cv_liveness*curator_type + cv_valence*curator_type + cv_tempo*curator_type + 
              cv_loudness*curator_type + nr_artists*curator_type, data = train)

cat(capture.output(summary(model)), file = "gen/analysis/output/model_output.txt", sep = "\n", append = TRUE)
stargazer(model, type = 'html', no.space=T, single.row = T)

p_train <- predict(model, train)
e_train <- train$r_followers - p_train
sqrt(mean(e_train^2)) #RMSE training set: 0.2339427
p_test <- predict(model, test)
e_test <- test$r_followers - p_test
sqrt(mean(e_test^2)) #RMSE test set: 0.2333697
cor(p_test, test$r_followers)^2 #R2 test set: 0.572393

# Model (transition variety) ----------------------------------------------

model <- lm(r_followers ~ date + mad_key + mad_mode + mad_danceability + mad_energy + mad_speechiness + mad_acousticness + mad_instrumentalness + 
              mad_liveness + mad_valence + mad_tempo + mad_loudness + curator_type, data = ts_train)
car::vif(model) #All VIF values are < 2, no multicollinearity problem)

model <- lm(r_followers ~ date + mad_key + mad_mode + mad_danceability + mad_energy + mad_speechiness + mad_acousticness + mad_instrumentalness + 
              mad_liveness + mad_valence + mad_tempo + mad_loudness + curator_type +
              I(mad_key^2) + I(mad_mode^2) + I(mad_danceability^2) + I(mad_energy^2) + I(mad_speechiness^2) + I(mad_acousticness^2) + I(mad_instrumentalness^2) + 
              I(mad_liveness^2) + I(mad_valence^2) + I(mad_tempo^2) + I(mad_loudness^2) +
              mad_key*curator_type + mad_mode*curator_type + mad_danceability*curator_type + mad_energy*curator_type + mad_speechiness*curator_type + 
              mad_acousticness*curator_type + mad_instrumentalness*curator_type + mad_liveness*curator_type + mad_valence*curator_type + mad_tempo*curator_type + 
              mad_loudness*curator_type, data = ts_train)

cat(capture.output(summary(model)), file = "gen/analysis/output/model_output.txt", sep = "\n", append = TRUE)
stargazer(model, type = 'html', no.space=T, single.row = T)

p_train <- predict(model, ts_train)
e_train <- ts_train$r_followers - p_train
sqrt(mean(e_train^2)) #RMSE training set: 0.2310051
p_test <- predict(model, ts_test)
e_test <- ts_test$r_followers - p_test
sqrt(mean(e_test^2)) #RMSE test set: 0.2319131
cor(p_test, ts_test$r_followers)^2 #R2 test set: 0.5563353

