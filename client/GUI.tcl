# window:
set screen_width [expr {[winfo screenwidth .]/2}]
set screen_hight [expr {[winfo screenheight .]/2}]
set x [expr {([winfo screenwidth .]-[winfo width .])/5}]
set y [expr {([winfo screenheight .]-[winfo height .])/5}]

wm geometry . +$x+$y
wm title . "CMTS Control Tool(client)/Ver1.0/20170207"
ttk::style configure TLabel -foreground "gray20" -font {Courier 10 {bold}}
ttk::style configure GRE.TLabel -foreground "Dark Green" -font {Courier 10 {}}

# /menu gui
menu .mr -type menubar
set mcmts [menu .mr.file -tearoff 0]; set mdef [menu .mr.default -tearoff 0]
set mfft [menu .mr.fft -tearoff 0]
set mofdm1 [menu .mr.ofdm1 -tearoff 0]; set mofdm2 [menu .mr.ofdm2 -tearoff 0]
set mofdma1 [menu .mr.ofdma1 -tearoff 0]; set mofdma2 [menu .mr.ofdma2 -tearoff 0]

menu $mfft.2k -tearoff 0
menu $mfft.4k -tearoff 0
.mr add cascade -label "CMTS" -menu $mcmts
.mr add cascade -label "Edit" -menu $mdef -state disable
$mcmts add command -label "Link to Server" -state normal -command {
	catch {source client.tcl}
}

$mcmts add command -label "Huawei" -state disable -command {
	log_delete $Log_Text all
	# catch {% leave}
	catch {puts $Channel_ID R}
	catch {puts $Channel_ID H}
	vwait currentip
	% show config
	.p.pg start
	$Log_Text1 delete 0 end
	$Log_Text2 delete 0 end
	$Log_Text3 delete 0 end
	$Log_Text4 delete 0 end
	.p.pg configure -value 400
	% get_port_all
	% get_mib
	.p.pg stop
}

$mcmts add command -label "CASA" -state disable -command {
	log_delete $Log_Text all
	catch {puts $Channel_ID R}
	catch {puts $Channel_ID C}
	vwait currentip
	.p.pg start
	$Log_Text1 delete 0 end
	$Log_Text2 delete 0 end
	$Log_Text3 delete 0 end
	$Log_Text4 delete 0 end
	.p.pg configure -value 400
	% get_port_all
	% get_mib
	.p.pg stop
}

$mcmts add command -label "C10G" -state disable -command {
	log_delete $Log_Text all
	catch {puts $Channel_ID R}
	catch {puts $Channel_ID C10}
	vwait currentip
	.p.pg start
	$Log_Text1 delete 0 end
	$Log_Text2 delete 0 end
	$Log_Text3 delete 0 end
	$Log_Text4 delete 0 end
	.p.pg configure -value 400
	% get_port_all
	% get_mib
	.p.pg stop
}

$mdef add command -label "Power Edit" -state normal -command {
	power_gui
}

bind . <KeyPress-F1> {
	.p.pg start
	log_delete $Log_Text all
	.p.pg configure -value 300
	%% show ofdm
	.p.pg configure -value 600
	.p.pg stop
}

bind . <KeyPress-F2> {
	.p.pg start
	log_delete $Log_Text all
	.p.pg configure -value 300
	%% show ofdma
	.p.pg configure -value 600
	.p.pg stop
} 

bind . <KeyPress-F3> {
	.p.pg start
	log_delete $Log_Text all
	.p.pg configure -value 300
	%% ofdmapro
	.p.pg configure -value 600
	.p.pg stop
} 

bind . <KeyPress-F4> {
	.p.pg start
	log_delete $Log_Text all
	.p.pg configure -value 300
	.p.pg configure -value 600
	.p.pg stop
} 

namespace eval ::Avoid {
	variable Enter 0
	variable F5 0
	variable Itrgt 0
}

