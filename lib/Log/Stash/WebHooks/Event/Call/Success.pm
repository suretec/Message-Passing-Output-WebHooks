package Log::Stash::WebHooks::Event::Call::Success;
use Moose;

with 'Log::Stash::WebHooks::Event::Call';

with 'Log::Message::Structured::Stringify::Sprintf' => {
    format_string => "webhook call to %s succeeded",
    attributes => [qw/ url /],
}, 'Log::Message::Structured';

no Moose;
__PACKAGE__->meta->make_immutable;
1;

