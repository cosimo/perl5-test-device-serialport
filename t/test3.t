use lib '.','./t','./lib','../lib';
# can run from here or distribution base

use Test::More;
plan tests => 195;

## some online discussion of issues with use_ok, so just sanity check
cmp_ok($AltPort::VERSION, '>=', 0.03, 'VERSION check');

# Some OS's (BSD, linux on Alpha, etc.) can't test pulse timing
my $TICKTIME=0;

use AltPort qw( :STAT 0.06 );

use strict;
use warnings;

package main;	# default, but safe to know when using write_decoder

sub test_write_decoder {
    return unless (@_ == 2);
    my $self = shift;
    my $wbuf = shift;
    my $response = "";
    return unless ($wbuf);
    if ($wbuf eq 'Test_A') {
	$response = 'Aa';
    } elsif ($wbuf eq 'Test_B') {
	$response = 'Bb';
    } else {
	$response = 'Not Found';
    }
    $self->lookclear($response);
    return length($wbuf);
}

## verifies the (0, 1) list returned by binary functions
sub test_bin_list {
    return undef unless (@_ == 2);
    return undef unless (0 == shift);
    return undef unless (1 == shift);
    return 1;
}

sub is_bad {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return ok(!shift, shift);
}

# assume a "vanilla" port on "TEST" to check alias and device

my $file = "TEST";

my $cfgfile = "$file"."_test.cfg";
$cfgfile =~ s/.*\///;

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
my %required_param;
my @necessary_param = AltPort->set_test_mode_active(1);

unlink $cfgfile;
foreach $e (@necessary_param) { $required_param{$e} = 0; }

# 2: Constructor

ok($ob = AltPort->new ($file), "new $file");
die unless ($ob);    # next tests would die at runtime

# 3 - 8: object debug method

is_bad( scalar $ob->debug(), 'object debug init');
ok( scalar $ob->debug("T"), 'T' );
ok( scalar $ob->debug(), 'read debug state' );
is_bad( scalar $ob->debug("2"), 'invalid debug turns off' );
is_bad( scalar $ob->debug(), 'confirm off' );

@opts = $ob->debug();
ok(test_bin_list(@opts), 'binary_opt_array');

#### 9 - 29: Check Port Capabilities 

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

is($ob->can_spec_char, 0, 'can_spec_char');
is($ob->can_16bitmode, 0, 'can_16bitmode');

if ($^O eq 'MSWin32') {
	ok($ob->can_rlsd, 'can_rlsd');
	ok($ob->can_interval_timeout, 'can_interval_timeout');
	is($ob->can_ioctl, 0, 'can_ioctl');
	is($ob->device, '\\\\.\\'.$file, 'Win32 device');
} else {
	is($ob->can_rlsd, 0, 'can_rlsd');
	is($ob->can_interval_timeout, 0, 'can_interval_timeout');
	ok($ob->can_ioctl, 'can_ioctl');
	is($ob->alias, $file, 'device not implemented');
}
is($ob->alias, $file, 'alias init');
ok($ob->is_rs232, 'is_rs232');
is($ob->is_modem, 0, 'is_modem');

#### 30 - 70: Set Basic Port Parameters 

## 30 - 35: Baud (Valid/Invalid/Current)

@opts=$ob->baudrate;		# list of allowed values
ok(1 == grep(/^9600$/, @opts), '9600 baud in list');
ok(0 == grep(/^9601/, @opts), '9601 baud not in list'); # force scalar context

ok($in = $ob->baudrate, 'read baudrate');
ok(1 == grep(/^$in$/, @opts), "confirm $in in baud array");
is_bad(scalar $ob->baudrate(9601), 'cannot set 9601 baud');
ok($ob->baudrate(9600), 'can set 9600 baud');
    # leaves 9600 pending

## 36 - 41: Parity (Valid/Invalid/Current)

@opts=$ob->parity;		# list of allowed values
ok(1 == grep(/none/, @opts), 'parity none in list');
ok(0 == grep(/any/, @opts), 'parity any not in list');

ok($in = $ob->parity, 'read parity');
ok(1 == grep(/^$in$/, @opts), "confirm $in in parity array");

is_bad(scalar $ob->parity("any"), 'cannot set any parity');
ok($ob->parity("none"), 'can set none parity');
    # leaves "none" pending

## 42 - 47: Databits (Valid/Invalid/Current)

@opts=$ob->databits;		# list of allowed values
ok(1 == grep(/8/, @opts), '8 databits in list');
ok(0 ==  grep(/4/, @opts), '4 databits not in list');

ok($in = $ob->databits, 'read databits');
ok(1 == grep(/^$in$/, @opts), "confirm $in databits in list");

