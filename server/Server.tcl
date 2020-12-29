package require Tk
package require tile
package require TclOO
catch {package require twapi}
if {[catch {package require tablelist_tile 5.16}]} {package require tablelist}
image create photo openImg -file [file join [pwd] image file.gif]
tablelist::addBWidgetEntry
source function.tcl
source [file join [pwd] lib MA5633.tcl]
source [file join [pwd] lib CASA-C10G.tcl]
source [file join [pwd] lib CASAC2200.tcl]
source [file join [pwd] lib CASA536.tcl]
# Kill Client Socket Process

# set pids [list]
# set self_pid [pid]
# catch [set pids [twapi::get_process_ids -name "tclsh86.exe"]]
# if { [llength $pids] > 0 } {
 # foreach ppid $pids {
  # if { $ppid != $self_pid } {
   # catch [twapi::end_process $ppid -force]
  # }
 # }
# }

############ Socket Parameters #############
set Server_IP		127.0.0.1
# set Server_IP		127.0.0.1
set Server_Port		6000
set CMTS			""
############ Processes #####################
set channelID ""
proc Open_Server_Socket { channelID clientIP clientPort } {
	# .text insert end "Client Channel ID : $channelID Client IP : $clientIP Port : $clientPort\n"
	puts "Client Channel ID : $channelID Client IP : $clientIP Port : $clientPort\n"
	fconfigure $channelID -blocking 0 -buffering line
	fileevent $channelID readable [list Handle_ClientMessage $channelID $clientIP]
	puts $channelID [list log "Choose CMTS Type" "H:Huawei" "B:Broadcom" "C:CASA" "C10:C10G"]
}

proc Handle_ClientMessage { Channel_ID clientIP } {
	if { [gets $Channel_ID line] < 0} {
         if {[eof $Channel_ID]} {close $Channel_ID} else {after 20}
		return
	}
	global CMTS Server_list
	if {$CMTS == ""} {
		switch $line {
			H {set CMTS "Huawei"; set CMTS_List $::Huawei::list}
			B {set CMTS "Broadcom"; set CMTS_List $::BCOM::list}
			C {set CMTS "CASA"; set CMTS_List $::CASA::list}
			C10 {set CMTS "C10G"; set CMTS_List $::C10G::list}
			R {set CMTS ""; set msg "Reset setting"}
			default {set CMTS ""; set msg [list log "Error command"]}
		}
		if {$CMTS != ""} {
			if [catch {set msg [list $CMTS $CMTS_List $Channel_ID]}] {
				set msg [list log "No any $CMTS Link!!"]
			}
			puts $msg
			foreach line [split $msg \n] {
				puts $Channel_ID [list Info $line]
			}
		} else {puts $Channel_ID $msg}
	} else {
		if {$line == "R"} {
			set CMTS ""; puts $Channel_ID [list log "Reset setting"]
		} else {
			set ip [lindex $line 0]
			if {[lindex $line 1 0] == "promptwait"} {set line [lindex $line 1]}
			after 100
			catch {eval $line} show
			set Logpath [lsearch [lindex [$Server_list columnconfigure 0 -text] 4] $ip]
			.log$Logpath.frame.list insert 0 "[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"] ($clientIP) : $line"
			# puts $show
			if [catch {set type [lindex $show 0]}] {set type ""}
			switch $type {
				getmib {
					set show [lrange $show 1 end]
					foreach line [split $show \n] {puts $Channel_ID [list getmib $line]}
				}
				cell {
					set show [lrange $show 1 end]
					foreach line [split $show \n] {puts $Channel_ID [list cell $line]}
				}
				port {
					set show [lrange $show 1 end]
					foreach line [split $show \n] {puts $Channel_ID [list port $line]}
				}
				log {
					set show [lindex $show 1]
					foreach line [split $show \n] {puts $Channel_ID [list log $line]}
				}
				default {
					foreach line [split $show \n] {puts $Channel_ID $line}
				}
			}
		}
	}
	# update
};#End Handle_ClientMessage

proc createButton {tbl row col w} {
    set key [$tbl getkeys $row]
    button $w -image openImg -highlightthickness 0 -takefocus 0 \
              -command [list viewFile $tbl $row $col $w]
}

proc viewFile {tbl row col w} {
	::tk::PlaceWindow .log$row
	puts "$tbl $row $col $w"
}

