catch {load netsnmptcl.dll}
catch {source snmp_oid.tcl}

proc promptwait {consoleid writein waitfor { wait_time 2 } { newline 1 } } {
	global tttiiimmmeee
	set tttiiimmmeee 0
	set line ""
	set start [clock seconds]
	catch {set aa [read $consoleid]}
	if { $newline } {
		if { [catch {puts $consoleid $writein}] } {
			return -code error
		}
	} else {
		if { [catch {puts -nonewline $consoleid $writein}] } {
			return -code error
		}
	}
	catch {flush $consoleid}
	while {1} {
		if {[clock seconds] - $start > $wait_time} {
			return $line
		}
		set tempchar ""
		catch {set tempchar [read $consoleid 1]}
		if { [string length $tempchar] == 0} {
			after 20 {incr tttiiimmmeee}
			vwait tttiiimmmeee
		} else {
			set line $line$tempchar
			set pat $waitfor\$
			if { [regexp -- $pat $line] } {
				return $line
			}
		}
	}
}

proc login_cmts {ip} {
	global fd
	if {$::CMTS::TYPE($ip) == "MA5633"} {
		set fd [socket $ip 23]
		fconfigure $fd -blocking 0
		promptwait $fd "" "User name:"	3
		promptwait $fd "root" "password:" 3
		catch {promptwait $fd $::CMTS::PW "MA5633>" 3} msg
		promptwait $fd " " "MA5633>" 3
		promptwait $fd "en" "#" 3
		promptwait $fd "config" "#" 3
		promptwait $fd "scroll" ":" 3
		promptwait $fd " " "#" 3
		promptwait $fd "undo smart" "#" 3
		return $msg
	} else {
		set fd [open "|plink -telnet $ip" w+]
		fconfigure $fd -blocking 0 -buffering full
		promptwait $fd "" "login:"
		promptwait $fd "root" "Password:"
		promptwait $fd $::CMTS::PW ">"
		promptwait $fd "en" "Password:"
		promptwait $fd $::CMTS::PW "#"
		catch {promptwait $fd "conf" "#"} msg
		promptwait $fd "page-off" "#"
		return $msg
	}
}

