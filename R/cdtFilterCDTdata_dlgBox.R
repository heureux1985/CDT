
filterCDTData_getParams <- function(){
	listOpenFiles <- openFile_ttkcomboList()
	if(WindowsOS()){
		largeur1 <- 55
		largeur2 <- 52
	}else{
		largeur1 <- 41
		largeur2 <- 40
	}

	############################################

	tt <- tktoplevel()
	tkgrab.set(tt)
	tkfocus(tt)

	frMRG0 <- tkframe(tt, relief = 'raised', borderwidth = 2)
	frMRG1 <- tkframe(tt)

	############################################

	xml.dlg <- file.path(.cdtDir$dirLocal, "languages", "cdtFilterCDTdata_dlgBox.xml")
	lang.dlg <- cdtLanguageParse(xml.dlg, .cdtData$Config$lang.iso)

	#############

	frInput <- tkframe(frMRG0, relief = "groove", borderwidth = 2)

	file.stnfl1 <- tclVar(.cdtData$GalParams$filein)
	filter.crt <- tclVar(.cdtData$GalParams$opfilter)
	filter.val <- tclVar(.cdtData$GalParams$valfilter)
	file.save1 <- tclVar(.cdtData$GalParams$file2save)

	txtStnfl1 <- tklabel(frInput, text = lang.dlg[['label']][['1']], anchor = 'w', justify = 'left')
	cbStnfl1 <- ttkcombobox(frInput, values = unlist(listOpenFiles), textvariable = file.stnfl1, width = largeur2)
	btStnfl1 <- tkbutton(frInput, text = "...")

	sep.filter1 <- ttkseparator(frInput)

	txtFilter1 <- tklabel(frInput, text = lang.dlg[['label']][['2']], anchor = 'e', justify = 'right')
	txtFilter2 <- tklabel(frInput, text = lang.dlg[['label']][['3']], anchor = 'e', justify = 'right')
	cbFilter <- ttkcombobox(frInput, values = c(">=", ">", "<=", "<"), textvariable = filter.crt, width = 4)
	enFilter <- tkentry(frInput, textvariable = filter.val, width = 4)
	txtFilter3 <- tklabel(frInput, text = '%', anchor = 'w', justify = 'left')

	sep.filter2 <- ttkseparator(frInput)

	txtFileSave <- tklabel(frInput, text = lang.dlg[['label']][['4']], anchor = 'w', justify = 'left')
	enFileSave <- tkentry(frInput, textvariable = file.save1, width = largeur1)
	btFileSave <- tkbutton(frInput, text = "...")

	#############

	tkconfigure(btStnfl1, command = function(){
		dat.opfiles <- getOpenFiles(tt)
		if(!is.null(dat.opfiles)){
			update.OpenFiles('ascii', dat.opfiles)
			listOpenFiles[[length(listOpenFiles) + 1]] <<- dat.opfiles[[1]]
			tclvalue(file.stnfl1) <- dat.opfiles[[1]]
			tkconfigure(cbStnfl1, values = unlist(listOpenFiles), textvariable = file.stnfl1)
		}
	})

	tkconfigure(btFileSave, command = function(){
		file2save1 <- tk_get_SaveFile(filetypes = .cdtEnv$tcl$data$filetypes1)
		tclvalue(file.save1) <- if(is.na(file2save1)) "" else file2save1
	})

	#############

	tkgrid(txtStnfl1, row = 0, column = 0, sticky = 'we', rowspan = 1, columnspan = 10, padx = 1, pady = 0, ipadx = 1, ipady = 1)
	tkgrid(cbStnfl1, row = 1, column = 0, sticky = 'we', rowspan = 1, columnspan = 9, padx = 0, pady = 0, ipadx = 1, ipady = 1)
	tkgrid(btStnfl1, row = 1, column = 9, sticky = 'w', rowspan = 1, columnspan = 1, padx = 0, pady = 0, ipadx = 1, ipady = 1)

	tkgrid(sep.filter1, row = 2, column = 0, sticky = 'we', rowspan = 1, columnspan = 10, padx = 1, pady = 1, ipadx = 1, ipady = 1)

	tkgrid(txtFilter1, row = 3, column = 0, sticky = 'we', rowspan = 1, columnspan = 4, padx = 1, pady = 0, ipadx = 1, ipady = 1)
	tkgrid(txtFilter2, row = 3, column = 4, sticky = 'we', rowspan = 1, columnspan = 3, padx = 0, pady = 0, ipadx = 1, ipady = 1)
	tkgrid(cbFilter, row = 3, column = 7, sticky = 'e', rowspan = 1, columnspan = 1, padx = 0, pady = 0, ipadx = 1, ipady = 1)
	tkgrid(enFilter, row = 3, column = 8, sticky = 'e', rowspan = 1, columnspan = 1, padx = 0, pady = 0, ipadx = 1, ipady = 1)
	tkgrid(txtFilter3, row = 3, column = 9, sticky = 'w', rowspan = 1, columnspan = 1, padx = 0, pady = 0, ipadx = 1, ipady = 1)

	tkgrid(sep.filter2, row = 4, column = 0, sticky = 'we', rowspan = 1, columnspan = 10, padx = 1, pady = 1, ipadx = 1, ipady = 1)

	tkgrid(txtFileSave, row = 5, column = 0, sticky = 'we', rowspan = 1, columnspan = 10, padx = 1, pady = 0, ipadx = 1, ipady = 1)
	tkgrid(enFileSave, row = 6, column = 0, sticky = 'we', rowspan = 1, columnspan = 9, padx = 0, pady = 0, ipadx = 1, ipady = 1)
	tkgrid(btFileSave, row = 6, column = 9, sticky = 'w', rowspan = 1, columnspan = 1, padx = 0, pady = 0, ipadx = 1, ipady = 1)

	############################################

	tkgrid(frInput, row = 0, column = 0, sticky = 'news', padx = 5, pady = 1, ipadx = 1, ipady = 1)

	############################################

	bt.prm.OK <- ttkbutton(frMRG1, text = .cdtEnv$tcl$lang$global[['button']][['1']])
	bt.prm.CA <- ttkbutton(frMRG1, text = .cdtEnv$tcl$lang$global[['button']][['2']])

	tkconfigure(bt.prm.OK, command = function(){
		if(str_trim(tclvalue(file.stnfl1)) %in% c("", "NA")){
			tkmessageBox(message = lang.dlg[['message']][['6']], icon = "warning", type = "ok")
			tkwait.window(tt)
		}else if(str_trim(tclvalue(file.save1)) %in% c("", "NA")){
			tkmessageBox(message = lang.dlg[['message']][['7']], icon = "warning", type = "ok")
			tkwait.window(tt)
		}else{
			.cdtData$GalParams$filein <- str_trim(tclvalue(file.stnfl1))
			.cdtData$GalParams$opfilter <- str_trim(tclvalue(filter.crt))
			.cdtData$GalParams$valfilter <- as.numeric(str_trim(tclvalue(filter.val)))
			.cdtData$GalParams$file2save <- str_trim(tclvalue(file.save1))
			.cdtData$GalParams$message <- lang.dlg[['message']]

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

	tkgrid(bt.prm.OK, row = 0, column = 0, sticky = 'w', padx = 5, pady = 1, ipadx = 1, ipady = 1)
	tkgrid(bt.prm.CA, row = 0, column = 1, sticky = 'e', padx = 5, pady = 1, ipadx = 1, ipady = 1)

	############################################

	tkgrid(frMRG0, row = 0, column = 0, sticky = 'nswe', rowspan = 1, columnspan = 2, padx = 1, pady = 1, ipadx = 1, ipady = 1)
	tkgrid(frMRG1, row = 1, column = 1, sticky = 'se', rowspan = 1, columnspan = 1, padx = 1, pady = 1, ipadx = 1, ipady = 1)

	############################
	tkwm.withdraw(tt)
	tcl('update')
	tt.w <- as.integer(tkwinfo("reqwidth", tt))
	tt.h <- as.integer(tkwinfo("reqheight", tt))
	tt.x <- as.integer(.cdtEnv$tcl$data$width.scr*0.5 - tt.w*0.5)
	tt.y <- as.integer(.cdtEnv$tcl$data$height.scr*0.5 - tt.h*0.5)
	tkwm.geometry(tt, paste0('+', tt.x, '+', tt.y))
	tkwm.transient(tt)
	tkwm.title(tt, lang.dlg[['title']])
	tkwm.deiconify(tt)

	tkfocus(tt)
	tkbind(tt, "<Destroy>", function(){
		tkgrab.release(tt)
		tkfocus(.cdtEnv$tcl$main$win)
	})
	tkwait.window(tt)
}
