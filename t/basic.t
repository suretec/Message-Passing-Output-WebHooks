use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Log::Stash::Output::WebHooks;
use Plack::Request;

my $cv = AnyEvent->condvar;
my $app = sub {
    my $env = shift;
    my $r = Plack::Request->new($env);
    my $bytes = $r->content;
    $cv->send($bytes);
#    warn Dumper($env);
    return [ '200', [ 'Content-Type' => 'text/html' ], [ "Ok" ] ]
};

use Twiggy::Server;
my $s = Twiggy::Server->new(port => 5000);
$s->register_service($app);

my $output = Log::Stash::Output::WebHooks->new();

my $publish; $publish = AnyEvent->idle(cb => sub {
     undef $publish;
    $output->consume({
        url => "http://localhost:5000/",
        parameters => {
            foo => "bar",
        },
    });
});

is $cv->recv, '{"foo":"bar"}';

done_testing;

