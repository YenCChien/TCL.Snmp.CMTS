package require Tk
package require tile
if {[catch {package require tablelist_tile 5.16}]} {package require tablelist}
package require BWidget
catch {package require twapi}
package require img::png
if [catch {package require TclOO}] {set ::OO 0} else {set ::OO 1}

tablelist::addBWidgetEntry
tablelist::addBWidgetSpinBox
tablelist::addBWidgetComboBox

# Kill Client Socket Process
# set pids [list]
# set self_pid [pid]
# catch [set pids [twapi::get_process_ids -name "wish84.exe"]]
# if { [llength $pids] > 0 } {
 # foreach ppid $pids {
  # if { $ppid != $self_pid } {
   # catch [twapi::end_process $ppid -force]
  # }
 # }
# }

# source 
source GUI.tcl

proc set_state {state} {; # disable or normal 
	global mdef
	for {set i 0} {$i < 4} {incr i} {
		.fr$i.freqlow	configure -state $state
		.fr$i.frequp	configure -state $state
		.fr$i.bt		configure -state $state
		set currentStete ""
		if {$state == "normal"} {set currentState "readonly"} else {set currentState $state}
		.fr$i.state		configure -state $currentState
		.fr$i.spacing	configure -state $currentState
		.fr$i.cp		configure -state $currentState
		.fr$i.rp		configure -state $currentState
		.fr$i.mod		configure -state $currentState
		.fr$i.k		configure -state $currentState

	}
	.mr entryconfigure 2 -state $state
}

proc power_gui {} {
	catch {destroy .y}
	toplevel .y -bd 3 -relief raised -takefocus 1
	wm title .y "Power_Edit"
	# wm withdraw .y
	wm resizable .y 0 0
	# wm overrideredirect .y 1
	set x [winfo x .]
    set y [winfo y .]
	wm geometry .y +$x+$y
	wm deiconify .y
	update idletasks
	grab .y
	ttk::labelframe .y.ofdm -text "OFDM (25~60dBmV)" -relief ridge
	ttk::labelframe .y.ofdma -text "OFDMA (-10~10dBmV)" -relief ridge
	grid .y.ofdm -column 0 -row 0 -sticky news
	grid .y.ofdma -column 0 -row 1 -sticky news
	for {set i 0} {$i < 2} {incr i} {
		ttk::entry .y.ofdm.e$i -textvariable ofdmp($i) -justify center
		ttk::button .y.ofdm.b$i -text Set -command "power_edit ofdm $i"
		grid .y.ofdm.e$i -column 0 -row $i -sticky news
		grid .y.ofdm.b$i -column 1 -row $i -sticky news
	}
	for {set i 0} {$i < 2} {incr i} {
		ttk::entry .y.ofdma.e$i -textvariable ofdmap($i) -justify center
		ttk::button .y.ofdma.b$i -text Set -command "power_edit ofdma $i"
		grid .y.ofdma.e$i -column 0 -row $i -sticky news
		grid .y.ofdma.b$i -column 1 -row $i -sticky news
	}
}

proc usxds {} {
	global takeds takeus dsenvar usenvar Log_Text1 Log_Text2 Log_Text3 Log_Text4
	catch {destroy .y}
	toplevel .y -bd 3 -relief raised -takefocus 1
	wm title .y "DSxUS"
	# wm withdraw .y
	wm resizable .y 0 0
	# wm overrideredirect .y 1
	set x [winfo x .]
    set y [winfo y .]
	wm geometry .y +$x+$y
	wm deiconify .y
	update idletasks
	grab .y
	set dsenvar 333000000; set usenvar 10000000
	for {set s 1} {$s <= $takeds} {incr s} {lappend dsnum $s}
	for {set s 1} {$s <= $takeus} {incr s} {lappend usnum $s}
	ttk::labelframe .y.sc -text "DS Count x US Count" -relief ridge
	grid .y.sc -column 0 -columnspan 2 -row 0 -sticky news
	ttk::entry .y.sc.dsen -textvar dsenvar -justify center
	::ttk::combobox .y.sc.dsbox -values $dsnum -textvariable dsbox -width 6 -justify center -state readonly
	::ttk::label .y.sc. -text "x"
	ttk::entry .y.sc.usen -textvar usenvar -justify center
	::ttk::combobox .y.sc.usbox -values $usnum -textvariable usbox -width 6 -justify center -state readonly
	grid .y.sc.dsen .y.sc.dsbox .y.sc. .y.sc.usen .y.sc.usbox -padx 10 -pady 5 -sticky ew
	ttk::button .y.bt1 -text "OK" -command {
		destroy .y 
		.p.pg start
		% set_ds_freq $dsbox $dsenvar
		puts "% set_ds_freq $dsbox $dsenvar"
		.p.pg configure -value 300
		% set_us_freq $usbox $usenvar
		puts "% set_us_freq $usbox $usenvar"
		.p.pg configure -value 600
		$Log_Text1 delete 0 end
		$Log_Text2 delete 0 end
		$Log_Text3 delete 0 end
		$Log_Text4 delete 0 end
		% get_mib
		.p.pg stop
		set dsbox ""
		set usbox ""
	}
	ttk::button .y.bt2 -text "Cancel" -command {
		destroy .y 
		set dsbox ""
		set usbox ""
	}
	grid .y.bt1 .y.bt2 -padx 10 -pady 5 -sticky ew
}