proc CmdLog {tbl row} {
	set s .log$row
	# catch {destroy $s}
	set ip [$tbl cellcget $row,0 -text]
	toplevel $s
	wm title $s "View $ip Cmd Log"
	wm iconname $s "log"
	wm protocol $s WM_DELETE_WINDOW "wm withdraw $s"
	label $s.msg -font "Courier 10" -wraplength 4i -justify left -text "The listbox below contains a collection of Client echo.  You can scan the command from Log to check their status."
	pack $s.msg -side top
	
	frame $s.frame -borderwidth 10
	pack $s.frame -side top -expand yes -fill both -padx 1c
	
	scrollbar $s.frame.yscroll -command "$s.frame.list yview"
	scrollbar $s.frame.xscroll -orient horizontal \
		-command "$s.frame.list xview"
	listbox $s.frame.list -width 80 -height 25 -setgrid 1 \
		-yscroll "$s.frame.yscroll set" -xscroll "$s.frame.xscroll set"
	
	grid $s.frame.list -row 0 -column 0 -rowspan 1 -columnspan 1 -sticky news
	grid $s.frame.yscroll -row 0 -column 1 -rowspan 1 -columnspan 1 -sticky news
	grid $s.frame.xscroll -row 1 -column 0 -rowspan 1 -columnspan 1 -sticky news
	grid rowconfig    $s.frame 0 -weight 1 -minsize 0
	grid columnconfig $s.frame 0 -weight 1 -minsize 0
	wm withdraw $s
}

