
# cdtTemp_LMCoeff_dlgBox

coefLMGetInfoTemp <- function(){
	listOpenFiles <- openFile_ttkcomboList()
	if(WindowsOS()){
		largeur0 <- 27
		largeur1 <- 42
		largeur2 <- 45
		largeur3 <- 27
	}else{
		largeur0 <- 21
		largeur1 <- 38
		largeur2 <- 39
		largeur3 <- 21
	}

	# xml.dlg <- file.path(.cdtDir$dirLocal, "languages", "cdtTemp_LMCoeff_dlgBox.xml")
	# lang.dlg <- cdtLanguageParse(xml.dlg, .cdtData$Config$lang.iso)

	####################################

	tt <- tktoplevel()
	tkgrab.set(tt)
	tkfocus(tt)

	frMRG0 <- tkframe(tt, relief = 'raised', borderwidth = 2, padx = 5, pady = 5)
	frMRG1 <- tkframe(tt)

	####################################

	bwnote <- bwNoteBook(frMRG0)
	conf.tab1 <- bwAddTab(bwnote, text = "Input-Output")
	conf.tab2 <- bwAddTab(bwnote, text = "LMCoef Parameters")

	bwRaiseTab(bwnote, conf.tab1)
	tkgrid.columnconfigure(conf.tab1, 0, weight = 1)
	tkgrid.columnconfigure(conf.tab2, 0, weight = 1)

	############################################

	frTab1 <- tkframe(conf.tab1)

		####################################

		frtimestep <- tkframe(frTab1, relief = 'sunken', borderwidth = 2, padx = 3, pady = 3)

		file.period <- tclVar()
		CbperiodVAL <- .cdtEnv$tcl$lang$global[['combobox']][['1']][2:5]
		periodVAL <- c('daily', 'pentad', 'dekadal', 'monthly')
		tclvalue(file.period) <- CbperiodVAL[periodVAL %in% .cdtData$GalParams$period]

		cb.period <- ttkcombobox(frtimestep, values = CbperiodVAL, textvariable = file.period, width = largeur0)

		tkgrid(cb.period, row = 0, column = 0, sticky = '', rowspan = 1, columnspan = 1, padx = 1, pady = 1, ipadx = 1, ipady = 1)

		infobulle(cb.period, 'Select the time step of the data')
		status.bar.display(cb.period, 'Select the time step of the data')

		####################################

		frInputData <- tkframe(frTab1, relief = 'sunken', borderwidth = 2, padx = 3, pady = 3)

		file.stnfl <- tclVar(.cdtData$GalParams$STN.file)
		dir.RFE <- tclVar(.cdtData$GalParams$TEMP$dir)

		txt.stnfl <- tklabel(frInputData, text = 'Station data file', anchor = 'w', justify = 'left')
		cb.stnfl <- ttkcombobox(frInputData, values = unlist(listOpenFiles), textvariable = file.stnfl, width = largeur1)
		bt.stnfl <- tkbutton(frInputData, text = "...")
		txt.RFE <- tklabel(frInputData, text = 'Adjusted data directory', anchor = 'w', justify = 'left')
		set.RFE <- ttkbutton(frInputData, text = .cdtEnv$tcl$lang$global[['button']][['5']])
		en.RFE <- tkentry(frInputData, textvariable = dir.RFE, width = largeur2)
		bt.RFE <- tkbutton(frInputData, text = "...")

		######
		tkconfigure(bt.stnfl, command = function(){
			dat.opfiles <- getOpenFiles(tt)
			if(!is.null(dat.opfiles)){
				update.OpenFiles('ascii', dat.opfiles)
				listOpenFiles[[length(listOpenFiles) + 1]] <<- dat.opfiles[[1]]
				tclvalue(file.stnfl) <- dat.opfiles[[1]]
				lapply(list(cb.stnfl, cb.grddem), tkconfigure, values = unlist(listOpenFiles))
			}
		})

		tkconfigure(set.RFE, command = function(){
			.cdtData$GalParams[["TEMP"]] <- getInfoNetcdfData(tt, .cdtData$GalParams[["TEMP"]],
															str_trim(tclvalue(dir.RFE)), str_trim(tclvalue(file.period)))
		})

		tkconfigure(bt.RFE, command = function(){
			dirrfe <- tk_choose.dir(getwd(), "")
			tclvalue(dir.RFE) <- if(!is.na(dirrfe)) dirrfe else ""
		})

		######
		tkgrid(txt.stnfl, row = 0, column = 0, sticky = 'we', rowspan = 1, columnspan = 5, padx = 1, pady = 0, ipadx = 1, ipady = 1)
		tkgrid(cb.stnfl, row = 1, column = 0, sticky = 'we', rowspan = 1, columnspan = 4, padx = 0, pady = 0, ipadx = 1, ipady = 1)
		tkgrid(bt.stnfl, row = 1, column = 4, sticky = 'w', rowspan = 1, columnspan = 1, padx = 0, pady = 0, ipadx = 1, ipady = 1)

		tkgrid(txt.RFE, row = 2, column = 0, sticky = 'we', rowspan = 1, columnspan = 3, padx = 1, pady = 0, ipadx = 1, ipady = 1)
		tkgrid(set.RFE, row = 2, column = 3, sticky = 'we', rowspan = 1, columnspan = 2, padx = 1, pady = 0, ipadx = 1, ipady = 1)
		tkgrid(en.RFE, row = 3, column = 0, sticky = 'we', rowspan = 1, columnspan = 4, padx = 0, pady = 0, ipadx = 1, ipady = 1)
		tkgrid(bt.RFE, row = 3, column = 4, sticky = 'w', rowspan = 1, columnspan = 1, padx = 0, pady = 0, ipadx = 1, ipady = 1)

		infobulle(cb.stnfl, 'Select the file from the list')
		status.bar.display(cb.stnfl, 'Select the file containing the gauge data')
		infobulle(bt.stnfl, 'Browse file if not listed')
		status.bar.display(bt.stnfl, 'Browse file if not listed')
		infobulle(en.RFE, 'Enter the full path to directory containing the Adjusted data')
		status.bar.display(en.RFE, 'Enter the full path to directory containing the Adjusted data')
		infobulle(bt.RFE, 'Or browse here')
		status.bar.display(bt.RFE, 'Or browse here')
		infobulle(set.RFE, 'Setting netcdf data options')
		status.bar.display(set.RFE, 'Setting netcdf data options')

		####################################

		frDEM <- tkframe(frTab1, relief = 'sunken', borderwidth = 2, padx = 3, pady = 3)

		file.grddem <- tclVar(.cdtData$GalParams$DEM.file)

		statedem <- if(.cdtData$GalParams$LMCOEF$interp.method == "NN" |
						.cdtData$GalParams$auxvar$dem |
						.cdtData$GalParams$auxvar$slope |
						.cdtData$GalParams$auxvar$aspect) 'normal' else 'disabled'

		txt.grddem <- tklabel(frDEM, text = "Elevation data (NetCDF)", anchor = 'w', justify = 'left')
		cb.grddem <- ttkcombobox(frDEM, values = unlist(listOpenFiles), textvariable = file.grddem, state = statedem, width = largeur1)
		bt.grddem <- tkbutton(frDEM, text = "...", state = statedem)

		tkconfigure(bt.grddem, command = function(){
			nc.opfiles <- getOpenNetcdf(tt, initialdir = getwd())
			if(!is.null(nc.opfiles)){
				update.OpenFiles('netcdf', nc.opfiles)
				listOpenFiles[[length(listOpenFiles) + 1]] <<- nc.opfiles[[1]]
				tclvalue(file.grddem) <- nc.opfiles[[1]]
				lapply(list(cb.stnfl, cb.grddem), tkconfigure, values = unlist(listOpenFiles))
			}
		})

		tkgrid(txt.grddem, row = 0, column = 0, sticky = 'we', rowspan = 1, columnspan = 2, padx = 1, pady = 1, ipadx = 1, ipady = 1)
		tkgrid(cb.grddem, row = 1, column = 0, sticky = 'we', rowspan = 1, columnspan = 1, padx = 0, pady = 1, ipadx = 1, ipady = 1)
		tkgrid(bt.grddem, row = 1, column = 1, sticky = 'w', rowspan = 1, columnspan = 1, padx = 0, pady = 1, ipadx = 1, ipady = 1)

		infobulle(cb.grddem, 'Select the file in the list')
		status.bar.display(cb.grddem, 'File containing the elevation data in netcdf')
		infobulle(bt.grddem, 'Browse file if not listed')
		status.bar.display(bt.grddem, 'Browse file if not listed')

		####################################

		frSave <- tkframe(frTab1, relief = 'sunken', borderwidth = 2)

		dir2save <- tclVar(.cdtData$GalParams$output$dir)

		txt.dir2save <- tklabel(frSave, text = 'Directory to save result', anchor = 'w', justify = 'left')
		en.dir2save <- tkentry(frSave, textvariable = dir2save, width = largeur2)
		bt.dir2save <- tkbutton(frSave, text = "...")

		#####

		tkconfigure(bt.dir2save, command = function(){
			dir2savepth <- tk_choose.dir(.cdtData$GalParams$output$dir, "")
			if(is.na(dir2savepth)) tclvalue(dir2save) <- .cdtData$GalParams$output$dir
			else{
				dir.create(dir2savepth, showWarnings = FALSE, recursive = TRUE)
				tclvalue(dir2save) <- dir2savepth
			}
		})

		#####

		tkgrid(txt.dir2save, row = 0, column = 0, sticky = 'we', rowspan = 1, columnspan = 2, padx = 1, pady = 2, ipadx = 1, ipady = 1)
		tkgrid(en.dir2save, row = 1, column = 0, sticky = 'we', rowspan = 1, columnspan = 1, padx = 0, pady = 1, ipadx = 1, ipady = 1)
		tkgrid(bt.dir2save, row = 1, column = 1, sticky = 'w', rowspan = 1, columnspan = 1, padx = 0, pady = 1, ipadx = 1, ipady = 1)

		infobulle(en.dir2save, 'Enter the full path to directory to save result')
		status.bar.display(en.dir2save, 'Enter the full path to directory to save result')
		infobulle(bt.dir2save, 'or browse here')
		status.bar.display(bt.dir2save, 'or browse here')

		####################################

		tkgrid(frtimestep, row = 0, column = 0, sticky = '', padx = 1, pady = 1, ipadx = 1, ipady = 1)
		tkgrid(frInputData, row = 1, column = 0, sticky = 'we', padx = 1, pady = 1, ipadx = 1, ipady = 1)
		tkgrid(frDEM, row = 2, column = 0, sticky = 'we', padx = 1, pady = 1, ipadx = 1, ipady = 1)
		tkgrid(frSave, row = 3, column = 0, sticky = 'we', padx = 1, pady = 1, ipadx = 1, ipady = 1)

		####################################

		tkgrid(frTab1, padx = 0, pady = 1, ipadx = 1, ipady = 1)

	####################################

	frTab2 <- tkframe(conf.tab2)

		####################################

		frameLMCoef <- tkframe(frTab2, relief = 'sunken', borderwidth = 2, padx = 5, pady = 5)

		bt.baseLMCoef <- ttkbutton(frameLMCoef, text = "Set Base Period")
		bt.LMCoef.interp <- ttkbutton(frameLMCoef, text = "LMCoef Interpolations Parameters")

		tkconfigure(bt.baseLMCoef, command = function(){
			.cdtData$GalParams[["LMCOEF"]] <- getInfoBasePeriod(tt, .cdtData$GalParams[["LMCOEF"]])
		})

		tkconfigure(bt.LMCoef.interp, command = function(){
			.cdtData$GalParams[["LMCOEF"]] <- getInterpolationPars(tt, .cdtData$GalParams[["LMCOEF"]], interpChoix = 1)

			statedem <- if(.cdtData$GalParams$LMCOEF$interp.method == "NN" |
								tclvalue(dem.auxvar) == "1" |
								tclvalue(slope.auxvar) == "1" |
								tclvalue(aspect.auxvar) == "1") 'normal' else 'disabled'

			tkconfigure(cb.grddem, state = statedem)
			tkconfigure(bt.grddem, state = statedem)
		})

		tkgrid(bt.baseLMCoef, row = 0, column = 0, sticky = 'we', rowspan = 1, columnspan = 1, padx = 1, pady = 3, ipadx = 10, ipady = 1)
		tkgrid(bt.LMCoef.interp, row = 1, column = 0, sticky = 'we', rowspan = 1, columnspan = 1, padx = 1, pady = 3, ipadx = 10, ipady = 1)

		infobulle(bt.baseLMCoef, 'Set the base period to be used to compute LM coefficients')
		status.bar.display(bt.baseLMCoef, 'Set the base period to be used to compute LM coefficients')
		infobulle(bt.LMCoef.interp, 'Set the parameters to interpolate the LM coefficients')
		status.bar.display(bt.LMCoef.interp, 'Set the parameters to interpolate the LM coefficients')

		####################################

		frauxvar <- tkframe(frTab2, relief = 'sunken', borderwidth = 2, padx = 5, pady = 5)

		dem.auxvar <- tclVar(.cdtData$GalParams$auxvar$dem)
		slope.auxvar <- tclVar(.cdtData$GalParams$auxvar$slope)
		aspect.auxvar <- tclVar(.cdtData$GalParams$auxvar$aspect)
		lon.auxvar <- tclVar(.cdtData$GalParams$auxvar$lon)
		lat.auxvar <- tclVar(.cdtData$GalParams$auxvar$lat)

		txt.auxvar <- tklabel(frauxvar, text = 'Include auxiliary variables', anchor = 'w', justify = 'left')
		dem.chk.auxvar <- tkcheckbutton(frauxvar, variable = dem.auxvar, text = 'DEM', anchor = 'w', justify = 'left')
		slope.chk.auxvar <- tkcheckbutton(frauxvar, variable = slope.auxvar, text = 'Slope', anchor = 'w', justify = 'left')
		aspect.chk.auxvar <- tkcheckbutton(frauxvar, variable = aspect.auxvar, text = 'Aspect', anchor = 'w', justify = 'left')
		lon.chk.auxvar <- tkcheckbutton(frauxvar, variable = lon.auxvar, text = 'Lon', anchor = 'w', justify = 'left')
		lat.chk.auxvar <- tkcheckbutton(frauxvar, variable = lat.auxvar, text = 'Lat', anchor = 'w', justify = 'left')

		tkgrid(txt.auxvar, row = 0, column = 0, sticky = 'we', rowspan = 1, columnspan = 5, padx = 1, pady = 1, ipadx = 1, ipady = 1)
		tkgrid(dem.chk.auxvar, row = 1, column = 0, sticky = 'we', rowspan = 1, columnspan = 1, padx = 0, pady = 1, ipadx = 0, ipady = 1)
		tkgrid(slope.chk.auxvar, row = 1, column = 1, sticky = 'we', rowspan = 1, columnspan = 1, padx = 0, pady = 1, ipadx = 0, ipady = 1)
		tkgrid(aspect.chk.auxvar, row = 1, column = 2, sticky = 'we', rowspan = 1, columnspan = 1, padx = 0, pady = 1, ipadx = 0, ipady = 1)
		tkgrid(lon.chk.auxvar, row = 1, column = 3, sticky = 'we', rowspan = 1, columnspan = 1, padx = 0, pady = 1, ipadx = 0, ipady = 1)
		tkgrid(lat.chk.auxvar, row = 1, column = 4, sticky = 'we', rowspan = 1, columnspan = 1, padx = 0, pady = 1, ipadx = 0, ipady = 1)

		infobulle(dem.chk.auxvar, 'Include elevation data as auxiliary variable')
		status.bar.display(dem.chk.auxvar, 'Include elevation data as auxiliary variable')
		infobulle(slope.chk.auxvar, 'Include slope data as auxiliary variable')
		status.bar.display(slope.chk.auxvar, 'Include slope data as auxiliary variable')
		infobulle(aspect.chk.auxvar, 'Include aspect data as auxiliary variable')
		status.bar.display(aspect.chk.auxvar, 'Include aspect data as auxiliary variable')
		infobulle(lon.chk.auxvar, 'Include longitude as auxiliary variable')
		status.bar.display(lon.chk.auxvar, 'Include longitude as auxiliary variable')
		infobulle(lat.chk.auxvar, 'Include latitude as auxiliary variable')
		status.bar.display(lat.chk.auxvar, 'Include latitude as auxiliary variable')

		###########

		tkbind(dem.chk.auxvar, "<Button-1>", function(){
			statedem <- if(tclvalue(dem.auxvar) == "0" |
							(.cdtData$GalParams$LMCOEF$interp.method == "NN" |
							tclvalue(slope.auxvar) == "1" |
							tclvalue(aspect.auxvar) == "1")) 'normal' else 'disabled'
			tkconfigure(cb.grddem, state = statedem)
			tkconfigure(bt.grddem, state = statedem)
		})

		tkbind(slope.chk.auxvar, "<Button-1>", function(){
			statedem <- if(tclvalue(slope.auxvar) == "0" |
							(.cdtData$GalParams$LMCOEF$interp.method == "NN" |
							tclvalue(dem.auxvar) == "1" |
							tclvalue(aspect.auxvar) == "1")) 'normal' else 'disabled'
			tkconfigure(cb.grddem, state = statedem)
			tkconfigure(bt.grddem, state = statedem)
		})

		tkbind(aspect.chk.auxvar, "<Button-1>", function(){
			statedem <- if(tclvalue(aspect.auxvar) == "0" |
							(.cdtData$GalParams$LMCOEF$interp.method == "NN" |
							tclvalue(slope.auxvar) == "1" |
							tclvalue(dem.auxvar) == "1")) 'normal' else 'disabled'
			tkconfigure(cb.grddem, state = statedem)
			tkconfigure(bt.grddem, state = statedem)
		})

		####################################

		tkgrid(frameLMCoef, row = 0, column = 0, sticky = '', padx = 1, pady = 1, ipadx = 1, ipady = 1)
		tkgrid(frauxvar, row = 1, column = 0, sticky = 'we', padx = 1, pady = 1, ipadx = 1, ipady = 1)

		####################################

		tkgrid(frTab2, padx = 0, pady = 1, ipadx = 1, ipady = 1)

	############################################

	bt.prm.OK <- ttkbutton(frMRG1, text = .cdtEnv$tcl$lang$global[['button']][['1']])
	bt.prm.CA <- ttkbutton(frMRG1, text = .cdtEnv$tcl$lang$global[['button']][['2']])

	#######

	tkconfigure(bt.prm.OK, command = function(){
		if(str_trim(tclvalue(file.stnfl)) == ""){
			tkmessageBox(message = "Select the file containing the station data", icon = "warning", type = "ok")
			tkwait.window(tt)
		}else if(str_trim(tclvalue(dir.RFE)) %in% c("", "NA")){
			tkmessageBox(message = "Browse or enter the directory containing the downscaled or adjusted files", icon = "warning", type = "ok")
			tkwait.window(tt)
		}else if(str_trim(tclvalue(file.grddem)) == "" &
				(.cdtData$GalParams$LMCOEF$interp.method == "NN" |
				tclvalue(aspect.auxvar) == "1" | tclvalue(slope.auxvar) == "1" |
				tclvalue(dem.auxvar) == "1"))
		{
			tkmessageBox(message = "You have to provide DEM data in NetCDF format", icon = "warning", type = "ok")
			tkwait.window(tt)
		}else if(str_trim(tclvalue(dir2save)) %in% c("", "NA")){
			tkmessageBox(message = "Browse or enter the path to directory to save results", icon = "warning", type = "ok")
			tkwait.window(tt)
		}else{
			.cdtData$GalParams$period <- periodVAL[CbperiodVAL %in% str_trim(tclvalue(file.period))]

			.cdtData$GalParams$STN.file <- str_trim(tclvalue(file.stnfl))
			.cdtData$GalParams$TEMP$dir <- str_trim(tclvalue(dir.RFE))

			.cdtData$GalParams$DEM.file <- str_trim(tclvalue(file.grddem))
			.cdtData$GalParams$output$dir <- str_trim(tclvalue(dir2save))

			.cdtData$GalParams$auxvar$dem <- switch(tclvalue(dem.auxvar), '0' = FALSE, '1' = TRUE)
			.cdtData$GalParams$auxvar$slope <- switch(tclvalue(slope.auxvar), '0' = FALSE, '1' = TRUE)
			.cdtData$GalParams$auxvar$aspect <- switch(tclvalue(aspect.auxvar), '0' = FALSE, '1' = TRUE)
			.cdtData$GalParams$auxvar$lon <- switch(tclvalue(lon.auxvar), '0' = FALSE, '1' = TRUE)
			.cdtData$GalParams$auxvar$lat <- switch(tclvalue(lat.auxvar), '0' = FALSE, '1' = TRUE)

			tkgrab.release(tt)
			tkdestroy(tt)
			tkfocus(.cdtEnv$tcl$main$win)
		}
	})

	tkconfigure(bt.prm.CA, command = function(){
		tkgrab.release(tt)
		tkdestroy(tt)
			tkfocus(.cdtEnv$tcl$main$win)
	})

	tkgrid(bt.prm.CA, row = 0, column = 0, sticky = 'w', padx = 5, pady = 1, ipadx = 1, ipady = 1)
	tkgrid(bt.prm.OK, row = 0, column = 1, sticky = 'e', padx = 5, pady = 1, ipadx = 1, ipady = 1)

	############################################
	
	tkgrid(frMRG0, row = 0, column = 0, sticky = 'nswe', rowspan = 1, columnspan = 2, padx = 1, pady = 1, ipadx = 1, ipady = 1)
	tkgrid(frMRG1, row = 1, column = 1, sticky = 'se', rowspan = 1, columnspan = 1, padx = 1, pady = 1, ipadx = 1, ipady = 1)

	tcl('update')
	tkgrid(bwnote, sticky = 'nwes')
	tkgrid.columnconfigure(bwnote, 0, weight = 1)

	############################################

	tkwm.withdraw(tt)
	tcl('update')
	tt.w <- as.integer(tkwinfo("reqwidth", tt))
	tt.h <- as.integer(tkwinfo("reqheight", tt))
	tt.x <- as.integer(.cdtEnv$tcl$data$width.scr*0.5 - tt.w*0.5)
	tt.y <- as.integer(.cdtEnv$tcl$data$height.scr*0.5 - tt.h*0.5)
	tkwm.geometry(tt, paste0('+', tt.x, '+', tt.y))
	tkwm.transient(tt)
	tkwm.title(tt, 'Spatio-Temporal Coefficients - Settings')
	tkwm.deiconify(tt)

	tkfocus(tt)
	tkbind(tt, "<Destroy>", function(){
		tkgrab.release(tt)
		tkfocus(.cdtEnv$tcl$main$win)
	})
	tkwait.window(tt)
	invisible()
}
