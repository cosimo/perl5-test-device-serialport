use lib './lib','../lib';	# can run before final install

## This implements the same tied actions as demo6 in the
## Win32 and Device::SerialPort distributions
## But simulates the results

use Test::Device::SerialPort 0.06;
require 5.008;

use strict;
use warnings;

package main;	# default, but safe to know when using write_decoder

# loopback responses
sub test_write_decoder {
    return unless (@_ == 2);
    my $self = shift;
    my $wbuf = shift;
    my $response = "";
    return unless ($wbuf);
    if ($wbuf =~ /one character/) {
	$response = 'A';
    } elsif ($wbuf =~ /enter line/) {
	$response = "The quick brown fox jumped over the lazy dog\n";
    } elsif ($wbuf =~ /enter 5 char/) {
	$response = "Abcde";
    } elsif ($wbuf =~ /enter 5 more/) {
	$response = "Fghij";
    } else {
	$response = 'Not Found';
    }
    $self->lookclear($response);
    my $sent = $wbuf;
    $sent =~ s/^\s*//omg;	# strip leading whitespace
    warn "RECEIVED: $sent\n";	# see what was sent
    return length($wbuf);
}

my $cfgfile = "DEMO.cfg";
unlink $cfgfile;

my $ob = Test::Device::SerialPort->new('DEMO');
die "Can't open serial port DEMO\n" unless ($ob);

$ob->save($cfgfile);
undef $ob;

my $head	= "\r\n\r\n+++++++++++ Tied FileHandle Demo ++++++++++\r\n";
my $e="\r\n....Bye\r\n";

    # constructor = TIEHANDLE method
my $tie_ob = tie(*PORT,'Test::Device::SerialPort', $cfgfile)
                 || die "Can't start $cfgfile\n";

    # match parameters
$tie_ob->are_match("\n");
$tie_ob->set_no_random_data(1);
$tie_ob->lookclear;

    # setup loopback write decoding
$tie_ob->write_decoder('main::test_write_decoder');

    # Print Prompt to Port
print PORT $head;

    # tie to PRINT method
print PORT "\r\nEnter one character (10 seconds): "
    or die "PRINT timed out\n";	# should never happen in loopback

    # tie to GETC method
my $char = getc PORT;
print PORT "$char\r\n";

    # tie to WRITE method
my $out = "\r\nThis is a 'syswrite' test\r\n\r\n";
syswrite PORT, $out, length($out), 0
    or die "WRITE timed out\n";

    # tie to READLINE method
print PORT "enter line: ";
my $line = <PORT>;
print PORT "\r\nREADLINE received: $line\r";

    # tie to READ method
my $in = "FIRST:12345, SECOND:67890, END";
print PORT "\r\nenter 5 char: ";
unless (defined sysread (PORT, $in, 5, 6)) {
    die "...READ timed out\n";
}
print PORT "\r\nenter 5 more char: ";
unless (defined sysread (PORT, $in, 5, 20)) {
    die "...second READ timed out\n";
}

    # tie to PRINTF method
printf PORT "\r\nreceived: %s\r\n", $in
    or die "PRINTF timed out\n";

    # PORT-specific versions of the $, and $\ variables
my $n1 = ".number1_";
my $n2 = ".number2_";
my $n3 = ".number3_";

print PORT $n1, $n2, $n3;
print PORT "\r\n";

$tie_ob->output_field_separator("COMMA");
print PORT $n1, $n2, $n3;
print PORT "\r\n";

$tie_ob->output_record_separator("RECORD");
print PORT $n1, $n2, $n3;
$tie_ob->output_record_separator("");
print PORT "\r\n";
    # the $, and $\ variables will also work

print PORT $e;

    # destructor = CLOSE method
close PORT || print "CLOSE failed\n\n";

    # destructor = DESTROY method
undef $tie_ob;	# Don't forget this one!!
untie *PORT;
