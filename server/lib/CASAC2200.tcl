oo::class create CASA-C2200 {
	variable array domain domain_all_ds domain_all_us domain_port_ds domain_port_us snmp_oid
	variable dsportlist usportlist dsindexlist usindexlist
	variable array tdma mtdma atdma scdma Domain_Num
	variable W R ip sock
	mixin CMTS
	constructor {Read Write CMTS_ip CMTS_sock} {
		####set basic parameter 
		set R $Read; set W $Write; set ip $CMTS_ip; set sock $CMTS_sock
		source snmp_oid.tcl
		####get domain index
		my get_domain_index
		####get port & index list
		set dsportlist [my get_port ds]
		set usportlist [my get_port us]
		set dsindexlist [my get_index ds]
		set usindexlist [my get_index us]
		
		my getServiceGroup
		
		####search each type and qam profile, and create it if profile hadn't been created.
		if [catch {snmp_walk -Oqf $ip $R $snmp_oid(docsIfCmtsModControl)} msg] {return [list 0 $msg]}
		set AtvProfileList ""
		foreach [list OID status] $msg {
			# puts "$OID $status"
			set Atvnum [lindex [split $OID "."] end-1]
			if {[string first $Atvnum $AtvProfileList] < "0"} {lappend AtvProfileList $Atvnum}
		}
		set tdma(qpsk) ""; set tdma(16qam) ""
		set atdma(qpsk) ""; set atdma(8qam) ""; set atdma(16qam) ""; set atdma(32qam) ""; set atdma(64qam) ""
		set mtdma(qpsk) ""; set mtdma(8qam) ""; set mtdma(16qam) ""; set mtdma(32qam) ""; set mtdma(64qam) ""
		set scdma(qpsk) ""; set scdma(8qam) ""; set scdma(16qam) ""; set scdma(32qam) ""; set scdma(64qam) ""; set scdma(128qam) ""
		foreach profile $AtvProfileList {
			catch {promptwait $sock "show modulation-profile $profile" "#" 5} msg
			if {[lindex $msg [expr [lsearch $msg short]+1]] == "tdma"} {
				set type [lindex $msg [expr [lsearch $msg short]+1]]; set qam [lindex $msg [expr [lsearch $msg short]+2]]
			} else {
				set type [lindex $msg [expr [lsearch $msg a-short]+1]]; set qam [lindex $msg [expr [lsearch $msg a-short]+2]]
			}
			if {[lindex [array get $type $qam] 1] == ""} {array set $type [list $qam $profile]}
		}
		set AllProfileNum [range 1 to 100]
		set num 0
		foreach ss $AtvProfileList {set AllProfileNum [lsearch -all -inline -not -exact $AllProfileNum $ss]}
		set typelist [list tdma atdma mtdma scdma]
		foreach type $typelist {
			foreach [list qam profilenum] [array get $type] {
				if {$profilenum == ""} {
					catch {promptwait $sock "modulation-profile [lindex $AllProfileNum $num] $type $qam" "#" 5} msg
					array set $type [list $qam [lindex $AllProfileNum $num]]
					puts $msg
					promptwait $sock "exit" "#" 5
					incr num
				}
			}
		}
		puts "Create Profile End"
	}
	method putsss {domain type} {
		switch $type {
			ds {return "$domain_all_ds($domain) $domain_port_ds($domain)"}
			us {return "$domain_all_us($domain) $domain_port_us($domain)"}
		}
	}
	method getServiceGroup {} {
		set allGroup [string trim [lindex [my cmd "show service group"] 1] "show service group"]
		set GroupLocate [lsearch -all $allGroup group]
		foreach GroupID $GroupLocate {
			lappend GroupList [lindex $allGroup [expr $GroupID+1]]
		}
		set x 1 
		foreach Group $GroupList {
			set content [lrange [lindex [my cmd "show service group $Group"] 1] 7 end-1]
			foreach [list type port] $content {
				if {[string first qam $type] >= "0"} {lappend domain_port_ds($x) $port; lappend domain_all_ds($x) [my portindex ds $port]}
				if {[string first upstream $type] >= "0"} {lappend domain_port_us($x) $port; lappend domain_all_us($x) [my portindex us $port/0]}
			}
			incr x
		}
		return 1
	}
	method get_domain_index {} {
		set allindex [snmp_walk -Oqf $ip $R $snmp_oid(ifDescr)]
		foreach [list qqindex port] $allindex {
			set ss [lindex [split $qqindex "."] end]
			set aryindex($ss) $port
			# puts $aryindex($ss)
			if {[string first "CATV-MAC" $aryindex($ss)] >= "0"} {
				set domain([lindex $port end]) $ss
				puts "set domain([lindex $port end]) $ss"
			}
		}
		set DomainList [array get domain]; set Domain_Num [expr [llength $DomainList]/2]
		puts $DomainList
		puts $Domain_Num
	}
	method portindex {type args} {
		switch $type {
			ds {
				foreach dsport $dsportlist dsindex $dsindexlist {set dsportindex($dsport) $dsindex}
				foreach port $args {lappend portindex $dsportindex($port)}
			}
			us {
				foreach usport $usportlist usindex $usindexlist {set usportindex($usport) $usindex}
				foreach port $args {lappend portindex $usportindex($port)}
			}
			default {return [list 0 "Error Type!!"]}
		}
		return $portindex
	}
	method domain_index {num type} {
		if {$num > $Domain_Num || $num <= 0} {return [list 0 "No Such Domain"]}
		catch {promptwait $sock "show interface docsis-mac $num" "#" 3} msg
		set qq [split $msg \n]
		set cmdmsg "my portindex $type "
		switch $type {
			ds {
				foreach ss $qq {
					if {[string first "interface qam" $ss] >= "0"} {lappend cmdmsg [lindex $ss 4]}
				}
			}
			us {
				foreach ss $qq {
					if {[string first "interface upstream" $ss] >= "0"} {lappend cmdmsg [lindex $ss 4]}
				}
			}
			default {return [list 0 "Error Type!!"]}
		}
		return [eval $cmdmsg]
	}
	method domain_port {domain type} {
		if {$domain > $Domain_Num || $domain <= 0} {return [list 0 "No Such Domain"]}
		set indexlist [my domain_index $domain $type]
		switch $type {
			ds {
					foreach [list f1 f2 f3 f4] $indexlist {lappend getlist $f1}
					foreach index $getlist {
						set portindex [string range [lindex [snmp_get -Oqv $ip $R $snmp_oid(ifDescr).$index] 0 1] 0 end-2]
						lappend domainPortList $portindex
					}
				}
			us {
				foreach index $indexlist {
					set portindex [string range [lindex [snmp_get -Oqv $ip $R $snmp_oid(ifDescr).$index] 0 end] 0 end-2]
					lappend domainPortList $portindex
				}
			}
			default {return [list 0 "Error Type!!"]}
		}
		return $domainPortList
	}
	method setUsPreEqualizer {in_domain in_state} {
		switch $in_state {1 {set state "logical-channel 0 pre-equalization"} 2 {set state "no logical-channel 0 pre-equalization"} default {return [list 0 [Error in_State]]}}
		set domain_port [my domain_port $in_domain us]
		puts $domain_port
		foreach port $domain_port {
			promptwait $sock "interface upstream $port" "#" 3
			puts "interface upstream $port"
			promptwait $sock "$state" "#" 3
			puts "$state"
			promptwait $sock "exit" "#" 3
			puts exit
		}
		return 1
	}
	method setUsModulation {domain profilenum} {
		set indexlist [my domain_index $domain us]
		foreach index $indexlist {
			catch {my usprofile $index $profilenum} msg
			if {[lindex $msg 0] == "0"} {return $msg} else {
				lappend msglist $msg
			}
		}
		return [list 1 $msglist]
	}
	method setUsNoiseCancellation  {in_domain in_state} {
		switch $in_state {1 {set state "ingress-cancellation"} 2 {set state "no ingress-cancellation"} default {return [list 0 [Error in_State]]}}
		set domain_port [my domain_port $in_domain us]
		puts $domain_port
		foreach port $domain_port {
			promptwait $sock "interface upstream $port" "#" 3
			promptwait $sock "$state" "#" 3
			promptwait $sock "exit" "#" 3
		}
		return 1
	}
	method setUsChannelWidth {domain chwidth} {
		set indexlist [my domain_index $domain us]
		foreach index $indexlist {
			catch {my uschwidth $index $chwidth} msg
			if {[lindex $msg 0] == "0"} {return $msg} else {
				lappend msglist $msg
			}
		}
		return [list 1 $msglist]
	}
	method setQamModulation {in_Domain dsQam} {
		set indexlist [my domain_index $in_Domain ds]
		foreach index $indexlist {
			# catch {my output $index 2} msg
			catch {my dsmod $index $dsQam} msg
			if {[lindex $msg 0] == "0"} {return $msg} else {
				lappend msglist $msg
			}
		}
		return [list 1 $msglist]
	}
	method quickSetUsProfile {type qam} {
		catch {lindex [array get $type $qam] 1} msg
		if {$msg == ""} {return [list 0 "no such array"]}
		return [list 1 $msg]
	}
	method setIpProvMode {in_Domain in_IpProvMode} {
		if {[catch {snmp_set -Oqv $ip $W $snmp_oid(docsIf3MdCfgIpProvMode).$domain($in_Domain) i $in_IpProvMode} msg]} {
			return [list 0 $msg]
		} else {
			return [list 1 $msg]
		}
	}
	method quickSet {in_Domain in_annex in_ipProv in_ds in_us} {
		if {$in_Domain > $Domain_Num || $in_Domain <= 0} {return [list 0 "No Such Domain"]}
		if {$in_annex == "A" || $in_annex == "B" || $in_annex == "C"} {} else {return [list 0 "Error Annex"]}
		if {$in_ds > 32} {return [list 0 "Error DS Channel Count"]}
		if {$in_us > 8} {return [list 0 "Error US Channel Count"]}
		########### Modify docsis-mac contents
		 if [catch {my createDomain $in_Domain $in_ds $in_us}] {return [list 0 "createDomain $in_Domain $in_ds $in_us Fail!"]}
		set domain_port [my domain_port $in_Domain ds] 
		foreach port $domain_port {
			promptwait $sock "interface qam $port" "#" 3
			promptwait $sock "annex $in_annex" "#" 3
			puts "$port Annex$in_annex"
			promptwait $sock "exit" "#" 3
		}
		set domain_dslist [lrange $domain_all_ds($in_Domain) 0 [expr $in_ds-1]] ; set domain_uslist [lrange $domain_all_us($in_Domain) 0 [expr $in_us-1]]
		set getAnnex [snmp_get -t 1 -r 0 -Oqv $ip $R $snmp_oid(docsIf3MdCfgDownChannelAnnex).$domain($in_Domain)]
		switch $getAnnex {3 {set BW 8000000} 4 {set BW 6000000} default {return [list 0 "Error Get Annex"]}}
		set firstdsFrequency [my dsfrequency 333000000]
		set firstusFrequency 7000000
		puts "setIpProvMode Setup"
		set checkProv [my setIpProvMode $in_Domain $in_ipProv]
		if {[lindex $checkProv 0] == 0} {return $checkProv}
		puts "[llength $domain_dslist]  [llength $domain_uslist]"
		if {$in_ds > [llength $domain_dslist]} {return [list 0 "Over Downstream Port"]}
		if {$in_us > [llength $domain_uslist]} {return [list 0 "Over Upstream Port"]}
		puts "Frequency Setup"
		for {set i 0} {$i < $in_ds} {incr i} {
			set index [lindex $domain_dslist $i] ; set frequency [expr $firstdsFrequency+$BW*$i]
			if {[catch {my dsfrequency $index $frequency} msg]} {return [list 0 $msg]}
			if {[catch {my output $index 1} msg]} {return [list 0 $msg]}
		}
		for {set i 0} {$i < $in_us} {incr i} {
			set index [lindex $domain_uslist $i] ; set frequency [expr $firstusFrequency+3200000*$i]
			if {[catch {my usfrequency $index $frequency} msg]} {return [list 0 $msg]}
			if {[catch {my output $index 1} msg]} {return [list 0 $msg]}
		}
		set getfirstds [my dsfrequency [lindex $domain_dslist 0]]
		return [list 1 $getfirstds]
	}
	method resetDutByCmts {in_cmip} {
		catch {promptwait $sock "clear cable modem $in_cmip reset" "#" 3} msg
		puts $msg
		if {[string first "no such cm!" $msg] < 0} {return [list 0 $msg]}
		if {[string first "Syntax Error" $msg] < 0} {return [list 0 $msg]}
		return 1
	}
	method getDutIndex {in_cmip} {
		if [catch {snmp_walk -v 2c -O bsqe -t 15 -I r -m all -r 0 -c $R $ip $snmp_oid(docsIf3CmtsCmRegStatusIPv4Addr)} Query_CMIndex] {
			return [list 0 "Error get docsIf3CmtsCmRegStatusIPv4Addr"]
		}
		foreach [list OID MAC] $Query_CMIndex { 
			set DecIP ""
			foreach Dec $MAC {
				append DecIP [format %i 0x$Dec].
			}
			set DecIP [string range $DecIP 0 end-1]
			set index [lindex [split $OID .] end]
			if {[string equal $DecIP $in_cmip]} {return [list 1 $index]}
		}
		return [list 0 "No Such Index!!"]
	}
	method chkDutStatus {in_cm_index} {
		if [catch {snmp_get -v 2c -c $R -O qv -r 1 -t 1 $ip $snmp_oid(docsIfCmtsCmStatusValue).$in_cm_index} msg] {
			return [list 0 $msg]
		}
		switch $msg {
			1 {set msg other} 2 {set msg ranging} 3 {set msg rangingAborted} 4 {set msg rangingComplete}
			5 {set msg ipComplete} 6 {set msg registrationComplete} 7 {set msg accessDenied} 8 {set msg operational}
			9 {set msg registeredBPIInitializing}
		}
		return [list 1 $msg]
	}
	method createDomain {in_Domain in_ds in_us} {
		set domain_dslist $domain_all_ds($in_Domain) ; set domain_uslist $domain_all_us($in_Domain)
		foreach dsindex $domain_dslist usindex $domain_uslist {
			my output $dsindex 2; my output $usindex 2
			my dsmod $dsindex 4; my uschwidth $usindex 3200000; my usprofile $usindex [my quickSetUsProfile atdma qpsk]
		}
		if { ![lindex [set ret [my deleteMdChRowStatus $in_Domain]] 0] } {return [list 0 [lrange $ret 1 end]]}
		if { ![lindex [set ret [my deleteRccAndBgConfigs $in_Domain]] 0] } {return [list 0 [lrange $ret 1 end]]}
		
		set getDsList [lrange $domain_dslist 0 [expr $in_ds-1]]; set getUsList [lrange $domain_uslist 0 [expr $in_us-1]]
		set i 1
		foreach index $getDsList {
			if {$i > $in_ds} {break}
			puts $index
			if {[catch {snmp_set -t 1 -r 3 -Ov -c $W $ip $snmp_oid(ifAdminStatus).$index i 1} err]} {
				return [list 0 "Set DS QAM $index FAIL! $err"]
			}
			if {[catch {snmp_set -t 1 -r 3 -Obsqx -c $W $ip $snmp_oid(docsIf3MdChCfgRowStatus).$domain($in_Domain).$index i 4} err]} {
				return [list 0 "Set DS QAM $index FAIL! $err"]
			}
			if {[catch {snmp_set -t 1 -r 3 -Ov -c $W $ip $snmp_oid(docsIf3MdChCfgIsPriCapableDs).$domain($in_Domain).$index i 1} err]} {
				return [list 0 "Set DS QAM $index FAIL! $err"]
			}
			if {[catch {snmp_set -t 1 -r 3 -Ov -c $W $ip $snmp_oid(docsIf3MdChCfgChId).$domain($in_Domain).$index u $i} err]} {
				return [list 0 "Set DS QAM $index FAIL! $err"]
			}
			if {[catch {snmp_set -t 1 -r 3 -Ov -c $W $ip $snmp_oid(docsIf3MdChCfgSfProvAttrMask).$domain($in_Domain).$index x 00000000} err]} {
				return [list 0 "Set DS QAM $index FAIL! $err"]
			}
			incr i
		}
		set i 1
		foreach index $getUsList {
			puts $index
			if {[catch {snmp_set -t 1 -r 3 -Ov -c $W $ip $snmp_oid(ifAdminStatus).$index i 1} err]} {
				return [list 0 "Set Upstream $index FAIL! $err"]
			}
			if {[catch {snmp_set -t 1 -r 3 -Obsqx -c $W $ip $snmp_oid(docsIf3MdChCfgRowStatus).$domain($in_Domain).$index i 4} err]} {
				return [list 0 "Set US QAM $index FAIL! $err"]
			}
			# if {[catch {snmp_set -t 1 -r 3 -Ov -c $W $ip $snmp_oid(docsIf3MdChCfgIsPriCapableDs).$domain($in_Domain).$index i 2} err]} {
				# return [list 0 "Set US QAM $index FAIL! $err"]
			# }
			if {[catch {snmp_set -t 1 -r 3 -Ov -c $W $ip $snmp_oid(docsIf3MdChCfgChId).$domain($in_Domain).$index u $i} err]} {
				return [list 0 "Set US QAM $index FAIL! $err"]
			}
			if {[catch {snmp_set -t 1 -r 3 -Ov -c $W $ip $snmp_oid(docsIf3MdChCfgSfProvAttrMask).$domain($in_Domain).$index x 00000000} err]} {
				return [list 0 "Set US QAM $index FAIL! $err"]
			}
			incr i
		}

		if {![lindex [set ret [my setDocsIf3MdCfg $in_Domain]] 0]} {
			return [list 0 "Set Default DocsIf3MdCfg FAIL! [lrange $ret 1 end]"]
		}
		if {$in_ds > "1" || $in_us > "1"} {
			if {![lindex [set ret [my setRccAndBgConfig $in_Domain $in_ds $in_us]] 0]} {
				return [list 0 "Set RCC & Bonding Groups FAIL! [lrange $ret 1 end]"]
			}
		}
		return 1
	}
	method deleteMdChRowStatus {in_Domain} {
		Sleep 10
		set retVal [catch {snmp_walk -O bsqe -c $R $ip $snmp_oid(docsIf3MdChCfgRowStatus).$domain($in_Domain)} ret]
		if {$retVal} {
			return [list 0 $ret] 
		}
		if {$ret != ""} {
			foreach [list OID value] $ret {
				Sleep 10
				set retVal [catch {snmp_set -v 2c -Ov -c $W -r 3 -t 1 $ip $OID i 6} ret]
				if {$retVal} {
					return [list 0 $ret] 
				}
			}
		}
		return 1
	}
	method deleteRccAndBgConfigs {in_Domain} {
		set retVal [catch {snmp_walk -O bsqe -c $R $ip $snmp_oid(docsIf3RccCfgRowStatus).$domain($in_Domain)} ret]
		if {$retVal} {
			return [list 0 "Walk docsIf3RccCfgRowStatus.$domain($in_Domain) FAIL! $ret"]
		}
		if {$ret != ""} {
			foreach [list OID value] $ret {
				puts $OID
				set retVal [catch {snmp_set -v 2c -Ov -c $R -r 3 -t 1 $ip $OID i 6} ret]
				if {$retVal} {return [list 0 $ret]}
			}
		}
		promptwait $sock "no bonding-group downstream mac-domain $in_Domain group-id $in_Domain" "#"
		catch {promptwait $sock "no bonding-group upstream mac-domain $in_Domain group-id $in_Domain" "#"} msg
		if {[string first "config" $msg] < 0} {promptwait $sock "exit" "#"}
		return 1
	}
	method setDocsIf3MdCfg {in_Domain} {
		set OIDName_list [list docsIf3MdCfgMddInterval docsIf3MdCfgCmStatusEvCtlEnabled docsIf3MdCfgUsFreqRange docsIf3MdCfgMcastDsidFwdEnabled \
			docsIf3MdCfgMultRxChModeEnabled docsIf3MdCfgMultTxChModeEnabled docsIf3MdCfgEarlyAuthEncrCtrl docsIf3MdCfgTftpProxyEnabled \
			docsIf3MdCfgSrcAddrVerifEnabled docsIf3MdCfgCmUdcEnabled docsIf3MdCfgSendUdcRulesEnabled]
		set OID_Syntax	[list u i i i i i i i i i i]
		set OID_value	[list 2000 2 0 1 1 1 1 2 2 2 2]
		foreach OID_name $OIDName_list Syntax $OID_Syntax value $OID_value {
			if {[catch {snmp_set -t 1 -r 3 -Ov -c $W $ip $snmp_oid($OID_name).$domain($in_Domain) $Syntax $value} err]} {
				return [list 0 "Set MAC Domain $domain($in_Domain) $OID_name FAIL! $err"]
			}
		}
		return 1
	}
	method setRccAndBgConfig {in_Domain in_ds in_us} {
		if { ![lindex [set ret [my createRcc $in_Domain $in_ds]] 0] } {
			return [list 0 [lrange $ret 1 end]]
		}
		Sleep 100
		if { ![lindex [set ret [my setBondingGroups $in_Domain $in_ds $in_us]] 0] } {
			return [list 0 [lrange $ret 1 end]]
		}
		Sleep 100
		return 1
	}
	
	method createRcc {in_Domain in_ds} {
		set rcpChanNum $in_ds
		set rccChanList [lrange $domain_all_ds($in_Domain) 0 [expr $in_ds-1]]
		foreach rcpId [list "0.16.0.16" "0.16.0.0"] spac {8 6} desc [list "casa-EU-$rcpChanNum" "casa-NA-$rcpChanNum"] { 
			set rcIndex $domain($in_Domain).$rcpId.$rcpChanNum.1
			set rmFreq 333000000
			set retVal [catch {snmp_set -v 2c -Obsqx -c $W -r 3 -t 1 $ip $snmp_oid(docsIf3RccCfgRowStatus).$rcIndex i 4} ret]
			if {$retVal} {return [list 0 "Creating RCC FAIL! $ret"]}
			set retVal [catch {snmp_set -v 2c -Obsqx -c $W -r 3 -t 1 $ip $snmp_oid(docsIf3RccCfgDescription).$rcIndex s $desc} ret]
			if {$retVal} {return [list 0 "Creating RCC FAIL! $ret"]}
			
			set rcId 0
			foreach rccChan $rccChanList {
				incr rcId
				puts $rcId
				if {$rcId == 1} { set primary 1 } else { set primary 2 }
				set retVal [catch {snmp_set -v 2c -Obsqx -c $W -r 3 -t 1 $ip $snmp_oid(docsIf3RxChCfgRowStatus).$rcIndex.$rcId i 4} ret]
				if {$retVal} {return [list 0 "Creating RCC FAIL! $ret"]}
				set retVal [catch {snmp_set -v 2c -Obsqx -c $W -r 3 -t 1 $ip $snmp_oid(docsIf3RxChCfgChIfIndex).$rcIndex.$rcId i $rccChan} ret]
				if {$retVal} {return [list 0 "Creating RCC FAIL! $ret"]}
				set retVal [catch {snmp_set -v 2c  -Obsqx -c $W -r 3 -t 1 $ip $snmp_oid(docsIf3RxChCfgPrimaryDsIndicator).$rcIndex.$rcId i $primary} ret]
				if {$retVal} {return [list 0 "Creating RCC FAIL! $ret"]}
				set retVal [catch {snmp_set -v 2c -Obsqx -c $W -r 3 -t 1 $ip $snmp_oid(docsIf3RxChCfgRcRmConnectivityId).$rcIndex.$rcId u 1} ret]
				if {$retVal} {return [list 0 "Creating RCC FAIL! $ret"]}
			}
			set retVal [catch {snmp_set -v 2c -Obsqx -c $W -r 3 -t 1 $ip $snmp_oid(docsIf3RxModuleCfgRowStatus).$rcIndex.1 i 4} ret]
			if {$retVal} {return [list 0 "Creating RCC FAIL! $ret"]}
			set retVal [catch {snmp_set -v 2c -Obsqx -c $W -r 3 -t 1 $ip $snmp_oid(docsIf3RxModuleCfgFirstCenterFrequency).$rcIndex.1 u $rmFreq} ret]
			if {$retVal} {return [list 0 "Creating RCC FAIL! $ret"]}
		}
		return 1
	}	
	method setBondingGroups {in_Domain in_ds in_us} {
		set DsBondGrpList [lrange $domain_port_ds($in_Domain) 0 [expr $in_ds-1]]
		set UsBondGrpList [lrange $domain_port_us($in_Domain) 0 [expr $in_us-1]]
		promptwait $sock "bonding-group downstream mac-domain $in_Domain group-id $in_Domain" "#" 3
		foreach ds $DsBondGrpList {promptwait $sock "qam $ds" "#" 3}
		promptwait $sock "bonding-group upstream mac-domain $in_Domain group-id $in_Domain" "#" 3
		foreach us $UsBondGrpList {promptwait $sock "upstream $us" "#" 3}
		promptwait $sock "exit" "#"
		return 1
	}	
	method getDutV4Ip {in_cm_index} {
		if [catch {snmp_get -v 2c -Oqv -c $R -t 1 -r 0 $ip $snmp_oid(docsIf3CmtsCmRegStatusIPv4Addr).$in_cm_index} ret] {
			return [list 0 $ret]
		} else {
	
	if {[string first "No Such Instance currently exists" $ret] == 0} {return [list 0 $ret]}
			foreach Dec [lindex $ret 0] {append DecIP [format %i 0x$Dec].}
			set DecIP [string range $DecIP 0 end-1]
			return [list 1 $DecIP]
		}
	}
	method getDutV6Ip {in_cm_index} {
		# docsIf3CmtsCmRegStatusIPv6LinkLocal
		if [catch {snmp_get -v 2c -Oqv -c $R -t 1 -r 0 $ip $snmp_oid(docsIf3CmtsCmRegStatusIPv6Addr).$in_cm_index} ret] {
			return [list 0 $ret]
		} else {
			if {[string first "No Such Instance currently exists" $ret] >= 0} {return [list 0 $ret]}
			set CheckIP ""
			foreach [list DecIPv6_1 DecIPv6_2] [lindex $ret 0] {
				if {$DecIPv6_1 == "00" && $DecIPv6_2 == "00"} {append IPv6 0:} else {
					set IPv6Str $DecIPv6_1$DecIPv6_2
					for {set i 0} {$i < 4} {incr i} {
						if {[string index $IPv6Str $i] == 0} {
							set CheckIP [expr $i+1]
						} else {break}
					}
					if {$CheckIP != ""} {set IPv6Str [string range $IPv6Str $CheckIP end]}
					append IPv6 $IPv6Str:
				}
			}
			set IPv6 [string range $IPv6 0 end-1]
			return [list 1 $IPv6]
		}
	}
}

	