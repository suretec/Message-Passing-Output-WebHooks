package Log::Stash::Output::WebHooks;
use Moose;
use Log::Stash::Types;
use Log::Stash::DSL;
use AnyEvent::HTTP;
use aliased 'Log::Stash::WebHooks::Event::Call::Success';
use aliased 'Log::Stash::WebHooks::Event::Call::Timeout';
use aliased 'Log::Stash::WebHooks::Event::Call::Failure';
use namespace::autoclean;

our $VERSION = '0.001';
$VERSION = eval $VERSION;

with 'Log::Stash::Role::Output',
    'Log::Stash::Role::CLIComponent' => { name => 'log', default => 'Log::Stash::Output::Null' };

sub BUILD {
    my $self = shift;
    $self->log_chain;
}

has log_chain => (
    does => 'Log::Stash::Role::Output',
    handles => {
        log_result => 'consume',
    },
    lazy => 1,
    default => sub {
        my $self = shift;
        log_chain {
            output log => (
                class => $self->log,
                $self->log_options,
            );
        }->[0];
    },
);

has timeout => (
    isa => 'Int',
    is => 'ro',
    default => 300,
);

sub consume {
    my ($self, $data) = @_;
    my $body = $self->encode($data->{data});
    # XXX FIXME http://wiki.shopify.com/Verifying_Webhooks
    # HMAC goes here.
    #warn "MAKE POST to " . $data->{url};
    my $headers = {};
    my $timeout = $self->timeout;
    my ($timer, $guard);
    $timer = AnyEvent->timer(
        after => $timeout,
        cb => sub {
            undef $guard;
            undef $timer;
            $self->log_result(Timeout->new(
                url => $data->{url},
            ));
        },
    );
    $guard = http_post
        $data->{url},
        $body,
        headers => $headers,
        timeout => $timeout + 5,
        sub {
            undef $guard;
            undef $timer;
            my ($body, $headers) = @_;
            if ($headers->{Status} =~ /2\d\d/) {
                $self->log_result(Success->new(
                    url => $data->{url},
                ));
            }
            else {
                $self->log_result(Failure->new(
                    url => $data->{url} || 'No url!',
                    code => $headers->{Status},
                ));
            }
            #use Data::Dumper; warn Dumper(\@_);
        };
}

1;

=head1 NAME

Log::Stash::Output::WebHooks - call 'WebHooks' with logstash messages.

=head1 SYNOPSIS

    logstash --input STDIN --output WebHooks

    You type:
    {"url": "http://localhost:5000/test","@type":"WebHooks","data":{"foo":"bar"}}

    Causes:

    POST /test HTTP/1.1
    Host: localhost:5000
    Content-Length: 13
    Content-Type application/json

    {"foo":"bar"}

=head1 WHAT IS A WEBHOOK

A web-hook is an a notification method used by APIs.

The idea is that you (as a client) define a URI on your website which is called when a certain action
happens at your API provider. Some data relevant to the event is serialized out to you, allowing you
to take action.

The canonical example is Paypal's IPN system, in which Paypal make a call to your online payment system to
verify that a payment has been made.

See the L</SEE ALSO> section below for other examples.

=head1 DESCRIPTION

This class expects to have it's consume method called with a has of parameters, including:

=over

=item @url

The URL to make the request to.

=item data

The data to serialize out to the HTTP post request

=back

=head1 USAGE

As a L<Log::Stash> component, input is easy - if you're writing asynchronous perl code already,
you can use the L<Log::Stash::Output::WebHooks> class directly in your perl code, or
you can use L<Log::Dispatch::Log::Stash> to divert your application logs into it via the
L<Log::Dispatch> framework. 

If you're not already an L<AnyEvent> perl app (most people!), then you can use
L<Log::Stash::Input::STDIN>, L<Log::Stash::Input::ZeroMQ>
or any other input class, and the command line logstash utility supplied to run a worker
process, then send messages to it.

To send messages, you can either use Java or Ruby logstash L<http://logstash.net/>, or
if you're in perl, then it's entirely possible to use the L<ZeroMQ> output component,
L<Log::Stash::Output::ZeroMQ> from within a normal perl application (via L<Log::Dispatch::Log::Stash>
or directly).

=head1 METHODS

=head2 consume

Generates and sends the post request from the message passed.

=head1 SEE ALSO

=over

=item L<Log::Stash>

=item L<http://logstash.net>

=item L<http://wiki.shopify.com/WebHook>

=back

=head1 AUTHOR

Tomas (t0m) Doran <bobtfish@bobtfish.net>

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored it's development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API - 
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 COPYRIGHT

Copyright Suretec Systems 2012.

=head1 LICENSE

GNU Affero General Public License, Version 3

If you feel this is too restrictive to be able to use this software,
please talk to us as we'd be willing to consider re-licensing under
less restrictive terms.

=cut

1;