bind . <KeyPress-F5> {
	# puts $f5press
	if {$::Avoid::F5 == 0} {
		set ::Avoid::F5 1
		.p.pg start
		$Log_Text1 delete 0 end
		$Log_Text2 delete 0 end
		$Log_Text3 delete 0 end
		$Log_Text4 delete 0 end
		.p.pg configure -value 300
		%% get_port_all
		%% get_mib
		.p.pg configure -value 600
		.p.pg stop
	}
}

bind . <Control-Key-a> {
	log_delete $Log_Text all
	.p.pg start
	$Log_Text1 delete 0 end
	$Log_Text2 delete 0 end
	$Log_Text3 delete 0 end
	$Log_Text4 delete 0 end
	%% annex a
	%% show config
	.p.pg configure -value 300
	%% get_port_all
	%% get_mib
	.p.pg configure -value 600
	.p.pg stop
}

bind . <Control-Key-b> {
	log_delete $Log_Text all
	.p.pg start
	$Log_Text1 delete 0 end
	$Log_Text2 delete 0 end
	$Log_Text3 delete 0 end
	$Log_Text4 delete 0 end
	%% annex b
	%% show config
	.p.pg configure -value 300
	%% get_port_all
	%% get_mib
	.p.pg configure -value 600
	.p.pg stop
}

. configure -menu .mr
# menu end/

# /OFDM :
for {set i 0} {$i < 2} {incr i} {
::ttk::labelframe .fr$i -text "OFDM [expr $i+1]" -relief ridge
grid .fr$i 			-column 0 -row $i -sticky ew
# Frame 1 parameter and setting
::ttk::label .fr$i.# -text "####" -state disable
grid .fr$i.# 			-column 0 -row 0 -padx 2

::ttk::label .fr$i.ofdm -text "OFDM " -state disable
grid .fr$i.ofdm			-column 0 -row 1 -padx 2 

::ttk::label .fr$i.state# -text "State" -state disable
grid .fr$i.state#		-column 1 -row 0 -padx 2

::ttk::combobox .fr$i.state -values [list "" On Off] -textvariable state($i) -width 5 -justify center -state readonly
grid .fr$i.state		-column 1 -row 1 -padx 2

::ttk::label .fr$i.spacing# -text "Spacing" -state disable
grid .fr$i.spacing#		-column 2 -row 0 -padx 2

::ttk::combobox .fr$i.spacing -values [list "" 25k 50k] -textvariable spacing($i) -width 5 -justify center -state readonly
grid .fr$i.spacing		-column 2 -row 1 -padx 2

::ttk::label .fr$i.freqlow# -text "Freq_low" -state disable
grid .fr$i.freqlow#		-column 3 -row 0 -padx 2

::ttk::combobox .fr$i.freqlow -textvariable freqL($i) -width 7 -justify center
grid .fr$i.freqlow		-column 3 -row 1 -padx 2 

::ttk::label .fr$i.frequp# -text "Freq_up" -state disable
grid .fr$i.frequp#		-column 4 -row 0 -padx 2

::ttk::combobox .fr$i.frequp -textvariable freqU($i) -width 7 -justify center
grid .fr$i.frequp		-column 4 -row 1 -padx 2

::ttk::label .fr$i.cp# -text "CP" -state disable
grid .fr$i.cp#			-column 5 -row 0 -padx 2 

::ttk::combobox .fr$i.cp -values [list "" 192 256 512 768 1024] -textvariable cp($i) -width 6 -justify center -state readonly
grid .fr$i.cp			-column 5 -row 1 -padx 2

::ttk::label .fr$i.rp# -text "RP" -state disable
grid .fr$i.rp#			-column 6 -row 0 -padx 2

::ttk::combobox .fr$i.rp -values [list "" 0 64 128 192 256] -textvariable rp($i) -width 6 -justify center -state readonly
grid .fr$i.rp			-column 6 -row 1 -padx 2

::ttk::label .fr$i.mod# -text "Mod" -state disable
grid .fr$i.mod#			-column 7 -row 0 -padx 2

::ttk::combobox .fr$i.mod -values [list "" 16 32 64 128 256 512 1024 2048 4096] -textvariable mod($i) -width 6 -justify center -state readonly
grid .fr$i.mod			-column 7 -row 1 -padx 2

::ttk::label .fr$i.k# -text "Depth" -state disable
grid .fr$i.k#			-column 8 -row 0 -padx 2

::ttk::combobox .fr$i.k -values [list "" 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32] -textvariable k($i) -width 6 -justify center -state disable
grid .fr$i.k			-column 8 -row 1 -padx 2

::ttk::button .fr$i.bt -text "Set" -command "
.p.pg start
perform ofdm $i
.p.pg configure -value 600
.p.pg stop
Waitforcmd
"
grid .fr$i.bt			-column 9 -row 0 -rowspan 2 -padx 2 -sticky ns

# OFDM end/
}

