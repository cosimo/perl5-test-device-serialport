use lib '.','./eg','./lib','../lib';
# can run from here or distribution base

use Test::More;
plan tests => 29;
our %config_parms;

use Test::Device::SerialPort qw( :STAT 0.06 );
use ControlX10::CM17 qw( send_cm17 0.06 );

use strict;
use warnings;

my $file = "TEST";
## my @necessary_param = Test::Device::SerialPort->set_test_mode_active(1);

# 1: Constructor

my $ob;
ok($ob = Test::Device::SerialPort->new ($file), "new $file");
die unless ($ob);    # next tests would die at runtime

is($ControlX10::CM17::DEBUG, 0, 'debug off');
is(send_cm17($ob, 'A1J'), 1, 'send_cm17 A1J');
is($ControlX10::CM17::DEBUG, 0, 'debug off');
is($ob->read_back_cmd, 1, 'read_back_cmd');

$main::config_parms{debug} = "X10";
is(send_cm17($ob, 'A1J'), 1, 'send_cm17 A9J');
is($ControlX10::CM17::DEBUG, 1, 'debug on');
is($ob->read_back_cmd, 1, 'read_back_cmd');

$main::config_parms{debug} = "";
is(send_cm17($ob, 'AGJ'), 1, 'send_cm17 AGJ');
is($ControlX10::CM17::DEBUG, 0, 'debug off');
is($ob->read_back_cmd, 1, 'read_back_cmd');

is(send_cm17($ob, 'A2B'), undef, 'bad send_cm17 A2B');
is(send_cm17($ob, 'AHJ'), undef, 'bad send_cm17 AHJ');
is(send_cm17($ob, 'Q1J'), undef, 'bad send_cm17 Q1J');
is(ControlX10::CM17::send($ob, 'A1K'), 1, 'send');
is($ob->read_back_cmd, 1, 'read_back_cmd');

is(send_cm17($ob, 'A2J'), 1, 'send_cm17 A2J');
is(send_cm17($ob, 'AM'), 1, 'send_cm17 AM');
is(send_cm17($ob, 'AL'), 1, 'send_cm17 AL');
is(send_cm17($ob, 'A1K'), 1, 'send_cm17 A1K');
is($ob->read_back_cmd(4), 1, 'read_back_cmd(4)');

is(send_cm17($ob, 'AN'), 1, 'send_cm17 AN');
is(send_cm17($ob, 'AO'), 1, 'send_cm17 AO');
is(send_cm17($ob, 'AP'), 1, 'send_cm17 AP');
is($ob->read_back_cmd(3), 1, 'read_back_cmd(3)');

is(send_cm17($ob, 'A3-50'), 1, 'send_cm17 A3-50');
is($ob->read_back_cmd(5), 1, 'read_back_cmd(5)');
is(send_cm17($ob, 'AF+10'), 1, 'send_cm17 AF+10');
is($ob->read_back_cmd(2), 1, 'read_back_cmd(2)');

undef $ob;