proc power_edit {type i} {
	global ofdmp ofdmap Log_Text
	log_delete $Log_Text all
	switch $type {
		ofdm {
			if {$i == 0} {set chid 97}
			if {$i == 1} {set chid 98}
			% power $type $chid $ofdmp($i)
		}
		ofdma {
			if {$i == 0} {set chid 17}
			if {$i == 1} {set chid 18}
			% power $type $chid $ofdmap($i)
		}
	}
	% show $type $chid
}

proc perform {type i} {
	global state spacing freqL freqU cp rp mod k Log_Text 
	log_delete $Log_Text all
	switch $i {
		0 {set chid 97}
		1 {set chid 98}
		2 {set chid 17}
		3 {set chid 18}
	}
	if {$state($i) == "On"} {set st 1}
	if {$state($i) == "Off"} {set st 0}
	set sp [string trim $spacing($i) k]
	if {$type == "ofdm"} {
		set subz [expr $freqL($i)-7.4]
		set plc [expr ($freqU($i)-$freqL($i))/2+$freqL($i)]
		% $type $chid $st $sp $subz $freqL($i) $freqU($i) $plc $cp($i) $rp($i) $mod($i) $k($i)
	} elseif {$type == "ofdma"} {
		set subz [expr $freqL($i)-3.7]
		% $type $chid $st $sp $subz $freqL($i) $freqU($i) $cp($i) $rp($i) $mod($i) $k($i)
	}
	% show $type $chid
}

proc log_write { log_text msg {color black} {type 0}} {
	switch $type {
		"0" {
			$log_text insert end "$msg\n"
		}
		"1" {
			$log_text insert end "$msg"
		}	}
	$log_text see end
	
	if { $type == "0" || $type == "2" } {
		set index [$log_text index end]
		$log_text tag add tag_$color $index-2l $index-1l
	} 
}

proc log_delete { log_text line } {
	if { $line == "all" } {
		$log_text delete 0.0 end
	} else {
		set index [$log_text index end]
		$log_text delete [expr $index-$line-1] end
	}
	$log_text insert end "\n"
	$log_text see end
}

proc Vcmd {S} {
	if {$S == "?"} {return 0} else {return 1}
}

proc ::Cnsl::Keyin {msg} {
	global currentip Channel_ID
	# % "promptwait \$sock($currentip) \{$msg\} # 5"
	% cmd $msg
	if {$msg != ""} {set ::Cnsl::Rcmd($::Cnsl::i) $msg}
	set ::Cnsl::Cmd ""
	if {$::Cnsl::i > 3} {set ::Cnsl::i 1} else {incr ::Cnsl::i}
}

proc ::Cnsl::help {msg} {
	global currentip Channel_ID
	# % "promptwait \$sock($currentip) \{$msg \?\} # 5"
	% cmd "$msg ?"
}

proc main {} {
	global Log_Text mcmts
	set_state disable
	$Log_Text insert end "Link to Server...\n"
	# source client.tcl
}

main

#===================================== tablelist proc
set placeX ""; set placeY ""
proc editEndCmd_ds {tbl row col text} {
	global dsindex placeX placeY return_msg
	set placeY $row; set placeX $col
	# puts $row
	set idx [expr $row+1]
	# puts $dsindex($idx)
	% modifyds $col $dsindex($idx) $text
	set text $return_msg
	set chstatus [$tbl rowcget $row -text]
	if {$::OO} {
		switch $col {
			1 {ds$idx modify [expr [lindex $chstatus 2]/1000000] [expr [lindex $chstatus 3]/10.0] $text $idx}
			2 {ds$idx modify [expr $text/1000000] [expr [lindex $chstatus 3]/10.0] [lindex $chstatus 1] $idx}
			3 {ds$idx modify [expr [lindex $chstatus 2]/1000000] [expr $text/10.0] [lindex $chstatus 1] $idx}
		}
	}
	return $text
}

