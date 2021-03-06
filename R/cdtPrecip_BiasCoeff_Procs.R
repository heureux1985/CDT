
execBiasRain <- function(){
	origdir <- file.path(.cdtData$GalParams$output$dir, paste0('BIAS_Data_',
						 file_path_sans_ext(.cdtData$GalParams$STN.file)))

	dir.create(origdir, showWarnings = FALSE, recursive = TRUE)
	Insert.Messages.Out('Computing Gauge-RFE bias ...')

	freqData <- .cdtData$GalParams$period
	.cdtData$GalParams$biasFilenames <- .cdtData$GalParams$output$format

	#######get data
	stnData <- getStnOpenData(.cdtData$GalParams$STN.file)
	stnData <- getCDTdataAndDisplayMsg(stnData, freqData, .cdtData$GalParams$STN.file)
	if(is.null(stnData)) return(NULL)

	##################
	## RFE sample file
	rfeDataInfo <- getNCDFSampleData(.cdtData$GalParams$RFE$sample)
	if(is.null(rfeDataInfo)){
		Insert.Messages.Out("No RFE data sample found", format = TRUE)
		return(NULL)
	}

	##################
	## DEM data
	demData <- NULL
	if(.cdtData$GalParams$BIAS$interp.method == "NN" |
		.cdtData$GalParams$Grid.Creation$grid == "2" |
		.cdtData$GalParams$auxvar$dem |
		.cdtData$GalParams$auxvar$slope |
		.cdtData$GalParams$auxvar$aspect)
	{
		demInfo <- getNCDFSampleData(.cdtData$GalParams$DEM.file)
		if(is.null(demInfo)){
			Insert.Messages.Out("No elevation data found", format = TRUE)
			return(NULL)
		}
		jfile <- getIndex.AllOpenFiles(.cdtData$GalParams$DEM.file)
		demData <- .cdtData$OpenFiles$Data[[jfile]][[2]]
		demData$lon <- demData$x
		demData$lat <- demData$y
	}

	##################
	##Create grid for interpolation
	if(.cdtData$GalParams$Grid.Creation$grid == '1'){
		grd.lon <- rfeDataInfo$lon
		grd.lat <- rfeDataInfo$lat
	}else if(.cdtData$GalParams$Grid.Creation$grid == '2'){
		grd.lon <- demData$lon
		grd.lat <- demData$lat
	}else if(.cdtData$GalParams$Grid.Creation$grid == '3'){
		X0 <- .cdtData$GalParams$Grid.Creation$minlon
		X1 <- .cdtData$GalParams$Grid.Creation$maxlon
		pX <- .cdtData$GalParams$Grid.Creation$reslon
		Y0 <- .cdtData$GalParams$Grid.Creation$minlat
		Y1 <- .cdtData$GalParams$Grid.Creation$maxlat
		pY <- .cdtData$GalParams$Grid.Creation$reslat
		grd.lon <- seq(X0, X1, pX)
		grd.lat <- seq(Y0, Y1, pY)
	}
	nlon0 <- length(grd.lon)
	nlat0 <- length(grd.lat)
	xy.grid <- list(lon = grd.lon, lat = grd.lat)

	##################
	## regrid DEM data
	if(!is.null(demData)){
		is.regridDEM <- is.diffSpatialPixelsObj(defSpatialPixels(xy.grid), defSpatialPixels(demData), tol = 1e-07)
		if(is.regridDEM)
			demData <- cdt.interp.surface.grid(demData, xy.grid)
		demData$z[demData$z < 0] <- 0
	}

	##################
	## Get RFE data info
	errmsg <- "RFE data not found"
	RFE.DIR <- .cdtData$GalParams$RFE$dir
	RFE.Format <- .cdtData$GalParams$RFE$format

	allyears <- .cdtData$GalParams$BIAS$all.years
	year1 <- .cdtData$GalParams$BIAS$start.year
	year2 <- .cdtData$GalParams$BIAS$end.year
	minyear <- .cdtData$GalParams$BIAS$min.year
	years <- as.numeric(substr(stnData$dates, 1, 4))
	iyrUse <- if(allyears) rep(TRUE, length(years)) else years >= year1 & years <= year2
	years <- years[iyrUse]

	if(length(unique(years)) < minyear){
		Insert.Messages.Out("Data too short", format = TRUE)
		return(NULL)
	}

	start.date1 <- as.Date(paste0(years[1], '0101'), format = '%Y%m%d')
	end.date1 <- as.Date(paste0(years[length(years)], '1231'), format = '%Y%m%d')
	months <- .cdtData$GalParams$BIAS$Months

	ncInfoBias <- ncFilesInfo(freqData, start.date1, end.date1, months, RFE.DIR, RFE.Format, errmsg)
	if(is.null(ncInfoBias)) return(NULL)
	ncInfoBias$ncinfo <- rfeDataInfo
	ncInfoBias$xy.rfe <- rfeDataInfo[c('lon', 'lat')]

	.cdtData$GalParams$biasParms <- list(stnData = stnData, ncInfo = ncInfoBias, bias.DIR = origdir,
										months = months, interp.grid = list(grid = xy.grid,
											nlon = nlon0, nlat = nlat0))
	bias.pars <- Precip_ComputeBias()
	if(is.null(bias.pars)) return(NULL)

	.cdtData$GalParams$biasParms <- list(bias.pars = bias.pars, months = months,
					stnData = stnData[c('lon', 'lat')], demData = demData, ncInfo = ncInfoBias, bias.DIR = origdir,
					interp.grid = list(grid = xy.grid, nlon = nlon0, nlat = nlat0))
	ret <- Precip_InterpolateBias()

	rm(ncInfoBias, stnData, demData, rfeDataInfo, bias.pars)
	gc()
	if(!is.null(ret)){
		if(ret == 0) return(0)
		else return(ret)
	}else return(NULL)
}

