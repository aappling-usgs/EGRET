context("EGRET utils")
test_that("axis functions generate correct ticks", {
  #logPretty, generalAxis
  axis1 <- logPretty1(0.7, 990000)
  expect_is(axis1, "numeric")
  expect_equal(range(axis1), c(1e-1, 1e6))
  
  axis3 <- logPretty3(3,60)
  expect_is(axis3, "numeric")
  expect_equal(range(axis3), c(2, 100))
  
  q <- Choptank_eList$Daily$Q
  genAx <- generalAxis(x = q, max = max(q), min = min(q), 
                       units = getInfo(Choptank_eList)$param.units)
  expect_is(genAx, "list")
  expect_is(genAx$ticks, "numeric")
  expect_equal(genAx$bottom, 0)
  expect_equal(genAx$top, 250)
  expect_equal(range(genAx$ticks), c(0,250))
})

test_that("censoredSegments doesn't error", {
  x <- c(1,2,3,4,5,6)
  y <- c(1,3,4,3.3,4.4,7)
  xlim <- c(min(x)*.75,max(x)*1.25)
  ylim <- c(0,1.25*max(y))
  xlab <- "Date"
  ylab <- "Concentration"
  xTicks <- pretty(xlim)
  yTicks <- pretty(ylim)
  genericEGRETDotPlot(x=x, y=y, 
                      xlim=xlim, ylim=ylim,
                      xlab=xlab, ylab=ylab,
                      xTicks=xTicks, yTicks=yTicks,
                      plotTitle="Test")
  yBottom <- 0
  yLow <- c(NA,3,4,3.3,4,7)
  yHigh <- c(1,3,4,3.3,5,NA)
  Uncen <- c(0,1,1,1,0,0)
  censoredSegments(yBottom=yBottom,yLow=yLow,yHigh=yHigh,x=x,Uncen=Uncen)
})

test_that("date functions work", {
  correctDates <- checkStartEndDate("2016-01-01", "2017-01-01")
  expect_length(correctDates, 2)
  expect_warning(checkStartEndDate("2017-01-01", "2016-01-01", 
                                   interactive = FALSE))
  expect_true(dateFormatCheck("2017-01-01"))
  expect_false(dateFormatCheck("2017-1-1"))
  
})

test_that("data functions work", {
  testthat::skip_on_cran()
  
  #compressData
  dateTime <- c('1985-01-01', '1985-01-02', '1985-01-03')
  comment1 <- c("","","")
  value1 <- c(1,2,3)
  comment2 <- c("","<","")
  value2 <- c(2,3,4)
  comment3 <- c("","","<")
  value3 <- c(3,4,5)
  dataInput <- data.frame(dateTime, comment1, value1, 
                          comment2, value2, 
                          comment3, value3, stringsAsFactors=FALSE)
  compressed <- compressData(dataInput)
  expect_is(compressed, "data.frame")
  expect_gt(nrow(compressed), 1)
  expect_equal(names(compressed), c("dateTime", "ConcLow", "ConcHigh",
                                    "Uncen"))
  
  #mergeReport
  
  siteNumber <- '01594440'
  pCode <- '01075'
  Daily <- readNWISDaily(siteNumber,'00060', '1985-01-01', '1990-03-31')
  Sample <- readNWISSample(siteNumber,pCode, '1985-01-01', '1990-03-31')
  INFO <- readNWISInfo(siteNumber,pCode,interactive=FALSE)
  eList <- mergeReport(INFO, Daily, Sample)
  expect_equal(names(eList), c("INFO", "Daily", "Sample", "surfaces"))
  expect_is(eList$INFO, "data.frame")
  expect_is(eList$Daily, "data.frame")
  expect_is(eList$Sample, "data.frame")
  expect_gt(nrow(eList$Daily), 1)
  expect_gt(nrow(eList$Sample), 1)
  expect_gt(nrow(eList$INFO), 0)
  
  code <- c("","<","")
  value <- c(1,2,3)
  dataInput <- data.frame(value, code, stringsAsFactors=FALSE)
  concentrationDF <- populateConcentrations(dataInput)
  expect_is(concentrationDF, "data.frame")
  expect_equal(0, concentrationDF$ConcLow[2])
  expect_equal(names(concentrationDF), c("ConcLow", "ConcHigh", "Uncen"))
  expect_gt(nrow(concentrationDF), 0)
  
  Daily <- getDaily(Arkansas_eList)
  DailySubset <- selectDays(Daily, 4, 11)
  expect_is(DailySubset, "data.frame")
  months <- lubridate::month(DailySubset$Date)
  expect_true(all(months %in% c(11,12,1,2)))
  
})

test_that("Other miscellaneous functions work", {

  dailyMeas <- getDaily(Choptank_eList)
  lab <- setSeasonLabel(setupYears(dailyMeas))
  expect_equal(lab, "Water Year")
  
  lab_calendar <- setSeasonLabel(setupYears(dailyMeas, paStart = 1))
  expect_equal(lab_calendar, "Calendar Year")
  
  eList <- setPA(Arkansas_eList, paStart=12, paLong=3, window = 30)
  param.nm <- getInfo(eList)
  expect_equal(param.nm$paStart, 12)
  expect_equal(param.nm$paLong, 3)
  expect_equal(param.nm$window, 30)
})

