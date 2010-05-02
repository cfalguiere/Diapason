source("scripts/apache/util_apache_html.r")
source("scripts/common/util_monitoring_config.r")

processFile <- function(dataFilePath) {

    print(dataFilePath)

    logInfo <- apacheReport.extractLogInfo(dataFilePath)
    print(logInfo)

    monitoringReportConfig <-
        monitoringReportConfig.new(homeDir,
                                   logInfo)

    htmlFilePath <- apacheReport.make(dataFilePath, monitoringReportConfig)

    storedDataFilePath <- apacheReport.storeResult(dataFilePath,
                                                   monitoringReportConfig)

}

homeDir <- getwd()
print(homeDir)

apacheFiles <- list.files(path = "./inbox", pattern = "apache_status.*",
           all.files = FALSE,
           full.names = TRUE, recursive = FALSE,
           ignore.case = FALSE)

lapply(apacheFiles, processFile)