# /OFDMA :
for {set i 2} {$i < 4} {incr i} {
::ttk::labelframe .fr$i -text "OFDMA [expr $i+1]" -relief ridge
grid .fr$i 			-column 0 -row $i -sticky ew
# Frame 1 parameter and setting
::ttk::label .fr$i.# -text "####" -state disable
grid .fr$i.# 			-column 0 -row 0 -padx 2

::ttk::label .fr$i.ofdma -text "OFDMA" -state disable
grid .fr$i.ofdma			-column 0 -row 1 -padx 2

::ttk::label .fr$i.state# -text "State" -state disable
grid .fr$i.state#		-column 1 -row 0 -padx 2

::ttk::combobox .fr$i.state -values [list "" On Off] -textvariable state($i) -width 5 -justify center -state readonly
grid .fr$i.state		-column 1 -row 1 -padx 2

::ttk::label .fr$i.spacing# -text "Spacing" -state disable
grid .fr$i.spacing#		-column 2 -row 0 -padx 2

::ttk::combobox .fr$i.spacing -values [list "" 25k 50k] -textvariable spacing($i) -width 5 -justify center -state readonly
grid .fr$i.spacing		-column 2 -row 1 -padx 2

::ttk::label .fr$i.freqlow# -text "Freq_low" -state disable
grid .fr$i.freqlow#		-column 3 -row 0 -padx 2

::ttk::combobox .fr$i.freqlow -textvariable freqL($i) -width 7 -justify center
grid .fr$i.freqlow		-column 3 -row 1 -padx 2

::ttk::label .fr$i.frequp# -text "Freq_up" -state disable
grid .fr$i.frequp#		-column 4 -row 0 -padx 2

::ttk::combobox .fr$i.frequp -textvariable freqU($i) -width 7 -justify center
grid .fr$i.frequp		-column 4 -row 1 -padx 2

::ttk::label .fr$i.cp# -text "CP" -state disable
grid .fr$i.cp#			-column 5 -row 0 -padx 2

::ttk::combobox .fr$i.cp -values [list "" 96 128 160 192 224 256 288 320 384 512 640] -textvariable cp($i) -width 6 -justify center -state readonly
grid .fr$i.cp			-column 5 -row 1 -padx 2

::ttk::label .fr$i.rp# -text "RP" -state disable
grid .fr$i.rp#			-column 6 -row 0 -padx 2

::ttk::combobox .fr$i.rp -values [list "" 0 32 64 96 128 160 192 224] -textvariable rp($i) -width 6 -justify center -state readonly
grid .fr$i.rp			-column 6 -row 1 -padx 2

::ttk::label .fr$i.mod# -text "Mod" -state disable
grid .fr$i.mod#			-column 7 -row 0 -padx 2

::ttk::combobox .fr$i.mod -values [list "" QPSK 8 16 32 64 128 256 512 1024 2048 4096] -textvariable mod($i) -width 6 -justify center -state readonly
grid .fr$i.mod			-column 7 -row 1 -padx 2

::ttk::label .fr$i.k# -text "K" -state disable
grid .fr$i.k#			-column 8 -row 0 -padx 2

::ttk::combobox .fr$i.k -values [list "" 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36] -textvariable k($i) -width 6 -justify center -state disable
grid .fr$i.k			-column 8 -row 1 -padx 2

::ttk::button .fr$i.bt -text "Set" -command "
.p.pg start
perform ofdma $i
.p.pg configure -value 600
.p.pg stop
Waitforcmd
"
grid .fr$i.bt			-column 9 -row 0 -rowspan 2 -padx 2 -sticky ns

# OFDMA end/
}
# bind freq combobox to record value
 