is_bad(scalar $ob->databits(3), 'cannot set 3 databits');
ok($ob->databits(8), 'can set 8 databits');
    # leaves 8 pending

## 48 - 53: Stopbits (Valid/Invalid/Current)

@opts=$ob->stopbits;		# list of allowed values
ok(1 == grep(/2/, @opts), '2 stopbits in list');
ok(0 == grep(/1.5/, @opts), '1.5 stopbits not in list');

ok($in = $ob->stopbits, 'read stopbits');
ok(1 == grep(/^$in$/, @opts), "confirm $in stopbits in list");

is_bad(scalar $ob->stopbits(3), 'cannot set 3 stopbits');
ok($ob->stopbits(1), 'can set 1 stopbit');
    # leaves 1 pending

## 54 - 59: Handshake (Valid/Invalid/Current)

@opts=$ob->handshake;		# list of allowed values
ok(1 == grep(/none/, @opts), 'handshake none in list');
ok(0 ==  grep(/moo/, @opts), 'handshake moo not in list');

ok($in = $ob->handshake, 'read handshake');
ok(1 == grep(/^$in$/, @opts), "confirm handshake $in in list");

is_bad(scalar $ob->handshake("moo"), 'cannot set handshake moo');
ok($ob->handshake("rts"), 'can set handshake rts');

## 60 - 66: Buffer Size

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

## 67 - 70: Other Parameters (Defaults)

is($ob->alias("TestPort"), 'TestPort', 'alias');
is(scalar $ob->parity_enable(0), 0, 'parity disable');
ok($ob->write_settings, 'write_settings');
ok($ob->binary, 'binary');

## 71 - 72: Read Timeout Initialization

is(scalar $ob->read_const_time, 0, 'read_const_time');
is(scalar $ob->read_char_time, 0, 'read_char_time');

## 73 - 78: No Handshake, Polled Write

is($ob->handshake("none"), 'none', 'set handshake for write');

$e="testing is a wonderful thing - this is a 60 byte long string";
#   123456789012345678901234567890123456789012345678901234567890
my $line = "\r\n$e\r\n$e\r\n$e\r\n";	# about 195 MS at 9600 baud

my $tick=$ob->get_tick_count;
sleep 2;
my $tock=$ob->get_tick_count;
$err=$tock - $tick;
unless ($err > 1950 && $err < 2100) {
	$TICKTIME = 1;	# can't test pulse timing
}
print "<2000> elapsed time=$err\n";

is(($ob->write($line)), 188, 'write character count');
ok (1, 'skip write timeout');

ok(scalar $ob->purge_tx, 'purge_tx');
ok(scalar $ob->purge_rx, 'purge_rx');
ok(scalar $ob->purge_all, 'purge_all');

## 79 - 84: Optional Messages

@opts = $ob->user_msg;
ok(test_bin_list(@opts), 'user_msg_array');
is(scalar $ob->user_msg, 0, 'user_msg init OFF');
ok(1 == $ob->user_msg(1), 'user_msg_ON');

@opts = $ob->error_msg;
ok(test_bin_list(@opts), 'error_msg_array');
is(scalar $ob->error_msg, 0, 'error_msg init OFF');
ok(1 == $ob->error_msg(1), 'error_msg_ON');

## 85 - 91: Save and Check Configuration

ok(scalar $ob->save($cfgfile), 'save');

is($ob->baudrate, 9600, 'baudrate');
is($ob->parity, 'none', 'parity');

is($ob->databits, 8, 'databits');
is($ob->stopbits, 1, 'stopbits');


ok (300 == $ob->read_const_time(300), 'read_const_time');
ok (20 == $ob->read_char_time(20), 'read_char_time');

