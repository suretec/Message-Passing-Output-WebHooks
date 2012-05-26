use strict;
use warnings;
use inc::Module::Install;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;
use Module::Install::Authority;

all_from 'lib/Message/Passing/Output/WebHooks.pm';

license 'AGPL_3';
authority('GHENRY');
resources(
    repository => "git://github.com/suretec/Message-Passing-Output-WebHooks.git",
);

requires 'Moose';
requires 'namespace::autoclean';
requires 'AnyEvent';
requires 'AnyEvent::HTTP';
requires 'JSON';
requires 'JSON::XS';
requires 'Try::Tiny';
requires 'Log::Message::Structured' => '0.005';
requires 'aliased';
requires 'Message::Passing' => '0.002';

test_requires 'Plack';
test_requires 'Twiggy';

author_requires(
    'Test::Pod' => '1.14',
    'Test::NoTabs' => '0',
    'Test::Pod::Coverage' => '1.04',
    'Pod::Coverage' => '0.19',
    'Pod::Coverage::TrustPod' => '0',
    'Test::Spelling' => '0',
);

author_tests 't/author';

install_script 'script/message-passing_webhooks';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Message/Passing/Output/WebHooks.pm > README")
        and die $!;
}

WriteAll;