bind .fr0.freqlow <Return> {
	set freqL_list(0) [.fr0.freqlow cget -values]
	if {[string first $freqL(0) $freqL_list(0)] == -1} {
		.fr0.freqlow configure -values [linsert $freqL_list(0) 0 $freqL(0)]
	}
}

bind .fr0.frequp <Return> {
	set freqU_list(0) [.fr0.frequp cget -values]
	if {[string first $freqU(0) $freqU_list(0)] == -1} {
		.fr0.frequp configure -values [linsert $freqU_list(0) 0 $freqU(0)]
	}
}

bind .fr1.freqlow <Return> {
	set freqL_list(1) [.fr1.freqlow cget -values]
	if {[string first $freqL(1) $freqL_list(1)] == -1} {
		.fr1.freqlow configure -values [linsert $freqL_list(1) 0 $freqL(1)]
	}
}

bind .fr1.frequp <Return> {
	set freqU_list(1) [.fr1.frequp cget -values]
	if {[string first $freqU(1) $freqU_list(1)] == -1} {
		.fr1.frequp configure -values [linsert $freqU_list(1) 0 $freqU(1)]
	}
}

bind .fr2.freqlow <Return> {
	set freqL_list(2) [.fr2.freqlow cget -values]
	if {[string first $freqL(2) $freqL_list(2)] == -1} {
		.fr2.freqlow configure -values [linsert $freqL_list(2) 0 $freqL(2)]
	}
}

bind .fr2.frequp <Return> {
	set freqU_list(2) [.fr2.frequp cget -values]
	if {[string first $freqU(2) $freqU_list(2)] == -1} {
		.fr2.frequp configure -values [linsert $freqU_list(2) 0 $freqU(2)]
	}
}

bind .fr3.freqlow <Return> {
	set freqL_list(3) [.fr3.freqlow cget -values]
	if {[string first $freqL(3) $freqL_list(3)] == -1} {
		.fr3.freqlow configure -values [linsert $freqL_list(3) 0 $freqL(3)]
	}
}

bind .fr3.frequp <Return> {
	set freqU_list(3) [.fr3.frequp cget -values]
	if {[string first $freqU(3) $freqU_list(3)] == -1} {
		.fr3.frequp configure -values [linsert $freqU_list(3) 0 $freqU(3)]
	}
}

# /LOG gui :
set Ltext [frame .log -relief flat]
grid $Ltext -column 1 -row 0 -rowspan 6 -padx 2 -pady 2 -sticky news

# proc log_xy {Ltext args} {
	# global Log_Text
	# frame $Ltext
	# set Log_Text [text $Ltext.test_log -font {"Courier" {10}} -foreground Blue -xscrollcommand [list $Ltext.hsb set] -yscrollcommand [list $Ltext.vsb set]] 
	# eval $Log_Text configure $args
	# scrollbar $Ltext.vsb -orient vertical -command [list $Log_Text yview]
	# scrollbar $Ltext.hsb -orient horizontal -command [list $Log_Text xview]
	# grid $Ltext -sticky news
	# grid $Log_Text $Ltext.vsb -sticky news
	# grid $Ltext.hsb -sticky news
	# grid rowconfigure $Ltext 0 -weight 1
	# grid columnconfigure $Ltext 0 -weight 1
# }

proc scrolled_text { f args } {
	global Log_Text
    frame $f
    set Log_Text [text $f.text -wrap none -fg Blue -font [font create -family "Courier" -size 9] -xscrollcommand [list $f.xscroll set] -yscrollcommand [list $f.yscroll set]]
    eval $Log_Text configure $args
    scrollbar $f.xscroll -orient horizontal -command [list $Log_Text xview]
    scrollbar $f.yscroll -orient vertical -command [list $Log_Text yview]
    grid $Log_Text $f.yscroll -sticky news
    grid $f.xscroll -sticky news
    grid rowconfigure $f 0 -weight 1
    grid columnconfigure $f 0 -weight 1
    return $Log_Text
}
set st1 [scrolled_text $Ltext.f1 -width 50 -height 35]
grid $Ltext.f1 -sticky news

