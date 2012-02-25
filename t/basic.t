use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Log::Stash::Output::WebHooks;
use Log::Stash::Output::Test;
use Plack::Request;

my $respond;
my $cv = AnyEvent->condvar;
my $app = sub {
    my $env = shift;
    my $r = Plack::Request->new($env);
    my $bytes = $r->content;
    $cv->send($bytes);
    if ($env->{PATH_INFO} eq '/timeout') {
        return sub {
            $respond = shift;
            # $respond->([ 200, $headers, [ $content ] ]);
        };
    }
    if (my ($code) = $env->{PATH_INFO} =~ m{^/code/(\d+)$}) {
        return [ $code, [ 'Content-Type' => 'text/html' ], [ "Error $code" ] ];
    }
    return [ '200', [ 'Content-Type' => 'text/html' ], [ "Ok" ] ]
};

use Twiggy::Server;
my $s = Twiggy::Server->new(port => 5000);
$s->register_service($app);

my $log_cv = AnyEvent->condvar;
my $log = Log::Stash::Output::Test->new(
    on_consume_cb => sub { $log_cv->send(shift()) },
);
my $output = Log::Stash::Output::WebHooks->new(log => $log, timeout => 2,);

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

$cv = AnyEvent->condvar;
$log_cv = AnyEvent->condvar;

$publish = AnyEvent->idle(cb => sub {
     undef $publish;
    $output->consume({
        url => "http://localhost:5000/code/500",
        data => {
            foo => "bar",
        },
    });
});
is $cv->recv, '{"foo":"bar"}';

$log_event = $log_cv->recv;
is $log_event . '', 'webhook call to http://localhost:5000/code/500 failed, return code 500';
isa_ok($log_event, 'Log::Stash::WebHooks::Event::Call::Failure');
is $log_event->url, 'http://localhost:5000/code/500';
is $log_event->code, '500';

$cv = AnyEvent->condvar;
$log_cv = AnyEvent->condvar;

$publish = AnyEvent->idle(cb => sub {
     undef $publish;
    $output->consume({
        url => "http://localhost:5000/timeout",
        data => {
            foo => "bar",
        },
    });
});
is $cv->recv, '{"foo":"bar"}', "Please wait - testing timeouts";

$log_event = $log_cv->recv;
is $log_event . '', 'webhook call to http://localhost:5000/timeout timed out';
isa_ok($log_event, 'Log::Stash::WebHooks::Event::Call::Timeout');
is $log_event->url, 'http://localhost:5000/timeout';
undef $respond;

done_testing;

