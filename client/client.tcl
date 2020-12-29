# client link Server
if {[catch {set Channel_ID [socket 127.0.0.1 6000]} err]} {
	log_write $Log_Text $err
} else {
	log_write $Log_Text $err
	$mcmts entryconfigure 1 -state normal
	$mcmts entryconfigure 2 -state normal
	$mcmts entryconfigure 3 -state normal
	.mr entryconfigure 2 -state normal
	.mr entryconfigure 3 -state normal
	eval set_state normal
}
fconfigure $Channel_ID -buffering line
set response 0

proc Handle_ServerMessage {Channel_ID} {
	global response Log_Text dsindex placeX placeY return_msg f4press usindex currentip srvsock dsport usport
	if { [gets $Channel_ID line] < 0} {return}
	# puts $line
	if [catch {set command [lindex $line 0]}] {set command ""}
	catch {set msg [lindex $line 1]}
	switch $command {
		Info {
			set srvsock [lindex $msg end]
			log_write $Log_Text [lrange $msg 0 end-1]
			select_cmts [lindex $msg end-1]
			if !{[catch {set cmtsip $currentip}]} {
				wm title . "CMTS Control Tool(client)....$cmtsip, Link : [lindex $msg 0], Ver1.0/20170207"
			}
		}
		log {log_write $Log_Text $msg; puts $msg}
		port {set dsport [lindex $msg 0]; set usport [lindex $msg 1]}
		getmib {getvlu $msg}
		cell {set return_msg $msg}
		default {puts $line}
	}
	set response 1;set ::Avoid::F5 0;set ::Avoid::Enter 0;set ::Avoid::Itrgt 0
}

