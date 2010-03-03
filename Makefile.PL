use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR            => 'Cosimo Streppone <cosimo@cpan.org>',
    NAME              => 'Test::Device::SerialPort',
    LICENSE           => 'perl',
    ABSTRACT_FROM     => 'lib/Test/Device/SerialPort.pm',
    VERSION_FROM      => 'lib/Test/Device/SerialPort.pm',
    PREREQ_PM         => {
		'Test::More' => 0,
	},
    META_MERGE => {
        resources => {
            repository => 'git://github.com/cosimo/perl5-test-device-serialport.git',
            bugtracker => 'mailto:bug-test-device-serialport@rt.cpan.org',
            license    => 'http://dev.perl.org/licenses/',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-Device-SerialPort-*' },
);
