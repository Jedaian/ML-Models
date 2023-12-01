data <- read.csv2('Dataset/titanic2.csv', encoding = 'UTF-8')

#Renaming Column to be shorter
colnames(data)[2] <- 'Pclass'
colnames(data)[6] <- 'SibSp'
colnames(data)[7] <- 'ParCh'
colnames(data)[8] <- 'Ticket'
colnames(data)[9] <- 'Fare'
colnames(data)[11] <- 'Embarked'

#Grouping for analyzing
pclass_surv <- aggregate(Survived~Pclass, data, FUN = 'mean')
sex_surv <- aggregate(Survived~Sex, data, FUN = 'mean')
sibsp_surv <- aggregate(Survived~SibSp, data, FUN = 'mean')
parch_surv <- aggregate(Survived~ParCh, data, FUN = 'mean')

#Visualization
#install.packages("ggplot2")
library(ggplot2)
data <- data[!(is.na(data$Survived) | data$Survived==""), ]
label_survived <- c('No' = 'Survived = 0', 'Yes' = 'Survived = 1')
a <- ggplot(data, aes(x = Age, fill = Survived)) + geom_histogram(bins = 20, alpha = 0.7)
a + facet_grid(.~Survived, labeller = labeller(Survived = label_survived)) + 
  labs(x = "Age", y = 'Frequency', title = 'Distribution of Age based on Survival') + theme_grey()

label_pclass <- c('First' = 'PClass = 1', 'Second' = 'PClass = 2', 'Third' = 'PClass = 3')
b <- ggplot(data, aes(Age, fill = Survived)) + geom_histogram(bins = 20, alpha = 0.7)
b + facet_grid(.~Pclass~Survived, labeller = labeller(Survived = label_survived, Pclass = label_pclass)) + 
  labs(x = 'Age', y = 'Frequency', title = 'Distribution of Age based on Survival and Pclass') + theme_grey()

data <- data[!(is.na(data$Embarked) | data$Embarked==""), ]
c <- ggplot(data, aes(x = Sex, y = Fare, fill = Sex)) + geom_bar(stat = 'identity')
c + facet_grid(.~Embarked~Survived, labeller = labeller(Survived = label_survived)) + 
  theme_grey() + labs(title = 'Correlation of Embarked and Survival rate with Sex and Fare')

#Data preprocessing
library(plyr)
map <- c('Female', 'Male')
data$Sex <- mapvalues(data$Sex, from = map, to = c(0, 1))
data$Sex <- as.integer(data$Sex)

Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}
data$Embarked <- replace(data$Embarked, data$Embarked == "", Mode(data$Embarked))
map2 <- c(unique(data$Embarked))
data$Embarked <- mapvalues(data$Embarked, from = map2, to = c(0, 1, 2))
data$Embarked <- as.integer(data$Embarked)

data$Age <- replace(data$Age, is.na(data$Age), mean(data$Age, na.rm = TRUE))

agegroup <- c()
for(x in data$Age){
  if(x < 20){
    agegroup <- c(agegroup, 1)
  }else if(x >= 20 && x < 40){
    agegroup <- c(agegroup, 2)
  }else if(x >= 40 && x < 60){
    agegroup <- c(agegroup, 3)
  }else if(x >= 60){
    agegroup <- c(agegroup, 4)
  }
}
data$Age <- agegroup

map3 <- unique(data$Survived)
data$Survived <- mapvalues(data$Survived, from = map3, to = c(1, 0))
data$Survived <- as.integer(data$Survived)

map4 <- unique(data$Pclass)
data$Pclass <- mapvalues(data$Pclass, from = map4, to = c(1, 2, 3))
data$Pclass <- as.integer(data$Pclass)

data$Fare <- replace(data$Fare, is.na(data$Fare), mean(data$Fare, na.rm = TRUE))
faregroup <- c()
for(x in data$Fare){
  if(x < 50){
    faregroup <- c(faregroup, 1)
  }else if(x >= 50 && x < 100){
    faregroup <- c(faregroup, 2)
  }else if(x >= 100 && x < 150){
    faregroup <- c(faregroup, 3)
  }else if(x >= 150 && x < 200){
    faregroup <- c(faregroup, 4)
  }else if(x >= 200){
    faregroup <- c(faregroup, 5)
  }
}
data$Fare <- faregroup

#Feature Engineering
#install.packages('plyr')
splits <- gsub(".*,(.*?)\\..*", "\\1", data$Name)
splits <- gsub(paste(c('Lady', 'Countess','Capt', 'Col', 'Don', 'Dr', 'Major', 'Rev', 'Sir', 
                       'Jonkheer', 'Dona', 'the Countess', 'Master'), collapse = '|'), 'Others', splits)
splits <- gsub(paste(c('Miss', 'Mlle', 'Ms', 'Mrs'), collapse = '|'), 'Miss', splits)
splits <- gsub(paste(c('Mr', 'Mme'), collapse = "|"), 'Mister', splits)
data$Title <- splits