test_that("nDischarge returns correct numbers", {
  expect_equal(nDischarge(Arkansas_eList), 8401)
  expect_equal(nDischarge(Choptank_eList), 11688)
})

test_that("nObservations returns correct numbers", {
  expect_equal(nObservations(Arkansas_eList), 254)
  expect_equal(nObservations(Choptank_eList), 606)
})

test_that("nCensored returns correct numbers", {
  expect_equal(nCensoredVals(Arkansas_eList), 115)
  expect_equal(nCensoredVals(Choptank_eList), 1)
})

context("plot method for egret objects")

test_that("plot method for egret objects work", {
  testthat::skip_on_cran()
  graphics.off()
  dev_start <- dev.cur()
  eList <- Choptank_eList
  plot(eList)
  
  expect_true(dev_start + 1 == dev.cur())
})

test_that("plot.egret passes correct arguments", {
  graphics.off()
  dev_start <- dev.cur()
  eList <- Choptank_eList
  plot(eList, logScaleConc = TRUE)
  
  expect_true(dev_start + 1 == dev.cur())
})

test_that("other plot functions don't error", {
  testthat::skip_on_cran()
  
  eList <- Choptank_eList
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(boxConcMonth(eList))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(boxQTwice(eList))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(plotConcTime(eList))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(plotConcQ(eList))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(multiPlotDataOverview(eList))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(plotConcTimeDaily(eList))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(plotFluxTimeDaily(eList))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(plotConcPred(eList))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(plotFluxPred(eList))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(plotQTimeDaily(eList))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(plotFluxQ(eList))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(plotFlowSingle(eList, istat = 1))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(plotFour(eList))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(plotFour(eList))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(plot1of15(eList, yearStart = 1995, yearEnd = 2005, qf = 1))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(plotSDLogQ(eList))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(plot15(eList = eList, yearStart = 1995, yearEnd = 2005))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(plotResidPred(eList))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(plotResidQ(eList))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(plotResidTime(eList))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(boxResidMonth(eList))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(boxConcThree(eList))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(plotConcHist(eList))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(plotFluxHist(eList))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  date1 <- "2000-09-01"
  date2 <- "2005-09-01"
  date3 <- "2009-09-01"
  qBottom<-100
  qTop<-5000
  
  expect_silent(plotConcQSmooth(eList, date1, date2, date3, qBottom, qTop, 
                                concMax=2,qUnit=1, legendLeft = 1000, legendTop = 2))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  q1 <- 10
  q2 <- 25
  q3 <- 75
  centerDate <- "07-01"
  yearEnd <- 2009
  yearStart <- 2000
  expect_silent(plotConcTimeSmooth(eList, q1, q2, q3, centerDate, yearStart, yearEnd))
  expect_true(dev_start + 1 == dev.cur())
  
  
})

test_that("plot.egret passes correct arguments", {
  expect_error(plot(eList, col='blue'))
})

test_that("flexPlotAddOn functions properly", {
  testthat::skip_on_cran()
  
  eList <- Choptank_eList
  eList <- setUpEstimation(eList)
  sampleSegStart <- c(1980,1985,2000)
  flowSegStart <- c(1980,1990,2000)
  flowSegEnd <- c(1990,2000,2010)
  dateInfo <- data.frame(sampleSegStart, flowSegStart, flowSegEnd)
  eList <- flexFN(eList, dateInfo)

  graphics.off()
  dev_start <- dev.cur()
  expect_silent(plotFluxHist(eList))
  expect_silent(flexPlotAddOn(eList))
  expect_true(dev_start + 1 == dev.cur())
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(plotFluxHist(eList))
  expect_silent(flexPlotAddOn(eList, customPalette = 
                                c("#02df77", "#dc28b2", "#2137a6")))
  expect_true(dev_start + 1 == dev.cur())
  
  sampleSegStart <- seq(1980,2011)
  flowSegStart <- seq(1980,2011)
  flowSegEnd <- seq(1981,2012)
  dateInfo <- data.frame(sampleSegStart, flowSegStart, flowSegEnd)
  eList <- flexFN(eList, dateInfo)
  
  graphics.off()
  dev_start <- dev.cur()
  expect_silent(plotFluxHist(eList))
  expect_error(flexPlotAddOn(eList), 
               "The number of segments exceed the length of the color palette. Supply custom palette of length 32")
  expect_true(dev_start + 1 == dev.cur())
  
  startBlank <- "1995-01-01"
  endBlank <- "2005-01-01"
  
  blank_eList <- blankTime(eList, startBlank, endBlank)
  expect_is(blank_eList, "egret")
  blank_daily <- getDaily(blank_eList)
  expect_true(all(is.na(blank_daily$FNConc[blank_daily$Date > startBlank &
                                 blank_daily$Date < endBlank])))
  
  not_blank <- getDaily(eList)
  expect_false(all(is.na(not_blank$FNConc[not_blank$Date > startBlank &
                                            not_blank$Date < endBlank])))
  
  expect_output(printFluxUnitCheatSheet(),
"The following codes apply to the fluxUnit list", ignore.case = TRUE)
  
  expect_output(printqUnitCheatSheet(),
                "The following codes apply to the qUnit list:", ignore.case = TRUE)
  
  bias <- fluxBiasStat(localSample = eList$Sample)
  rounded <- as.numeric(signif(bias))
  expect_equal(rounded, c(-0.0235532,-0.0235429,-0.023548))
})