proc ip_gui {} {
	global Server_list
	# Shut .y first to make sure executing not duplicated
	wm title . Server
	wm withdraw .
	wm protocol . WM_DELETE_WINDOW {exit}
	# wm overrideredirect .y 1
	set tf [ttk::frame .ds -relief flat]
	grid $tf -column 0 -row 1 -sticky news
	ttk::button $tf.bt1 -text "Insert"	-command {$Server_list insert end [list "" "" "" "" 0 ""]}
	ttk::button $tf.bt2 -text "Delete"	-command {$Server_list delete end}
	ttk::button $tf.bt3 -text "Quit"	-command {exit}
	
	grid $tf.bt1 $tf.bt2 $tf.bt3 -padx 5 -pady 5 -sticky we
	
	set Server_list [tablelist::tablelist $tf.t -columntitles {"IP" "Read Community" "Set Community" "Password" "Link" "Status" "Log"} \
	-selecttype cell -editendcommand editEndCmd_gui -stretch all -width 90 -height 9 -font "Courier 10" -foreground #312251]
	$Server_list configure -columns { 
		4	"IP"					center
		3	"Read Community" 		center
		3	"Set Community" 		center
		3	"Password" 				center
		2	"Link" 					center
		4	"Status" 				center
		4	"Type" 					center
		1	"Log" 					center
	}
	grid $tf.t -column 0 -columnspan 3 -row 1 -sticky news
	$Server_list columnconfigure 0 -name IP  -editable yes -editwindow ttk::entry
	$Server_list columnconfigure 1 -name "Read Community"  -editable yes -editwindow ttk::entry
	$Server_list columnconfigure 2 -name "Set Community"  -editable yes -editwindow ttk::entry
	$Server_list columnconfigure 3 -name "Set Community"  -editable yes -editwindow ttk::entry
	$Server_list columnconfigure 4 -name Link  -editable yes -editwindow ttk::entry
	$Server_list columnconfigure 5 -name Status  -editable no -editwindow ttk::entry
	$Server_list columnconfigure 6 -name Type  -editable no -editwindow ttk::entry
	
	$Server_list insert end [list 192.168.142.248 public123 private123 admin123 0 ""]
	$Server_list insert end [list 10.10.160.14 public private casa 0 ""]
	$Server_list insert end [list 10.10.160.18 public private mduadmin 0 ""]
	
	wm geometry . +250+300
	wm deiconify .
	focus -force $tf.bt1
	update idletasks
	grab .
}

proc editEndCmd_gui {tbl row col text} {
	global Server_list fd snmp_oid
	if {$col != 4} {return $text} else {
		#get ip
		set ip [$Server_list cellcget $row,0 -text]
		puts $ip
		if {$text != 1} {
			catch {close [$Server_list cellcget $row,5 -text]}
			catch {$ip destroy}
			catch {destroy .log$row}
			# unset R($ip); unset W($ip)
			catch {set ::Huawei::list [lsearch -all -inline -not -exact $Huawei::list $ip]}
			catch {set ::CASA::list [lsearch -all -inline -not -exact $CASA::list $ip]}
			catch {set ::C10G::list [lsearch -all -inline -not -exact $C10G::list $ip]}
			catch {set ::CMTS::sock [lsearch -all -inline -not -exact $CMTS::sock [$Server_list cellcget $row,5 -text]]}
			catch {.ds.t.body.frm_k$row,7.w configure -state disable}
			$Server_list cellconfigure $row,5 -text ""
			$Server_list cellconfigure $row,6 -text ""
			$Server_list cellconfigure $row,0 -editable yes
			$Server_list cellconfigure $row,1 -editable yes
			$Server_list cellconfigure $row,2 -editable yes
			$Server_list cellconfigure $row,3 -editable yes
			update
			return 0
		} else {
			#login CMTS
			set ::CMTS::PW [$Server_list cellcget $row,3 -text]
			set R($ip) [$Server_list cellcget $row,1 -text]
			set W($ip) [$Server_list cellcget $row,2 -text]
			set ::CMTS::TYPE($ip) [string range [snmp_get -t 1 -r 0 -Oqv -c $R($ip) $ip $snmp_oid(sysName).0] 1 end-1]
			if {[catch {login_cmts $ip} msg]} {
				puts $msg
				catch {.ds.t.body.frm_k$row,7.w configure -state disable}
				$Server_list cellconfigure $row,5 -text error
				$Server_list cellconfigure $row,6 -text ""
				$Server_list cellconfigure $row,0 -editable yes
				$Server_list cellconfigure $row,1 -editable yes
				$Server_list cellconfigure $row,2 -editable yes
				$Server_list cellconfigure $row,3 -editable yes
				return 0
			}
			if {[string first "Reenter times have reached the upper limit" $msg] >= "0"} {
				catch {.ds.t.body.frm_k$row,7.w configure -state disable}
				$Server_list cellconfigure $row,5 -text error
				$Server_list cellconfigure $row,6 -text ""
				$Server_list cellconfigure $row,0 -editable yes
				$Server_list cellconfigure $row,1 -editable yes
				$Server_list cellconfigure $row,2 -editable yes
				$Server_list cellconfigure $row,3 -editable yes
				return 0
			}
			set sock($ip) $fd
			$Server_list cellconfigure $row,6 -text "Wait..."
			$::CMTS::TYPE($ip) create $ip $R($ip) $W($ip) $ip $sock($ip)
			# puts "$R($ip) $W($ip)"
			# oo::define $::CMTS::TYPE($ip) mixin CMTS
			$Server_list cellconfigure $row,7 -window createButton
			CmdLog $Server_list $row
			.ds.t.body.frm_k$row,7.w configure -state normal
			$Server_list cellconfigure $row,5 -text $sock($ip)
			$Server_list cellconfigure $row,6 -text $::CMTS::TYPE($ip)
			$Server_list cellconfigure $row,0 -editable no
			$Server_list cellconfigure $row,1 -editable no
			$Server_list cellconfigure $row,2 -editable no
			$Server_list cellconfigure $row,3 -editable no
			switch $::CMTS::TYPE($ip) {
				MA5633		{lappend Huawei::list $ip}
				CASA536		{lappend CASA::list $ip}
				CASA-C2200	{lappend CASA::list $ip}
				CASA-C10G	{lappend C10G::list $ip}
				default		{puts $::CMTS::TYPE($ip)}
			}
			lappend ::CMTS::sock $sock($ip)
			update
			return 1
		}
	}
}

proc Sleep { msecs } {
	set wake 0
	after $msecs {set wake 1}
	vwait wake
	set wake 0
	update
}

namespace eval ::CMTS {
	variable list
	variable sock
	namespace eval ::Huawei	{variable list ""}
	namespace eval ::CASA	{variable list ""}
	namespace eval ::C10G	{variable list ""}
	namespace eval ::BCOM	{variable list ""}
}

ip_gui

proc timer {} {
	catch {
		foreach ss $::CMTS::sock {
			promptwait $ss " " "#" 3
			puts "promptwait $ss {} # 3"
		}
	}
	after 200000 {timer}
	update
}
after 100000 {timer}


########### Open Server Socket ##########
set Server_Socket [socket -server Open_Server_Socket -myaddr $Server_IP $Server_Port]
vwait forever