########################################################################################################

Precip_ComputeBias <- function(){
	Insert.Messages.Out('Compute bias factors ...')

	biasParms <- .cdtData$GalParams$biasParms
	freqData <- .cdtData$GalParams$period
	date.stn <- biasParms$stnData$dates
	data.stn <- biasParms$stnData$data
	nstn <- length(biasParms$stnData$lon)

	############### 

	if(.cdtData$GalParams$BIAS$interp.method == 'NN'){
		rad.lon <- .cdtData$GalParams$BIAS$rad.lon
		rad.lat <- .cdtData$GalParams$BIAS$rad.lat
		grd.lon <- biasParms$interp.grid$grid$lon
		grd.lat <- biasParms$interp.grid$grid$lat
		nlon0 <- biasParms$interp.grid$nlon
		nlat0 <- biasParms$interp.grid$nlat
		res.coarse <- sqrt((rad.lon * mean(grd.lon[-1] - grd.lon[-nlon0]))^2 +
							(rad.lat * mean(grd.lat[-1] - grd.lat[-nlat0]))^2) / 2
	}else res.coarse <- .cdtData$GalParams$BIAS$maxdist / 2
	res.coarse <- if(res.coarse >= 0.25) res.coarse else 0.25

	ptsData <- biasParms$stnData[c('lon', 'lat')]
	if(.cdtData$GalParams$BIAS$bias.method == 'Quantile.Mapping')
	{
		idcoarse <- indexCoarseGrid(biasParms$ncInfo$xy.rfe$lon, biasParms$ncInfo$xy.rfe$lat, res.coarse)
		ptsData1 <- expand.grid(lon = biasParms$ncInfo$xy.rfe$lon[idcoarse$ix], lat = biasParms$ncInfo$xy.rfe$lat[idcoarse$iy])
		nbgrd <- nrow(ptsData1)
		ptsData <- list(lon = c(ptsData$lon, ptsData1$lon), lat = c(ptsData$lat, ptsData1$lat))
	}
	msg <- list(start = 'Read and extract RFE data ...', end = 'Reading RFE data finished')

	rfeData <- readNetCDFData2Points(biasParms$ncInfo, ptsData, msg)

	data.rfe.stn <- rfeData$data[, 1:nstn, drop = FALSE]
	if(.cdtData$GalParams$BIAS$bias.method == 'Quantile.Mapping')
		data.rfe <- rfeData$data[, nstn + (1:nbgrd), drop = FALSE]
	date.bias <- rfeData$dates

	###############

	ibsdt <- match(date.stn, date.bias)
	ibsdt <- ibsdt[!is.na(ibsdt)]
	date.bias <- date.bias[ibsdt]
	istdt <- date.stn %in% date.bias

	if(length(ibsdt) == 0){
		Insert.Messages.Out("Date out of range", format = TRUE)
		return(NULL)
	}

	###############
	if(.cdtData$GalParams$BIAS$bias.method != 'Quantile.Mapping')
	{
		data.rfe.stn <- data.rfe.stn[ibsdt, , drop = FALSE]
		data.stn <- data.stn[istdt, , drop = FALSE]

		if(.cdtData$GalParams$BIAS$bias.method == 'Multiplicative.Bias.Mon'){
			times.stn <- as(substr(date.bias, 5, 6), 'numeric')
		}
		if(.cdtData$GalParams$BIAS$bias.method == 'Multiplicative.Bias.Var'){
			if(freqData == 'daily'){
				endmon <- c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
				vtimes <- cbind(unlist(sapply(endmon, function(j) 1:j)), rep(1:12, endmon), 1:365)
				xdaty <- paste(as.numeric(substr(date.bias, 7, 8)), as.numeric(substr(date.bias, 5, 6)), sep = '_')
				xvtm <- paste(vtimes[, 1], vtimes[, 2], sep = '_')
				times.stn <- vtimes[match(xdaty, xvtm), 3]
				times.stn[is.na(times.stn)] <- 59
				## Add  +/- 5 days
				ix5days <- lapply(unique(times.stn), function(nt){
					ix1 <- which(times.stn == nt)
					ix1 <- c(sapply(ix1, function(x) x + (-5:5)))
					cbind(nt, ix1[ix1 > 0 & ix1 <= length(date.bias)])
				})
				ix5days <- do.call('rbind', ix5days)
				times.stn <- ix5days[, 1]
				data.rfe.stn <- data.rfe.stn[ix5days[, 2], , drop = FALSE]
				data.stn <- data.stn[ix5days[, 2], , drop = FALSE]
			}
			if(freqData == 'pentad'){
				vtimes <- cbind(expand.grid(1:6, 1:12), 1:72)
				xdaty <- paste(as.numeric(substr(date.bias, 7, 7)), as.numeric(substr(date.bias, 5, 6)), sep = '_')
				xvtm <- paste(vtimes[, 1], vtimes[, 2], sep = '_')
				times.stn <- vtimes[match(xdaty, xvtm), 3]
			}
			if(freqData == 'dekadal'){
				vtimes <- cbind(expand.grid(1:3, 1:12), 1:36)
				xdaty <- paste(as.numeric(substr(date.bias, 7, 7)), as.numeric(substr(date.bias, 5, 6)), sep = '_')
				xvtm <- paste(vtimes[, 1], vtimes[, 2], sep = '_')
				times.stn <- vtimes[match(xdaty, xvtm), 3]
			}
			if(freqData == 'monthly'){
				times.stn <- as.numeric(substr(date.bias, 5, 6))
			}
		}

		index <- split(seq(length(times.stn)), times.stn)
		bias <- lapply(index, function(x){
			stn <- data.stn[x, , drop = FALSE]
			rfe <- data.rfe.stn[x, , drop = FALSE]
			na.data <- is.na(stn) | is.na(rfe)
			stn[na.data] <- NA
			rfe[na.data] <- NA
			len <- colSums(!na.data)
			stn <- colSums(stn, na.rm = TRUE)
			rfe <- colSums(rfe, na.rm = TRUE)
			bs <- stn/rfe
			bs[len < .cdtData$GalParams$BIAS$min.length] <- 1
			bs[is.na(bs)] <- 1
			bs[is.infinite(bs)] <- 1
			bs[is.nan(bs)] <- 1
			bs[bs > 3] <- 3
			bs
		})

		bias <- do.call(rbind, bias)

		##########
		bias.pars <- list(bias = bias, lon.stn = biasParms$stnData$lon, lat.stn = biasParms$stnData$lat,
							id.stn = biasParms$stnData$id, data.stn = data.stn, data.rfe = data.rfe.stn,
							date = date.bias, grid = biasParms$interp.grid)
		rm(data.rfe.stn)
	}else{
		mplus.pentad.date <- function(daty){
			pen1 <- as.character(daty)
			pen2 <- addPentads(as.Date(pen1, format = '%Y%m%d'), n = 1)
			pen2 <- paste0(format(pen2, '%Y%m'), as.numeric(format(pen2, '%d')))
			pen0 <- addPentads(as.Date(pen1, format = '%Y%m%d'), n = -1)
			pen0 <- paste0(format(pen0, '%Y%m'), as.numeric(format(pen0, '%d')))
			unique(sort(c(pen0, pen1, pen2)))
		}
		mplus.dekad.date <- function(daty){
			dek1 <- as.character(daty)
			dek2 <- addDekads(as.Date(dek1, format = '%Y%m%d'), n = 1)
			dek2 <- paste0(format(dek2, '%Y%m'), as.numeric(format(dek2, '%d')))
			dek0 <- addDekads(as.Date(dek1, format = '%Y%m%d'), n = -1)
			dek0 <- paste0(format(dek0, '%Y%m'), as.numeric(format(dek0, '%d')))
			unique(sort(c(dek0, dek1, dek2)))
		}
		mplus.month.date <- function(daty){
			mon1 <- as.character(daty)
			mon2 <- addMonths(as.Date(paste0(mon1, '01'), format = '%Y%m%d'), n = 1)
			mon2 <- format(mon2, '%Y%m')
			mon0 <- addMonths(as.Date(paste0(mon1, '01'), format = '%Y%m%d'), n = -1)
			mon0 <- format(mon0, '%Y%m')
			unique(sort(c(mon0, mon1, mon2)))
		}

		data.stn <- data.stn[istdt, , drop = FALSE]
		data.rfe <- data.rfe[ibsdt, , drop = FALSE]
		data.rfe.stn <- data.rfe.stn[ibsdt, , drop = FALSE]

		months <- biasParms$months
		xmonth <- as(substr(date.bias, 5, 6), 'numeric')

		BIAS <- .cdtData$GalParams$BIAS
		packages <- c('qmap', 'ADGofTest')
		parsDistr <- vector(mode = 'list', length = 12)

		is.parallel <- doparallel(length(months) >= 3)
		`%parLoop%` <- is.parallel$dofun

		parsDistr[months] <- foreach (m = months, .packages = packages) %parLoop% {
			if(freqData == 'daily') xdt <- xmonth == m
			if(freqData == 'pentad') xdt <- date.bias %in% mplus.pentad.date(date.bias[xmonth == m])
			if(freqData == 'dekadal') xdt <- date.bias %in% mplus.dekad.date(date.bias[xmonth == m])
			if(freqData == 'monthly') xdt <- date.bias %in% mplus.month.date(date.bias[xmonth == m])

			xstn <- data.stn[xdt, , drop = FALSE]
			xrfestn <- data.rfe.stn[xdt, , drop = FALSE]
			xrfe <- data.rfe[xdt, , drop = FALSE]
			xstn <- lapply(seq(ncol(xstn)), function(j) fit.mixture.distr(xstn[, j], BIAS$min.length, distr.fun = "berngamma"))
			xrfestn <- lapply(seq(ncol(xrfestn)), function(j) fit.mixture.distr(xrfestn[, j], BIAS$min.length, distr.fun = "berngamma"))
			xrfe <- lapply(seq(ncol(xrfe)), function(j) fit.mixture.distr(xrfe[, j], BIAS$min.length, distr.fun = "berngamma"))

			list(stn = xstn, rfestn = xrfestn, rfe = xrfe)
		}
		if(is.parallel$stop) stopCluster(is.parallel$cluster)

		pars.Obs.Stn <- lapply(parsDistr, '[[', 1)
		pars.Obs.rfe <- lapply(parsDistr, '[[', 2)
		pars.Crs.Rfe <- lapply(parsDistr, '[[', 3)

		AD.stn <- outputADTest(pars.Obs.Stn, months, distr = "berngamma")
		AD.rfestn <- outputADTest(pars.Obs.rfe, months, distr = "berngamma")
		AD.rfe <- outputADTest(pars.Crs.Rfe, months, distr = "berngamma")

		pars.Stn <- extractDistrParams(pars.Obs.Stn, months, distr = "berngamma")
		pars.Rfestn <- extractDistrParams(pars.Obs.rfe, months, distr = "berngamma")
		pars.Rfe <- extractDistrParams(pars.Crs.Rfe, months, distr = "berngamma")

		parsAD <- vector(mode = 'list', length = 12)
		if(.cdtData$GalParams$BIAS$AD.test){
			parsAD[months] <- lapply(months, function(j){
				istn <- AD.stn[[j]] == 'yes' & AD.rfestn[[j]] == 'yes'
				irfe <- AD.rfe[[j]] == 'yes'
				list(rfe = irfe, stn = istn)
			})
		}else{
			parsAD[months] <- lapply(months, function(j){
				istn <- rep(TRUE, length(AD.stn[[j]]))
				irfe <- rep(TRUE, length(AD.rfe[[j]]))
				list(rfe = irfe, stn = istn)
			})
		}

		parsAD.Rfe <- lapply(parsAD, '[[', 1)
		parsAD.Stn <- lapply(parsAD, '[[', 2)

		bias <- list(pars.ad.stn = parsAD.Stn, pars.ad.rfe = parsAD.Rfe, pars.stn = pars.Stn,
					pars.rfestn = pars.Rfestn, pars.rfe = pars.Rfe)

		##########
		bias.pars <- list(bias = bias, fit.stn = pars.Obs.Stn, fit.rfestn = pars.Obs.rfe, fit.rfe = pars.Crs.Rfe,
						lon.stn = biasParms$stnData$lon, lat.stn = biasParms$stnData$lat, id.stn = biasParms$stnData$id,
						lon.rfe = biasParms$ncInfo$xy.rfe$lon[idcoarse$ix], lat.rfe = biasParms$ncInfo$xy.rfe$lat[idcoarse$iy],
						data.stn = data.stn, data.rfestn = data.rfe.stn, data.rfe = data.rfe, date = date.bias, grid = biasParms$interp.grid)
		rm(parsDistr, pars.Obs.Stn, pars.Obs.rfe, pars.Crs.Rfe, pars.Stn, pars.Rfe,
			pars.Rfestn, parsAD, parsAD.Rfe, parsAD.Stn, data.rfe.stn, data.rfe)
	}

	saveRDS(bias.pars, file = file.path(biasParms$bias.DIR, "BIAS_PARAMS.rds"))

	Insert.Messages.Out('Computing bias factors finished')
	rm(rfeData, data.stn, bias.pars)
	gc()
	return(bias)
}