## 92 - 107: Output bits and pulses

    ok ($ob->dtr_active(0), 'dtr inactive');
    $tick=$ob->get_tick_count;
    ok ($ob->pulse_dtr_on(100), 'pulse_dtr_on');
    $tock=$ob->get_tick_count;
    $err=$tock - $tick;
    SKIP: {
        skip "Can't time pulses", 1 if $TICKTIME;
        is_bad (($err < 180) or ($err > 265), 'dtr pulse timing');
    }
    print "<200> elapsed time=$err\n";
    
    ok ($ob->dtr_active(1), 'dtr active');
    $tick=$ob->get_tick_count;
    ok ($ob->pulse_dtr_off(200), 'pulse_dtr_off');
    $tock=$ob->get_tick_count;
    $err=$tock - $tick;
    SKIP: {
        skip "Can't time pulses", 1 if $TICKTIME;
        is_bad (($err < 370) or ($err > 485), 'dtr pulse timing');
    }
    print "<400> elapsed time=$err\n";
   
    SKIP: {
        skip "Can't RTS", 7 unless $ob->can_rtscts();
	
	ok ($ob->rts_active(0), 'rts inactive');
    	$tick=$ob->get_tick_count;
	ok ($ob->pulse_rts_on(150), 'pulse rts on');
	$tock=$ob->get_tick_count;
	$err=$tock - $tick;
	SKIP: {
            skip "Can't time pulses", 1 if $TICKTIME;
	    is_bad (($err < 275) or ($err > 365), 'pulse rts timing');
	}
	print "<300> elapsed time=$err\n";
    
	ok ($ob->rts_active(1), 'rts active');
	$tick=$ob->get_tick_count;
	ok ($ob->pulse_rts_off(50), 'pulse rts off');
	$tock=$ob->get_tick_count;
	$err=$tock - $tick;
	SKIP: {
            skip "Can't time pulses", 1 if $TICKTIME;
	    is_bad (($err < 80) or ($err > 145), 'pulse rts timing');
	}
	print "<100> elapsed time=$err\n";

	ok ($ob->rts_active(0), 'reset rts inactive');
    }
    
    ok ($ob->dtr_active(0), 'reset dtr inactive');
    is($ob->handshake("rts"), 'rts', 'set handshake');
    is($ob->handshake("none"), 'none', 'release handshake block');

## 108 - 119: Modem Status Bits

    ok(MS_CTS_ON, 'MS_CTS_ON');
    ok(MS_DSR_ON, 'MS_DSR_ON');
    ok(MS_RING_ON, 'MS_RING_ON');
    ok(MS_RLSD_ON, 'MS_RLSD_ON');
    $blk = MS_CTS_ON | MS_DSR_ON | MS_RING_ON | MS_RLSD_ON;
    ok(defined($in = $ob->modemlines), 'modemlines');
    ok (1, 'skip modemlines');

    is(ST_BLOCK, 0, 'ST_BLOCK');
    is(ST_INPUT, 1, 'ST_INPUT');
    is(ST_OUTPUT, 2, 'ST_OUTPUT');
    is(ST_ERROR, 3, 'ST_ERROR');

## 120 - 372: Status

    $ob->reset_error;
    is(scalar (@opts = $ob->is_status), 4, 'is_status array');

    # default should be $in=0, $out=0, $blk=0, $err=0
    ($blk, $in, $out, $err)=@opts;

    is($blk, 0, 'blocking bits');
    is($in, 0, 'input count');
    is($out, 0, 'output count');
    is($err, 0, 'error bits');

    ($blk, $in, $out, $err)=$ob->is_status(0x150, 0xaa);	# test only
    is($err, 0x150, 'error_bits forced');
    is($blk, 0xaa, 'blocking bits forced');

    ($blk, $in, $out, $err)=$ob->is_status(0, 0x55);	# test only
    is($err, 0x150, 'error_bits retained');
    is($blk, 0x55, 'blocking bits forced alt');

    ($blk, $in, $out, $err)=$ob->is_status(0x0f);	# test only
    is($err, 0x15f, 'error bits add');
    is($blk, 0, 'blocking bits reset');

    is($ob->reset_error, 0x15f, 'reset_error');

    ($blk, $in, $out, $err)=$ob->is_status;
    is($err, 0, 'error bits');

    $tick=$ob->get_tick_count;
    ok ($ob->pulse_break_on(250), 'pulse break on');
    $tock=$ob->get_tick_count;
    $err=$tock - $tick;
    SKIP: {
        skip "Can't time pulses", 1 if $TICKTIME;
	is_bad (($err < 235) or ($err > 900), 'pulse break timing');
    }
    print "<500> elapsed time=$err\n";

ok($ob->close, 'close');	# finish gracefully

    # destructor = DESTROY method
undef $ob;					# Don't forget this one!!

## 187 - xxx: Check Saved Configuration (File Headers)

ok(open(CF, "$cfgfile"), 'open config file');
my ($signature, $name, @values) = <CF>;
close CF;

ok(1 == grep(/SerialPort_Configuration_File/, $signature), 'signature');

chomp $name;
if ($file =~ /^COM\d+$/io) {
	is($name, '\\\\.\\'.$file, 'config file device');
} else {
	is($name, $file, 'config file device');
}

# ## 191 - 192: Check that Values listed exactly once
# 
# $fault = 0;
# foreach $e (@values) {
#     chomp $e;
#     ($in, $out) = split(',',$e);
#     $fault++ if ($out eq "");
#     $required_param{$in}++;
#     }
# is($fault, 0, 'no duplicate values exist');
# 
# $fault = 0;
# foreach $e (@necessary_param) {
#     $fault++ unless ($required_param{$e} ==1);
#     }
# is($fault, 0, 'all required keys appear once');

## 193 - 125: Reopen as Tie

