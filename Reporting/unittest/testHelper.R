# SvUnit test helper
# displays test status as bars
#
# Author: Claude.Falguiere
###############################################################################

library("grid")
library("svUnit")

LINE.HEIGHT=.05
NAME.WIDTH=0.95
STATUS.WIDTH=.05


statuscolor <- data.frame( rbind(  c("OK","green3"),
				c("**FAILS**","orange"),
				c("**ERROR**","red") ,
				c("DEACTIVATED","grey") ))
colnames(statuscolor) <- c("status","color")

svudraw_init <- function() {
    rm(list=ls(all=TRUE))
    clearLog()
}

svudraw <- function() {
    grid.newpage()
    stats <- stats(Log())
    #print(stats)
    nLine <- 1
    for( i in 1:nrow(stats)) {
        sr <- stats[i,]
	drawTestResultLine(nLine, rownames(sr), as.character(sr[,"kind"]))
	nLine <- nLine + 1
    }
    print(Log())
    stats(Log())
}

drawTestResultLine <- function(i,testname, teststatus) {
	#print(i)
	#print(testname)
	#print(teststatus)
	color <- as.character(statuscolor[statuscolor["status"]==teststatus, "color"])
	#print(color)
	y <- i * LINE.HEIGHT
	grid.text(x=0.05, y=1-y, just="left", testname)
	grid.rect(x=NAME.WIDTH, y=1-y, width=STATUS.WIDTH, height=LINE.HEIGHT,
			gp=gpar(fill=color, col = "lightgrey"))
}

runUnitTest <- function(functionName) {
	fct <- get(functionName)
	if (! is.function(fct)) return()
	if (length(grep("test_",functionName))<1) return()

	cat(paste("\n======== Running test",functionName,"========\n"))
	svf <- as.svTest(fct)
	testData <- runTest(svf,name=functionName)
	print(testData)

	stats <- stats(Log())
	i <- pmatch(functionName, testNames)
	sr <- stats[i,]
	#print(sr)
	nLine = i
	drawTestResultLine(nLine, rownames(sr), as.character(sr[,"kind"]))
}

runUnitTests <- function(functionNames) {
    clearLog()
    grid.newpage()
    sapply(functionNames, runUnitTest )
}

