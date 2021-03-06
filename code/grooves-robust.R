grooves <- readr::read_csv("csvs/grooves.csv")

library(dplyr)
library(ggplot2)
library(MASS)
library(tidyr)

grooves <- grooves %>% dplyr::select (-groove_left_pred, -groove_right_pred, -left_twist, -right_twist)
grooves <- data.frame(grooves)
res <- grooves %>%  tidyr::nest(-bullet)

res$grooves <- res$data %>% purrr::map(
  .f = function(d) {
    groove_right_pred = d$groove_right
    groove_left_pred = d$groove_left
    right_twist = NA
    left_twist = NA
    
#    d <- d %>% mutate(
#      groove_right = replace(groove_right, groove_right == max(groove_right), NA),
#      groove_left = replace(groove_left, groove_left == min(groove_left), NA)
#    )
    d <- d %>% mutate(
      groove_right = replace(groove_right, groove_right < quantile(groove_right, .1, na.rm=TRUE), NA),
      groove_right = replace(groove_right, groove_right > quantile(groove_right, .9, na.rm=TRUE), NA),
      groove_left = replace(groove_left, groove_left < quantile(groove_left, .1, na.rm=TRUE), NA),
      groove_left = replace(groove_left, groove_left > quantile(groove_left, .9, na.rm=TRUE), NA),
      groove_right = replace(groove_right, groove_right == max(groove_right, na.rm = TRUE), NA),
      groove_left = replace(groove_left, groove_left == min(groove_left, na.rm = TRUE), NA)
    )
    
    right_sample = sum(!is.na(d$groove_right))
    if (!all(is.na(d$groove_right))) {
      rr <- try({rlm(data=d, groove_right~x)})
      if (!inherits(rr, "try-error")) {
          groove_right_pred=predict(rr, d)
          right_twist = rr$coefficients[2]
      }
    }
    left_sample = sum(!is.na(d$groove_right))
    if (!all(is.na(d$groove_left))) {
      rl <- try({rlm(data=d, groove_left~x)})
      if (!inherits(rl, "try-error")) {
          groove_left_pred= predict(rl,d)
          left_twist = rl$coefficients[2]
      }
    }
    data.frame(groove_left_pred, groove_right_pred, 
               right_twist=right_twist, left_twist= left_twist, 
               right_sample = right_sample, left_sample = left_sample)
  }
)

grooves <- res %>% unnest()
write.csv(grooves, "csvs/grooves.csv", row.names=FALSE)

grooves %>% ggplot(aes(x = groove_left, y = groove_left_pred)) + geom_point()
####################
# some visualizations

land <- grooves %>% filter(bullet == "images/Hamby (2009) Barrel/bullets/Br10 Bullet 1-1.x3p")

rr <- rlm(data=land, groove_right~x)
rl <- rlm(data=land, groove_left~x)

land %>%
  ggplot(aes(x = x, y = groove_right)) +
  geom_point() +
  geom_smooth(method="lm", se=FALSE) +
  geom_abline(intercept = rr$coefficients[1], slope = rr$coefficients[2], colour="red") 

land %>% 
  ggplot(aes(x = predict(rr, land), y = x)) + 
  geom_point() +
  geom_point(aes(x = predict(rl, land))) +
  geom_point(aes(x = groove_right), colour="red") +
  geom_point(aes(x = groove_left), colour="red") 
