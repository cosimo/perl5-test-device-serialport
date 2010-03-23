use lib '.','./t','./lib','../lib','..';
# can run from here or distribution base

use Test::More;
plan tests => 131;

## some online discussion of issues with use_ok, so just sanity check
cmp_ok($AltPort::VERSION, '>=', 0.03, 'VERSION check');

# USB and virtual ports can't test output timing, first fail will set this
my $BUFFEROUT=0;

use AltPort qw( :STAT 0.03 );

use strict;
use warnings;

## verifies the (0, 1) list returned by binary functions
sub test_bin_list {
    return undef unless (@_ == 2);
    return undef unless (0 == shift);
    return undef unless (1 == shift);
    return 1;
}

sub is_zero {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return ok(shift == 0, shift);
}

sub is_bad {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return ok(!shift, shift);
}

# assume a "vanilla" port on "COM1" to check alias and device

my $file = "COM1";

my $cfgfile = "$file"."_test.cfg";
my $tstlock = "$file"."_lock.cfg";
$cfgfile =~ s/.*\///;
$tstlock =~ s/.*\///;

my $fault = 0;
my $ob;
my $pass;
my $fail;
my $in;
my $in2;
my @opts;
my $out;
my $err;
my $blk;
my $e;
my $tick;
my $tock;
my %required_param;
my @necessary_param = AltPort->set_test_mode_active(1);

unlink $cfgfile;
foreach $e (@necessary_param) { $required_param{$e} = 0; }

## 2 - 4 SerialPort Global variable ($Babble);


# 19: Constructor

ok($ob = AltPort->new ($file), "new $file");
die unless ($ob);    # next tests would die at runtime

# 5 - 18: object debug method

is_bad( scalar $ob->debug(), 'object debug init');
ok( scalar $ob->debug("T"), 'T' );
ok( scalar $ob->debug(), 'read debug state' );
is_bad( scalar $ob->debug("2"), 'invalid debug turns off' );
is_bad( scalar $ob->debug(), 'confirm off' );

@opts = $ob->debug();
ok(test_bin_list(@opts), 'binary_opt_array');

#### 20 - 38: Check Port Capabilities 

ok($ob->can_baud, 'can_baud');
ok($ob->can_databits, 'can_databits');
ok($ob->can_stopbits, 'can_stopbits');
ok($ob->can_dtrdsr, 'can_dtrdsr');
ok($ob->can_handshake, 'can_handshake');
ok($ob->can_parity_check, 'can_parity_check');
ok($ob->can_parity_config, 'can_parity_config');
ok($ob->can_parity_enable, 'can_parity_enable');
ok($ob->can_rtscts, 'can_ctsrts');
ok($ob->can_xonxoff, 'can_xonxoff');
ok($ob->can_total_timeout, 'can_total_timeout');
ok($ob->can_xon_char, 'can_xon_char');

is_zero($ob->can_spec_char, 'can_spec_char');
is_zero($ob->can_16bitmode, 'can_16bitmode');

if ($^O eq 'MSWin32') {
	ok($ob->can_rlsd, 'can_rlsd');
	ok($ob->can_interval_timeout, 'can_interval_timeout');
	is_zero($ob->can_ioctl, 'can_ioctl');
	is($ob->device, '\\\\.\\'.$file, 'Win32 device');
} else {
	is_zero($ob->can_rlsd, 'can_rlsd');
	is_zero($ob->can_interval_timeout, 'can_interval_timeout');
	ok($ob->can_ioctl, 'can_ioctl');
	is($ob->alias, $file, 'device not implemented');
}
is($ob->alias, $file, 'alias init');
ok($ob->is_rs232, 'is_rs232');
is_zero($ob->is_modem, 'is_modem');

#### 40 - 95: Set Basic Port Parameters 

## 26 - 45: Baud (Valid/Invalid/Current)

