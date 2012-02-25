package Log::Stash::Output::WebHooks;
use Moose;
use AnyEvent::HTTP;
use aliased 'Log::Stash::WebHooks::Event::Call::Success';
use aliased 'Log::Stash::WebHooks::Event::Call::Timeout';
use namespace::autoclean;

our $VERSION = '0.001';
$VERSION = eval $VERSION;

with 'Log::Stash::Role::Output';

has log => (
    does => 'Log::Stash::Role::Output',
    handles => {
        log => 'consume',
    },
    default => sub { require Log::Stash::Output::Null; Log::Stash::Output::Null->new },
);

sub consume {
    my ($self, $data) = @_;
    my $body = $self->encode($data->{parameters});
    # XXX FIXME http://wiki.shopify.com/Verifying_Webhooks
    # HMAC goes here.
    #warn "MAKE POST to " . $data->{url};
    my $headers = {};
    http_post $data->{url}, $body, headers => $headers, sub {
        my ($body, $headers) = @_;
        warn "POST CALLBACK";
        if ($headers->{Status} =~ /2\d\d/) {
            $self->log(Success->new(
                url => $data->{url},
            ));
        }
        use Data::Dumper; warn Dumper(\@_);
    };
}

1;

=head1 NAME

Log::Stash::Output::WebHooks - call 'WebHooks' with logstash messages.

=head1 WHAT IS A WEBHOOK

=head1 DESCRIPTION

=head1 SEE ALSO

=over

=item L<Log::Stash>

=item L<http://logstash.net>

=item L<http://wiki.shopify.com/WebHook>

=back

=head1 AUTHOR

Tomas (t0m) Doran <bobtfish@bobtfish.net>

=head1 SPONSORSHIP

This module exists due to the wonderful people at
L<Suretec Systems|http://www.suretecsystems.com/> who sponsored it's
development.

=head1 COPYRIGHT

Copyright Suretec Systems 2012.

=head1 LICENSE

XXX - TODO

