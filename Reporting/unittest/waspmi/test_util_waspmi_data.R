# TODO: Add comment
#
# Author: Claude.Falguiere
###############################################################################

source("testHelper.R")
source("../scripts/waspmi/util_waspmi_data.r")
source("../scripts/common/util_monitoring_config.r")


test_WASPerfLogIsLoaded <-  function() {
    filename <- "waspmi/data/hewqalive/was_perf_2010-03-26_17-20.xml"
    doc <- wasPerfLog.load(filename)
    checkEquals(TRUE, length(doc)>0)
}

test_WASPerfLogJVMHeapSizeIsLoaded <-  function() {
    filename <- "waspmi/data/hewqalive/was_perf_2010-03-26_17-20.xml"
    doc <- wasPerfLog.load(filename)
    nodeName <- "WC_hewqalive_node"
    serverName <- "WC_hewqalive_server1"
    metricName <- "JVM Runtime.HeapSize"
    metricType <- "BoundedRangeStatistic"
    attribute <- "value"
    value <- wasPerfLog.read(doc, nodeName, serverName,
                      metricName, metricType, attribute)
    checkEquals("1037502", value)

}

test_WASPerfLogWebThreadPoolSizeIsLoaded <-  function() {
    filename <- "waspmi/data/hewqalive/was_perf_2010-03-26_17-20.xml"
    doc <- wasPerfLog.load(filename)
    nodeName <- "WC_hewqalive_node"
    serverName <- "WC_hewqalive_server1"
    metricName <- "Thread Pools.WebContainer.PoolSize"
    metricType <- "BoundedRangeStatistic"
    attribute <- "value"
    value <- wasPerfLog.read(doc, nodeName, serverName,
                      metricName, metricType, attribute)
    checkEquals("15", value)

}

test_WASPerfLogConfigIsLoaded <-  function() {
    filename <- "waspmi/data/hewqalive/was_perf_config.xml"
    config <- wasPerfConfig.load(filename)
    checkEqualsNumeric(1, length(config))

    instance <- getNodeSet(config, "//instance")
    print(instance)
    checkEqualsNumeric(1, length(instance))
    nodeName <- sapply(instance, xmlGetAttr, "node")
    checkEquals("WC_hewqalive_node", nodeName)
    serverName <- sapply(instance, xmlGetAttr, "server")
    checkEquals("WC_hewqalive_server1", serverName)

    metric <- getNodeSet(config, "//metric")
    print(metric)
    checkEqualsNumeric(2, length(metric))
    path <- sapply(metric, xmlGetAttr, "path")
    checkEquals("JVM Runtime.HeapSize", path[1])
    type <- sapply(metric, xmlGetAttr, "type")
    checkEquals("BoundedRangeStatistic", type[1])
    attribute <- sapply(metric, xmlGetAttr, "attribute")
    checkEquals("value", attribute[1])

}

test_WASPerfLogIsExported <-  function() {
    configFilename <- "waspmi/data/hewqalive/was_perf_config.xml"
    config <- wasPerfConfig.load(configFilename)
    checkEqualsNumeric(1, length(config))

    filename <- "waspmi/data/hewqalive/was_perf_2010-03-26_17-20.xml"
    logInfo <- wasPerf.extractLogInfo(filename)
    checkEquals("2010-03-26", logInfo$day)
    checkEquals("17:20:00", logInfo$time)
    checkEquals("waspmi", logInfo$component)
    checkEquals("hewqalive", logInfo$instance)

    doc <- wasPerfLog.load(filename)
    checkEquals(TRUE, length(doc)>0)

    homeDir = ".."
    monitoringReportConfig <-
    monitoringReportConfig.new(homeDir,
                                   logInfo)

    storeDir <- monitoringReportConfig$storeInfo$storeDir
    outFileName <- sprintf("%s/waspmi/was_pmi_%s_%s.csv",
                           storeDir, logInfo$day,  logInfo$instance)
    print(outFileName)
    expectedOutFileName <- "../results/2010-03-26/waspmi/was_pmi_2010-03-26_hewqalive.csv"
    checkEquals(expectedOutFileName, outFileName)
 
    wasPerf.export(doc, config, outFileName, logInfo$time)
    lines <- readLines(outFileName)
    print(lines[2])
    checkEquals("\"WC_hewqalive_node\";\"WC_hewqalive_server1\";\"JVM Runtime.HeapSize\";\"17:20:00\";\"1037502\"", lines[2])
}

test_WASPerfLogIsStored <-  function() {
    filename <- "waspmi/data/hewqalive/was_perf_2010-03-26_17-20.xml"
    filename2 <- "waspmi/data/hewqalive/was_perf_2010-03-26_17-21.xml"
    file.copy(filename, filename2)
    logInfo <- wasPerf.extractLogInfo(filename)

    homeDir = ".."
    monitoringReportConfig <-
    monitoringReportConfig.new(homeDir, logInfo)

    storedDataFilePath <- wasPerf.storeResult(filename2, monitoringReportConfig)
    expectedStoredDataFilePath <- "../results/2010-03-26/waspmi/hewqalive/was_perf_2010-03-26_17-21.xml"
    print(storedDataFilePath)
    checkEquals(expectedStoredDataFilePath, storedDataFilePath)
    checkEquals(TRUE, file.exists(expectedStoredDataFilePath))
}

testNames <- ls(pattern="test_*")
runUnitTests(testNames)