@opts=$ob->baudrate;		# list of allowed values
ok(1 == grep(/^9600$/, @opts), '9600 baud in list');
ok(0 == grep(/^9601/, @opts), '9601 baud not in list'); # force scalar context

ok($in = $ob->baudrate, 'read baudrate');
### warn "WCB: $in\n";
### warn Dumper \@opts;
ok(1 == grep(/^$in$/, @opts), "confirm $in in baud array");
is_bad(scalar $ob->baudrate(9601), 'cannot set 9601 baud');
ok($ob->baudrate(9600), 'can set 9600 baud');
    # leaves 9600 pending

## 46 - 51: Parity (Valid/Invalid/Current)

@opts=$ob->parity;		# list of allowed values
ok(1 == grep(/none/, @opts), 'parity none in list');
ok(0 == grep(/any/, @opts), 'parity any not in list');

ok($in = $ob->parity, 'read parity');
ok(1 == grep(/^$in$/, @opts), "confirm $in in parity array");

is_bad(scalar $ob->parity("any"), 'cannot set any parity');
ok($ob->parity("none"), 'can set none parity');
    # leaves "none" pending

## 52 - 57: Databits (Valid/Invalid/Current)

@opts=$ob->databits;		# list of allowed values
ok(1 == grep(/8/, @opts), '8 databits in list');
ok(0 ==  grep(/4/, @opts), '4 databits not in list');

ok($in = $ob->databits, 'read databits');
ok(1 == grep(/^$in$/, @opts), 'confirm $in databits in list');

is_bad(scalar $ob->databits(3), 'cannot set 3 databits');
ok($ob->databits(8), 'can set 8 databits');
    # leaves 8 pending

## 58 - 63: Stopbits (Valid/Invalid/Current)

@opts=$ob->stopbits;		# list of allowed values
ok(1 == grep(/2/, @opts), '2 stopbits in list');
ok(0 == grep(/1.5/, @opts), '1.5 stopbits not in list');

ok($in = $ob->stopbits, 'read stopbits');
ok(1 == grep(/^$in$/, @opts), "confirm $in stopbits in list");

is_bad(scalar $ob->stopbits(3), 'cannot set 3 stopbits');
ok($ob->stopbits(1), 'can set 1 stopbit');
    # leaves 1 pending

## 64 - 69: Handshake (Valid/Invalid/Current)

@opts=$ob->handshake;		# list of allowed values
ok(1 == grep(/none/, @opts), 'handshake none in list');
ok(0 ==  grep(/moo/, @opts), 'handshake moo not in list');

ok($in = $ob->handshake, 'read handshake');
ok(1 == grep(/^$in$/, @opts), "confirm handshake $in in list");

is_bad(scalar $ob->handshake("moo"), 'cannot set handshake moo');
ok($ob->handshake("rts"), 'can set handshake rts');

## 70 - 76: Buffer Size

($in, $out) = $ob->buffer_max(512);
is_bad(defined $in, 'invalid buffer_max command');
($in, $out) = $ob->buffer_max;
ok(defined $in, 'read in buffer_max');
ok(defined $out, 'read out buffer_max');

if (($in > 0) and ($in < 4096))		{ $in2 = $in; } 
else					{ $in2 = 4096; }

if (($out > 0) and ($out < 4096))	{ $err = $out; } 
else					{ $err = 4096; }

ok(scalar $ob->buffers($in2, $err), 'valid set buffer_max');

@opts = $ob->buffers(4096, 4096, 4096);
is_bad(defined $opts[0], 'invalid buffers command');
($in, $out)= $ob->buffers;
ok($in2 == $in, 'check buffers in setting');
ok($out == $err, 'check buffers out setting');

## 77 - 80: Other Parameters (Defaults)

is($ob->alias("TestPort"), 'TestPort', 'alias');
is_zero(scalar $ob->parity_enable(0), 'parity disable');
ok($ob->write_settings, 'write_settings');
ok($ob->binary, 'binary');