# constructor = TIEHANDLE method
ok ($ob = tie(*PORT,'Test::Device::SerialPort', $cfgfile), 'tie');
die unless ($ob);    # next tests would die at runtime

# flush _fake_input
is($ob->input, chr(0xa5), 'flush CM11 preset');

# confirm no write decoding
is(($ob->write('Test_A')), 6, 'write_decoder init off Test_A');
is($ob->input, '', 'empty input A');
is(($ob->write('Test_B')), 6, 'write Test_B');
is($ob->input, '', 'empty input B');
is(($ob->write('Test_Z')), 6, 'write Test_Z');
is($ob->input, '', 'empty input other');

# now add write decoding
is(($ob->write_decoder('main::test_write_decoder')), '', 'set write decoder');
is(($ob->write('Test_A')), 6, 'write_decoder init off Test_A');
is($ob->input, 'Aa', 'Test_A response');
is(($ob->write('Test_B')), 6, 'write Test_B');
is($ob->input, 'Bb', 'Test_B response');
is(($ob->write('Test_Z')), 6, 'write Test_Z');
is($ob->input, 'Not Found', 'other response');

# turn write decoding off again, confirm returns prior subroutine
is(($ob->write_decoder('')), 'main::test_write_decoder', 'write decoder off');
is(($ob->write('Test_A')), 6, 'write Test_A');
is($ob->input, '', 'empty input A');
is(($ob->write('Test_B')), 6, 'write Test_B');
is($ob->input, '', 'empty input B');
is(($ob->write('Test_Z')), 6, 'write Test_Z');
is($ob->input, '', 'empty input other');

# tie to PRINT method
is((print PORT $line), 1, 'PRINT method');

# tie to PRINTF method
is((printf PORT "123456789_%s_987654321", $line), 1, 'PRINTF method');

# read (no data)
ok ($ob->set_no_random_data(1), 'set no_random_data');
($in, $in2) = $ob->read(10);
is($in, 0, 'read disconnected port');
ok ($in2 eq "", 'no data');

# tie to GETC method
is((getc PORT), undef, 'GETC method no data');
is(($ob->lookclear('C')), 1, 'preload character');
is((getc PORT), 'C', 'GETC method C');

# tie to READLINE method
@opts = $ob->are_match("\n");
is(scalar @opts, 1, 'are match');
is($opts[0], "\n", 'new line as default');
$fail = <PORT>;
is($fail, undef, 'READLINE method no data');
is(($ob->lookclear("Line_1\nLine_2\nLine3")), 1, 'preload data');
$pass = <PORT>;
is($pass, "Line_1\n", 'READLINE Line_1');
$pass = <PORT>;
is($pass, "Line_2\n", 'READLINE Line_2');
$fail = <PORT>;
is($fail, undef, 'READLINE no data for incomplete line');

# slurp mode
@opts = <PORT>;
is(scalar @opts, 0, 'READLINE no data');
is(($ob->lookclear("Line_1\nLine_2\nLine3")), 1, 'preload data');
@opts = <PORT>;
is(scalar @opts, 2, 'READLINE slurp data');
is($opts[0], "Line_1\n", 'READLINE Line_1');
is($opts[1], "Line_2\n", 'READLINE Line_2');

# tie to WRITE method
$pass=syswrite PORT, $line, length($line), 0;
is($pass, 188, 'syswrite count');
$pass=syswrite PORT, $line, 30, 0;
is($pass, 30, 'syswrite count with length');
$pass=syswrite PORT, $line, length($line), 20;
is($pass, 168, 'syswrite count with offset');

# tie to READ method
$in = "1234567890";
$fail = sysread (PORT, $in, 5, 0);
is($fail, undef, 'sysread returns undef');

is(($ob->lookclear("ABCDE")), 1, 'preload data');
$pass = sysread (PORT, $in, 5, 0);
is($pass, 5, 'sysread reads 5 characters');
is($in, "ABCDE67890", 'sysread no offset');

is(($ob->lookclear("defgh")), 1, 'preload data');
$pass = sysread (PORT, $in, 5, 3);
is($pass, 5, 'sysread reads 5 characters offset 3');
is($in, "ABCdefgh90", 'sysread no offset');

is(($ob->lookclear("ijklm")), 1, 'preload data');
$pass = sysread (PORT, $in, 5, 8);
is($pass, 5, 'sysread reads 5 characters offset 8');
is($in, "ABCdefghijklm", 'sysread no offset');

is(($ob->lookclear("12345")), 1, 'preload data');
$pass = sysread (PORT, $in, 5, -9);
is($pass, 5, 'sysread reads 5 characters offset -9');
is($in, "ABCd12345jklm", 'sysread no offset');

# destructor = CLOSE method
ok(close PORT, 'close');

# destructor = DESTROY method
undef $ob;					# Don't forget this one!!
untie *PORT;

