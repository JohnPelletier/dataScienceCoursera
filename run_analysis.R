#!

######################################################################################################################
##
## GETTING AND CLEANING DATA FINAL PROJECT 
##
## run_analysis.R
##
## By John Pelletier
##
## This script downloads a machine learning dataset from the web, conditions and cleans the data and 
##then gets means and deviations of certain data from the dataset
##
######################################################################################################################

library(curl)
library(dplyr)

######################################################################################################################
##
## This first section downloads the zip file, unzips and reads the various datasets into memory
##
######################################################################################################################

##Get the data
if(!file.exists("./data")){dir.create("./data")}
fileUrl <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
cat("Downloading the dataset zip file using curl_download...\n")
curl_download(fileUrl, destfile ="./data/Dataset.zip")

##Unzip it
cat("Unzipping the file...\n")
unzip(zipfile="./data/Dataset.zip",exdir="./data")

##set path to the files
path_rf <- file.path("./data" , "UCI HAR Dataset")

##Activities are the various 6 activities such as WALKING, STANDING, etc.
##Read activity files into memory, combine them, then clean up
cat("Reading activity data (activity 1, activity = 2, etc)...\n")
activityTest  <- read.table(file.path(path_rf, "test" , "Y_test.txt" ),header = FALSE)
activityTrain <- read.table(file.path(path_rf, "train", "Y_train.txt"),header = FALSE)
dataActivity<- rbind(activityTrain, activityTest)
names(dataActivity)<- c("activity")
rm(activityTrain)
rm(activityTest)

##Subjects are the different test subjects' (people's) reference numbers
##Read subject files into memory, combine them then clean up
cat("Reading subject data (Subject IDs 1, 2, etc)...\n")
dataSubjectTrain <- read.table(file.path(path_rf, "train", "subject_train.txt"),header = FALSE)
dataSubjectTest  <- read.table(file.path(path_rf, "test" , "subject_test.txt"),header = FALSE)
dataSubject <- rbind(dataSubjectTrain, dataSubjectTest)
names(dataSubject)<-c("subject")
rm(dataSubjectTrain)
rm(dataSubjectTest)

##Features are the actual value readings from the different sensors
##read features files, combine them, then clean up
cat("Reading normalized value readings data...\n")
dataFeaturesTest  <- read.table(file.path(path_rf, "test" , "X_test.txt" ),header = FALSE)
dataFeaturesTrain <- read.table(file.path(path_rf, "train", "X_train.txt"),header = FALSE)
dataFeatures<- rbind(dataFeaturesTrain, dataFeaturesTest)
rm(dataFeaturesTrain)
rm(dataFeaturesTest)

##Assign titles to every column in the features dataset, such as "tBodyAcc-mean()-X"
cat("Reading variable names for values...\n")
dataFeaturesNames <- read.table(file.path(path_rf, "features.txt"),head=FALSE)
names(dataFeatures)<- dataFeaturesNames$V2
rm(dataFeaturesNames)

##Read in the six activity labels [WALKING, WALKING_UPSTAIRS, etc]
cat("Converting to readable activity labels (1 => WALKING, 2 => WALKING_UPSTAIRS, etc...\n")
activityLabels <- read.table(file.path(path_rf, "activity_labels.txt"),header = FALSE)
##Create a vector with readable activity names that match activity of subjects
rdblActivity <- activityLabels$V2[dataActivity$activity]
rm(dataActivity)
rm(activityLabels)

######################################################################################################################
##
## This next section conditions the data to be 'clean' and readable
##
######################################################################################################################


##Filter to only have std and mean columns
cat("Filtering to only std deviation and mean columns...\n")
dataFeatures <- subset(dataFeatures, select = grep(".*std|mean.*", names(dataFeatures)))
##get rid of parentheses and dashes in names so they don't cause trouble later 
cat("Getting rid of () and - in the column names...\n")
names(dataFeatures) <- sapply(names(dataFeatures), function(x) gsub("\\(\\)", "", x))
names(dataFeatures) <- sapply(names(dataFeatures), function(x) gsub("\\-", "\\_", x))

## Convert to a data table for easier handling
##dataFeatures <- tbl_df(dataFeatures)

## Combine subjects with their activity
subject.activity <- cbind(dataSubject, rdblActivity)
##Add subject and activity to the dataset 
Data <- cbind(subject.activity, dataFeatures)

## Remove other temp variables to free up memory
rm(dataSubject)
rm(subject.activity)
rm(dataFeatures)
rm(rdblActivity)

## Make the variables names more readable
cat("Make column names more readable...\n")
names(Data)<-gsub("^t", "time", names(Data))
names(Data)<-gsub("^f", "frequency", names(Data))
names(Data)<-gsub("Acc", "Accelerometer", names(Data))
names(Data)<-gsub("Gyro", "Gyroscope", names(Data))
names(Data)<-gsub("Mag", "Magnitude", names(Data))
names(Data)<-gsub("BodyBody", "Body", names(Data))


##Convert the main dataset to a data table for easier management
Data <- tbl_df(Data)

## Rename to lower case activity variable
Data <- rename(Data, activity = rdblActivity)


######################################################################################################################
##
## This last section makes the smaller data subset of just column means for each subject+activity combination
##
######################################################################################################################


## Create tidy data subset that only has the means of each column for each combination of subject and action
cat("Aggregating data by subject and activity...\n")
tidyData <-aggregate(. ~subject + activity, Data, mean)
  
## Reorder rows based on subject, then activity
tidyData<-tidyData[order(tidyData$subject,tidyData$activity),]

## Write the response out to a text file
cat("Writing new tidyData dataset out to a text file...\n")
write.table(tidyData, file = "tidydata.txt",row.name=FALSE) 

cat("Finished!\n")


#######################
##DONE! FINITO! FIN!  #
#######################

