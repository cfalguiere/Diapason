# html generation
library(hwriter)

# images generation
library(Cairo)

# time series
library(zoo)

apacheReport.extractLogInfo <- function(dataFilePath) {
   pathTokens <- strsplit(dataFilePath, "/")
   n <- length(pathTokens[[1]])
   nameRadix <- strsplit(pathTokens[[1]][n], ".log")
   nameTokens <- strsplit(nameRadix[[1]][1], "_")
   list(
        day=nameTokens[[1]][3],
        component="apache",
        instance=nameTokens[[1]][4]
   )
}

apacheReport.make <- function(dataFilePath, monitoringReportConfig) {
    logInfo <-  monitoringReportConfig$logInfo
    reportInfo <-  monitoringReportConfig$reportInfo

    htmlFilePath <- sprintf("%s/%s",
                            reportInfo$reportDir,
                            reportInfo$htmlFileName)

    data <-  apacheReport.load(dataFilePath)

    cat(sprintf("starting html page %s \n", htmlFilePath))
    pageTitle = sprintf("Apache %s", logInfo$day)

    page = openPage(htmlFilePath,
    title=pageTitle, link.css=reportInfo$cssFileUrl)

    hwrite(pageTitle, page, heading=1, br=TRUE)

    hwrite("<p>The table below shows Apache status statistics</p>",
           page, br=TRUE)
    apacheReport.outputStats(data$BusyWorker, page)
    hwrite("<p>The figure below plots Apache status: Green=busy workers, Blue=total number of workers</p>",
           page, br=TRUE)
    apacheReport.outputPlot(data, page, monitoringReportConfig)

    cat(sprintf("closing html page %s \n", htmlFilePath))
    closePage(page)

    htmlFilePath
}

apacheReport.load <- function(dataFilePath, monitoringReportConfig) {
    cat(sprintf("Loading data from %s \n", dataFilePath))
    data <- read.csv(file=dataFilePath, sep=" ", head=TRUE)
    cat(sprintf("Data loaded (%d lines) \n", nrow(data)))
    data
}

apacheReport.outputStats <- function(values, page) {
    cat("writing stats \n")
    stats <- cbind( min(values), max(values),
        round(mean(values),2), round(sd(values),2),
        round(quantile(values, 0.95),2) )
    colnames(stats) <- c("min","max","mean","sd","95%")
    hwrite(stats, page,
           row.names=FALSE, col.names=TRUE, class='list',
           table.class='list',
           table.style='border-collapse: collapse',
           br=TRUE )
}

apacheReport.outputPlot <- function(data, page, monitoringReportConfig) {
    reportInfo <- monitoringReportConfig$reportInfo

    busy  <- data$BusyWorker
    all <- data$BusyWorker + data$IdleWorker
    labels <- data$ts

    cat("Computing time series \n")
    tsBusy <- suppressWarnings(zoo(busy, order.by=labels))
    tsBusyMean <- aggregate(tsBusy, by=labels, FUN=mean)
    tsAll <- suppressWarnings(zoo(all, order.by=labels))
    tsAllMean <- aggregate(tsAll, by=labels, FUN=mean)

    filelink <- sprintf("%s/plot-busy.png",reportInfo$imagesFolder)
    filename <- sprintf("%s/%s", reportInfo$reportDir, filelink)

    cat(sprintf("Drawing plot in %s \n", filename))
    Cairo(800, 400, file=filename, type="png", bg="white")
    ylim <- c(0,max(all))
    title <- "Number of busy workers"
    plot.zoo(tsBusyMean, type="h",col="darkseagreen", lwd=1, ylim=ylim,
             main=title, xlab="Time", ylab="Number of workers")
    lines(tsAllMean, type="p", pch=18, col="darkblue", lwd=1, ylim=ylim)

    dev.off()

    hwriteImage(filelink, page, br=TRUE)
}

apacheReport.storeResult <- function(dataFilePath, monitoringReportConfig) {
    logInfo <- monitoringReportConfig$logInfo

    storedFileName <- sprintf("%s/apache_status_%s_%s.log",
                              monitoringReportConfig$storeInfo$storeDir,
                              logInfo$day,
                              logInfo$instance)
    cat(sprintf("Moving log file %s to %s \n", dataFilePath, storedFileName))
    file.rename(dataFilePath, storedFileName)
    storedFileName
}
