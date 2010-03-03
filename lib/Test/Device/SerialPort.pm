package Test::Device::SerialPort;

use strict;
our $VERSION = '0.02';

sub new
{
    my($ref, $port) = @_;
    my $class = ref($ref) || $ref;
    my $self = {
        _port => $port,
        _are_match => [],
    };
    bless $self;
}

sub are_match
{
    my $self = shift;
    if( @_ )
    {
        my @patterns = [ @_ ];
        $self->{_are_match} = \@patterns;
    }
    return @{$self->{_are_match}};
}

# Set the baudrate
sub baudrate
{
    my($self, $baud) = @_;
    $self->{_baudrate} = $baud;
}

# It seems Device::SerialPort::buffers() it's a fake
sub buffers
{
    my($self, $rx_size, $tx_size) = @_;
    $self->{_rx_bufsize} = $rx_size;
    $self->{_tx_bufsize} = $tx_size;
    return wantarray ? (4096, 4096) : 1;
}

# If this class implements wait_modemlines()
sub can_wait_modemlines
{
    return(1);
}

sub close
{
    # noop
    return(1);
}

# Set databits
sub databits
{
    my($self, $databits) = @_;
    $self->{_databits} = $databits;
}

# Set handshake type property
sub handshake
{
    my($self, $type) = @_;
    my @allow = ('none', 'xoff', 'rts');

    if(wantarray)
    {
        return(@allow);
    }
    if(! grep { $type eq $_ } @allow )
    {
        return(undef);
    }
    return($self->{_handshake} = $type);
}

sub lookfor
{
    my $self = shift;
    my $count = undef;
    if( @_ )
    {
        $count = $_[0];
    }

    # When count is defined, behave like read()
    if( $count > 0 )
    {
        return $self->read($count);
    }

    # Lookfor specific behaviour
    my $look = 0;
    my @patt = $self->are_match();

    # XXX What we do here?
    if( ! @patt )
    {
        @patt = ("\n");
    }

    if( rand(1) < 0.3 )
    {
        $look = 1;
    }

    return '' unless $look;

    # Return random data with appended one of the user-defined patterns
    my $data = $self->_produce_data(10);
    $data .= $patt[ rand(@patt) ];

    return($data);
}

# Return the status of the serial line signals
# Randomly activate signals...
sub modemlines
{
    require Device::SerialPort;
    my $status = 0;
    $status |= &Device::SerialPort::MS_CTS_ON  if rand(1) > 0.3;
    $status |= &Device::SerialPort::MS_DSR_ON  if rand(1) > 0.3;
    $status |= &Device::SerialPort::MS_RING_ON if rand(1) > 0.95;
    $status |= &Device::SerialPort::MS_RLSD_ON if rand(1) > 0.5;
    return($status);
}

# Set parity
sub parity
{
    my($self, $parity) = @_;
    $self->{_parity} = $parity;
}

# Produce random data
sub _produce_data
{
    my($self, $bytes) = @_;
    my @chars = ('A' .. 'Z', 0 .. 9, 'a' .. 'z' );
    my $data  = '';
    my $len   = int rand($bytes);

    for( 1 .. $len )
    {
        $data .= $chars[rand(@chars)];
    }
    return($data);
}

# Empty transmit and receive buffers
sub purge_all
{
    my $self = shift;
    $self->{_tx_buf} = '';
    $self->{_rx_buf} = '';
    return();
}

# Wait some time between a min and a max (seconds)
sub _random_wait
{
    my($self, $min, $max) = @_;
    my $time = $min + rand($max - $min);
    select(undef, undef, undef, $time);
    return();
}

# Read data from line. For us is "generate" some random
# data as it came from the serial line.
sub read
{
    my($self, $bytes) = @_;
    my $new_input = '';
    my $buf;

    # Wait some random time
    $self->_random_wait(0, 0.5);

    # We can have or not input
    my $have_input = rand(1);

    if( $have_input > 0.7 )
    {
        $new_input = $self->_produce_data($bytes);
        $self->{_rx_buf} .= $new_input;
    }

    # Empty read buffer
    $buf = $self->{_rx_buf};
    $self->{_rx_buf} = '';

    return(length($buf), $buf);
}

sub read_char_time
{
    my $self = shift;
    if( @_ )
    {
        $self->{_read_char_time} = shift() / 1000;
    }
    return($self->{_read_char_time} * 1000);
}

sub read_const_time
{
    my $self = shift;
    if( @_ )
    {
        $self->{_read_const_time} = shift() / 1000;
    }
    return($self->{_read_const_time} * 1000);
}

sub read_interval
{
    die qq(Can't locate object method "read_interval" via package "Device::SerialPort");
}

# Set stopbits
sub stopbits
{
    my($self, $stopbits) = @_;
    $self->{_stopbits} = $stopbits;
}

# Randomly wait some time, and then return with status 1
sub wait_modemlines
{
    my $self = shift;
    $self->_random_wait(10, 60);
    return(1);
}

# Write data down the line
sub write
{
    my($self, $str) = @_;
    $self->_random_wait(0, 0.5);
    $self->{_tx_buf} .= $str;
    return(length($str));
}

# Empty the write buffer
sub write_drain
{
    my($self) = @_;
    $self->{_tx_buf} = '';
    return(1);
}

# Write serial port settings into external files
sub write_settings
{
    # noop
    return(1);
}

1;

__END__

=head1 NAME

Test::Device::SerialPort - Serial port mock object to be used for testing

=head1 SYNOPSIS

    use Test::Device::SerialPort;
    my $PortObj = Test::Device::SerialPort->new('/dev/ttyS0');

    $PortObj->baudrate(19200);
    $PortObj->parity('none');
    $PortObj->databits(8);
    $PortObj->stopbits(1);

    # Simulate read from port (can also read nothing)
    my($count, $data) = $PortObj->read(100);

    print "Read random data from serial [$data]\n";

    # Simulate write to serial port
    $count = $PortObj->write("MY_MESSAGE\r");

    print "Written $count chars to test port\n";

    # ...

=head1 DESCRIPTION

Nothing more.
It's a test object that mimics the real Device::SerialPort thing.
Used mainly for testing when I don't have an actual device to test.

=head1 STATUS

Just a sketch version...

=head1 SEE ALSO

=over *

=item Device::SerialPort

=item Win32::SerialPort

=back

=head1 AUTHOR

Cosimo Streppone, <cosimo@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2010 by Cosimo Streppone

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

