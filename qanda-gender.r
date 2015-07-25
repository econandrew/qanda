library(reshape2)
library(RSQLite)
library(ggplot2)

setwd('/Users/andrew/Documents/Ideas/Qanda/')

# open 
db <- dbConnect(SQLite(), 'qanda.db')
res <- dbGetQuery(db, "select * from speeches_by_party_pols_complete_panels")
res2 <- dbGetQuery(db, "select * from apps_by_party_pols_complete_panels")
res3 <- dbGetQuery(db, "select * from words_by_party_pols_complete_panels")