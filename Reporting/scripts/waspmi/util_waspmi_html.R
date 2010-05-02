# TODO: Add comment
#
# Author: Claude.Falguiere
###############################################################################
# html generation
library(hwriter)

# images generation
library(Cairo)

# time series
library(zoo)


wasPmiReport.extractLogInfo <- function(dataFilePath) {
    pathTokens <- strsplit(dataFilePath, "/")[[1]]
    n <- length(pathTokens)
    name <- pathTokens[n]
    #was_pmi_2010-01-01_hewqalive.csv
    day <- gsub("was_pmi_(.+)_.+.csv", "\\1", name )
    instance <- gsub("was_pmi_.+_(.+).csv", "\\1", name )

    list(
         day=day,
         component="waspmi",
         instance=instance
         )
}

wasPmiReport.load <- function(dataFilePath, monitoringReportConfig) {
    cat(sprintf("loading data from %s \n", dataFilePath))
    data <- read.csv2(file=dataFilePath,  head=TRUE)
    print(data)
    #colnames(data) <- c("instance","day","time","metric","reading")
    cat(sprintf("Data loaded (%d lines) \n", nrow(data)))
    data
}

wasPmiReport.split <- function(data, monitoringReportConfig) {
    cat("Splitting data \n")

    cat("creating dir \n")
    metricDataDir <- sprintf("%s/data",
                                 monitoringReportConfig$reportInfo$reportDir)
    dir.create(metricDataDir, recursive=TRUE) # TODO move to config

    metrics <- factor(data$metric)
    splittedData <- split(data, metrics)
    print(splittedData)

    cat("copying file \n")
    lapply(splittedData, wasPmiReport._writeMetric, monitoringReportConfig)

    n <- length(attributes(splittedData)$names)
    cat(sprintf("Data splitted (%d files) \n", n))
    splittedData
}

wasPmiReport._writeMetric <- function(.element, monitoringReportConfig) {
   cat(sprintf("creating file for  %s \n", .element$metric))
   name <- .element$metric
   name <- gsub(" ", "_", name)
   #name <- gsub("\\.", "-", name) # - is not legal in name
   metricDataFilePath <- sprintf("%s/data/data-%s.csv",
                                 monitoringReportConfig$reportInfo$reportDir,
                                 name)
   cat(sprintf("output file is %s \n", metricDataFilePath))
   write.csv2(.element, file = metricDataFilePath,
             append=FALSE,
             col.names=TRUE, row.names=FALSE)
}

wasPmiReport.makeMain <- function(index, monitoringReportConfig) {
    cat("Generating main report \n")

    reportInfo <- monitoringReportConfig$reportInfo
    logInfo <- monitoringReportConfig$logInfo

    htmlFilePath = sprintf("%s/index.html", reportInfo$reportDir)

    cat(sprintf("starting html page %s \n", htmlFilePath))

    pageTitle <- sprintf("WAS %s %s", logInfo$instance, logInfo$day)

    page = openPage(htmlFilePath,
    title=pageTitle, link.css=reportInfo$cssFileUrl)

    hwrite(pageTitle, page, heading=1, br=TRUE)

    hwrite("By metric", page, heading=2, br=TRUE)

    cat("applying link format to each index line \n")
    metrics <- gsub(" ", "_",  attributes(index)$names)
    print(metrics)
    lapply(metrics,
           function(m) {
               hwrite(m, page, link=sprintf("report%s.html",m), br=TRUE)
           })


    hwrite("Summary", page, heading=2, br=TRUE)
    cat("computing stats for each index line \n")
    stats <- t(sapply(index, wasPmiReport._computeStats))
    print(stats)
    hwrite(stats, page,
           row.names=TRUE, col.names=TRUE, class='list',
           table.class='list',
           table.style='border-collapse: collapse',
           br=TRUE )

    cat(sprintf("closing html page %s \n", htmlFilePath))
    closePage(page)

    cat("Main report DONE \n")
    htmlFilePath
}

wasPmiReport.makeMetric <- function(metricData, monitoringReportConfig) {
    reportInfo <- monitoringReportConfig$reportInfo
    logInfo <- monitoringReportConfig$logInfo

    print(metricData)
    print(metricData$metric)

    metricName <- gsub(" ", "_", metricData$metric[1])
    cat(sprintf("Generating report for metric %s \n", metricName))

    htmlFilePath = sprintf("%s/report%s.html",
    reportInfo$reportDir, metricName)

    cat(sprintf("starting html page %s \n", htmlFilePath))

    pageTitle <- sprintf("WAS %s %s %s",
                         logInfo$instance, logInfo$day, metricName)

    page = openPage(htmlFilePath,
    title=pageTitle, link.css=reportInfo$cssFileUrl)

    hwrite(pageTitle, page, heading=1, br=TRUE)

    description <- sprintf("<p>The table below shows WAS %s statistics</p>",
                           metricName)
    hwrite(description, page, br=TRUE)
    stats <- wasPmiReport._computeStats(metricData)
    #print(stats)
    hwrite(stats, page,
           row.names=TRUE, col.names=TRUE, class='list',
           table.class='list',
           table.style='border-collapse: collapse',
           br=TRUE )

    hwrite("<p>The figure below plots WAS metric</p>",
           page, br=TRUE)
    wasPmiReport.outputPlot(metricData, metricName,
                           page, monitoringReportConfig)

    cat(sprintf("closing html page %s \n", htmlFilePath))
    closePage(page)

    cat(sprintf("Report for metric %s DONE \n", metricName))
    htmlFilePath
}

wasPmiReport._computeStats <- function(.element) {
    values <- .element$value
    stats <- c( min=min(values), max=max(values),
        mean=round(mean(values),2), sd=round(sd(values),2),
        q95=round(quantile(values, 0.95),2) )
    print(stats)
    stats
}

wasPmiReport.outputPlot <- function(data, metricName, page, monitoringReportConfig) {
    reportInfo <- monitoringReportConfig$reportInfo

    values  <- data$value
    labels <- data$ts

    cat("Computing time series \n")
    ts <- suppressWarnings(zoo(values, order.by=labels))
    tsMean <- aggregate(ts, by=labels, FUN=mean)

    #todo
    filelink <- sprintf("%s/plot-%s.png",
                        reportInfo$imagesFolder, metricName)
    filename <- sprintf("%s/%s", reportInfo$reportDir, filelink)

    cat(sprintf("Drawing plot in %s \n", filename))
    Cairo(800, 400, file=filename, type="png", bg="white")
    title <- metricName
    plot.zoo(tsMean, type="h",col="darkseagreen", lwd=1,
             main=title, xlab="Time", ylab="Quantity")

    dev.off()

    hwriteImage(filelink, page, br=TRUE)
}

wasPmiReport.make <- function(dataFilePath, monitoringReportConfig) {
    # load
    data <- wasPmiReport.load(dataFilePath)
    index <- wasPmiReport.split(data, monitoringReportConfig)

    # reports
    cat(sprintf("Generating reports for %s \n", dataFilePath))
    htmlFilePath <- wasPmiReport.makeMain(index, monitoringReportConfig)
    metricFiles <- sapply(index,
                          wasPmiReport.makeMetric,
                          monitoringReportConfig)
    htmlFilePath
}

