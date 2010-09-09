use lib '.','./eg','./lib','../lib';
# can run from here or distribution base

use Test::More;
plan tests => 99;
our %config_parms;

use Test::Device::SerialPort qw( 0.06 );
use ControlX10::CM11 qw( 2.09 );

use strict;
use warnings;

package main;	# default, but safe to know when using write_decoder

sub write_cm11 {
    return unless (@_ == 2);
    my $self = shift;
    my $wbuf = shift;
    my $response = "";
    return unless ($wbuf);
    my @loc_char = split (//, $wbuf);
    my $f_char = ord (shift @loc_char);
    if ($f_char == 0x00) {
	$response = chr(0x55);
	$self->lookclear($response);
	return 1;
    }
    elsif ($f_char == 0xc3) {
	$response = chr(0x05).chr(0x04).chr(0xe9).chr(0xe5).chr(0xe5).chr(0x58);
	    # example from protocol.txt
	$self->lookclear($response);
	return 1;
    }
    elsif (($f_char == 0xeb) or ($f_char == 0xeb)) {
	$response = chr($f_char);
	$self->lookclear($response);
	return 1;
    }
    else {
	my $ccount = 1;
	my $n_char = "";
	foreach $n_char (@loc_char) {
	    $f_char += ord($n_char);
	    $ccount++;
	}
	$response = chr($f_char & 0xff);
	$self->lookclear($response);
##        printf "response = %x\n", ord($response);
	return $ccount;
    }
}

my $file = "TEST";

# 1: Constructor

my $ob;
ok($ob = Test::Device::SerialPort->new ($file), "new $file");
die unless ($ob);    # next tests would die at runtime

$ob->write_decoder('main::write_cm11');
$ob->lookclear("Test123");
$main::config_parms{debug} = "";

# end of preliminaries.
is(read_cm11($ob, 1), 'Test123', 'data preload');
is($ControlX10::CM11::DEBUG, 0, 'debug off');
is(send_cm11($ob, 'A1'), 0x55, 'send_cm11 A1');
is($ControlX10::CM11::DEBUG, 0, 'debug off');
is(send_cm11($ob, 'AOFF'), 0x55, 'send_cm11 AOFF');

$main::config_parms{debug} = "X10";
is(send_cm11($ob, 'bg'), 0x55, 'send_cm11 bg');
is($ControlX10::CM11::DEBUG, 1, 'debug on');

$main::config_parms{debug} = "";
is(send_cm11($ob, 'B-25'), 0x55, 'send_cm11 B-25');
is(send_cm11($ob, 'BON'), 0x55, 'send_cm11 BON');

is(send_cm11($ob, 'B2'), 0x55, 'send_cm11 B2');
is($ControlX10::CM11::DEBUG, 0, 'debug off');
is(send_cm11($ob, 'Bl'), 0x55, 'send_cm11 Bl');

is(send_cm11($ob, 'cStatus'), 0x55, 'send_cm11 cStatus');
is(send_cm11($ob, 'DF'), 0x55, 'send_cm11 DF');
is(send_cm11($ob, 'DALL_ON'), 0x55, 'send_cm11 DALL_ON');

is(send_cm11($ob, 'A2B'), undef, 'send_cm11 A2B');
is(send_cm11($ob, 'AH'), undef, 'send_cm11 AH');
is(send_cm11($ob, 'Q1'), undef, 'send_cm11 Q1');
is(send_cm11($ob, 'BAD'), undef, 'send_cm11 BAD');
is(send_cm11($ob, 'EQ'), undef, 'send_cm11 EQ');
is(ControlX10::CM11::send($ob, 'EE'), 0x55, 'send EE');
is(ControlX10::CM11::send($ob, 'EDIM'), 0x55, 'send EDIM');
 
is(send_cm11($ob, 'Fbright'), 0x55, 'send_cm11 Fbright');
is(send_cm11($ob, 'GM'), 0x55, 'send_cm11 GM');

is(send_cm11($ob, 'HL'), 0x55, 'send_cm11 HL');
is(send_cm11($ob, 'IK'), 0x55, 'send_cm11 IK');
is(send_cm11($ob, 'JJ'), 0x55, 'send_cm11 JJ');
is(send_cm11($ob, 'KO'), 0x55, 'send_cm11 KO');
is(send_cm11($ob, 'LP'), 0x55, 'send_cm11 LP');
is(send_cm11($ob, 'mALL_OFF'), 0x55, 'send_cm11 mALL_OFF');
is(send_cm11($ob, 'NP'), 0x55, 'send_cm11 NP');

is(send_cm11($ob, 'O3'), 0x55, 'send_cm11 O3');
is(send_cm11($ob, 'P4'), 0x55, 'send_cm11 P4');
is(send_cm11($ob, 'A5'), 0x55, 'send_cm11 A5');
is(send_cm11($ob, 'B6'), 0x55, 'send_cm11 B6');
is(send_cm11($ob, 'C7'), 0x55, 'send_cm11 C7');

is(send_cm11($ob, 'd8'), 0x55, 'send_cm11 d8');
is(send_cm11($ob, 'e9'), 0x55, 'send_cm11 e9');
is(send_cm11($ob, 'fa'), 0x55, 'send_cm11 fa');
is(send_cm11($ob, 'gb'), 0x55, 'send_cm11 gb');
is(send_cm11($ob, 'hc'), 0x55, 'send_cm11 hc');

is(send_cm11($ob, 'id'), 0x55, 'send_cm11 id');
is(send_cm11($ob, 'PALL_LIGHTS_OFF'), 0x55, 'send_cm11 PALL_LIGHTS_OFF');
is(send_cm11($ob, 'AEXTENDED_CODE'), 0x55, 'send_cm11 AEXTENDED_CODE');
is(send_cm11($ob, 'BHAIL_REQUEST'), 0x55, 'send_cm11 BHAIL_REQUEST');

is(send_cm11($ob, 'CHAIL_ACK'), 0x55, 'send_cm11 CHAIL_ACK');
is(send_cm11($ob, 'DPRESET_DIM1'), 0x55, 'send_cm11 DPRESET_DIM1');
is(send_cm11($ob, 'PPRESET_DIM2'), 0x55, 'send_cm11 PPRESET_DIM2');
is(send_cm11($ob, 'AEXTENDED_DATA'), 0x55, 'send_cm11 AEXTENDED_DATA');
is(send_cm11($ob, 'BSTATUS_ON'), 0x55, 'send_cm11 BSTATUS_ON');
is(send_cm11($ob, 'CSTATUS_OFF'), 0x55, 'send_cm11 CSTATUS_OFF');

is(send_cm11($ob, 'i-10'), 0x55, 'send_cm11 i-10');
is(send_cm11($ob, 'P-20'), 0x55, 'send_cm11 P-20');
is(send_cm11($ob, 'A-30'), 0x55, 'send_cm11 A-30');
is(send_cm11($ob, 'B-40'), 0x55, 'send_cm11 B-40');
is(send_cm11($ob, 'C-50'), 0x55, 'send_cm11 C-50');

is(send_cm11($ob, 'i-60'), 0x55, 'send_cm11 i-60');
is(send_cm11($ob, 'P-70'), 0x55, 'send_cm11 P-70');
is(send_cm11($ob, 'A-80'), 0x55, 'send_cm11 A-80');
is(send_cm11($ob, 'B-90'), 0x55, 'send_cm11 B-90');
is(send_cm11($ob, 'C-100'), undef, 'send_cm11 C-100');

is(send_cm11($ob, 'A-0'), undef, 'send_cm11 A-0');
is(send_cm11($ob, 'P+20'), 0x55, 'send_cm11 P+20');

is(send_cm11($ob, 'A+30'), 0x55, 'send_cm11 A+30');
is(send_cm11($ob, 'B+40'), 0x55, 'send_cm11 B+40');
is(send_cm11($ob, 'C+50'), 0x55, 'send_cm11 C+50');
is(send_cm11($ob, 'i+60'), 0x55, 'send_cm11 i+60');
is(send_cm11($ob, 'P+70'), 0x55, 'send_cm11 P+70');
is(send_cm11($ob, 'A+80'), 0x55, 'send_cm11 A+80');
is(send_cm11($ob, 'B+90'), 0x55, 'send_cm11 B+90');
is(send_cm11($ob, 'C+100'), undef, 'send_cm11 C+100');

is(send_cm11($ob, 'A+10'), 0x55, 'send_cm11 A+10');
is(send_cm11($ob, 'A-95'), 0x55, 'send_cm11 A-95');
is(send_cm11($ob, 'A+95'), 0x55, 'send_cm11 A+95');
is(send_cm11($ob, 'B+65'), 0x55, 'send_cm11 B+65');
is(send_cm11($ob, 'C-75'), 0x55, 'send_cm11 C-75');

my $data = "";
my $response = "B6B7BMGE";
ok($data = receive_cm11($ob), 'receive_cm11');
is($data, $response, 'response value');
is(dim_decode_cm11("GE"), 40, 'dim_decode_cm11("GE")');

is(dim_decode_cm11("A3"), 45, 'dim_decode_cm11("A3")');
is(dim_decode_cm11("E9"), 10, 'dim_decode_cm11("E9")');
is(dim_decode_cm11("N3"), 60, 'dim_decode_cm11("N3")');
is(dim_decode_cm11("ID"), 50, 'dim_decode_cm11("ID")');
is(dim_decode_cm11("M5"), 0, 'dim_decode_cm11("M5")');

is(dim_decode_cm11("O4"), 35, 'dim_decode_cm11("O4")');
is(dim_decode_cm11("C3"), 15, 'dim_decode_cm11("C3")');
is(dim_decode_cm11("FA"), 75, 'dim_decode_cm11("FA")');
is(dim_decode_cm11("L9"), 85, 'dim_decode_cm11("L9")');
is(dim_decode_cm11("P4"), 95, 'dim_decode_cm11("P4")');

is(send_cm11($ob, 'C1&P25'), 0x55, 'send_cm11 C1&P25');
is(send_cm11($ob, 'C&P05'), undef, 'send_cm11 C&P05');
is(send_cm11($ob, 'M4'), 0x55, 'send_cm11 M4');
is(send_cm11($ob, 'OPRESET_DIM2'), 0x55, 'send_cm11 OPRESET_DIM2');
is(send_cm11($ob, 'C1&P'), undef, 'send_cm11 C1&P');
is(send_cm11($ob, 'C1&PA5'), undef, 'send_cm11 C1&PA5');
is(send_cm11($ob, 'C1&P5'), 0x55, 'send_cm11 C1&P5');
is(send_cm11($ob, 'C1&P105'), undef, 'send_cm11 C1&P105');
is(send_cm11($ob, 'D5'), 0x55, 'send_cm11 D5');

undef $ob;