## 81 - 82: Read Timeout Initialization

is_zero(scalar $ob->read_const_time, 'read_const_time');
is_zero(scalar $ob->read_char_time, 'read_char_time');

## 83 - 89: No Handshake, Polled Write

is($ob->handshake("none"), 'none', 'set handshake for write');

$e="testing is a wonderful thing - this is a 60 byte long string";
#   123456789012345678901234567890123456789012345678901234567890
my $line = "\r\n$e\r\n$e\r\n$e\r\n";	# about 195 MS at 9600 baud

$tick=$ob->get_tick_count;
$pass=$ob->write($line);
$tock=$ob->get_tick_count;

ok($pass == 188, 'write character count');
$err=$tock - $tick;
unless ($ob->can_write_done() && $err > 120) {
	$BUFFEROUT = 1;	# USB and virtual ports can't test output timing
}
if ($BUFFEROUT) {
	ok (1, 'skip write timeout');
} else {
	is_bad (($err < 120) or ($err > 300), 'write timing');
}
print "<195> elapsed time=$err\n";

ok(scalar $ob->purge_tx, 'purge_tx');
ok(scalar $ob->purge_rx, 'purge_rx');
ok(scalar $ob->purge_all, 'purge_all');

## 90 - 95: Optional Messages

@opts = $ob->user_msg;
ok(test_bin_list(@opts), 'user_msg_array');
is_zero(scalar $ob->user_msg, 'user_msg init OFF');
ok(1 == $ob->user_msg(1), 'user_msg_ON');

@opts = $ob->error_msg;
ok(test_bin_list(@opts), 'error_msg_array');
is_zero(scalar $ob->error_msg, 'error_msg init OFF');
ok(1 == $ob->error_msg(1), 'error_msg_ON');

## 96 - 164: Save and Check Configuration

ok(scalar $ob->save($cfgfile), 'save');

is($ob->baudrate, 9600, 'baudrate');
is($ob->parity, 'none', 'parity');

is($ob->databits, 8, 'databits');
is($ob->stopbits, 1, 'stopbits');


ok (300 == $ob->read_const_time(300), 'read_const_time');
ok (20 == $ob->read_char_time(20), 'read_char_time');

## 131 - 145: Output bits and pulses

    ok ($ob->dtr_active(0), 'dtr inactive');
    $tick=$ob->get_tick_count;
    ok ($ob->pulse_dtr_on(100), 'pulse_dtr_on');
    $tock=$ob->get_tick_count;
    $err=$tock - $tick;
    is_bad (($err < 180) or ($err > 265), 'dtr pulse timing');
    print "<200> elapsed time=$err\n";
    
    ok ($ob->dtr_active(1), 'dtr active');
    $tick=$ob->get_tick_count;
    ok ($ob->pulse_dtr_off(200), 'pulse_dtr_off');
    $tock=$ob->get_tick_count;
    $err=$tock - $tick;
    is_bad (($err < 370) or ($err > 485), 'dtr pulse timing');
    print "<400> elapsed time=$err\n";
   
    SKIP: {
        skip "Can't RTS", 7 unless $ob->can_rtscts();
	
	ok ($ob->rts_active(0), 'rts inactive');
    	$tick=$ob->get_tick_count;
	ok ($ob->pulse_rts_on(150), 'pulse rts on');
	$tock=$ob->get_tick_count;
	$err=$tock - $tick;
	is_bad (($err < 275) or ($err > 365), 'pulse rts timing');
	print "<300> elapsed time=$err\n";
    
	ok ($ob->rts_active(1), 'rts active');
	$tick=$ob->get_tick_count;
	ok ($ob->pulse_rts_off(50), 'pulse rts off');
	$tock=$ob->get_tick_count;
	$err=$tock - $tick;
	is_bad (($err < 80) or ($err > 145), 'pulse rts timing');
	print "<100> elapsed time=$err\n";

	ok ($ob->rts_active(0), 'reset rts inactive');
    }
    
    ok ($ob->dtr_active(0), 'reset dtr inactive');
    is($ob->handshake("rts"), 'rts', 'set handshake');

