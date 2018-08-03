
StnChkCoordsPlotMap <- function(){
	MapOp <- .cdtData$EnvData$MapOp
	don <- .cdtData$EnvData$Maps.Disp

	id <- rep(1, nrow(don))
	id[don$StatusX == "orange"] <- 2
	id[don$StatusX == "red"] <- 3
	loko <- c(MapOp$blue$col, MapOp$orange$col, MapOp$red$col)[id]
	pch <- c(MapOp$blue$pch, MapOp$orange$pch, MapOp$red$pch)[id]
	cex <- c(MapOp$blue$cex, MapOp$orange$cex, MapOp$red$cex)[id]

	ocrds <- .cdtData$EnvData$shp$ocrds
	if(is.null(ocrds)) ocrds <- matrix(NA, 1, 2)

	#######
	xmin <- .cdtData$EnvData$ZoomXYval[1]
	xmax <- .cdtData$EnvData$ZoomXYval[2]
	ymin <- .cdtData$EnvData$ZoomXYval[3]
	ymax <- .cdtData$EnvData$ZoomXYval[4]

	if(is.na(xmin) | is.null(xmin) | is.infinite(xmin)){
		Insert.Messages.Out('Longitude min not valid', format = TRUE)
		return(NULL)
	}
	if(is.na(xmax) | is.null(xmax) | is.infinite(xmax)){
		Insert.Messages.Out('Longitude max not valid', format = TRUE)
		return(NULL)
	}
	if(is.na(ymin) | is.null(ymin) | is.infinite(ymin)){
		Insert.Messages.Out('Latitude min not valid', format = TRUE)
		return(NULL)
	}
	if(is.na(ymax) | is.null(ymax) | is.infinite(ymax)){
		Insert.Messages.Out('Latitude max not valid', format = TRUE)
		return(NULL)
	}

	#######
	opar <- par(mar = c(4, 4, 2, 2))
	plot(1, xlim = c(xmin, xmax), ylim = c(ymin, ymax), xlab = "", ylab = "", type = "n", xaxt = 'n', yaxt = 'n')
	lines(ocrds[, 1], ocrds[, 2], lwd = MapOp$shp$lwd, col = MapOp$shp$col)
	abline(h = axTicks(2), v = axTicks(1) , col = "lightgray", lty = 3)
	axlabs <- LatLonAxisLabels(axTicks(1), axTicks(2))
	axis(side = 1, at = axTicks(1), labels = axlabs$xaxl, tck = -0.01, cex.axis = 0.8)
	axis(side = 2, at = axTicks(2), labels = axlabs$yaxl, tck = -0.01, las = 1, cex.axis = 0.8)

	points(don$LonX, don$LatX, col = loko, pch = pch, cex = cex)

	plt <- par("plt")
	usr <- par("usr")
	par(opar)

	return(list(par = c(plt, usr)))
}

#################################################################

