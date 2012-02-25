use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Log::Stash::Output::WebHooks;
use Log::Stash::Output::Test;
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

my $log_cv = AnyEvent->condvar;
my $log = Log::Stash::Output::Test->new(
    on_consume_cb => sub { $log_cv->send(shift()) },
);
my $output = Log::Stash::Output::WebHooks->new(log => $log);

my $publish; $publish = AnyEvent->idle(cb => sub {
     undef $publish;
    $output->consume({
        url => "http://localhost:5000/",
        data => {
            foo => "bar",
        },
    });
});

is $cv->recv, '{"foo":"bar"}';

my $log_event = $log_cv->recv;
is $log_event . '', 'webhook call to http://localhost:5000/ succeeded';
isa_ok($log_event, 'Log::Stash::WebHooks::Event::Call::Success');
is $log_event->url, 'http://localhost:5000/';

done_testing;

