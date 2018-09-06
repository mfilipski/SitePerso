# Clean the environment, clean the graphics parameters
rm(list=ls())

# Load packages (install them if needed)
list.of.packages <- c("UsingR", "datasets", "lattice", "circlize", "maps",
                      "gridExtra", "tm", "wordcloud", "RColorBrewer", "SnowballC", "xlsx")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=TRUE)


# Part 1: R is really good at getting data online 
####################################################################

# Let's get infant mortality from the Unicef page: 
# https://data.unicef.org/topic/child-survival/under-five-mortality/
# Give R the URL, download the file: 
url <- "https://data.unicef.org/wp-content/uploads/2015/12/IMR_mortality_rate_2017.xls"
dir.create(file.path(getwd(), "data"))
filepath <- "data/infmort.xls"
download.file(url, destfile="data/infmort.xls", mode = "wb")

# Read the file, and start working with it. 
infant <- read.xlsx2(filepath, sheetIndex = 1, check.names=TRUE, col.names=TRUE, startRow = 12)
head(infant)



# Part 2: R makes graphs easy (Wow!) 
####################################
rm(list=ls())
# First, some practice: load data, see what's in it, plot the points.
data(cars)
head(cars)
plot(cars)

# Multiple graphs: 
data(iris)
head(iris)
pairs(iris[1:4], pch= 16, col=iris$Species, main="Correlations between flower characteristics")

# Even more graphs at once: 
data(snacks)
head(snacks)
pairs(snacks[,-1])

# It's not only for scatterplots:
data("Medicare")
head(Medicare)
densityplot(~log(Average.Total.Payments) | Provider.State, data=Medicare )

# Works with 3d too: 
cloud(Sepal.Length~Petal.Length*Petal.Width | Species, data=iris )


# You can easily superimpose different functions in the plot: 
data("diamonds")
head(diamonds)
dim(diamonds)
g <- ggplot(data=diamonds, aes(y=price, x=carat, color=cut))
g <- g + facet_wrap(~cut, scales = "free_x") 
g <- g + geom_point(color="steelblue", shape=16, alpha=0.2)
g <- g + geom_smooth(method="lm",color="darkgrey", size=0.5, se=FALSE)
g <- g + geom_smooth(level=.99)
g




# Part 3: R has packages for so many amazing graphs (More "Wow!")
####################################################################
### Awesome graph 1: Chord diagrams 
#---------------------------------------------------------------------
library(circlize)

# Go see the graph online: http://www.global-migration.info/  (made with D3.js)
# We can make a basic version of that with R. 
# Read in Regional Migration data and take a look: 
rm(list=ls())
# I put the file up online at the bottom of this page http://www.mateuszfilipski.net/stata.html  
fileUrl <- "http://www.mateuszfilipski.net/files/region_custom.txt"
fileName <- "data/regfile.txt"
download.file(fileUrl, destfile=fileName)
regData<-read.table(fileName, skip=2, stringsAsFactors=FALSE)
regData

# Extract flow matrix:
mFlows<-regData[,-(1:3)]/1e06
mFlows<-as.matrix(mFlows)
dimnames(mFlows)<-list(orig=regData[,3],dest=regData[,3])
# Exclude the smallest flows:
m<-mFlows
m[m<0.2] <- 0
m

# Extract colors:
col <- regData[,2] 
n <- length(col)
col <- cbind(col, matrix(as.numeric(unlist(strsplit(col,","))),nrow=n, byrow=TRUE))
cols<-rgb(col[,2], col[,3], col[,4], max = 255)
grid.col = cols
col_mat <- rep(cols,each=n)
col_mat

# Call circos to make a (much simpler) version of the chord diagram: 
circos.clear()
circos.par(cell.padding=c(0,0,0,0), start.degree = 90, gap.degree =4)
chordDiagram(as.matrix(m),grid.col=grid.col, col= col_mat, transparency = 0.5, link.border= 0, directional = 1, direction.type = c("arrows"),
             link.arr.type = "big.arrow")
circos.clear()


### Awesome graph 2: MAPS!  
#---------------------------------------------------------------------
rm(list=ls())
dev.off()
library(maps); library(ggplot2); library(gridExtra)

# data comes with those packages: 
states <- map_data("state")
head(states)
map("state")
map("state", boundary=FALSE, col="gray", add=TRUE)


# Even better: 
ggplot(data = states) + 
    geom_polygon(aes(x = long, y = lat, fill = region, group = group), color = "white") + 
    coord_fixed(1.3) +
    guides(fill=FALSE)

# Better still - adding in data by state:
head(state.x77)
usdata = data.frame(region=tolower(rownames(state.x77)), state.x77, stringsAsFactors=F)
mapIncome <- ggplot(usdata, aes(map_id = region)) + 
    geom_map(aes(fill = Income), map = states) +
    scale_fill_gradientn(colours=c("lightblue","darkblue")) + 
    expand_limits(x = states$long, y = states$lat) +
    geom_map(aes(fill = Income), map = states)+
    coord_fixed(1.3)
mapIncome

# Ok, last one:
mapIncome2 <- ggplot(usdata, aes(map_id = region)) + 
    geom_map(aes(fill = Income), map = states) +
    scale_fill_gradientn(colours=c("lightblue","darkblue")) + 
    expand_limits(x = states$long, y = states$lat) +
    coord_fixed(1.3) + theme_void()
mapMurder <- ggplot(usdata, aes(map_id = region)) + 
    geom_map(aes(fill = Murder), map = states) +
    scale_fill_gradientn(colours=c("darkgreen","red")) + 
    expand_limits(x = states$long, y = states$lat) +
    coord_fixed(1.3)  + theme_void()         
mapPop <- ggplot(usdata, aes(map_id = region)) + 
    geom_map(aes(fill = Population), map = states) +
    scale_fill_gradientn(colours=c("bisque","coral4")) + 
    expand_limits(x = states$long, y = states$lat) +
    coord_fixed(1.3) + theme_void()
mapSchool <- ggplot(usdata, aes(map_id = region)) + 
    geom_map(aes(fill = HS.Grad), map = states) +
    scale_fill_gradientn(colours=c("brown4","blue")) + 
    expand_limits(x = states$long, y = states$lat) +
    coord_fixed(1.3) + theme_void()
grid.arrange(mapPop, mapIncome2, mapSchool, mapMurder)


### Awesome graoh 3: Word Cloud
#---------------------------------------------------------------------
library(tm); library(wordcloud); library(SnowballC); library(RColorBrewer)

# Download text file with all the lyrics from Justin Bieber's first album ("My World")
rm(list=ls())
fileUrl <- "http://www.mateuszfilipski.net/files/jblyrics.txt"
fileName <- "data/jbl.txt"
download.file(fileUrl, destfile=fileName)

# read in the file 
jbl <- readLines(fileName)
justin <- Corpus(VectorSource(jbl))

inspect(justin[1:100])

# Clean up 
j <- tm_map(justin, tolower)
j <- tm_map(j, removePunctuation)
j <- tm_map(j, removeWords, stopwords("English"))
j <- tm_map(j, removeWords, c("one", "yeah","ill","ah")) 
j <- tm_map(j, stripWhitespace)
inspect(j[1:100])

# draw the graph:
wordcloud(j, scale=c(3,0.5), max.words=100, random.order=FALSE, rot.per=0.35, use.r.layout=FALSE, colors=brewer.pal(6, "Dark2"))




#-------------------------------------------------------------
#(Unicef Url just in case: https://data.unicef.org/wp-content/uploads/2015/12/IMR_mortality_rate_2017.xls)

