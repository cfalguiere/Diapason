# TODO: Add comment
#
# Author: Claude.Falguiere
###############################################################################

source("testHelper.R")
source("../scripts/waspmi/util_waspmi_html.r")
source("../scripts/common/util_monitoring_config.r")

svudraw_init()

test_WasPmiReportDirHasBeenCreated <- function() {
    #DEACTIVATED()
    dataFilePath = "../unittest/waspmi/data/was_pmi_2010-01-01_hewqalive1.csv"
    homeDir = ".."
    htmlDir = "../reports/2010-01-01/waspmi/hewqalive1"

    #remove old
    file.remove(htmlDir)

    # config
    logInfo <- wasPmiReport.extractLogInfo(dataFilePath)
    print(logInfo)
    checkEquals("hewqalive1", logInfo$instance)
    checkEquals("waspmi", logInfo$component)
    checkEquals("2010-01-01", logInfo$day)

    # new report
    monitoringReportConfig <-
        monitoringReportConfig.new(homeDir, logInfo)
    checkEquals(htmlDir, monitoringReportConfig$reportInfo$reportDir)
    cssFile <- sprintf("%s/css/main.css", htmlDir)
    checkEquals(TRUE, file.exists(cssFile))

}

test_WasPmiReportDataHasBeenLoaded <-  function() {
    #DEACTIVATED()
    dataFilePath = "../unittest/waspmi/data/was_pmi_2010-01-01_hewqalive2.csv"
    data <- wasPmiReport.load(dataFilePath)
    checkEquals(44,nrow(data))
}

test_WasPmiReportDataHasBeenSplitted <-  function() {
    #DEACTIVATED()
    dataFilePath = "../unittest/waspmi/data/was_pmi_2010-01-01_hewqalive2.csv"
    homeDir = ".."

    # config
    logInfo <- wasPmiReport.extractLogInfo(dataFilePath)
    print(logInfo)
    checkEquals("hewqalive2", logInfo$instance)
    checkEquals("2010-01-01", logInfo$day)

    # new report
    monitoringReportConfig <-
        monitoringReportConfig.new(homeDir, logInfo)

    # load
    data <- wasPmiReport.load(dataFilePath)
    checkEquals(44,nrow(data))

    # split
    index <- wasPmiReport.split(data, monitoringReportConfig)
    #print(index)
    checkEquals(2,length(attributes(index)$names))

    cat("listing data files \n")
    dataFiles <- list.files(path="../reports/2010-01-01/waspmi/hewqalive2/data/",
                           pattern="data-.*.csv",
                           all.files=FALSE,
                           full.names=TRUE,
                           recursive=FALSE,
                           ignore.case=FALSE)
    print(dataFiles)
    checkEquals(2, length(dataFiles))

    metricDataFilePath <- dataFiles[1]
    cat(sprintf("reading data file %s \n", metricDataFilePath))
    checkEquals("../reports/2010-01-01/waspmi/hewqalive2/data/data-JVM_Runtime.HeapSize.csv", metricDataFilePath)
    checkEquals(TRUE, file.exists(metricDataFilePath))
    metricData <- read.csv2(file=metricDataFilePath, head=TRUE)
    checkEquals(22,nrow(metricData))
    firstTs <- metricData$ts[1]
    #print(metricData)
    checkEquals("17:20:00",as.character(firstTs))

}

