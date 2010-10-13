package Net::MQ::Transport::AMQP;

use Moose;

=head1 NAME

Net::MQ::Transport::AMQP - transport Net::MQ messages using AMQP

=head1 SYNOPSIS

This class may be used separately, but it is designed to be
used as part of the unified Net::MQ API for integrating the
messaging pattern into your application.

 package MyApp::Event::Album::Purchased;

 with 'Net::MQ::Message';

 __PACKAGE__->transport([ AMQP => { host => '192.168.0.32' } ]);

=cut

our $VERSION = '0.01';

use MooseX::ClassAttribute;
use Try::Tiny;

has host =>
	isa			=> 'Str',
	is			=> 'ro',
	required	=> 1;

has channel =>
	isa			=> 'Int',
	is			=> 'ro',
	default		=> 1;

has exchange =>
	isa			=> 'Str',
	is			=> 'ro',
	default		=> 'amq.direct';

has proxy =>
	does		=> 'Net::MQ::Transport',
	is			=> 'ro',
	lazy_build	=> 1,
	init_arg	=> undef,
	handles		=> [ qw(publish dequeue poll ack) ];

class_has providers =>
	traits		=> [ 'Array' ],
	isa			=> 'ArrayRef[Str]',
	is			=> 'ro',
	default		=> sub { [] },
	handles		=> {
		register_provider	=> 'push',
		find_provider		=> 'first'
	};

__PACKAGE__->register_provider('Net::MQ::Transport::AMQP::RabbitMQ');

sub _build_proxy
{
	my $self = shift;

	my $class = $self->load_provider;

	$class->new(map { $_ => $self->$_ } qw(host channel exchange));
}

sub load_provider
{
	my $self = shift;

	my $err		= '';
	my $loader	= sub { try { Class::MOP::load_class($_) } catch { $err .= $_; 0 } };
	my $class	= $self->find_provider($loader);

	if (not defined $class) {
		warn $err;
		die 'unable to locate provider for transport "AMQP"';
	}

	return $class;
}


=head1 AUTHOR

Mike Eldridge, C<< <diz at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Mike Eldridge.

This program is free software; you can redistribute it and/or
modify it under the terms of either: the GNU General Public
License as published by the Free Software Foundation; or the
Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;