## 146 - 152: Write Status

    SKIP: {
        skip "Can't test status of buffered write", 7 if  $BUFFEROUT;

	# for an unconnected port, should be $in=0, $out=0, $blk=0, $err=0
	if ($ob->can_status()) {
	   	($blk, $in, $out, $err) = $ob->status;
	}
	else {
		$out=0;
	}
	is_zero($out, 'output empty');
	ok(188 == $ob->write($line), 'write to output');
	# XXX What is this group trying to do? --Eric
	### print "<0 or 1> can_status=".$ob->can_status()."\n";
	### trying to confirm the status is actually responding to
	### outputs and not transmitting until the blocking signal is removed.
	### But this test may not always work depending on hardware
	if ($ob->can_status()) {
	   	($blk, $in, $out, $err) = $ob->status;
	}
	else {
		$out=188;
		$in=0;
		$err=0;
		$blk=0;
	}
	is_zero($blk);
	is_zero($in);
	is($out, 188, 'output bytes is 188 (cannot have anything attached to port)');
	is_zero($err);
	if ($ob->can_write_done()) {
    		($out, $err) = $ob->write_done(0);
	}
	else {
		$out=0;
	}
	is_zero($out);
    }

## 153 - 157: Write Status

	$tick=$ob->get_tick_count;
	is($ob->handshake("none"), 'none', 'release handshake block');

    SKIP: {
        skip "Can't test write_done", 4 if ($BUFFEROUT);

	if ($ob->can_write_done()) {
	    	($out, $err) = $ob->write_done(0);
	}
	else {
		$out=0;
	}
	is_zero($out, 'write not finished yet');
	if ($ob->can_write_done()) {
	    	($out, $err) = $ob->write_done(1);
	}
	else {
		$out=1;
		select(undef,undef,undef,0.200);
	}
	$tock=$ob->get_tick_count;

	ok(1 == $out, 'write complete');
	$err=$tock - $tick;
	is_bad (($err < 170) or ($err > 255));
	print "<200> elapsed time=$err\n";
	if ($ob->can_status()) {
		($blk, $in, $out, $err) = $ob->status;
	}
	else {
		$out=0;
	}
	is_zero($out, 'transmit buffer empty');
    }

## 158 - 163: Modem Status Bits

    ok(MS_CTS_ON, 'MS_CTS_ON');
    ok(MS_DSR_ON, 'MS_DSR_ON');
    ok(MS_RING_ON, 'MS_RING_ON');
    ok(MS_RLSD_ON, 'MS_RLSD_ON');
    $blk = MS_CTS_ON | MS_DSR_ON | MS_RING_ON | MS_RLSD_ON;
    ok(defined($in = $ob->modemlines), 'modemlines');
    if ($BUFFEROUT) {
	ok (1, 'skip modemlines');
        printf "blk=%x, modemlines=%x\n", $blk, $in;
    } else {
        is($blk & $ob->modemlines, 0, "Modem lines clear (cannot have anything attached to port)");
    }

is(ST_BLOCK, 0, 'ST_BLOCK');
is(ST_INPUT, 1, 'ST_INPUT');
is(ST_OUTPUT, 2, 'ST_OUTPUT');
is(ST_ERROR, 3, 'ST_ERROR');

$tick=$ob->get_tick_count;
ok ($ob->pulse_break_on(250), 'pulse break on');
$tock=$ob->get_tick_count;
$err=$tock - $tick;
is_bad (($err < 235) or ($err > 900), 'pulse break timing');
print "<500> elapsed time=$err\n";

ok($ob->close, 'close');

    # destructor = DESTROY method
undef $ob;					# Don't forget this one!!