# LOG end/

# Command entry
namespace eval ::Cnsl {
	variable Cmd ""
	variable i 1
	set Rcmd(1) ""; set Rcmd(2) ""; set Rcmd(3) ""
}

::ttk::entry $Ltext.encmd -font {Courier 10} -textvariable ::Cnsl::Cmd -validate key -validatecommand {Vcmd %S}
grid $Ltext.encmd -column 0 -row 1 -padx 2 -pady 2 -sticky news

bind $Ltext.encmd <Return> {
	if {$::Avoid::Enter == 0} {
		set ::Avoid::Enter 1
		::Cnsl::Keyin $::Cnsl::Cmd
	}
}
bind $Ltext.encmd <Shift-Key-?> {
	if {$::Avoid::Itrgt == 0} {
		set ::Avoid::Itrgt 1
		::Cnsl::help $::Cnsl::Cmd
	}
}

if {$::OO} {
	oo::class create Record {
		variable x     
		constructor {} {
			set x 0
		}
		method add {} {
			if {$x == 3} {return 3} 
			return [incr x]
		}
		method sub {} {
			if {$x == 1 || $x == 0} {return 1} 
			return [incr x -1]
		}
	}
	Record create Rcmd
	
	bind $Ltext.encmd <Key-Up> {set ::Cnsl::Cmd $::Cnsl::Rcmd([Rcmd add])}
	bind $Ltext.encmd <Key-Down> {set ::Cnsl::Cmd $::Cnsl::Rcmd([Rcmd sub])}
}
# /nb
::ttk::notebook .nb
grid .nb -column 0 -row 4 -padx 2 -pady 2 -sticky news

# nb end/

