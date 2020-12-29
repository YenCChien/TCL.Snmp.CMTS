# example, ofdm 97(chanid) 50(spacing) 250.6(subc_zero) 258(low_freq) 448(up_freq) 278(plc) 256(cp) 128(rp) 64(ncp_mod)
# Apendix A >>>>> ofdm 97 1 50 250.6 258 448 278 256 128 64
# PHY30 part 1
# case 1 > ofdm 97 1 25 250.6 257 281 270 256 128 16
oo::class create MA5633 {
	variable array snmp_oid
	variable array tdma mtdma atdma scdma
	variable R W ip sock domain
	mixin CMTS
	constructor {Read Write CMTS_ip CMTS_sock} {
		####set basic parameter 
		set R $Read; set W $Write; set ip $CMTS_ip; set sock $CMTS_sock
		source snmp_oid.tcl

		set tdma(qpsk) ""; set tdma(16qam) ""
		set atdma(qpsk) 19; set atdma(8qam) ""; set atdma(16qam) 20; set atdma(32qam) 21; set atdma(64qam) 22
		set mtdma(qpsk) ""; set mtdma(8qam) ""; set mtdma(16qam) ""; set mtdma(32qam) ""; set mtdma(64qam) ""
		set scdma(qpsk) ""; set scdma(8qam) ""; set scdma(16qam) ""; set scdma(32qam) ""; set scdma(64qam) ""; set scdma(128qam) ""
		
		my get_domain_index
	}
	method ofdm {chid state spacing sub_zero low_freq up_freq plc_freq cp rp mod depth {ncp_mod 64}} { 
		# Channel status Must be shot down, else cannot modify parameter.
		if {$state == 1} {set state "enable"} else {set state "disable"}
		set FFTsize [expr 204.8/$spacing*1000]
		if {$chid == 97} {set index 2013274209}
		if {$chid == 98} {set index 2013274210}
		set sub_zero [expr round($sub_zero*1000000)]
		set low_freq [expr round($low_freq*1000000)]
		set up_freq [expr round($up_freq*1000000)]
		if {$plc_freq == 1} {set plc_freq [expr low_freq+($up_freq-$low_freq)/2]} else {set plc_freq [expr int($plc_freq*1000000)]}
		set cp [expr (1.0/$spacing*1000)*($cp.0/$FFTsize)]
		set rp [expr (1.0/$spacing*1000)*($rp.0/$FFTsize)]; if {$rp == 0.0} {set rp 0}
		catch {snmp_set -Oqv $ip $W $snmp_oid(ifAdminStatus).$index i 2}; # ofdm 1 = 2013274209 , ofdm 2 = 2013274210, (1) up (2) down
		promptwait $sock "interface cable 0/1/0" "#" 3
		# promptwait $sock "cable ofdm-downstream $chid disable" "#" 3
		# promptwait $sock " " "#" 3
		catch {promptwait $sock "cable ofdm-downstream $chid subcarrier-spacing $spacing\K subcarrier-zero-frequency $sub_zero\
						lower-frequency $low_freq upper-frequency $up_freq plc-frequency $plc_freq\
						cyclic-prefix $cp rolloff-period $rp ncp-modulation qam$ncp_mod\
						time-interleave-depth $depth $state" "#" 3} msg
		promptwait $sock "cable ofdm-downstream $chid profile 0 default-modulation qam$mod" "#" 3
		promptwait $sock "quit" "#" 3
		return [list log $msg]
	}
	method power {type chid level} {
		promptwait $sock "interface cable 0/1/0" "#" 3
		if {$type == "ofdm"} {
			set type "ofdm-downstream"
		} elseif {$type == "ofdma"} {
			set type "ofdma-upstream"
		}
		promptwait $sock "cable $type $chid rf-power $level" "#" 3
		catch {promptwait $sock " " "#" 3} msg
		promptwait $sock "quit" "#" 3
		return [list log $msg]
	}
	# example, ofdm 97(chanid) 50(spacing) 250.6(subc_zero) 258(low_freq) 448(up_freq) 256(cp) 128(rp)
	# Apendix A >>>>> ofdma 17 1 50 6.3 10 30 256 128 64 9
	# ofdma 17 1 50 4.3 8 100 256 128 64 9
	# K minimum = 6,  when spacing 25K, BW >=72 K maximum = 9, 48 <= BW <= 72 K maximum = 12, BW < 48 maximum = 18
	# 							   50K, BW >=72 K maximum = 18, 48 <= BW <= 72 K maximum = 24, BW < 48 maximum = 36
	method ofdma {chid state spacing sub_zero low_freq up_freq cp rp mod k} { ; # ofdma 1 = 1979719697 , ofdma 2 = 1979719698
		# Channel status must be shot down, else cannot modify parameter.
		if {$state == 1} {set state "enable"} else {set state "disable"}
		if {$spacing == 50} {set pilot 4} else {set pilot 8}
		set FFTsize [expr 102.4/$spacing*1000]
		if {$chid == 17} {set index 1979719697}
		if {$chid == 18} {set index 1979719698}
		set sub_zero [expr round($sub_zero*1000000)]
		set low_freq [expr round($low_freq*1000000)]
		set up_freq [expr round($up_freq*1000000)]
		set cp [expr (1.0/$spacing*1000)*($cp.0/$FFTsize)]
		set rp [expr (1.0/$spacing*1000)*($rp.0/$FFTsize)]; if {$rp == 0.0} {set rp 0}
		snmp_set -Oqv $ip $W $snmp_oid(ifAdminStatus).$index i 2; # ofdma 1 = 1979719697 , ofdma 2 = 1979719698 , (1) up (2) down
		# puts "profile $chid $spacing $pilot $mod"
		# profile $chid $spacing $pilot $mod
		promptwait $sock "interface cable 0/1/0" "#" 3
		puts "cable ofdma-upstream $chid subcarrier-spacing $spacing\K subcarrier-zero-frequency $sub_zero lower-frequency $low_freq upper-frequency $up_freq cyclic-prefix $cp rolloff-period $rp frame-size $k $state"
		catch {promptwait $sock "cable ofdma-upstream $chid subcarrier-spacing $spacing\K subcarrier-zero-frequency $sub_zero lower-frequency $low_freq upper-frequency $up_freq cyclic-prefix $cp rolloff-period $rp frame-size $k $state" "#" 3} msg
		promptwait $sock "quit" "#" 3
		return [list log $msg]
	}
	method enable {type chid} {
		promptwait $sock "interface cable 0/1/0" "#" 3
		if {$type == "ofdm"} {
			set type "ofdm-downstream"
			promptwait $sock "cable $type $chid enable" "#" 3
			catch {promptwait $sock " " "#" 3} msg
		} elseif {$type == "ofdma"} {
			set type "ofdma-upstream"
			promptwait $sock "cable $type $chid enable" "#" 3
			catch {promptwait $sock " " "#" 3} msg
		} else {
			catch {promptwait $sock "cable $type $chid enable" "#" 5} msg
			
		}
		promptwait $sock "quit" "#" 3
		if {$msg == ""} {return "Certain Channels cannot be opened"}
		return [list log $msg] 
	}
	method disable {type chid} {
		promptwait $sock "interface cable 0/1/0" "#" 3
		if {$type == "ofdm"} {
			set type "ofdm-downstream"
			promptwait $sock "cable $type $chid disable" "#" 3
			catch {promptwait $sock " " "#" 3} msg
		} elseif {$type == "ofdma"} {
			set type "ofdma-upstream"
			promptwait $sock "cable $type $chid disable" "#" 3
			catch {promptwait $sock " " "#" 3} msg
		} else {
			catch {promptwait $sock "cable $type $chid disable" "#" 5} msg
		}
		promptwait $sock "quit" "#" 3
		if {$msg == ""} {return "Certain Channels cannot be opened"}
		return [list log $msg]
	}
	# profile 17(channelid) 50(spacing) 4(pilot-pattern) 64(data-modulation) 256(other-modulation)
	# pilot-pattern 1~7 must be with 2KFFT size, and 8~14 with 4KFFT size.
	# example, profile 17 50 4 64 256
	method profile {chid spacing pilot_pattern data_modulation {other_modulation 64}} {
		if {$chid == 17} {set index 1979719697}
		if {$chid == 18} {set index 1979719698}
		snmp_set -Oqv $ip $W $snmp_oid(ifAdminStatus).$index i 2; # ofdma 1 = 1979719697 , ofdma 2 = 1979719698 , (1) up (2) down
		promptwait $sock "interface cable 0/1/0" "#" 3
		promptwait $sock "cable ofdma-upstream $chid subcarrier-spacing $spacing\K" "#" 3
		# promptwait $sock " " "#" 3
		promptwait $sock "cable ofdma-upstream $chid profile 1 iuc a-long default-minislot-pilot-pattern $pilot_pattern default-minislot-modulation qam$other_modulation" "#" 3
		promptwait $sock "cable ofdma-upstream $chid profile 1 iuc a-short default-minislot-pilot-pattern $pilot_pattern default-minislot-modulation qam$other_modulation" "#" 3
		promptwait $sock "cable ofdma-upstream $chid profile 1 iuc a-ugs default-minislot-pilot-pattern $pilot_pattern default-minislot-modulation qam$other_modulation" "#" 3
		if {$data_modulation != "QPSK"} {set mod qam$data_modulation} else {set mod $data_modulation}
		promptwait $sock "cable ofdma-upstream $chid profile 1 iuc data default-minislot-pilot-pattern $pilot_pattern default-minislot-modulation $mod" "#" 3
		promptwait $sock "cable ofdma-upstream $chid profile 1 iuc data-init default-minislot-pilot-pattern $pilot_pattern default-minislot-modulation $mod" "#" 3
		promptwait $sock "cable ofdma-upstream $chid profile 1 iuc long default-minislot-pilot-pattern $pilot_pattern default-minislot-modulation qam$other_modulation" "#" 3
		promptwait $sock "cable ofdma-upstream $chid profile 1 iuc short default-minislot-pilot-pattern $pilot_pattern default-minislot-modulation qam$other_modulation" "#" 3
	}
	method get_domain_index {} {
		set allindex [snmp_walk -Oqf $ip $R $snmp_oid(ifDescr)]
		set i 1
		foreach [list qqindex port] $allindex {
			set ss [lindex [split $qqindex "."] end]
			set aryindex($ss) $port
			# puts $aryindex($ss)
			if {[string first "Huawei-MA5633-V800R017-CABLE" $aryindex($ss)] >= "0"} {
				set domain($i) $ss
				puts "set domain($i) $ss"
				incr i
			}
		}
		set DomainList [array get domain]; set Domain_Num [expr [llength $DomainList]/2]
		puts $Domain_Num
		return $DomainList
	}
	method setUsPreEqualizer {in_domain in_state} {
		switch $in_state {1 {set state enable} 2 {set state disable} default {return [list 0 [Error in_State]]}}
		promptwait $sock "interface cable 0/1/0" "#" 3
		promptwait $sock "cable upstream pre-equalization $state" "#" 3
		promptwait $sock "quit" "#" 3
		return 1
	}
	method setUsModulation {domain profilenum} {
		set indexlist [my get_index us]
		foreach index $indexlist {
			catch {my usprofile $index $profilenum} msg
			if {[lindex $msg 0] == "0"} {return $msg} else {
				lappend msglist $msg
			}
		}
		return [list 1 $msglist]
	}
	method setUsNoiseCancellation {in_domain in_state} {
		return [list 0 "No such setting"]
	}
	method setUsChannelWidth {domain chwidth} {
		set indexlist [my get_index us]
		foreach index $indexlist {
			catch {my uschwidth $index $chwidth} msg
			if {[lindex $msg 0] == "0"} {return $msg} else {
				lappend msglist $msg
			}
		}
		return [list 1 $msglist]
	}
	method setQamModulation {in_Domain dsQam} {
		set indexlist [my get_index ds]
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
		puts $msg
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
		if {$in_annex == "A" || $in_annex == "B" || $in_annex == "C"} {} else {return [list 0 "Error Annex"]}
		if {$in_ds > 32} {return [list 0 "Error DS Channel Count"]}
		if {$in_us > 8} {return [list 0 "Error US Channel Count"]}
		set domain_dslist [my get_index ds] ; set domain_uslist [my get_index us]
		my disable downstream all; my disable upstream all
		foreach dsindex $domain_dslist usindex $domain_uslist {
			my dsmod $dsindex 4; my uschwidth $usindex 3200000; my usprofile $usindex [my quickSetUsProfile atdma qpsk]
		}
		switch $in_annex {"A" {set BW 8000000; set dsprofile 1} "B" {set BW 6000000; set dsprofile 3} default {return [list 0 "Error Get Annex"]}}
		set firstdsFrequency [my dsfrequency [lindex [my get_index ds] 0]]
		if {$firstdsFrequency == 0} {set firstdsFrequency 333000000}
		set firstusFrequency 7000000
		my disable ofdm 97; my disable ofdm 98
		my disable ofdma 17; my disable ofdma 18
		my return0 DS; my return0 US
		promptwait $sock "interface cable 0/1/0" "#" 3
		catch {promptwait $sock "cable downstream annex annex$type" "#" 3} msg
		promptwait $sock "cable bind frequency-profile $dsprofile" (y/n) 5
		promptwait $sock y "#" 5
		promptwait $sock "quit" "#" 3
		puts "setIpProvMode Setup"
		set checkProv [my setIpProvMode $in_Domain $in_ipProv]
		if {[lindex $checkProv 0] == 0} {return $checkProv}
		if {$in_ds > [llength $domain_dslist]} {return [list 0 "Over Downstream Port"]}
		if {$in_us > [llength $domain_uslist]} {return [list 0 "Over Upstream Port"]}
		puts "Frequency Setup"
		for {set i 0} {$i < $in_ds} {incr i} {
			set index [lindex $domain_dslist $i] ; set frequency [expr $firstdsFrequency+$BW*$i]
			if {[catch {my dsfrequency $index $frequency} msg]} {return [list 0 $msg]}
			puts "$i====ds"
		}
		for {set i 0} {$i < $in_us} {incr i} {
			set index [lindex $domain_uslist $i] ; set frequency [expr $firstusFrequency+3200000*$i]
			if {[catch {my usfrequency $index $frequency} msg]} {return [list 0 $msg]}
			puts "$i====us"
		}
		my enable downstream all; my enable upstream all
		set getfirstds [my dsfrequency [lindex $domain_dslist 0]]
		return [list 1 $getfirstds]
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
	method show {type {chid all}} {; #type = ofdm or ofdma
		switch $type {
			ofdm {set type ofdm-downstream}
			ofdma {set type ofdma-upstream}
			config {
				catch {promptwait $sock "display cable config 0/1/0" "#" 3} msg
				return [list log $msg]
			}
		}
		if {$type != "config"} {
			catch {promptwait $sock "display cable $type 0/1/0 $chid config" "#" 3} msg
			return [list log $msg]
		}
	}
	method ofdmapro {} {
		catch {promptwait $sock "display cable ofdma-upstream 0/1/0 all profile all iuc" "#" 3} msg
		return [list log $msg]
	}
	method annex {type} {
		my disable downstream all
		my disable upstream all
		my return0 DS
		promptwait $sock "interface cable 0/1/0" "#" 3
		catch {promptwait $sock "cable downstream annex annex$type" "#" 3} msg
		promptwait $sock "quit" "#" 3
		return [list log $msg]
	}
}
