
cdtConfiguration <- function(parent.win){
	if(WindowsOS()){
		wscrlwin <- .cdtEnv$tcl$fun$w.scale(28)
		hscrlwin <- .cdtEnv$tcl$fun$h.scale(28)
		largeur0 <- 19
		largeur1 <- 50

	}else{
		wscrlwin <- .cdtEnv$tcl$fun$w.scale(30)
		hscrlwin <- .cdtEnv$tcl$fun$h.scale(30)
		largeur0 <- 16
		largeur1 <- 35

	}

	xml.dlg <- file.path(.cdtDir$dirLocal, "languages", "cdtConfiguration_dlgBox.xml")
	lang.dlg <- cdtLanguageParse(xml.dlg, .cdtData$Config$lang.iso)

	cdt.file.conf <- file.path(.cdtDir$dirLocal, "config", "cdt_config.json")
	cdtConfig <- fromJSON(cdt.file.conf)

	tcl.file.conf <- file.path(.cdtDir$dirLocal, "config", "Tcl_config.json")
	tclConfig <- fromJSON(tcl.file.conf)

	####################################

	tt <- tktoplevel()
	tkgrab.set(tt)
	tkfocus(tt)

	frMRG0 <- tkframe(tt, relief = 'raised', borderwidth = 2)
	frMRG1 <- tkframe(tt)

	####################################

	bwnote <- bwNoteBook(frMRG0)
	conf.tab1 <- bwAddTab(bwnote, text = lang.dlg[['tab_title']][['1']])
	conf.tab2 <- bwAddTab(bwnote, text = lang.dlg[['tab_title']][['2']])

	bwRaiseTab(bwnote, conf.tab1)
	tkgrid.columnconfigure(conf.tab1, 0, weight = 1)
	tkgrid.columnconfigure(conf.tab2, 0, weight = 1)

	####################################

	frTab1 <- tkframe(conf.tab1)

		####################################

		lang.iso <- cdtConfig$lang.iso
		lang.iso.list <- cdtConfig$lang.iso.list
		lang.name.list <- cdtConfig$lang.name.list
		lang.select <- tclVar(lang.name.list[lang.iso.list %in% lang.iso])
		miss.value <- tclVar(cdtConfig$missval)
		miss.value.anom <- tclVar(cdtConfig$missval.anom)
		work.dir <- tclVar(.cdtData$Config$wd)

		txt.lang <- tklabel(frTab1, text = lang.dlg[['label']][['1']], anchor = 'e', justify = 'right')
		cb.lang <- ttkcombobox(frTab1, values = lang.name.list, textvariable = lang.select, width = largeur0, justify = 'right')
		txt.miss <- tklabel(frTab1, text = lang.dlg[['label']][['2']], anchor = 'e', justify = 'right')
		en.miss <- tkentry(frTab1, textvariable = miss.value, width = 8)
		txt.amiss <- tklabel(frTab1, text = lang.dlg[['label']][['3']], anchor = 'e', justify = 'right')
		en.amiss <- tkentry(frTab1, textvariable = miss.value.anom, width = 8)
		txt.wd <- tklabel(frTab1, text = lang.dlg[['label']][['4']], anchor = 'w', justify = 'left')
		en.wd <- tkentry(frTab1, textvariable = work.dir, width = largeur1)
		bt.wd <- tkbutton(frTab1, text = "...")

		tkconfigure(bt.wd, command = function(){
			dir.in <- tk_choose.dir(.cdtData$Config$wd, "")
			tclvalue(work.dir) <- if(dir.in %in% c("", "NA") | is.na(dir.in)) "" else dir.in
		})

		tkgrid(txt.lang, row = 0, column = 0, sticky = 'we', rowspan = 1, columnspan = 3, padx = 1, pady = 1, ipadx = 1, ipady = 1)
		tkgrid(cb.lang, row = 0, column = 3, sticky = 'w', rowspan = 1, columnspan = 2, padx = 1, pady = 1, ipadx = 1, ipady = 1)
		tkgrid(txt.miss, row = 1, column = 0, sticky = 'we', rowspan = 1, columnspan = 3, padx = 1, pady = 1, ipadx = 1, ipady = 1)
		tkgrid(en.miss, row = 1, column = 3, sticky = 'w', rowspan = 1, columnspan = 1, padx = 1, pady = 1, ipadx = 1, ipady = 1)
		tkgrid(txt.amiss, row = 2, column = 0, sticky = 'we', rowspan = 1, columnspan = 3, padx = 1, pady = 1, ipadx = 1, ipady = 1)
		tkgrid(en.amiss, row = 2, column = 3, sticky = 'w', rowspan = 1, columnspan = 1, padx = 1, pady = 1, ipadx = 1, ipady = 1)
		tkgrid(txt.wd, row = 3, column = 0, sticky = 'we', rowspan = 1, columnspan = 5, padx = 1, pady = 1, ipadx = 1, ipady = 1)
		tkgrid(en.wd, row = 4, column = 0, sticky = 'we', rowspan = 1, columnspan = 4, padx = 0, pady = 1, ipadx = 1, ipady = 1)
		tkgrid(bt.wd, row = 4, column = 4, sticky = 'w', rowspan = 1, columnspan = 1, padx = 0, pady = 1, ipadx = 1, ipady = 1)

		helpWidget(en.miss, lang.dlg[['tooltip']][['1']], lang.dlg[['status']][['1']])
		helpWidget(en.amiss, lang.dlg[['tooltip']][['2']], lang.dlg[['status']][['2']])

		####################################

		tkgrid(frTab1, padx = 0, pady = 1, ipadx = 1, ipady = 1)

	####################################

	frTab2 <- tkframe(conf.tab2)

		####################################

		if(WindowsOS()) ostype <- "Windows"
		if(MacOSXP()) ostype <- "MacOS"
		if(LinuxOS()) ostype <- "Linux"
		tclConf <- tclConfig[[ostype]]

		Tktable.auto <- tclVar(tclConf$Tktable.auto)
		Tktable.path <- tclVar(tclConf$Tktable.path)

		Bwidget.auto <- tclVar(tclConf$Bwidget.auto)
		Bwidget.path <- tclVar(tclConf$Bwidget.path)

		stateTkTb <- if(tclConf$Tktable.auto) "disabled" else "normal"
		stateBw <- if(tclConf$Bwidget.auto) "disabled" else "normal"

		if(WindowsOS()){
			useOTcl <- tclVar(tclConf$UseOtherTclTk)
			Tclbin <- tclVar(tclConf$Tclbin)
			statebin <- if(tclConf$UseOtherTclTk) "normal" else "disabled"

			fr.win <- tkframe(frTab2, relief = 'groove', borderwidth = 2)
			chk.win <- tkcheckbutton(fr.win, variable = useOTcl, text = lang.dlg[['checkbutton']][['1']], anchor = 'w', justify = 'left')
			txt.bin <- tklabel(fr.win, text = lang.dlg[['label']][['5']], anchor = 'w', justify = 'left')
			en.bin <- tkentry(fr.win, textvariable = Tclbin, width = largeur1, state = statebin)
			bt.bin <- tkbutton(fr.win, text = "...", state = statebin)

			tkconfigure(bt.bin, command = function(){
				dir.in <- tk_choose.dir(getwd(), "")
				tclvalue(Tclbin) <- if(dir.in %in% c("", "NA") | is.na(dir.in)) "" else dir.in
			})

			tkgrid(chk.win, row = 0, column = 0, sticky = 'we', rowspan = 1, columnspan = 5, padx = 1, pady = 1, ipadx = 1)
			tkgrid(txt.bin, row = 1, column = 0, sticky = 'we', rowspan = 1, columnspan = 5, padx = 1, pady = 1, ipadx = 1)
			tkgrid(en.bin, row = 2, column = 0, sticky = 'we', rowspan = 1, columnspan = 4, padx = 0, pady = 1, ipadx = 1)
			tkgrid(bt.bin, row = 2, column = 4, sticky = 'w', rowspan = 1, columnspan = 1, padx = 0, pady = 1, ipadx = 1)

			helpWidget(chk.win, lang.dlg[['tooltip']][['3']], lang.dlg[['status']][['3']])
			helpWidget(en.bin, lang.dlg[['tooltip']][['4']], lang.dlg[['status']][['4']])
		}

		fr.TkTb <- tkframe(frTab2, relief = 'groove', borderwidth = 2)
		chk.TkTb <- tkcheckbutton(fr.TkTb, variable = Tktable.auto, text = lang.dlg[['checkbutton']][['2']], anchor = 'w', justify = 'left')
		txt.TkTb <- tklabel(fr.TkTb, text = lang.dlg[['label']][['6']], anchor = 'w', justify = 'left')
		en.TkTb <- tkentry(fr.TkTb, textvariable = Tktable.path, width = largeur1, state = stateTkTb)
		bt.TkTb <- tkbutton(fr.TkTb, text = "...", state = stateTkTb)

		fr.Bw <- tkframe(frTab2, relief = 'groove', borderwidth = 2)
		chk.Bw <- tkcheckbutton(fr.Bw, variable = Bwidget.auto, text = lang.dlg[['checkbutton']][['3']], anchor = 'w', justify = 'left')
		txt.Bw <- tklabel(fr.Bw, text = lang.dlg[['label']][['7']], anchor = 'w', justify = 'left')
		en.Bw <- tkentry(fr.Bw, textvariable = Bwidget.path, width = largeur1, state = stateBw)
		bt.Bw <- tkbutton(fr.Bw, text = "...", state = stateBw)

		tkconfigure(bt.TkTb, command = function(){
			dir.in <- tk_choose.dir(getwd(), "")
			tclvalue(Tktable.path) <- if(dir.in %in% c("", "NA") | is.na(dir.in)) "" else dir.in
		})

		tkconfigure(bt.Bw, command = function(){
			dir.in <- tk_choose.dir(getwd(), "")
			tclvalue(Bwidget.path) <- if(dir.in %in% c("", "NA") | is.na(dir.in)) "" else dir.in
		})

		tkgrid(chk.TkTb, row = 0, column = 0, sticky = 'we', rowspan = 1, columnspan = 5, padx = 1, pady = 1, ipadx = 1)
		tkgrid(txt.TkTb, row = 1, column = 0, sticky = 'we', rowspan = 1, columnspan = 5, padx = 1, pady = 1, ipadx = 1)
		tkgrid(en.TkTb, row = 2, column = 0, sticky = 'we', rowspan = 1, columnspan = 4, padx = 0, pady = 1, ipadx = 1)
		tkgrid(bt.TkTb, row = 2, column = 4, sticky = 'w', rowspan = 1, columnspan = 1, padx = 0, pady = 1, ipadx = 1)

		tkgrid(chk.Bw, row = 0, column = 0, sticky = 'we', rowspan = 1, columnspan = 5, padx = 1, pady = 1, ipadx = 1)
		tkgrid(txt.Bw, row = 1, column = 0, sticky = 'we', rowspan = 1, columnspan = 5, padx = 1, pady = 1, ipadx = 1)
		tkgrid(en.Bw, row = 2, column = 0, sticky = 'we', rowspan = 1, columnspan = 4, padx = 0, pady = 1, ipadx = 1)
		tkgrid(bt.Bw, row = 2, column = 4, sticky = 'w', rowspan = 1, columnspan = 1, padx = 0, pady = 1, ipadx = 1)

		helpWidget(chk.TkTb, lang.dlg[['tooltip']][['5']], lang.dlg[['status']][['5']])
		helpWidget(en.TkTb, lang.dlg[['tooltip']][['6']], lang.dlg[['status']][['6']])
		helpWidget(chk.Bw, lang.dlg[['tooltip']][['7']], lang.dlg[['status']][['7']])
		helpWidget(en.Bw, lang.dlg[['tooltip']][['8']], lang.dlg[['status']][['8']])

		#############

		if(WindowsOS()){
			tkbind(chk.win, "<Button-1>", function(){
				statebin <- if(tclvalue(useOTcl) == '1') 'disabled' else 'normal'
				tkconfigure(en.bin, state = statebin)
				tkconfigure(bt.bin, state = statebin)
			})
		}

		tkbind(chk.TkTb, "<Button-1>", function(){
			stateTkTb <- if(tclvalue(Tktable.auto) == '1') 'normal' else 'disabled'
			tkconfigure(en.TkTb, state = stateTkTb)
			tkconfigure(bt.TkTb, state = stateTkTb)
		})

		tkbind(chk.Bw, "<Button-1>", function(){
			stateBw <- if(tclvalue(Bwidget.auto) == '1') 'normal' else 'disabled'
			tkconfigure(en.Bw, state = stateBw)
			tkconfigure(bt.Bw, state = stateBw)
		})

		#############

		if(WindowsOS()) tkgrid(fr.win, row = 0, sticky = 'we', padx = 1, pady = 1)
		tkgrid(fr.TkTb, row = 1, sticky = 'we', padx = 1, pady = 1)
		tkgrid(fr.Bw, row = 2, sticky = 'we', padx = 1, pady = 1)

		####################################

		tkgrid(frTab2, padx = 0, pady = 1, ipadx = 1, ipady = 1)

	####################################

	bt.prm.OK <- ttkbutton(frMRG1, text = lang.dlg[['button']][['1']])
	bt.prm.CA <- ttkbutton(frMRG1, text = lang.dlg[['button']][['2']])

	tkconfigure(bt.prm.OK, command = function(){
		if(WindowsOS()){
			if(tclvalue(useOTcl) == "1" &
				str_trim(tclvalue(Tclbin)) %in% c("", "NA"))
			{
				tkmessageBox(message = lang.dlg[['message']][['2']], icon = "warning", type = "ok")
				tkwait.window(tt)
			}
			if(tclvalue(useOTcl) == "1" &
				!dir.exists(str_trim(tclvalue(Tclbin))))
			{
				tkmessageBox(message = paste(tclvalue(Tclbin), lang.dlg[['message']][['3']]), icon = "warning", type = "ok")
				tkwait.window(tt)
			}
		}
		if(tclvalue(Tktable.auto) == "0" &
			str_trim(tclvalue(Tktable.path)) %in% c("", "NA"))
		{
			tkmessageBox(message = lang.dlg[['message']][['4']], icon = "warning", type = "ok")
			tkwait.window(tt)
		}else if(tclvalue(Tktable.auto) == "0" &
			!dir.exists(str_trim(tclvalue(Tktable.path))))
		{
			tkmessageBox(message = paste(tclvalue(Tktable.path), lang.dlg[['message']][['3']]), icon = "warning", type = "ok")
			tkwait.window(tt)
		}else if(tclvalue(Bwidget.auto) == "0" &
			str_trim(tclvalue(Bwidget.path)) %in% c("", "NA"))
		{
			tkmessageBox(message = lang.dlg[['message']][['5']], icon = "warning", type = "ok")
			tkwait.window(tt)
		}else if(tclvalue(Bwidget.auto) == "0" &
			!dir.exists(str_trim(tclvalue(Bwidget.path))))
		{
			tkmessageBox(message = paste(tclvalue(Bwidget.path), lang.dlg[['message']][['3']]), icon = "warning", type = "ok")
			tkwait.window(tt)
		}else{
			if(WindowsOS()){
				tclConfig[[ostype]]$UseOtherTclTk <- switch(tclvalue(useOTcl), '0' = FALSE, '1' = TRUE)
				tclConfig[[ostype]]$Tclbin <- str_trim(tclvalue(Tclbin))
			}
			tclConfig[[ostype]]$Tktable.auto <- switch(tclvalue(Tktable.auto), '0' = FALSE, '1' = TRUE)
			tclConfig[[ostype]]$Tktable.path <- str_trim(tclvalue(Tktable.path))
			tclConfig[[ostype]]$Bwidget.auto <- switch(tclvalue(Bwidget.auto), '0' = FALSE, '1' = TRUE)
			tclConfig[[ostype]]$Bwidget.path <- str_trim(tclvalue(Bwidget.path))

			write_json(tclConfig, path = tcl.file.conf, auto_unbox = TRUE, pretty = TRUE)

			cdtConfig$lang.iso <- lang.iso.list[lang.name.list %in% str_trim(tclvalue(lang.select))]
			cdtConfig$missval <- str_trim(tclvalue(miss.value))
			cdtConfig$missval.anom <- str_trim(tclvalue(miss.value.anom))
			cdtConfig$wd <- str_trim(tclvalue(work.dir))

			write_json(cdtConfig, path = cdt.file.conf, auto_unbox = TRUE, pretty = TRUE)

			.cdtData$Config$wd <- cdtConfig$wd
			.cdtData$Config$missval <- cdtConfig$missval
			.cdtData$Config$missval.anom <- cdtConfig$missval.anom
			.cdtData$Config$lang.iso <- cdtConfig$lang.iso

			setwd(cdtConfig$wd)
			Insert.Messages.Out(lang.dlg[['message']][['1']])

			tkgrab.release(tt)
			tkdestroy(tt)
			tkfocus(parent.win)
		}
	})

	tkconfigure(bt.prm.CA, command = function(){
		tkgrab.release(tt)
		tkdestroy(tt)
		tkfocus(parent.win)
	})

	tkgrid(bt.prm.CA, row = 0, column = 0, sticky = 'w', padx = 5, pady = 1, ipadx = 1, ipady = 1)
	tkgrid(bt.prm.OK, row = 0, column = 1, sticky = 'e', padx = 5, pady = 1, ipadx = 1, ipady = 1)

	####################################

	tkgrid(frMRG0, row = 0, column = 0, sticky = 'nswe', rowspan = 1, columnspan = 2, padx = 1, pady = 1, ipadx = 1, ipady = 1)
	tkgrid(frMRG1, row = 1, column = 1, sticky = 'se', rowspan = 1, columnspan = 1, padx = 1, pady = 1, ipadx = 1, ipady = 1)

	tcl('update')
	tkgrid(bwnote, sticky = 'nwes')
	tkgrid.columnconfigure(bwnote, 0, weight = 1)

	####################################

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
		tkfocus(parent.win)
	})
	tkwait.window(tt)
	invisible()
}