StnChkCoordsDisplayMap <- function(notebookTab){
	varplot <- c("parPlotSize1", "parPlotSize2", "parPlotSize3", "parPlotSize4",
				 "usrCoords1", "usrCoords2", "usrCoords3", "usrCoords4")
	parPltCrd <- setNames(lapply(varplot, function(x) assign(x, tclVar(), env = parent.frame())), varplot)

	plotIt <- function(){
		tkconfigure(.cdtEnv$tcl$main$win, cursor = 'watch')
		tcl('update')
		on.exit({
			tkconfigure(.cdtEnv$tcl$main$win, cursor = '')
			tcl('update')
		})

		op <- par(bg = "white")
		pltusr <- StnChkCoordsPlotMap()
		par(op)
		for(j in seq_along(varplot)) tclvalue(parPltCrd[[varplot[j]]]) <- pltusr$par[j]
	}

	###################################################################

	onglet <- imageNotebookTab_open(notebookTab, 'Coordinates Map')
	hscale <- as.numeric(tclvalue(tkget(.cdtEnv$tcl$toolbar$spinH)))
	vscale <- as.numeric(tclvalue(tkget(.cdtEnv$tcl$toolbar$spinV)))

	canvas <- tkcanvas(onglet[[2]])
	tkgrid(canvas)

	img <- tkrplot(canvas, fun = plotIt, hscale = hscale, vscale = vscale)
	img_w <- as.double(tcl('image', 'width', img$image))
	img_h <- as.double(tcl('image', 'height', img$image))
	tkconfigure(canvas, width = img_w, height = img_h)
	tkcreate(canvas, "image", 0, 0, anchor = 'nw', image = img$image)
	tcl('raise', canvas)
	tcl('update')

	tkbind(canvas, "<Enter>", function(){
		if(tclvalue(.cdtData$EnvData$zoom$pressButP) == "1")
			tkconfigure(canvas, cursor = 'sizing')
		else if(tclvalue(.cdtData$EnvData$zoom$pressButM) == "1")
			tkconfigure(canvas, cursor = 'sizing')
		else if(tclvalue(.cdtData$EnvData$zoom$pressButRect) == "1")
			tkconfigure(canvas, cursor = 'sizing')
		else if(tclvalue(.cdtData$EnvData$zoom$pressButDrag) == "1")
			tkconfigure(canvas, cursor = 'hand1')
		else
			tkconfigure(canvas, cursor = 'crosshair')
	})

	tkbind(canvas, "<Leave>", function() tkconfigure(canvas, cursor = ''))

	##########
	## draw rectangle initial value
	.cdtEnv$tcl$lastX <- 0
	.cdtEnv$tcl$lastY <- 0

	## zoom factor
	factZoom <- 0.2

	##zoom rectangle
	rectZoomInit <- .cdtData$EnvData$ZoomXYval

	## Pan Image
	panZoomInit <- c(0, 0, 0, 0, 0, 0)
	factPan <- 0.2

	##########
	## first click on map
	tkbind(canvas, "<Button-1>", function(W, x, y){
		ret <- getXYCoords(W, x, y, parPltCrd)
		tkdelete(W, 'rect')

		#Zoom plus
		if(tclvalue(.cdtData$EnvData$zoom$pressButP) == "1" & !ret$oin){
			rgX <- as.numeric(tclvalue(parPltCrd$usrCoords2)) - as.numeric(tclvalue(parPltCrd$usrCoords1))
			rgY <- as.numeric(tclvalue(parPltCrd$usrCoords4)) - as.numeric(tclvalue(parPltCrd$usrCoords3))
			shiftX <- rgX * (1 - factZoom)/2
			shiftY <- rgY * (1 - factZoom)/2
			xmin1 <- ret$xc - shiftX
			xmax1 <- ret$xc + shiftX
			ymin1 <- ret$yc - shiftY
			ymax1 <- ret$yc + shiftY

			.cdtData$EnvData$ZoomXYval <- c(xmin1, xmax1, ymin1, ymax1)

			tclvalue(.cdtData$EnvData$zoom$xx1) <- round(xmin1, 4)
			tclvalue(.cdtData$EnvData$zoom$xx2) <- round(xmax1, 4)
			tclvalue(.cdtData$EnvData$zoom$yy1) <- round(ymin1, 4)
			tclvalue(.cdtData$EnvData$zoom$yy2) <- round(ymax1, 4)

			refreshPlot(W, img,
						hscale = as.numeric(tclvalue(tkget(.cdtEnv$tcl$toolbar$spinH))),
						vscale = as.numeric(tclvalue(tkget(.cdtEnv$tcl$toolbar$spinV)))
						)
		}

		#Zoom Moins
		if(tclvalue(.cdtData$EnvData$zoom$pressButM) == "1" & !ret$oin){
			rgX <- as.numeric(tclvalue(parPltCrd$usrCoords2)) - as.numeric(tclvalue(parPltCrd$usrCoords1))
			rgY <- as.numeric(tclvalue(parPltCrd$usrCoords4)) - as.numeric(tclvalue(parPltCrd$usrCoords3))
			shiftX <- rgX * (1 + factZoom)/2
			shiftY <- rgY * (1 + factZoom)/2
			xmin1 <- ret$xc - shiftX
			xmax1 <- ret$xc + shiftX
			ymin1 <- ret$yc - shiftY
			ymax1 <- ret$yc + shiftY

			if(xmin1< -180 | xmax1 > 180 | ymin1< -90 | ymax1 > 90){
				tclvalue(.cdtData$EnvData$zoom$pressButP) <- 0
				tclvalue(.cdtData$EnvData$zoom$pressButM) <- 0
				tclvalue(.cdtData$EnvData$zoom$pressButRect) <- 0
				tclvalue(.cdtData$EnvData$zoom$pressButDrag) <- 0
				
				tkconfigure(.cdtData$EnvData$zoom$btZoomP, relief = 'raised', bg = 'lightblue', state = 'normal')
				tkconfigure(.cdtData$EnvData$zoom$btZoomM, relief = 'raised', bg = 'lightblue', state = 'normal')
				tkconfigure(.cdtData$EnvData$zoom$btZoomRect, relief = 'raised', bg = 'lightblue', state = 'normal')
				tkconfigure(.cdtData$EnvData$zoom$btPanImg, relief = 'raised', bg = 'lightblue', state = 'normal')

				tkconfigure(W, cursor = 'crosshair')
			}else{
				.cdtData$EnvData$ZoomXYval <- c(xmin1, xmax1, ymin1, ymax1)

				tclvalue(.cdtData$EnvData$zoom$xx1) <- round(xmin1, 4)
				tclvalue(.cdtData$EnvData$zoom$xx2) <- round(xmax1, 4)
				tclvalue(.cdtData$EnvData$zoom$yy1) <- round(ymin1, 4)
				tclvalue(.cdtData$EnvData$zoom$yy2) <- round(ymax1, 4)

				refreshPlot(W, img,
							hscale = as.numeric(tclvalue(tkget(.cdtEnv$tcl$toolbar$spinH))),
							vscale = as.numeric(tclvalue(tkget(.cdtEnv$tcl$toolbar$spinV)))
							)
			}
		}

		##Zoom rectangle
		if(tclvalue(.cdtData$EnvData$zoom$pressButRect) == "1" & !ret$oin){
			pPressRect(W, x, y, width = 1, outline = "red")
			rectZoomInit[1] <<- ret$xc
			rectZoomInit[3] <<- ret$yc
		}

		##Pan image
		if(tclvalue(.cdtData$EnvData$zoom$pressButDrag) == "1" & !ret$oin){
			panZoomInit[1] <<- ret$xc
			panZoomInit[2] <<- ret$yc

			panZoomInit[3] <<- as.numeric(tclvalue(.cdtData$EnvData$zoom$xx1))
			panZoomInit[4] <<- as.numeric(tclvalue(.cdtData$EnvData$zoom$xx2))
			panZoomInit[5] <<- as.numeric(tclvalue(.cdtData$EnvData$zoom$yy1))
			panZoomInit[6] <<- as.numeric(tclvalue(.cdtData$EnvData$zoom$yy2))

			tkconfigure(canvas, cursor = 'hand2')
		}
	})

	##########
	## cursor movement
	tkbind(canvas, "<Motion>", function(W, x, y){
		displayCursorPosition3Var(W, x, y, parPltCrd, getStnIDLabel,
								stn.coords = .cdtData$EnvData$plot.maps[c('lon', 'lat', 'id')])
	})

	#########
	## cursor movement with button-1 pressed
	tkbind(canvas, "<B1-Motion>", function(W, x, y){
		ret <- getXYCoords(W, x, y, parPltCrd)

		##Zoom rectangle
		if(tclvalue(.cdtData$EnvData$zoom$pressButRect) == "1"){
			pMoveRect(W, x, y)
		}

		##Pan image
		if(tclvalue(.cdtData$EnvData$zoom$pressButDrag) == "1"){
			transX <- ret$xc - panZoomInit[1]
			transY <- ret$yc - panZoomInit[2]

			tclvalue(.cdtData$EnvData$zoom$xx1) <- round(panZoomInit[3] + factPan * transX, 4)
			tclvalue(.cdtData$EnvData$zoom$xx2) <- round(panZoomInit[4] + factPan * transX, 4)
			tclvalue(.cdtData$EnvData$zoom$yy1) <- round(panZoomInit[5] + factPan * transY, 4)
			tclvalue(.cdtData$EnvData$zoom$yy2) <- round(panZoomInit[6] + factPan * transY, 4)

			.cdtData$EnvData$ZoomXYval <- as.numeric(c(
														tclvalue(.cdtData$EnvData$zoom$xx1),
														tclvalue(.cdtData$EnvData$zoom$xx2),
														tclvalue(.cdtData$EnvData$zoom$yy1),
														tclvalue(.cdtData$EnvData$zoom$yy2)
													))
		}

		refreshPlot(W, img,
					hscale = as.numeric(tclvalue(tkget(.cdtEnv$tcl$toolbar$spinH))),
					vscale = as.numeric(tclvalue(tkget(.cdtEnv$tcl$toolbar$spinV)))
					)
	})

	#########
	## release button1
	tkbind(canvas, "<ButtonRelease>", function(W, x, y){
		ret <- getXYCoords(W, x, y, parPltCrd)

		##Zoom rectangle
		if(tclvalue(.cdtData$EnvData$zoom$pressButRect) == "1"){
			rectZoomInit[2] <<- ret$xc
			rectZoomInit[4] <<- ret$yc
			if(rectZoomInit[1] > rectZoomInit[2]) rectZoomInit <- rectZoomInit[c(2, 1, 3, 4)]
			if(rectZoomInit[3] > rectZoomInit[4]) rectZoomInit <- rectZoomInit[c(1, 2, 4, 3)]
			.cdtData$EnvData$ZoomXYval <- rectZoomInit

			tclvalue(.cdtData$EnvData$zoom$xx1) <- round(rectZoomInit[1], 4)
			tclvalue(.cdtData$EnvData$zoom$xx2) <- round(rectZoomInit[2], 4)
			tclvalue(.cdtData$EnvData$zoom$yy1) <- round(rectZoomInit[3], 4)
			tclvalue(.cdtData$EnvData$zoom$yy2) <- round(rectZoomInit[4], 4)

			refreshPlot(W, img,
						hscale = as.numeric(tclvalue(tkget(.cdtEnv$tcl$toolbar$spinH))),
						vscale = as.numeric(tclvalue(tkget(.cdtEnv$tcl$toolbar$spinV)))
						)
			tkdelete(W, 'rect')
		}

		##Pan image
		if(tclvalue(.cdtData$EnvData$zoom$pressButDrag) == "1"){
			tkconfigure(canvas, cursor = 'hand1')
		}

		tcl('update')
	})

	###############################################
	## deactivate zoom (right button)
	tkbind(canvas, "<Button-3>", function(W){
		tclvalue(.cdtData$EnvData$zoom$pressButP) <- 0
		tclvalue(.cdtData$EnvData$zoom$pressButM) <- 0
		tclvalue(.cdtData$EnvData$zoom$pressButRect) <- 0
		tclvalue(.cdtData$EnvData$zoom$pressButDrag) <- 0

		tkconfigure(.cdtData$EnvData$zoom$btZoomP, relief = 'raised', bg = 'lightblue', state = 'normal')
		tkconfigure(.cdtData$EnvData$zoom$btZoomM, relief = 'raised', bg = 'lightblue', state = 'normal')
		tkconfigure(.cdtData$EnvData$zoom$btZoomRect, relief = 'raised', bg = 'lightblue', state = 'normal')
		tkconfigure(.cdtData$EnvData$zoom$btPanImg, relief = 'raised', bg = 'lightblue', state = 'normal')

		tkconfigure(canvas, cursor = 'crosshair')

		tkdelete(W, 'rect')

		refreshPlot(W, img,
					hscale = as.numeric(tclvalue(tkget(.cdtEnv$tcl$toolbar$spinH))),
					vscale = as.numeric(tclvalue(tkget(.cdtEnv$tcl$toolbar$spinV)))
					)
	})

	###
	return(list(onglet, list(canvas, img)))
}