library(reshape2)
library(RSQLite)
library(ggplot2)
library(lubridate)
library(data.table)

clip_copy = function(data) {
  clip <- pipe("pbcopy", "w")                       
  write.csv(data, file=clip)                               
  close(clip)
}


setwd('/Users/andrew/Documents/Ideas/Qanda2015/')

# open 
db <- dbConnect(SQLite(), 'qanda.db')
res <- dbGetQuery(db, "select * from speeches_by_party_pols_complete_panels")
res2 <- dbGetQuery(db, "select * from apps_by_party_pols_complete_panels")
res3 <- dbGetQuery(db, "select * from words_by_party_pols_complete_panels")
r = merge(merge(res, res2),res3)

words <- dbGetQuery(db, "select * from sample_words_by_party_pols_complete_panels")
words$party <- factor(words$party)

words.lib <- words[words$party == 'LIBERAL',]
words.lab <- words[words$party == 'LABOR',]
dens.lib <- density(words.lib$words)
dens.lab <- density(words.lab$words)
plot(range(dens.lib$x, dens.lab$x), range(dens.lib$y, dens.lab$y), type = "n", xlab = "x", ylab = "Density")
lines(dens.lab, col = "red")
lines(dens.lib, col = "blue")

hist(words.lab$words, col='black')
words.rs <- dcast(words, ep_date ~ party, value = 'words', mean)
words.liblab.wilcox <- wilcox.test(words.rs$LIBERAL, words.rs$LABOR, paired = TRUE)

print('*** Wilcoxon signed rank text for LIBERAL == LABOR words per appearance ***', quote=FALSE)
print(words.liblab.wilcox)

diffs = words.rs$LABOR - words.rs$LIBERAL

print('*** Median difference in words per appearance LABOR - LIBERAL ***', quote=FALSE)
print(median(diffs, na.rm = TRUE))

print('*** Per episode plots LABOR - COALITION ***', quote=FALSE)
cumwords <- dbGetQuery(db, "select * from cumwords_by_party_pols_fair_panels")
cumwords$ep_date <- as.Date(cumwords$ep_date)
cumwords$party[cumwords$party %in% c('LIBERAL', 'NATIONAL', 'LNP')] <- 'COALITION' 
cumwords$party <- factor(cumwords$party)
cumwords.liblab <- cumwords[cumwords$party == 'COALITION' | cumwords$party == 'LABOR',]

cumwords.liblab[cumwords.liblab$party == 'COALITION', 'wc'] <- - cumwords.liblab[cumwords.liblab$party == 'COALITION', 'wc']
cumwords.liblab.agg <- aggregate(wc ~ ep_date, cumwords.liblab, sum)
cumwords.liblab.agg[,'mov.wc'] <- filter(cumwords.liblab.agg$wc, rep(1,5), sides=1)
cumwords.liblab.agg[,'cum.wc'] <- cumsum(cumwords.liblab.agg$wc)

years.start <- c('2009-01-01', '2010-01-01', '2011-01-01', '2012-01-01', '2013-01-01', '2013-09-08', '2014-01-01', '2015-01-01')
years.end <- c('2009-12-31', '2010-12-31', '2011-12-31', '2012-12-31', '2013-09-07', '2013-12-31', '2014-12-13','2015-06-30')
map_year <- function(d, start) {
  for (i in 1:length(years.start)) {
    if (years.start[i] <= d && d <= years.end[i]) {
      if (start) {
        result = years.start[i]
      } else {
        result = years.end[i]
      }
    }
  }
  
  result
}

map_year_start <- function(x) map_year(x, TRUE)
map_year_end <- function(x) map_year(x, FALSE)

cumwords.liblab.agg[,'year.start'] <- as.Date(sapply(cumwords.liblab.agg$ep_date, map_year_start))
cumwords.liblab.agg[,'year.end'] <- as.Date(sapply(cumwords.liblab.agg$ep_date, map_year_end))

cumwords.liblab.year <- aggregate(wc ~ year.start + year.end, cumwords.liblab.agg, mean)

p <- qplot(x = ep_date, y = cum.wc, data = cumwords.liblab.agg, geom="path")
gp <- p + theme_bw() + xlab('Episode date') + ylab('Cumulative excess words (to Labor)')
ggsave('charts/cumwords.pdf', p)
p

p <- ggplot(data = cumwords.liblab.agg, aes(x = ep_date, y = wc))
p <- p + geom_point()
p <- p + geom_segment(data = cumwords.liblab.year[1:5,], aes(x = year.start, y = wc, xend = year.end, yend = wc), colour = "red")
p <- p + geom_segment(data = cumwords.liblab.year[6:8,], aes(x = year.start, y = wc, xend = year.end, yend = wc), colour = "blue")
p <- p + theme_bw() + xlab('Episode date') + ylab('Excess words (to Labor)')
p <- p + geom_hline(yintercept = 0, colour = "black", linetype = "longdash")
p <- p + ylim(-max(abs(cumwords.liblab.agg$wc)), max(abs(cumwords.liblab.agg$wc)))
p <- p + ggtitle("Annual average excess Labor words on ABC Q&A")
ggsave('charts/yearbyyear.pdf', p, width=13, height=13, units="cm")
p