test_WasPmiMainReportHasBeenCreated <-  function() {
    #DEACTIVATED()
    dataFilePath = "../unittest/waspmi/data/was_pmi_2010-01-01_hewqalive3.csv"
    homeDir = ".."

    expectedHtmlFilePath = "../reports/2010-01-01/waspmi/hewqalive3/index.html"

    # config
    logInfo <- wasPmiReport.extractLogInfo(dataFilePath)
    print(logInfo)
    checkEquals("hewqalive3", logInfo$instance)
    checkEquals("2010-01-01", logInfo$day)

    # new report
    monitoringReportConfig <-
        monitoringReportConfig.new(homeDir, logInfo)

    # load
    cat("loading data\n")
    data <- wasPmiReport.load(dataFilePath)
    index <- wasPmiReport.split(data, monitoringReportConfig)
    print(index)

    # report
    cat("generating report\n")
    htmlFilePath <- wasPmiReport.makeMain(index, monitoringReportConfig)
    print(htmlFilePath)
    checkEquals(expectedHtmlFilePath, htmlFilePath)
    checkEquals(TRUE, file.exists(htmlFilePath))

    lines <- readLines(htmlFilePath)
    checkEquals(TRUE, length(lines)>0)

    # title
    titleLine <- grep("WAS hewqalive3 2010-01-01", lines)
    print(titleLine)
    checkTrue(length(titleLine)>0)

    # links

    linksLine <- grep('<a href="report.*.html">.*</a>', lines)
    checkEqualsNumeric(2, length(linksLine))
    linksLine <- grep('<a href="reportJVM_Runtime.HeapSize.html">JVM_Runtime.HeapSize</a>', lines)
    checkEqualsNumeric(1, length(linksLine))

    # stats
    meanLine <- grep("mean", lines)
    checkEquals(TRUE, length(meanLine)>0)

}

test_WasPmiMetricReportHasBeenCreated <-  function() {
    #DEACTIVATED()
    dataFilePath = "../unittest/waspmi/data/was_pmi_2010-01-01_hewqalive4.csv"
    homeDir = ".."

    expectedHtmlFilePath = "../reports/2010-01-01/waspmi/hewqalive4/reportJVM_Runtime.HeapSize.html"

    # config
    logInfo <- wasPmiReport.extractLogInfo(dataFilePath)
    print(logInfo)
    checkEquals("hewqalive4", logInfo$instance)
    checkEquals("2010-01-01", logInfo$day)

    # new report
    monitoringReportConfig <-
        monitoringReportConfig.new(homeDir, logInfo)

    # load
    cat("loading data\n")
    data <- wasPmiReport.load(dataFilePath)
    index <- wasPmiReport.split(data, monitoringReportConfig)
    print(index)

    # report
    cat("generating report \n")
    metricData <- index[1]
    print(metricData)
    htmlFilePath <- wasPmiReport.makeMetric(index[[1]],
                                           monitoringReportConfig)
    checkEquals(expectedHtmlFilePath, htmlFilePath)
    checkEquals(TRUE, file.exists(htmlFilePath))

    lines <- readLines(htmlFilePath)
    checkEquals(TRUE, length(lines)>0)

    # title
    titleLine <- grep("WAS hewqalive4 2010-01-01 JVM_Runtime.HeapSize", lines)
    print(titleLine)
    checkEquals(TRUE, length(titleLine)>0)

    # stats
    meanLine <- grep("mean", lines)
    checkEquals(TRUE, length(meanLine)>0)

    # plot
    checkEquals(TRUE, file.exists("../reports/2010-01-01/waspmi/hewqalive4/images/plot-JVM_Runtime.HeapSize.png"))
    plotLine <- grep("plot-JVM_Runtime.HeapSize.png", lines)
    checkEquals(TRUE, length(plotLine)>0)

}

test_WasPmiMetricReportsHaveBeenCreated <-  function() {
    #DEACTIVATED()
    dataFilePath = "../unittest/waspmi/data/was_pmi_2010-01-01_hewqalive5.csv"
    homeDir = ".."


    # config
    logInfo <- wasPmiReport.extractLogInfo(dataFilePath)
    print(logInfo)
    checkEquals("hewqalive5", logInfo$instance)
    checkEquals("2010-01-01", logInfo$day)

    # new report
    monitoringReportConfig <-
        monitoringReportConfig.new(homeDir, logInfo)

    # report
    mainHtmlFilePath <- wasPmiReport.make(dataFilePath, monitoringReportConfig)

    expectedHtmlFilePath = "../reports/2010-01-01/waspmi/hewqalive5/index.html"
    checkEquals(TRUE, file.exists(expectedHtmlFilePath))

    reports <- list.files(path = "../reports/2010-01-01/waspmi/hewqalive5/",
                          pattern = "report.*.html",
                          all.files = FALSE,
                          full.names = TRUE, recursive = FALSE,
                          ignore.case = FALSE)
    checkEqualsNumeric(2, length(reports))
}

testNames <- ls(pattern="test_*")
runUnitTests(testNames)