proc editEndCmd_us {tbl row col text} {
	global usindex placeX placeY return_msg
	set placeY $row; set placeX $col
	set idx [expr $row+1]
	% modifyus $col $usindex($idx) $text
	set text $return_msg
	set chstatus [$tbl rowcget $row -text]
	if {$::OO} {
		switch $col {
			1 {us$idx modify [expr [lindex $chstatus 2]/1000000] [expr [lindex $chstatus 3]/1.5] $text $idx}
			2 {us$idx modify [expr $text/1000000] [expr [lindex $chstatus 3]/1.5] [lindex $chstatus 1] $idx}
			3 {us$idx modify [expr [lindex $chstatus 2]/1000000] [expr $text/1.5] [lindex $chstatus 1] $idx}
		}
	}
	return $text
}

proc editEndCmd_ofdm {tbl row col text} {
	global ofdmindex placeX placeY return_msg
	set placeY $row; set placeX $col
	set idx [expr $row+1]
	% modifyds $col $ofdmindex($idx) $text
	set text $return_msg
	set chstatus [$tbl rowcget $row -text]
	if {$::OO} {ofdm[$tbl cellcget $row,0 -text] modify [expr [lindex $chstatus 3]/1000000] [expr [lindex $chstatus 4]/1000000] 50 $text $idx}
	return $text
}

proc editEndCmd_ofdma {tbl row col text} {
	global ofdmaindex placeX placeY return_msg
	set placeY $row; set placeX $col
	set idx [expr $row+1]
	% modifyus $col $ofdmaindex($idx) $text
	set text $return_msg
	set chstatus [$tbl rowcget $row -text]
	if {$::OO} {ofdma[$tbl cellcget $row,0 -text] modify [expr [lindex $chstatus 3]/1000000] [expr [lindex $chstatus 4]/1000000] 50 $text $idx}
	return $text
}

proc Waitforcmd args {
	global Log_Text1 Log_Text2 Log_Text3 Log_Text4
	.p.pg start
	if {$args != ""} "% $args"
	$Log_Text1 delete 0 end
	$Log_Text2 delete 0 end
	$Log_Text3 delete 0 end
	$Log_Text4 delete 0 end
	.p.pg configure -value 300
	% get_mib
	.p.pg configure -value 600
	.p.pg stop
}

proc OfdmLabelCmd {path col} {puts "$path $col"}
proc OfdmaLabelCmd {path col} {puts "$path $col"}
proc DsLabelCmd {path col} {
	switch $col {
		1 {Waitforcmd enable downstream all}
		2 {usxds}
	}
}
proc UsLabelCmd {path col} {
	switch $col {
		1 {Waitforcmd enable upstream all}
		2 {usxds}
	}
}
proc DsLabelCmd2 {path col} {
	switch $col {
		1 {Waitforcmd disable downstream all}
		2 {Waitforcmd return0 DS}
		default {labelcmd downstream $path $col}
	}
}
proc UsLabelCmd2 {path col} {
	switch $col {
		1 {Waitforcmd disable upstream all}
		2 {Waitforcmd return0 US}
		default {labelcmd upstream $path $col}
	}
}

proc labelcmd {type path col} {
	global takeds takeus Log_Text1 Log_Text2 Log_Text3 Log_Text4
	set value [$path cellcget 0,$col -text]
	if {$type == "downstream"} {
		set count $takeds; set tp ds
		if {$col == 3} {set cmd power} elseif {$col == 4} {set cmd mod}
	} else {
		set count $takeus; set tp us
		if {$col == 3} {set cmd power} elseif {$col == 4} {set cmd chwidth} else {set cmd profile}
	}
	.p.pg start
	% disable $type all
	% set_$tp\_$cmd $count $value
	$Log_Text1 delete 0 end
	$Log_Text2 delete 0 end
	$Log_Text3 delete 0 end
	$Log_Text4 delete 0 end
	.p.pg configure -value 300
	% get_mib
	.p.pg configure -value 600
	.p.pg stop
}

