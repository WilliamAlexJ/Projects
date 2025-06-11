








install.packages(c("tidyverse","lubridate","randomForest","caret","ggplot2"))
library(tidyverse)
library(lubridate)
library(randomForest)
library(caret)
library(ggplot2)


df <- read_csv("DGS10.csv",
               col_types = cols(
                 observation_date = col_date(format = "%Y-%m-%d"),
                 DGS10             = col_double()
               ))

#Rename & sort
df <- df %>%
  rename(Date = observation_date,
         Yield = DGS10) %>%
  arrange(Date)

#create lagged features + calendar dummies
df <- df %>%
  mutate(
    lag1  = lag(Yield, 1),
    lag2  = lag(Yield, 2),
    lag5  = lag(Yield, 5),
    month = month(Date),
    wday  = wday(Date, label = TRUE)
  ) %>%
  drop_na()   # drops first few rows where lag is NA

#Train/test split (80% train, 20% test)
split <- floor(0.8 * nrow(df))
train <- df[1:split, ]
test  <- df[(split+1):nrow(df), ]

#Fit a Random Forest
set.seed(42)
rf_mod <- randomForest(
  formula = Yield ~ lag1 + lag2 + lag5 + month + wday,
  data    = train,
  ntree   = 500
)

#Predict & evaluate
test$pred <- predict(rf_mod, newdata = test)
rmse <- sqrt(mean((test$Yield - test$pred)^2))
cat("Out-of-sample RMSE:", round(rmse,4), "\n")

#Plot actual vs predicted
ggplot(test, aes(x = Date)) +
  geom_line(aes(y = Yield), color = "gray40") +
  geom_line(aes(y = pred),  color = "steelblue") +
  labs(
    title = "10-Year Treasury Yield: Actual vs RF Prediction",
    x     = "Date",
    y     = "Yield (%)"
  ) +
  theme_minimal()











# retrain on full dataset
rf_full <- randomForest(Yield ~ lag1 + lag2 + lag5 + month + wday,
                        data = df, ntree = 500)

# prepare a “current” feature row from the last available date
last_row <- tail(df, 1)

# function to get month/wday for a Date
next_md <- function(prev_date, days_ahead = 1) {
  nd <- prev_date + days_ahead
  list(
    month = month(nd),
    wday  = wday(nd, label = TRUE)
  )
}

h <- 10  # how many days to forecast
preds <- numeric(h)
cur_feats <- last_row

for(i in seq_len(h)) {
  # predict
  preds[i] <- predict(rf_full, newdata = cur_feats)
  
  # shift lags
  cur_feats <- cur_feats %>%
    mutate(
      Date   = Date + 1,             # next calendar day
      lag5   = lag2,                 # shift lag2 → lag5
      lag2   = lag1,                 # shift lag1 → lag2
      lag1   = preds[i],             # new pred → lag1
      # update month & wday
      month  = next_md(Date, 1)$month,
      wday   = next_md(Date, 1)$wday
    )
}

#data.frame of future dates
future_dates <- seq(from = last_row$Date + 1, by = "day", length.out = h)
forecast_df <- tibble(Date = future_dates, Predicted_Yield = preds)

# plot
library(ggplot2)
ggplot() +
  geom_line(data = df, aes(x = Date, y = Yield), color = "grey80") +
  geom_line(data = forecast_df, aes(x = Date, y = Predicted_Yield), color = "steelblue") +
  labs(title = paste0(h, "-Day Ahead RF Forecast of 10-Year Yield"),
       x = "Date", y = "Yield (%)") +
  theme_minimal()

