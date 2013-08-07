############
# Merge together data for regressions
# Christopher Gandrud
# 7 August 2013
############

# Load libraries
library(lubridate)
library(DataCombine)
library(plyr)

##### Econ Data ####
# Load econ data
EconData <- read.csv("~/Dropbox/Fed_Speeches_Paper/FedSpeech/Data/FREDEconData.csv")
EconData <- rename(EconData, c("DateField" = "month_year"))
EconData$month_year <- ymd(EconData$month_year) 

# Drop if missing
EconData <- subset(EconData, !is.na(U6RATE))
EconData <- subset(EconData, !is.na(GDPDEF))

#### Topics Data ####
Topics <- read.csv("~/Dropbox/Fed_Speeches_Paper/FedSpeech/Data/TopicsSpoken.csv")
Topics$full_date <- dmy(Topics$full_date) 

#### Speeches Connectivity Data ####
Connect <- read.csv("~/Dropbox/Fed_Speeches_Paper/FedSpeech/Data/ConnectivityClean.csv",
                    stringsAsFactors = FALSE)
Connect$full_date <- ymd(Connect$full_date)

OrgClass <- read.csv("~/Dropbox/Fed_Speeches_Paper/FedSpeech/Data/Raw/BaseSpeechCount.csv", 
                     stringsAsFactors = FALSE)
OrgClass$full_date <- dmy(OrgClass$full_date)

# Keep if 1997 or later
OrgClass <- subset(OrgClass, year > 1996)

# Remove Extraneous vars
OrgClass <- OrgClass[, -3:-5]

RemoveTitle <- function(data){
    data[, "name"] <- gsub(pattern = "Governor†", "", data[, "name"])
    data[, "name"] <- gsub(pattern = "Governor", "", data[, "name"])
    data[, "name"] <- gsub(pattern = "Chairman†", "", data[, "name"])
    data[, "name"] <- gsub(pattern = "Chairman", "", data[, "name"])
    data[, "name"] <- gsub(pattern = "Vice Chair†", "", data[, "name"])
    data[, "name"] <- gsub(pattern = "Vice Chair", "", data[, "name"])
    data
}
trim.leading <- function (x)  sub("^\\s+", "", x)

Connect <- RemoveTitle(data = Connect)
Connect$name <- trim.leading(Connect$name)
OrgClass <- RemoveTitle(data = OrgClass)

# Merge
Speeches <- merge(Connect, OrgClass, by = c("full_date", "name"), all = TRUE)
Speeches <- subset(Speeches, !is.na(full_date))
Speeches <- MoveFront(Speeches, c("month_year", "year"))

# Drop duplicates
Speeches <- Speeches[!duplicated(Speeches[, c("full_date", "name")]), ]

# Create new month_year variable
Speeches$month_year <- floor_date(Speeches$full_date, "month")

#### Congressional Scrutiny States ####
### See ChangePointCongFed.Rnw
Speeches$Scrutiny[Speeches$month_year < as.POSIXct("2007-04-01")] <- "Low" 
Speeches$Scrutiny[Speeches$month_year >= as.POSIXct("2007-04-01")] <- "High" 
Speeches$Scrutiny[Speeches$month_year >= as.POSIXct("2010-06-01")] <- "Medium"
Speeches$Scrutiny <- as.factor(Speeches$Scrutiny)

#### Final Merge and Clean #### 
Combined <- merge(Speeches, Topics, by = c("full_date", "name"))
Combined <- merge(Combined, EconData, by = "month_year")