proc getvlu {msg} {
	global Log_Text1 Log_Text2 Log_Text3 Log_Text4 dsindex usindex takeds takeus ofdmindex ofdmaindex dsport usport
	##ds
	array set dsindex [lindex $msg 0]; array set dsfreq [lindex $msg 1]; array set dsmod [lindex $msg 2]; array set dspow [lindex $msg 3]; array set dsswitch [lindex $msg 4]
	##us
	array set usindex [lindex $msg 5]; array set usfreq [lindex $msg 6]; array set usprofile [lindex $msg 7]; array set uspow [lindex $msg 8]; array set usswitch [lindex $msg 9]
	array set uschwidth [lindex $msg 10]
	##ofdm
	array set ofdmindex [lindex $msg 11]; array set ofdmid [lindex $msg 12]; array set ofdmspac [lindex $msg 13]; array set ofdmflow [lindex $msg 14]; 
	array set ofdmfup [lindex $msg 15];array set ofdmplc [lindex $msg 16]; array set ofdmmod [lindex $msg 17]; array set ofdmswitch [lindex $msg 18];
	array set ofdmcp [lindex $msg 19];array set ofdmrp [lindex $msg 20]
	##ofdma
	array set ofdmaindex [lindex $msg 21]; array set ofdmaid [lindex $msg 22]; array set ofdmaspac [lindex $msg 23]; array set ofdmaflow [lindex $msg 24]; 
	array set ofdmafup [lindex $msg 25];array set ofdmak [lindex $msg 26]; array set ofdmamod [lindex $msg 27]; array set ofdmaswitch [lindex $msg 28];
	array set ofdmacp [lindex $msg 29];array set ofdmarp [lindex $msg 30]
	
	set dsnum [expr [llength [lindex $msg 0]]/2];set takeds $dsnum
	set usnum [expr [llength [lindex $msg 5]]/2];set takeus $usnum
	set ofdmnum [expr [llength [lindex $msg 11]]/2];set takeofdm $ofdmnum
	set ofdmanum [expr [llength [lindex $msg 21]]/2];set takeofdma $ofdmanum
	if {$::OO} {init_spectrum}
	for {set ch 1} {$ch <= $dsnum} {incr ch} {
		set dsch [string range "000$ch" end-1 end]
		if {$::OO} {
			catch {ds$ch destroy} 
			SC_Spectrum create ds$ch [expr $dsfreq($ch)/1000000.0] [expr $dspow($ch)/10.0] $ch $dsswitch($ch) ds
		}
		$Log_Text3 insert end [list [lindex $dsport [expr $ch-1]] $dsswitch($ch) $dsfreq($ch) $dspow($ch) $dsmod($ch)]
		# if {$dsswitch($ch)==1} {$Log_Text3 cellconfigure end,State -image $checked} else {$Log_Text3 cellconfigure end,State -image $unchecked}
	}
	for {set ch 1} {$ch <= $usnum} {incr ch} {
		set usch [string range "000$ch" end-1 end]
		if {$::OO} {
			catch {us$ch destroy} 
			SC_Spectrum create us$ch [expr $usfreq($ch)/1000000.0] [expr $uspow($ch)/1.5] $ch $usswitch($ch) us
		}
		$Log_Text4 insert end [list [lindex $usport [expr $ch-1]] $usswitch($ch) $usfreq($ch) $uspow($ch) $uschwidth($ch) $usprofile($ch)]
		# if {$usswitch($ch)==1} {$Log_Text4 cellconfigure end,State -image $checked} else {$Log_Text4 cellconfigure end,State -image $unchecked}
	}
	for {set ch 1} {$ch <= $ofdmnum} {incr ch} {
		if {$::OO} {
			catch {ofdm$ofdmid($ch) destroy} 
			OFDM_Spectrum create ofdm$ofdmid($ch) [expr $ofdmflow($ch)/1000000.0] [expr $ofdmfup($ch)/1000000.0] 50 $ofdmid($ch) $ofdmswitch($ch) ds
		}
		$Log_Text1 insert end [list $ofdmid($ch) $ofdmswitch($ch) $ofdmspac($ch) $ofdmflow($ch) $ofdmfup($ch) $ofdmcp($ch) $ofdmrp($ch) $ofdmmod($ch) $ofdmplc($ch)]
	}
	for {set ch 1} {$ch <= $ofdmanum} {incr ch} {
		if {$::OO} {
			catch {ofdma$ofdmaid($ch) destroy} 
			OFDM_Spectrum create ofdma$ofdmaid($ch) [expr $ofdmaflow($ch)/1000000.0] [expr $ofdmafup($ch)/1000000.0] 50 $ofdmaid($ch) $ofdmaswitch($ch) us
		}
		$Log_Text2 insert end [list $ofdmaid($ch) $ofdmaswitch($ch) $ofdmaspac($ch) $ofdmaflow($ch) $ofdmafup($ch) $ofdmacp($ch) $ofdmarp($ch) $ofdmamod($ch) $ofdmak($ch)]
	}
}

proc select_cmts {ip_list} {
	global comment rb currentip
	set comment ""
	catch {destroy .y}
	toplevel .y -bd 3 -relief raised -takefocus 1
	wm withdraw .y
	wm overrideredirect .y 1
	ttk::labelframe .y.lf -text "Select CMTS IP"
	grid .y.lf -row 0 -column 0 -columnspan 2 -sticky news
	set i 0
	foreach ip $ip_list {
		ttk::radiobutton .y.lf.rb$i -text $ip -value $i -variable rb
		grid .y.lf.rb$i -row $i -column 0 -sticky news
		incr i
	}
	ttk::button .y.bt1 -text "OK" -command {
		set currentip [.y.lf.rb$rb cget -text]
		set comment 1
		destroy .y 
	}
	ttk::button .y.bt2 -text "Cancel" -command {
		set rb ""
		destroy .y 
	}
	grid .y.bt1 .y.bt2 -padx 10 -pady 5 -sticky ew
	set x [winfo x .]
    set y [winfo y .]
    wm geometry .y +$x+$y
	wm deiconify .y
	focus -force .y.bt1
	update idletasks
	grab .y
	vwait comment
}

fileevent $Channel_ID readable [list Handle_ServerMessage $Channel_ID]

proc % args {
	global Channel_ID response currentip
	puts $args
	puts $Channel_ID "$currentip $args"
	vwait response
}
vwait response

