use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/Log/Stash/Output/WebHooks.pm';

license 'AGPL_3';

requires 'Moose';
requires 'namespace::autoclean';
requires 'AnyEvent';
requires 'AnyEvent::HTTP';
requires 'JSON';
requires 'JSON::XS';
requires 'Try::Tiny';
requires 'Log::Message::Structured' => '0.005';
requires 'aliased';
requires 'Log::Stash' => '0.001';

test_requires 'Plack';
test_requires 'Twiggy';

author_requires 'Test::Pod' => '1.14';
author_requires 'Test::NoTabs';
author_requires 'Test::Pod::Coverage' => '1.04';
author_requires 'Pod::Coverage' => '0.19';
author_requires 'Pod::Coverage::TrustPod';
author_requires 'Test::Spelling';

author_tests 't/author';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Log/Stash/Output/WebHooks.pm > README")
        and die $!;
}

WriteAll;

