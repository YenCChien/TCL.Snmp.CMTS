
oo::class create CMTS {
	variable R W ip sock
	method getVar {} {
		puts "R $R W $W ip $ip sock $sock"
	}
	method CallVar {} {
		puts "R $R W $W ip $ip sock $sock"
	}
	method call {} {
		my CallVar
	}
}

oo::class create CASA-C10G {
	variable R W ip sock
	mixin CMTS
	constructor {Read Write CMTS_ip CMTS_sock} {
		set R $Read; set W $Write; set ip $CMTS_ip; set sock $CMTS_sock
	}
	method setR {Var} {
		set R $Var
	}
	method setW {Var} {
		set W $Var
	}
	destructor {
		puts Bye~~C10
	}
}

oo::class create Huawei {
	variable R W ip sock
	mixin CMTS
	constructor {Read Write CMTS_ip CMTS_sock} {
		set R $Read; set W $Write; set ip $CMTS_ip; set sock $CMTS_sock
	}
	method setR {Var} {
		set R $Var
	}
	method setW {Var} {
		set W $Var
	}
	destructor {
		puts Bye~~Huawei
	}
}

CASA-C10 create 10.10.160.14 public private 10.10.160.14 sock0357
Huawei create 10.10.160.24 public00 private00 10.10.160.24 sock0357

10.10.160.14 destroy
10.10.160.24 destroy
