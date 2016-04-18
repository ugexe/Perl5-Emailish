use strict;
use Test::More tests => 2;
use Emailish::Repo;
use Emailish::Message;
use Path::Tiny;


my $maildir_test = path("t/test-mails/maildir/with-attachment.txt");
my $repo_test    = path("t/test-mails/repo/");
my $repo         = Emailish::Repo->new(prefix => $repo_test);
my $message_id   = 'e61b63abe0bf481dbc3de1ac6bb1399ddfea6be5';

subtest 'From maildir' => sub {
    my @message_data = $maildir_test->slurp;
    my $message     = new_ok('Emailish::Message' => \@message_data);
    is($message->content_id, $message_id,  'sha1 of message id matches');
    is($message->mime_entity->get('From'), "Ricardo Signes <rjbs\@icgroup.com>\n", 'Entity "From" is correct');
    is($message->mime_entity->parts, 2,    "Correct number of message parts");

    # This also creates a repo in t/test-mails/repo so further tests will
    # (rightfully) fail if this test fails.
    # TODO: use temp directory to cleanup
    isa_ok($repo->commit($message), 'Emailish::Message');
};

subtest 'From repo' => sub {
    my $message = $repo->fetch($message_id);
    isa_ok($message, 'Emailish::Message');
    is($message->content_id, $message_id,  'sha1 of message id matches');
    is($message->mime_entity->get('From'), "Ricardo Signes <rjbs\@icgroup.com>\n", 'Entity "From" is correct');

    # I imagine the epilogue and preamble would be stored in `.manifest.yml` for each part.
    # Due to those parts not being stored yet the created message loses its overall structure
    TODO: {
        local $TODO = 'Preamble and epilogue are not yet indexed';
        is($message->mime_entity->parts, 2, "Correct number of message parts");
    };
};