data$Title <- trimws(data$Title)
map5 <- c('Miss', 'Mister', 'Others')
data$Title <- mapvalues(data$Title, from = map5, to = c(0, 1, 2))
data$Title <- as.integer(data$Title)

data$Fam <- data$ParCh + data$SibSp + 1
data$Alone <- ifelse(data$Fam == 1, 1, 0)

#Data reduction
drops <- c('Cabin', 'Ticket', 'Life.Boat', 'Name', 'PassengerId', 'ParCh', 'SibSp', 'Fam')
data <- data[, !(names(data) %in% drops)]

#Classification
set.seed(1)
sample <- sample(c(TRUE, FALSE), nrow(data), replace=TRUE, prob=c(0.7,0.3))
train  <- data[sample, ]
test   <- data[!sample, ]

#Random Forest
#install.packages('randomForest')
library(caret)
library(randomForest)
rf_model <- randomForest(Survived ~ Pclass + Sex + Age + Embarked + Title + Alone + Fare, data = train, ntree = 500)
rf_predictions <- predict(rf_model, newdata = test)

rf_predictions <- ifelse(rf_predictions > 0.5, '1', '0')
rf_predictions <- factor(rf_predictions, levels = c('0', '1'))
test_ref <- factor(test$Survived, levels = c('0', '1'))
conf_mat_RF <- confusionMatrix(rf_predictions, test_ref)
print(conf_mat_RF)

#Logistic Regression
logistic <- glm(Survived ~ Pclass + Sex + Age + Embarked + Title + Alone + Fare, family = binomial, data = train)
log_predictions <- predict(logistic, test, type = 'response')

log_predictions <- ifelse(log_predictions > 0.5, '1', '0')
log_predictions <- factor(log_predictions, levels = c('0', '1'))
conf_mat_log <- confusionMatrix(log_predictions, test_ref)
print(conf_mat_log)

#SVM
#install.packages('e1071')
library(e1071)
svm_model <- svm(formula = Survived ~ ., data = train, method="C-classification", kernel="radial")
svm_predictions <- predict(svm_model, test)

svm_predictions <- ifelse(svm_predictions > 0.5, '1', '0')
svm_predictions <- factor(svm_predictions, levels = c('0', '1'))
conf_mat_svm <- confusionMatrix(svm_predictions, test_ref)
print(conf_mat_svm)

#RF with PCA
library(stats)
pca <- prcomp(train[, -which(names(train) == "Survived")], center = TRUE, scale. = TRUE)
var_explained <- cumsum(pca$sdev^2) / sum(pca$sdev^2)
num_components <- which(var_explained > 0.95)[1]

train_pca <- predict(pca, train[, -which(names(train) == "Survived")])[ , 1:num_components]
test_pca <- predict(pca, test[, -which(names(test) == "Survived")])[ , 1:num_components]

train_ref <- as.factor(train$Survived)
rf_model_pca <- randomForest(x = train_pca, y = train_ref, ntree = 500)
rf_predictions_pca <- predict(rf_model_pca, newdata = test_pca)

rf_predictions_pca <- factor(rf_predictions_pca, levels(test_ref))
conf_mat_RF_pca <- confusionMatrix(rf_predictions_pca, test_ref)
print(conf_mat_RF_pca)

#Logistic Regression with PCA
train_pca <- as.data.frame(train_pca)
names(train_pca) <- paste0("PC", 1:ncol(train_pca))
test_pca <- as.data.frame(test_pca)
names(test_pca) <- paste0("PC", 1:ncol(test_pca))

train_pca$Survived <- factor(train$Survived, levels = c('0', '1'))
test_pca$Survived <- factor(test$Survived, levels = c('0', '1'))

logistic_pca <- glm(Survived ~ ., family = binomial, data = train_pca)
predictions_pca <- predict(logistic_pca, newdata = test_pca, type = 'response')

predicted_classes_pca <- ifelse(predictions_pca > 0.5, '1', '0')
predicted_classes_pca <- factor(predicted_classes_pca, levels = c('0', '1'))
confusion_mat_pca <- confusionMatrix(predicted_classes_pca, test_pca$Survived)
print(confusion_mat_pca)

#SVM with PCA
numeric_columns <- sapply(train, is.numeric)
train_numeric <- train[, numeric_columns]
test_numeric <- test[, numeric_columns]
pca <- prcomp(train_numeric, center = TRUE, scale. = TRUE)
train_pca <- predict(pca, train_numeric)[, 1:num_components]
test_pca <- predict(pca, test_numeric)[, 1:num_components]

svm_model_pca <- svm(x = train_pca, y = train_ref, method="C-classification", kernel="radial")
svm_predictions_pca <- predict(svm_model_pca, newdata = test_pca)

svm_predictions_pca <- factor(svm_predictions_pca, levels = c('0', '1'))
conf_mat_svm_pca <- confusionMatrix(svm_predictions_pca, test_ref)
print(conf_mat_svm_pca)
