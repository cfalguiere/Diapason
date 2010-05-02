# TODO: Add comment
#
# Author: Claude.Falguiere
###############################################################################

source("testHelper.R")
source("../scripts/apache/util_apache_html.r")
source("../scripts/common/util_monitoring_config.r")

svudraw_init()


test_ApacheReportDirHasBeenCreated <- function() {
    dataFilePath = "../unittest/apache/data/apache_status_2010-01-01_sampleserver1.log"

    homeDir = ".."
    htmlDir = "../reports/2010-01-01/apache/sampleserver1"

    # remove old
    file.remove(htmlDir)
    #checkEquals(FALSE, file.exists(htmlDir))

    # config
    logInfo <- apacheReport.extractLogInfo(dataFilePath)
    print(logInfo)
    checkEquals("sampleserver1", logInfo$instance)
    checkEquals("apache", logInfo$component)
    checkEquals("2010-01-01", logInfo$day)

    # new report
    monitoringReportConfig <-
        monitoringReportConfig.new(homeDir, logInfo)
    checkEquals(htmlDir, monitoringReportConfig$reportInfo$reportDir)
    checkEquals(TRUE, file.exists(monitoringReportConfig$reportInfo$reportDir),
                sprintf("Dir=%s", monitoringReportConfig$reportInfo$reportDir))
    cssFile <- sprintf("%s/css/main.css", htmlDir)
    checkEquals(TRUE, file.exists(cssFile))
}

#todo instance
test_ApacheReportHasBeenCreated <- function() {
    dataFilePath <- "../unittest/apache/data/apache_status_2010-01-01_sampleserver2.log"
    htmlDir <- "../reports/2010-01-01/apache/sampleserver2"
    homeDir <- ".."

    # remove old
    file.remove(htmlDir)
    #checkEquals(FALSE, file.exists(htmlDir))


    # config
    logInfo <- apacheReport.extractLogInfo(dataFilePath)
    checkEquals("sampleserver2",logInfo$instance)
    checkEquals("2010-01-01",logInfo$day)

    monitoringReportConfig <-
        monitoringReportConfig.new(homeDir, logInfo)
    checkEquals(htmlDir, monitoringReportConfig$reportInfo$reportDir)
    checkEquals(TRUE, file.exists(monitoringReportConfig$reportInfo$reportDir),
                sprintf("Dir=%s", monitoringReportConfig$reportInfo$reportDir))
    checkEquals("apacheReport.html",
                monitoringReportConfig$reportInfo$htmlFileName)

    # report
    htmlFilePath <- apacheReport.make(dataFilePath, monitoringReportConfig)
    checkEquals(TRUE, file.exists(htmlFilePath))

    lines <- readLines(htmlFilePath)
    checkEquals(TRUE, length(lines)>0)

    # title
    titleLine <- grep("Apache 2010-01-01", lines)
    print(titleLine)
    checkEquals(TRUE, length(titleLine)>0)

    # stats
    meanLine <- grep("mean", lines)
    checkEquals(TRUE, length(meanLine)>0)

    # plot
    checkEquals(TRUE, file.exists("../reports/2010-01-01/apache/sampleserver2/images/plot-busy.png"))
    plotLine <- grep("plot-busy.png", lines)
    checkEquals(TRUE, length(plotLine)>0)
}

test_ApacheReportDataHasBeenLoaded <- function() {
    dataFilePath = "../unittest/apache/data/apache_status_2010-01-01_sampleserver2.log"
    data <- apacheReport.load(dataFilePath)
    # 2010-03-09 14:45:00 6 44
    checkEquals("2010-03-10", as.character(data$day[1]))
}

test_ApacheLogHasBeenStored <- function() {
    sourceDataFilePath = "../unittest/apache/data/apache_status_2010-01-01_sampleserver3.log"
    dataFilePath = "../unittest/apache/data/apache_status_2010-01-01_sampleserver4.log"
    homeDir <- ".."
    file.copy(sourceDataFilePath, dataFilePath)

    # config
    logInfo <- apacheReport.extractLogInfo(dataFilePath)
    checkEquals("2010-01-01", logInfo$day)
    checkEquals("sampleserver4", logInfo$instance)

    monitoringReportConfig <-
        monitoringReportConfig.new(homeDir, logInfo)
    checkEquals("../results/2010-01-01",
                monitoringReportConfig$storeInfo$storeDir)
    checkEquals(TRUE, file.exists(monitoringReportConfig$storeInfo$storeDir),
                sprintf("Dir=%s", monitoringReportConfig$storeInfo$storeDir))

    # store
    expectedStoredDataFilePath <- "../results/2010-01-01/apache_status_2010-01-01_sampleserver4.log"
    file.remove(expectedStoredDataFilePath)
    storedDataFilePath <- apacheReport.storeResult(dataFilePath,
                                                   monitoringReportConfig)
    print(storedDataFilePath)
    checkEquals(expectedStoredDataFilePath, storedDataFilePath)
    checkEquals(TRUE, file.exists(expectedStoredDataFilePath))
}


testNames <- ls(pattern="test_*")
runUnitTests(testNames)