proc init_spectrum {} {
	global nvas
	$nvas.c delete all
	#x-axis
	$nvas.c create line 20 200 655 200 -width 2
	$nvas.c create line 655 200 645 192 -width 2
	$nvas.c create line 655 200 645 208 -width 2
	$nvas.c create text 655 188 -text "Freq." -font {Courier 8 {bold}} -fill brown
	for {set x 100} {$x < 1218} {incr x 100} {
		$nvas.c create text [expr $x/2+20] 212 -text $x -font {Courier 8 {bold}} -fill brown
	}
	#y-axis
	$nvas.c create line 20 250 20 50 -width 2
	$nvas.c create line 20 50 12 60 -width 2
	$nvas.c create line 20 50 28 60 -width 2
	$nvas.c create text 20 40 -text "Amp." -font {Courier 8 {bold}} -fill brown
	for {set y 10} {$y < 80} {incr y 10} {
		$nvas.c create text 10 [expr 200-$y*1.5] -text $y -font {Courier 8 {bold}} -fill brown
	}
	$nvas.c create text [expr 350/2+20] 248 -text Ds -font {Courier 12 {bold}} -fill black
	$nvas.c create line [expr 380/2+20] 255 [expr 380/2+20] 240 -width 2 -fill green
	$nvas.c create line [expr 390/2+20] 255 [expr 390/2+20] 240 -width 2 -fill green
	$nvas.c create line [expr 400/2+20] 255 [expr 400/2+20] 240 -width 2 -fill green
	$nvas.c create text [expr 500/2+20] 248 -text Us -font {Courier 12 {bold}} -fill black
	$nvas.c create line [expr 530/2+20] 255 [expr 530/2+20] 240 -width 2 -fill red
	$nvas.c create line [expr 540/2+20] 255 [expr 540/2+20] 240 -width 2 -fill red
	$nvas.c create line [expr 550/2+20] 255 [expr 550/2+20] 240 -width 2 -fill red
	$nvas.c create text [expr 650/2+20] 248 -text OFDM -font {Courier 12 {bold}} -fill black
	$nvas.c create rectangle [expr 700/2+20] 255 [expr 750/2+20] 240 -stipple @[file join [pwd] images gray25.xbm] -fill green -tags item]
	$nvas.c create text [expr 830/2+20] 248 -text OFDMA -font {Courier 12 {bold}} -fill black
	$nvas.c create rectangle [expr 900/2+20] 255 [expr 950/2+20] 240 -stipple @[file join [pwd] images gray25.xbm] -fill red -tags item]
}

if {$::OO} {
	oo::class create SC_Spectrum {
		variable array qq
		variable color
		constructor {x y index switch type} {
			global nvas
			if {$type == "ds"} {set color green} else {set color red}
			if {$switch != 2} {
				set qq($index) [$nvas.c create line [expr $x/2+20] 200 [expr $x/2+20] [expr 200-$y*1.5] -width 2 -fill $color]
			}
		}
		method modify {x y switch index} {
			global nvas
			catch {$nvas.c delete $qq($index)}
			if {$switch == "1"} {
				set qq($index) [$nvas.c create line [expr $x/2+20] 200 [expr $x/2+20] [expr 200-$y*1.5] -width 2 -fill $color]
			}
		}
	}
	oo::class create OFDM_Spectrum {
		variable array qq
		variable color
		constructor {Low_x Up_x y index switch type} {
			global nvas
			if {$type == "ds"} {set color green} else {set color red}
			set y [expr round(10*log10(6.0/($Up_x-$Low_x))+$y)]
			puts $y
			if {$switch != 2} {
				set qq($index) [$nvas.c create rectangle [expr $Low_x/2+20] 200 [expr $Up_x/2+20] [expr 200-$y*1.5] -stipple @[file join [pwd] images gray25.xbm] -fill $color -tags item]
			}
		}
		method modify {Low_x Up_x y switch index} {
			global nvas
			catch {$nvas.c delete $qq($index)}
			set y [expr round(10*log10(6.0/($Up_x-$Low_x))+$y)]
			puts $y
			if {$switch == 1} {
				set qq($index) [$nvas.c create rectangle [expr $Low_x/2+20] 200 [expr $Up_x/2+20] [expr 200-$y*1.5] -stipple @[file join [pwd] images gray25.xbm] -fill $color -tags item]
			}
		}
	}
}
# $nvas.c create rectangle 270 200 320 173.0 -stipple @[file join [pwd] images gray25.xbm] -fill green -tags item

# spectrum destroy