# /Table List
set table [ttk::frame .nb.d31 -relief flat]
grid $table -column 0 -row 0 -sticky news
.nb add $table -text "OFDM/OFDMA"
ttk::labelframe $table.ofdm -text "OFDM"
set Log_Text1 [tablelist::tablelist $table.ofdm.t -columntitles {"Channel" "On/Off" "Spacing" "FreqL" "FreqU" "CP" "RP" "Mod" "PLC"} -stretch all -width 75 -height 4 \
-font {Courier 11 {bold}} -foreground #312251 -labelcommand {OfdmLabelCmd} -editendcommand editEndCmd_ofdm]
$Log_Text1 configure -labelfont {Courier 10 {bold}}
$Log_Text1 configure -columns {
	0	"Channel"					center
	0	"On/Off" 					center
	0	"Spacing" 					center
	0	"FreqL" 					center
	0	"FreqU" 					center
	0	"CP" 						center
	0	"RP"	 					center
	0	"Mod" 						center
	0	"PLC" 						center
}
grid $table.ofdm -column 0 -row 0 -sticky news
grid $table.ofdm.t -column 0 -row 0 -sticky news
$Log_Text1 columnconfigure 1 -name "On/Off" -editable yes -editwindow ttk::entry


ttk::labelframe $table.ofdma -text "OFDMA"
set Log_Text2 [tablelist::tablelist $table.ofdma.t -columntitles {"Channel" "On/Off" "Spacing" "FreqL" "FreqU" "CP" "RP" "Mod" "K"} -stretch all -width 75 -height 4 \
-font {Courier 11 {bold}} -foreground #312251 -labelcommand {OfdmaLabelCmd} -editendcommand editEndCmd_ofdma]
$Log_Text2 configure -labelfont {Courier 10 {bold}}
$Log_Text2 configure -columns { 
	0	"Channel"				center
	0	"On/Off" 				center
	0	"Spacing" 				center
	0	"FreqL" 				center
	0	"FreqU" 				center
	0	"CP" 					center
	0	"RP" 					center
	0	"Mod" 					center
	0	"K" 					center
}
grid $table.ofdma -column 0 -row 1 -sticky news
grid $table.ofdma.t -column 0 -row 0 -sticky news
$Log_Text2 columnconfigure 1 -name "On/Off" -editable yes -editwindow ttk::entry

set table1 [ttk::frame .nb.ds -relief flat]
grid $table1 -column 0 -row 0 -sticky news
.nb add $table1 -text "SC-QAM/DS"
ttk::frame $table1.sc
set Log_Text3 [tablelist::tablelist $table1.sc.t -columntitles {"Channel" "On/Off" "Frequency" "Power" "Mod"} \
-selecttype cell -editendcommand editEndCmd_ds -stretch all -width 76 -height 12 -font {Courier 11 {bold}} -foreground #312251 \
 -labelcommand {DsLabelCmd} -labelcommand2 {DsLabelCmd2}]
 $Log_Text3 configure -labelfont {Courier 10 {bold}}
$Log_Text3 configure -columns { 
	0	"Channel"					center
	0	"On/Off" 					center
	0	"Frequency" 				center
	0	"Power" 					center
	0	"Mod" 						center
}
grid $table1.sc -column 0 -row 0 -sticky news
grid $table1.sc.t -column 0 -row 0 -sticky news
# $Log_Text3 columnconfigure 1 -name State -editable yes -editwindow checkbutton
$Log_Text3 columnconfigure 1 -name "On/Off"  -editable yes -editwindow ttk::entry
$Log_Text3 columnconfigure 2 -name Frequency  -editable yes -editwindow ttk::entry
$Log_Text3 columnconfigure 3 -name Power  -editable yes -editwindow ttk::entry
$Log_Text3 columnconfigure 4 -name Mod  -editable yes -editwindow ttk::entry



set table2 [ttk::frame .nb.us -relief flat]
grid $table2 -column 0 -row 0 -sticky news
.nb add $table2 -text "SC-QAM/US"
ttk::frame $table2.sc
set Log_Text4 [tablelist::tablelist $table2.sc.t -columntitles {"Channel" "On/Off" "Frequency" "Power" "ChannelWidth" "Profile"} \
-selecttype cell -editendcommand editEndCmd_us -stretch all -width 76 -height 12 -font {Courier 11 {bold}} -foreground #312251 \
-labelcommand {UsLabelCmd} -labelcommand2 {UsLabelCmd2}]
$Log_Text4 configure -labelfont {Courier 10 {bold}}
$Log_Text4 configure -columns { 
	0	"Channel"					center
	0	"On/Off" 					center
	0	"Frequency" 				center
	0	"Power" 					center
	0	"ChannelWidth" 				center
	0	"Profile" 					center
}
grid $table2.sc -column 0 -row 0 -sticky news
grid $table2.sc.t -column 0 -row 0 -sticky news
$Log_Text4 columnconfigure 1 -name "On/Off" -editable yes -editwindow ttk::entry
# $Log_Text4 columnconfigure 1 -name State -editable yes -editwindow checkbutton 
$Log_Text4 columnconfigure 2 -name Frequency  -editable yes -editwindow ttk::entry
$Log_Text4 columnconfigure 3 -name Power  -editable yes -editwindow ttk::entry
$Log_Text4 columnconfigure 4 -name ChannelWidth  -editable yes -editwindow ttk::entry
$Log_Text4 columnconfigure 5 -name Profile  -editable yes -editwindow ttk::entry
# Table list end/

# /Progress
ttk::frame .p -relief groove
grid .p -column 0 -row 5 -padx 5 -pady 5 -sticky we

ttk::label .p.lb -text "Show <F1>OFDM <F2>OFDMA <F3>UsProfile <F5>Update Mib <Ctrl+A||B>Annex" -foreground red -font "Courier 9"
pack .p.lb -side left -expand 1 -padx 5 -pady 5

ttk::progressbar .p.pg -mode determinate
pack .p.pg -side right -expand 0 -padx 5 -pady 5
.p.pg configure -maximum 800

# /Spectrum
if {$::OO} {
	set nvas [ttk::frame .nb.spectrum -relief flat]
	canvas $nvas.c -relief raised
	pack $nvas -side top -fill x
	pack $nvas.c -fill x
	.nb add $nvas -text "SPECTRUM"
}