oo::class create CMTS {
	variable R W ip sock
	variable array snmp_oid
	method cmd {msg} {
		catch {promptwait $sock $msg "#" 5} msg
		return [list log $msg]
	}
	
	method output {index {value ""}} {
		if {$value == ""} {
			catch {snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(ifAdminStatus).$index} msg
			return $msg
		} else {
			catch {snmp_set -Oqv $ip $W $snmp_oid(ifAdminStatus).$index i $value} msg
			# puts "snmp_set -Oqv $ip $W $snmp_oid(ifAdminStatus).$index i $value"
			return $msg
		}
	}
	# method annex {index {value ""}} {
		# global snmp_oid R W ip
		# if {$value == ""} {
			# catch {snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIfDownChannelAnnex).$index} msg
			# return $msg
		# } else {
			# catch {snmp_set -Oqv $ip $W $snmp_oid(docsIfDownChannelAnnex).$index i $value} msg
			# return $msg
		# }
	# }
	method dsfrequency {index {value ""}} {
		if {$value == ""} {
			catch {snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIfDownChannelFrequency).$index} msg
			return $msg
		} else {
			catch {snmp_set -Oqv $ip $W $snmp_oid(docsIfDownChannelFrequency).$index i $value} msg
			return $msg
		}
	}
	method dspower {index {value ""}} {
		if {$value == ""} {
			catch {snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIfDownChannelPower).$index} msg
			return $msg
		} else {
			catch {snmp_set -Oqv $ip $W $snmp_oid(docsIfDownChannelPower).$index i $value} msg
			return $msg
		}
	}
	method dsmod {index {value ""}} {
		if {$value == ""} {
			catch {snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIfDownChannelModulation).$index} msg
			return $msg
		} else {
			if {[catch {snmp_set -Oqv $ip $W $snmp_oid(docsIfDownChannelModulation).$index i $value} msg]} {
				return [list 0 $msg]
			} else {return $msg}
		}
	}
	method usfrequency {index {value ""}} {
		if {$value == ""} {
			catch {snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIfUpChannelFrequency).$index} msg
			return $msg
		} else {
			catch {snmp_set -Oqv $ip $W $snmp_oid(docsIfUpChannelFrequency).$index i $value} msg
			return $msg
		}
	}
	method uspower {index {value ""}} {
		if {$value == ""} {
			catch {snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIf3CmtsSignalQualityExtExpectedRxSignalPower).$index} msg
			return $msg
		} else {
			catch {snmp_set -Oqv $ip $W $snmp_oid(docsIf3CmtsSignalQualityExtExpectedRxSignalPower).$index i $value} msg
			return $msg
		}
	}
	method uschwidth {index {value ""}} {
		if {$value == ""} {
			catch {snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIfUpChannelWidth).$index} msg
			return $msg
		} else {
			if {[catch {snmp_set -Oqv $ip $W $snmp_oid(docsIfUpChannelWidth).$index i $value} msg]} {
				return [list 0 $msg]
			} else {return $msg}
		}
	}
	method usprofile {index {value ""}} {
		if {$value == ""} {
			catch {snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIfUpChannelModulationProfile).$index} msg
			return $msg
		} else {
			if {[catch {snmp_set -Oqv $ip $W $snmp_oid(docsIfUpChannelModulationProfile).$index u $value} msg]} {
				return [list 0 $msg]
			} else {return $msg}
		}
	}
	method get_index {type {index ""}} {
		switch $type {
			ds 		{set allindex [snmp_walk -Oqf $ip $R $snmp_oid(docsIfDownChannelId)]}
			us 		{set allindex [snmp_walk -Oqf $ip $R $snmp_oid(docsIfUpChannelId)]}
			ofdma	{set allindex [snmp_walk -Oqf $ip $R $snmp_oid(docsIf31CmtsUsOfdmaChanTemplateIndex)]}
			ofdm	{set allindex [snmp_walk -Oqf $ip $R $snmp_oid(docsIf31CmtsDsOfdmChanChannelId)]}
			help 	{return "example: (% get_index ds||us||ofdm||ofdma) or (% get_index ds||us||ofdm||ofdma index1 index2 index3....)"}
		}
		set OIDIdxList ""
		for {set i 0} {$i < [llength $allindex]} {incr i 2} {
			lappend OIDIdxList [lindex [split [lindex $allindex $i] "."] end]
		}
		if {$type == "ofdm"} {set OIDIdxList [lrange $OIDIdxList 0 1]}
		if {$index == ""} {return $OIDIdxList} else {return [lindex $OIDIdxList $index]}
	}
	method get_port {type {index ""}} {
		set dsportlist ""; set usportlist ""
		if {$::CMTS::TYPE($ip) == "MA5633"} {set dstext docsCableDownstream ; set ustext docsCableUpstream} else {
			set dstext Downstream ; set ustext "Logical Upstream Channel"
		}
		set allindex [snmp_walk -Oqf $ip $R $snmp_oid(ifDescr)]
		after 100
		foreach [list qqindex port] $allindex {
			set ss [lindex [split $qqindex "."] end]
			set aryindex($ss) $port
			if {[string first $dstext $aryindex($ss)] >= "0"} {
				lappend dsportlist [lindex $port end]
			}
			if {[string first $ustext $aryindex($ss)] >= "0"} {
				lappend usportlist [lindex $port end]
			}
		}
		if {$index == ""} {
			switch $type {ds {return $dsportlist} us {return $usportlist}}
		} else {
			switch $type {ds {return [lindex $dsportlist $index]} us {return [lindex $usportlist $index]}}
		}
	}
	method get_port_all {} {
		set dsport [my get_port ds]
		set usport [my get_port us]
		return [list port $dsport $usport]
	}
	
	namespace eval ::SC {
		namespace eval DS {}
		namespace eval US {}
	}
	namespace eval ::OFDM {}
	namespace eval ::OFDMA {}
	
	method ofdmMib {} {
		set OIDIdxList [my get_index ofdm]
		set i 1
		foreach x $OIDIdxList {
			set ::OFDM::index($i) $x
			set ::OFDM::id($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIf31CmtsDsOfdmChanChannelId).$::OFDM::index($i)]
			set ::OFDM::spacing($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIf31CmtsDsOfdmChanSubcarrierSpacing).$::OFDM::index($i)]
			set ::OFDM::lowf($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIf31CmtsDsOfdmChanLowerBdryFreq).$::OFDM::index($i)]
			set ::OFDM::upf($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIf31CmtsDsOfdmChanUpperBdryFreq).$::OFDM::index($i)]
			set ::OFDM::plc($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIf31CmtsDsOfdmChanPlcFreq).$::OFDM::index($i)]
			if [catch {set ::OFDM::mod($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIf31CmtsDsOfdmSubcarrierStatusModulation).$::OFDM::index($i).0.1]}] {
				set ::OFDM::mod($i) null
			}
			set ::OFDM::switch($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(ifAdminStatus).$::OFDM::index($i)]
			set ::OFDM::ofdmcp($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIf31CmtsDsOfdmChanCyclicPrefix).$::OFDM::index($i)]
			set ::OFDM::ofdmrp($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIf31CmtsDsOfdmChanRollOffPeriod).$::OFDM::index($i)]
			append indexlist "$i $::OFDM::index($i) "
			append ofdmid "$i $::OFDM::id($i) "
			append ofdmspac "$i $::OFDM::spacing($i) "
			append freqlow "$i $::OFDM::lowf($i) "
			append frequp "$i $::OFDM::upf($i) "
			append plclist "$i $::OFDM::plc($i) "
			append modlist "$i $::OFDM::mod($i) "
			append switchlist "$i $::OFDM::switch($i) "
			append ofdmcp "$i $::OFDM::ofdmcp($i) "
			append ofdmrp "$i $::OFDM::ofdmrp($i) "
			incr i
		}
		return "{$indexlist} {$ofdmid} {$ofdmspac} {$freqlow} {$frequp} {$plclist} {$modlist} {$switchlist} {$ofdmcp} {$ofdmrp}"
	}
	method ofdmaMib {} {
		set OIDIdxList [my get_index ofdma]
		set i 1
		foreach x $OIDIdxList {
			set ::OFDMA::index($i) $x
			set ::OFDMA::spacing($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIf31CmtsUsOfdmaChanSubcarrierSpacing).$::OFDMA::index($i)]
			set ::OFDMA::lowf($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIf31CmtsUsOfdmaChanLowerBdryFreq).$::OFDMA::index($i)]
			set ::OFDMA::upf($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIf31CmtsUsOfdmaChanUpperBdryFreq).$::OFDMA::index($i)]
			set ::OFDMA::k($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIf31CmtsUsOfdmaChanNumSymbolsPerFrame).$::OFDMA::index($i)]
			# set ::OFDMA::mod($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIf31CmtsDsOfdmSubcarrierStatusModulation).$::OFDMA::index($i).0.1]
			set ::OFDMA::switch($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(ifAdminStatus).$::OFDMA::index($i)]
			set ::OFDMA::ofdmcp($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIf31CmtsUsOfdmaChanCyclicPrefix).$::OFDMA::index($i)]
			set ::OFDMA::ofdmrp($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIf31CmtsUsOfdmaChanRollOffPeriod).$::OFDMA::index($i)]
			append indexlist "$i $::OFDMA::index($i) "
			# append ofdmaid "$i $::OFDMA::id($i) "
			append ofdmaspac "$i $::OFDMA::spacing($i) "
			append freqlow "$i $::OFDMA::lowf($i) "
			append frequp "$i $::OFDMA::upf($i) "
			append symperfram "$i $::OFDMA::k($i) "
			# append modlist "$i $::OFDMA::mod($i) "
			append switchlist "$i $::OFDMA::switch($i) "
			append ofdmacp "$i $::OFDMA::ofdmcp($i) "
			append ofdmarp "$i $::OFDMA::ofdmrp($i) "
			incr i
		}
		set ofdmaid [list 1 17 2 18]; set modlist [list 1 null 2 null]
		return "{$indexlist} {$ofdmaid} {$ofdmaspac} {$freqlow} {$frequp} {$symperfram} {$modlist} {$switchlist} {$ofdmacp} {$ofdmarp}"
	} 
	method get_mib {} {
		set ds [$ip sc_ds]
		set us [$ip sc_us]
		set allindex [snmp_walk -Oqf $ip $R $snmp_oid(docsIf31CmtsDsOfdmChanChannelId)]
		if {$allindex == ""} {return "getmib $ds $us"}
		set ofdm [$ip ofdmMib]
		set ofdma [$ip ofdmaMib]
		return "getmib $ds $us $ofdm $ofdma"
	}
	method sc_ds {} {
		set OIDIdxList [my get_index ds]
		# puts $OIDIdxList
		set i 1
		foreach x $OIDIdxList {
			set ::SC::DS::index($i) $x
			set ::SC::DS::freq($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIfDownChannelFrequency).$::SC::DS::index($i)]
			set ::SC::DS::mod($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIfDownChannelModulation).$::SC::DS::index($i)]
			set ::SC::DS::pow($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIfDownChannelPower).$::SC::DS::index($i)]
			set ::SC::DS::switch($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(ifAdminStatus).$::SC::DS::index($i)]
			append indexlist "$i $::SC::DS::index($i) "
			append freqlist "$i $::SC::DS::freq($i) "
			append modlist "$i $::SC::DS::mod($i) "
			append powlist "$i $::SC::DS::pow($i) "
			append switchlist "$i $::SC::DS::switch($i) "
			incr i
		}
		set ::SC::DS::Num [expr $i-1]
		return "{$indexlist} {$freqlist} {$modlist} {$powlist} {$switchlist}"
	}
	method sc_us {} {
		set OIDIdxList [my get_index us]
		# puts $OIDIdxList
		set i 1
		foreach x $OIDIdxList {
			set ::SC::US::index($i) $x
			set ::SC::US::freq($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIfUpChannelFrequency).$::SC::US::index($i)]
			set ::SC::US::profile($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIfUpChannelModulationProfile).$::SC::US::index($i)]
			set ::SC::US::pow($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIf3CmtsSignalQualityExtExpectedRxSignalPower).$::SC::US::index($i)]
			set ::SC::US::switch($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(ifAdminStatus).$::SC::US::index($i)]
			set ::SC::US::chwidth($i) [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIfUpChannelWidth).$::SC::US::index($i)]
			append indexlist "$i $::SC::US::index($i) "
			append freqlist "$i $::SC::US::freq($i) "
			append profilelist "$i $::SC::US::profile($i) "
			append powlist "$i $::SC::US::pow($i) "
			append switchlist "$i $::SC::US::switch($i) "
			append chwidthlist "$i $::SC::US::chwidth($i) "
			incr i
		}
		set ::SC::US::Num [expr $i-1]
		return "{$indexlist} {$freqlist} {$profilelist} {$powlist} {$switchlist} {$chwidthlist}"
	}
	method return0 {type} {
		if {$type == "DS"} {
			for {set i 1} {$i <= $::SC::DS::Num} {incr i} {
				set index $::SC::DS::index($i)
				my dsfrequency $index 0
			}
		} elseif {$type == "US"} {
			for {set i 1} {$i <= $::SC::US::Num} {incr i} {
				set index $::SC::US::index($i)
				my usfrequency $index 0
			}
		}
		return "Set $type 0"
	}
	method set_ds_freq {count lowf} {
		set value [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIfDownChannelWidth).$::SC::DS::index(1)]
		set x $lowf
		for {set s 1} {$s <= $count} {incr s} {
			set index $::SC::DS::index($s)
			my dsfrequency $index $x
			set x [expr $x+$value]
		}
		return "Set SC-DS"
	}
	method set_ds_power {count value} {
		for {set s 1} {$s <= $count} {incr s} {
			set index $::SC::DS::index($s)
			my dspower $index $value
		}
		return "Set DS Power"
	}
	method set_ds_mod {count value} {
		for {set s 1} {$s <= $count} {incr s} {
			set index $::SC::DS::index($s)
			my dsmod $index $value
		}
		return "Set DS Modulation"
	}
	method set_us_freq {count lowf} {
		set value [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIfUpChannelWidth).$::SC::US::index(1)]
		set x $lowf
		for {set s 1} {$s <= $count} {incr s} {
			set index $::SC::US::index($s)
			my usfrequency $index $x
			set x [expr $x+$value]
		}
		return "Set SC-US"
	}
	method set_us_power {count value} {
		for {set s 1} {$s <= $count} {incr s} {
			set index $::SC::US::index($s)
			my uspower $index $value
		}
		return "Set US Power"
	}
	method set_us_chwidth {count value} {
		for {set s 1} {$s <= $count} {incr s} {
			set index $::SC::US::index($s)
			my uschwidth $index $value
		}
		return "Set US Power"
	}
	method set_us_profile {count value} {
		for {set s 1} {$s <= $count} {incr s} {
			set index $::SC::US::index($s)
			my usprofile $index $value
		}
		return "Set US Profile"
	}
	method modifyds {col index value} {
		# puts "$W $R $sock $ip"
		switch -- $col {
			1 {catch {my output $index $value}; set value [my output $index]}
			2 {catch {my dsfrequency $index $value}; set value [my dsfrequency $index]}
			3 {catch {my dspower $index $value}; set value [my dspower $index]}
			4 {catch {my dsmod $index $value}; set value [my dsmod $index]}
			default {puts "no such $col"}
		}
		# puts "$col $index $value"
		return "cell $value"
	}
	method modifyus {col index value} {
		switch -- $col {
			1 {catch {my output $index $value}; set value [my output $index]}
			2 {catch {my usfrequency $index $value}; set value [my usfrequency $index]}
			3 {catch {my uspower $index $value}; set value [my uspower $index]}
			4 {catch {my uschwidth $index $value}; set value [my uschwidth $index]}
			5 {catch {my usprofile $index $value}; set value [my usprofile $index]}
			default {puts "no such $col"}
		}
		return "cell $value"
	}
	
	
	method quit {} {
		global CMTS
		set CMTS ""; return [list Reset setting] 
	}
	method help {} {
		return [lsort [info class methods CMTS]]
	}
}

proc range {start cutoff finish {step 1}} {
	if {[string is integer -strict $start] == 0 || [string is\
		integer -strict $finish] == 0} {
		error "range: Range must contain two integers"
	}
	if {$step == 0 || [string is integer -strict $step] == 0} {
		error "range: Step must be an integer other than zero"
	}
	switch $cutoff {
		"to" {set inclu 1}
		"no" {set inclu 0}
		default {
			error "range: Use \"to\" for an inclusive\
			range, or \"no\" for a noninclusive range"
		}
	}
	set up [expr {$start <= $finish}]
	if {$up == 0 && $step > 0 && [string first "+" $start] != 0} {
		set step [expr $step * -1]
	}
	set ranger [list]
	switch "$up $inclu" {
		"1 1" {set op "<="} 
		"1 0" {set op "<"}  
		"0 1" {set op ">="}
		"0 0" {set op ">"}
	}
	for {set i $start} "\$i $op $finish" {incr i $step} {lappend ranger $i}
	return $ranger
}
proc Sleep { msecs } {
	set wake 0
	after $msecs {set wake 1}
	vwait wake
	set wake 0
	update
}