########################################################################################################

Precip_InterpolateBias <- function(){
	Insert.Messages.Out('Interpolate bias factors ...')

	biasParms <- .cdtData$GalParams$biasParms

	#############
	auxvar <- c('dem', 'slp', 'asp', 'alon', 'alat')
	is.auxvar <- unlist(.cdtData$GalParams$auxvar)
	if(any(is.auxvar)){
		formule <- formula(paste0('pars', '~', paste(auxvar[is.auxvar], collapse = '+')))
	}else formule <- formula(paste0('pars', '~', 1))

	#############
	xy.grid <- biasParms$interp.grid$grid
	grdSp <- defSpatialPixels(xy.grid)
	nlon0 <- biasParms$interp.grid$nlon
	nlat0 <- biasParms$interp.grid$nlat

	#############
	#Defines netcdf output dims
	dx <- ncdim_def("Lon", "degreeE", xy.grid$lon)
	dy <- ncdim_def("Lat", "degreeN", xy.grid$lat)
	xy.dim <- list(dx, dy)

	#############
	demGrid <- biasParms$demData

	if(!is.null(demGrid)){
		slpasp <- raster.slope.aspect(demGrid)
		demGrid$slp <- slpasp$slope
		demGrid$asp <- slpasp$aspect
	}else{
		demGrid <- list(x = xy.grid$lon, y = xy.grid$lat, z = matrix(1, nlon0, nlat0))
		demGrid$slp <- matrix(0, nlon0, nlat0)
		demGrid$asp <- matrix(0, nlon0, nlat0)
	}

	ijGrd <- grid2pointINDEX(biasParms$stnData, xy.grid)
	ObjStn <- list(x = biasParms$stnData$lon, y = biasParms$stnData$lat,
					z = demGrid$z[ijGrd], slp = demGrid$slp[ijGrd], asp = demGrid$asp[ijGrd])

	#############
	# regrid RFE
	create.grd <- .cdtData$GalParams$Grid.Creation$grid
	rfeGrid <- NULL
	rfeSp <- defSpatialPixels(biasParms$ncInfo$xy.rfe)
	is.regridRFE <- is.diffSpatialPixelsObj(grdSp, rfeSp, tol = 1e-07)
	if(create.grd != '1' & is.regridRFE){
		xy.rfe <- biasParms$ncInfo$xy.rfe
		demGrid0 <- demGrid[c('x', 'y', 'z')]
		names(demGrid0) <- c('lon', 'lat', 'z')
		rfeGrid <- cdt.interp.surface.grid(demGrid0, xy.rfe)
		irfe <- over(rfeSp, grdSp)
		rfeGrid$slp <- matrix(demGrid$slp[irfe], length(xy.rfe$lon), length(xy.rfe$lat))
		rfeGrid$asp <- matrix(demGrid$asp[irfe], length(xy.rfe$lon), length(xy.rfe$lat))
	}

	#############
	## interpolation grid
	interp.method <- .cdtData$GalParams$BIAS$interp.method
	nmin <- .cdtData$GalParams$BIAS$nmin
	nmax <- .cdtData$GalParams$BIAS$nmax
	maxdist <- .cdtData$GalParams$BIAS$maxdist
	vgm.model <- .cdtData$GalParams$BIAS$vgm.model
	rad.lon <- .cdtData$GalParams$BIAS$rad.lon
	rad.lat <- .cdtData$GalParams$BIAS$rad.lat
	rad.elv <- .cdtData$GalParams$BIAS$rad.elv

	min.stn <- .cdtData$GalParams$BIAS$min.stn

	if(interp.method == 'NN'){
		grd.lon <- xy.grid$lon
		grd.lat <- xy.grid$lat
		res.coarse <- sqrt((rad.lon * mean(grd.lon[-1] - grd.lon[-nlon0]))^2 + (rad.lat * mean(grd.lat[-1] - grd.lat[-nlat0]))^2)/2
	}else res.coarse <- maxdist/2
	res.coarse <- if(res.coarse >= 0.25) res.coarse else 0.25

	#############
	## create grid to interp
	bGrd <- NULL
	if(interp.method == 'NN'){
		interp.grid <- createGrid(ObjStn, demGrid, rfeGrid,
						as.dim.elv = .cdtData$GalParams$BIAS$elev.3rd.dim,
						latlong = .cdtData$GalParams$BIAS$latlon.unit,
						normalize = .cdtData$GalParams$BIAS$normalize,
						coarse.grid = TRUE, res.coarse = res.coarse)
		xy.maxdist <- sqrt(sum((c(rad.lon, rad.lat) * (apply(coordinates(interp.grid$newgrid)[, c('lon', 'lat')], 2,
						function(x) diff(range(x))) / (c(nlon0, nlat0) - 1)))^2))
		elv.grd <- range(demGrid$z, na.rm = TRUE)
		nelv <- length(seq(elv.grd[1], elv.grd[2], 100))
		nelv <- if(nelv > 1) nelv else 2
		z.maxdist <- rad.elv * (diff(range(coordinates(interp.grid$newgrid)[, 'elv'])) / (nelv - 1))
		xy.maxdist <- if(xy.maxdist < res.coarse) res.coarse else xy.maxdist
		maxdist <- sqrt(xy.maxdist^2 + z.maxdist^2)
	}else{
		interp.grid <- createGrid(ObjStn, demGrid, rfeGrid, as.dim.elv = FALSE,
								coarse.grid = TRUE, res.coarse = res.coarse)
		maxdist <- if(maxdist < res.coarse) res.coarse else maxdist
		cells <- SpatialPixels(points = interp.grid$newgrid, tolerance = sqrt(sqrt(.Machine$double.eps)))@grid
		bGrd <- if(.cdtData$GalParams$BIAS$use.block) createBlock(cells@cellsize, 2, 5) else NULL
	}

	#############
	if(is.auxvar['lon']){
		interp.grid$coords.stn$alon <- interp.grid$coords.stn@coords[, 'lon']
		interp.grid$coords.grd$alon <- interp.grid$coords.grd@coords[, 'lon']
		if(!is.null(interp.grid$coords.rfe)) interp.grid$coords.rfe$alon <- interp.grid$coords.rfe@coords[, 'lon']
		interp.grid$newgrid$alon <- interp.grid$newgrid@coords[, 'lon']
	}

	if(is.auxvar['lat']){
		interp.grid$coords.stn$alat <- interp.grid$coords.stn@coords[, 'lat']
		interp.grid$coords.grd$alat <- interp.grid$coords.grd@coords[, 'lat']
		if(!is.null(interp.grid$coords.rfe)) interp.grid$coords.rfe$alat <- interp.grid$coords.rfe@coords[, 'lat']
		interp.grid$newgrid$alat <- interp.grid$newgrid@coords[, 'lat']
	}

	#######################################
	## interpolation

	months <- biasParms$months
	bias.pars <- biasParms$bias.pars

	if(.cdtData$GalParams$BIAS$bias.method != 'Quantile.Mapping'){
		itimes <- as.numeric(rownames(bias.pars))
		grd.bs <- ncvar_def("bias", "", xy.dim, NA, longname = "Multiplicative Mean Bias Factor", prec = "float", compression = 9)
		biasFilenames <- .cdtData$GalParams$biasFilenames

		is.parallel <- doparallel(length(itimes) >= 3)
		`%parLoop%` <- is.parallel$dofun
		ret <- foreach(m = itimes, .packages = c('sp', 'ncdf4')) %parLoop% {
			locations.stn <- interp.grid$coords.stn
			locations.stn$pars <- bias.pars[itimes == m, ]
			locations.stn <- locations.stn[!is.na(locations.stn$pars), ]

			if(any(is.auxvar) & interp.method != 'NN'){
				locations.df <- as.data.frame(!is.na(locations.stn@data[, auxvar[is.auxvar]]))
				locations.stn <- locations.stn[Reduce("&", locations.df), ]
			}

			if(length(locations.stn$pars) >= 1 & any(locations.stn$pars != 1)){
				if(interp.method == 'Kriging'){
					if(length(locations.stn$pars) > 7){
						vgm <- try(automap::autofitVariogram(formule, input_data = locations.stn, model = vgm.model, cressie = TRUE), silent = TRUE)
						vgm <- if(!inherits(vgm, "try-error")) vgm$var_model else NULL
					}else vgm <- NULL
				}else vgm <- NULL

				xstn <- as.data.frame(locations.stn)
				xadd <- as.data.frame(interp.grid$coords.grd)
				xadd$pars <- 1
				iadd <- rep(TRUE, nrow(xadd))

				for(k in 1:nrow(xstn)){
					if(interp.method == 'NN'){
						xy.dst <- sqrt((xstn$lon[k] - xadd$lon)^2 + (xstn$lat[k] - xadd$lat)^2) * sqrt(2)
						z.dst <- abs(xstn$elv[k] - xadd$elv)
						z.iadd <- (z.dst < z.maxdist) & (xy.dst == min(xy.dst))
						iadd <- iadd & (xy.dst >= xy.maxdist) & !z.iadd
					}else{
						dst <- sqrt((xstn$lon[k] - xadd$lon)^2 + (xstn$lat[k] - xadd$lat)^2) * sqrt(2)
						iadd <- iadd & (dst >= maxdist)
					}
				}
				xadd <- xadd[iadd, ]
				locations.stn <- rbind(xstn, xadd)

				if(interp.method == 'NN'){
					coordinates(locations.stn) <- ~lon + lat + elv
					pars.grd <- gstat::krige(pars~1, locations = locations.stn, newdata = interp.grid$newgrid,
										nmax = 1, maxdist = maxdist, debug.level = 0)
				}else{
					coordinates(locations.stn) <- ~lon + lat
					if(any(is.auxvar)){
						locations.df <- as.data.frame(!is.na(locations.stn@data[, auxvar[is.auxvar]]))
						locations.stn <- locations.stn[Reduce("&", locations.df), ]
						block <- NULL
					}else block <- bGrd

					pars.grd <- gstat::krige(formule, locations = locations.stn, newdata = interp.grid$newgrid, model = vgm,
										block = block, nmin = nmin, nmax = nmax, maxdist = maxdist, debug.level = 0)

					xtrm <- range(locations.stn$pars, na.rm = TRUE)
					pars.grd$var1.pred[!is.na(pars.grd$var1.pred) & pars.grd$var1.pred < xtrm[1]] <- xtrm[1]
					pars.grd$var1.pred[!is.na(pars.grd$var1.pred) & pars.grd$var1.pred > xtrm[2]] <- xtrm[2]

					ina <- is.na(pars.grd$var1.pred)
					if(all(ina)){
						pars.grd$var1.pred <- 1
					}else{
						if(any(ina)){
							pars.grd.na <- gstat::krige(var1.pred~1, locations = pars.grd[!ina, ], newdata = interp.grid$newgrid[ina, ], model = vgm,
												block = bGrd, nmin = nmin, nmax = nmax, maxdist = maxdist, debug.level = 0)
							pars.grd$var1.pred[ina] <- pars.grd.na$var1.pred
						}
					}
				}

				grdbias <- matrix(pars.grd$var1.pred, ncol = nlat0, nrow = nlon0)
				grdbias[grdbias > 3] <- 3
				grdbias[grdbias < 0] <- 0.1
				grdbias[is.na(grdbias)] <- 1
			}else grdbias <- matrix(1, ncol = nlat0, nrow = nlon0)

			######
			outnc <- file.path(biasParms$bias.DIR, sprintf(biasFilenames, m))
			nc2 <- nc_create(outnc, grd.bs)
			ncvar_put(nc2, grd.bs, grdbias)
			nc_close(nc2)
		}
		if(is.parallel$stop) stopCluster(is.parallel$cluster)
	}else{
		is.parallel <- doparallel(length(months) >= 3)
		`%parLoop%` <- is.parallel$dofun

		PARS.stn <- vector(mode = 'list', length = 12)
		PARS.stn[months] <- foreach(m = months, .packages = 'sp') %parLoop% {
			pars.mon <- lapply(1:3, function(j){
				locations.stn <- interp.grid$coords.stn
				locations.stn$pars <- bias.pars$pars.stn[[m]][, j]
				if(j > 1) locations.stn$pars[!bias.pars$pars.ad.stn[[m]]] <- NA
				locations.stn <- locations.stn[!is.na(locations.stn$pars), ]

				if(any(is.auxvar) & interp.method != 'NN'){
					locations.df <- as.data.frame(!is.na(locations.stn@data[, auxvar[is.auxvar]]))
					locations.stn <- locations.stn[Reduce("&", locations.df), ]
				}
				if(length(locations.stn$pars) < min.stn) return(NULL)

				if(interp.method == 'Kriging'){
					if(length(locations.stn$pars) > 7){
						vgm <- try(automap::autofitVariogram(formule, input_data = locations.stn, model = vgm.model, cressie = TRUE), silent = TRUE)
						vgm <- if(!inherits(vgm, "try-error")) vgm$var_model else NULL
					}else vgm <- NULL
				}else vgm <- NULL

				xstn <- as.data.frame(locations.stn)
				xadd <- if(create.grd != '1' & is.regridRFE) as.data.frame(interp.grid$coords.rfe) else as.data.frame(interp.grid$coords.grd)
				xadd$pars <- bias.pars$pars.rfe[[m]][, j]
				if(j > 1) xadd$pars[!bias.pars$pars.ad.rfe[[m]]] <- NA

				xaddstn <- as.data.frame(interp.grid$coords.stn)
				xaddstn$pars <- bias.pars$pars.rfestn[[m]][, j]
				if(j > 1) xaddstn$pars[!bias.pars$pars.ad.stn[[m]]] <- NA

				xadd <- rbind(xadd, xaddstn)
				xadd <- xadd[!is.na(xadd$pars), ]

				if(length(xadd$pars) < min.stn) return(NULL)

				iadd <- rep(TRUE, nrow(xadd))
				for(k in 1:nrow(xstn)){
					if(interp.method == 'NN'){
						xy.dst <- sqrt((xstn$lon[k] - xadd$lon)^2 + (xstn$lat[k] - xadd$lat)^2) * sqrt(2)
						z.dst <- abs(xstn$elv[k] - xadd$elv)
						z.iadd <- (z.dst < z.maxdist) & (xy.dst == min(xy.dst))
						iadd <- iadd & (xy.dst >= xy.maxdist) & !z.iadd
					}else{
						dst <- sqrt((xstn$lon[k] - xadd$lon)^2 + (xstn$lat[k] - xadd$lat)^2) * sqrt(2)
						iadd <- iadd & (dst >= maxdist)
					}
				}
				xadd <- xadd[iadd, ]
				locations.stn <- rbind(xstn, xadd)

				if(interp.method == 'NN'){
					locations.stn <- locations.stn[!duplicated(locations.stn[, c('lon', 'lat', 'elv')]), ]
					coordinates(locations.stn) <- ~lon + lat + elv
					pars.grd <- gstat::krige(pars~1, locations = locations.stn, newdata = interp.grid$newgrid,
										nmax = 1, maxdist = maxdist, debug.level = 0)
				}else{
					locations.stn <- locations.stn[!duplicated(locations.stn[, c('lon', 'lat')]), ]
					coordinates(locations.stn) <- ~lon + lat
					if(any(is.auxvar)){
						locations.df <- as.data.frame(!is.na(locations.stn@data[, auxvar[is.auxvar]]))
						locations.stn <- locations.stn[Reduce("&", locations.df), ]
						block <- NULL
					}else block <- bGrd
					pars.grd <- gstat::krige(formule, locations = locations.stn, newdata = interp.grid$newgrid, model = vgm,
										block = block, nmin = nmin, nmax = nmax, maxdist = maxdist, debug.level = 0)
				}
				ret <- matrix(pars.grd$var1.pred, ncol = nlat0, nrow = nlon0)
				if(j == 1){
					ret[ret < 0] <- 0.01
					ret[ret > 1] <- 0.99
				}else ret[ret < 0] <- NA
				ret
			})
			names(pars.mon) <- c('prob', 'scale', 'shape')
			pars.mon
		}

		PARS.rfe <- vector(mode = 'list', length = 12)
		PARS.rfe[months] <- foreach(m = months, .packages = 'sp') %parLoop% {
			pars.mon <- lapply(1:3, function(j){
				locations.rfe <- if(create.grd != '1' & is.regridRFE) interp.grid$coords.rfe else interp.grid$coords.grd
				locations.rfe$pars <- bias.pars$pars.rfe[[m]][, j]
				if(j > 1) locations.rfe$pars[!bias.pars$pars.ad.rfe[[m]]] <- NA

				locations.rfestn <- interp.grid$coords.stn
				locations.rfestn$pars <- bias.pars$pars.rfestn[[m]][, j]
				if(j > 1) locations.rfestn$pars[!bias.pars$pars.ad.stn[[m]]] <- NA

				locations.rfe <- rbind(locations.rfe, locations.rfestn)
				locations.rfe <- locations.rfe[!is.na(locations.rfe$pars), ]
				if(length(locations.rfe$pars) < min.stn) return(NULL)

				locations.rfe <- remove.duplicates(locations.rfe)

				if(any(is.auxvar) & interp.method != 'NN'){
					locations.df <- as.data.frame(!is.na(locations.rfe@data[, auxvar[is.auxvar]]))
					locations.rfe <- locations.rfe[Reduce("&", locations.df), ]
				}
				if(length(locations.rfe$pars) < min.stn) return(NULL)

				if(interp.method == 'Kriging'){
					if(length(locations.rfe$pars) > 7){
						vgm <- try(automap::autofitVariogram(formule, input_data = locations.rfe, model = vgm.model, cressie = TRUE), silent = TRUE)
						vgm <- if(!inherits(vgm, "try-error")) vgm$var_model else NULL
					}else vgm <- NULL
				}else vgm <- NULL

				if(interp.method == 'NN'){
					pars.grd <- gstat::krige(pars~1, locations = locations.rfe, newdata = interp.grid$newgrid,
										nmax = 1, maxdist = maxdist, debug.level = 0)
				}else{
					block <- if(any(is.auxvar)) NULL else bGrd
					pars.grd <- gstat::krige(formule, locations = locations.rfe, newdata = interp.grid$newgrid, model = vgm,
									block = block, nmin = nmin, nmax = nmax, maxdist = maxdist, debug.level = 0)
				}
				ret <- matrix(pars.grd$var1.pred, ncol = nlat0, nrow = nlon0)
				if(j == 1){
					ret[ret < 0] <- 0.01
					ret[ret > 1] <- 0.99
				}else ret[ret < 0] <- NA
				ret
			})
			names(pars.mon) <- c('prob', 'scale', 'shape')
			pars.mon
		}
		if(is.parallel$stop) stopCluster(is.parallel$cluster)

		################

		default <- colMedians(do.call(rbind, bias.pars$pars.rfe), na.rm = TRUE)
		names(default) <- c('prob', 'scale', 'shape')
		PARS <- vector(mode = 'list', length = 12)
		PARS[months] <- lapply(months, function(m){
			par.stn <- PARS.stn[[m]]
			par.rfe <- PARS.rfe[[m]]
			prob <- scale <- shape <- matrix(NA, ncol = nlat0, nrow = nlon0)
			if(!is.null(par.stn) & !is.null(par.rfe)){
				if(!is.null(par.stn$prob) & !is.null(par.stn$scale) & !is.null(par.stn$shape) &
					!is.null(par.rfe$prob) & !is.null(par.rfe$scale) & !is.null(par.rfe$shape)){
					ina <- is.na(par.stn$prob) | is.na(par.stn$scale) | is.na(par.stn$shape) |
							is.na(par.rfe$prob) | is.na(par.rfe$scale) | is.na(par.rfe$shape)
					mprob <- median(par.rfe$prob, na.rm = TRUE)
					mscale <- median(par.rfe$scale, na.rm = TRUE)
					mshape <- median(par.rfe$shape, na.rm = TRUE)
					par.stn$prob[ina] <- mprob
					par.stn$scale[ina] <- mscale
					par.stn$shape[ina] <- mshape
					par.rfe$prob[ina] <- mprob
					par.rfe$scale[ina] <- mscale
					par.rfe$shape[ina] <- mshape
					ret.stn <- list(prob = par.stn$prob, scale = par.stn$scale, shape = par.stn$shape)
					ret.rfe <- list(prob = par.rfe$prob, scale = par.rfe$scale, shape = par.rfe$shape)
				}else{
					prob[] <- default['prob']
					scale[] <- default['scale']
					shape[] <- default['shape']
					ret.stn <- ret.rfe <- list(prob = prob, scale = scale, shape = shape)
				}
				################
			}else{
				prob[] <- default['prob']
				scale[] <- default['scale']
				shape[] <- default['shape']
				ret.stn <- ret.rfe <- list(prob = prob, scale = scale, shape = shape)
			}
			list(stn = ret.stn, rfe = ret.rfe)
		})

		#Defines netcdf output
		grd.prob <- ncvar_def("prob", "", xy.dim, NA, longname = "Probability of non-zero event Bernoulli-Gamma distribution", prec = "float", compression = 9)
		grd.scale <- ncvar_def("scale", "", xy.dim, NA, longname = "Scale parameters of the gamma distribution", prec = "float", compression = 9)
		grd.shape <- ncvar_def("shape", "", xy.dim, NA, longname = "Shape parameters of the gamma distribution", prec = "float", compression = 9)

		for(jfl in months){
			outnc1 <- file.path(biasParms$bias.DIR, paste0('Bernoulli-Gamma_Pars.STN_', jfl, '.nc'))
			nc1 <- nc_create(outnc1, list(grd.prob, grd.scale, grd.shape))
			ncvar_put(nc1, grd.prob, PARS[[jfl]]$stn$prob)
			ncvar_put(nc1, grd.scale, PARS[[jfl]]$stn$scale)
			ncvar_put(nc1, grd.shape, PARS[[jfl]]$stn$shape)
			nc_close(nc1)
		}

		for(jfl in months){
			outnc2 <- file.path(biasParms$bias.DIR, paste0('Bernoulli-Gamma_Pars.RFE_', jfl, '.nc'))
			nc2 <- nc_create(outnc2, list(grd.prob, grd.scale, grd.shape))
			ncvar_put(nc2, grd.prob, PARS[[jfl]]$rfe$prob)
			ncvar_put(nc2, grd.scale, PARS[[jfl]]$rfe$scale)
			ncvar_put(nc2, grd.shape, PARS[[jfl]]$rfe$shape)
			nc_close(nc2)
		}
		rm(PARS.stn, PARS.rfe, PARS)
	}

	rm(demGrid, rfeGrid, ObjStn, interp.grid, bias.pars)
	gc()
	Insert.Messages.Out('Interpolating bias factors finished')
	return(0)
}

