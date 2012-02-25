use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/Log/Stash/Output/WebHooks.pm';

requires 'Moose';
requires 'namespace::autoclean';
requires 'AnyEvent';
requires 'AnyEvent::HTTP';
requires 'JSON';
requires 'JSON::XS';
requires 'Try::Tiny';

test_requires 'Plack';
test_requires 'Twiggy';

WriteAll;

