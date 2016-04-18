use strict;
use warnings;
use Emailish::Repo;
use Emailish::Message;
use Getopt::Long::Descriptive;
use Path::Tiny;
use feature "say";


my ($opt, $usage) = describe_options(
  "$0 %o",
    [ 'from|f=s', 'Path to repo dir (directory containing repo directories)', {required => 1} ],
    [],
    [ 'help', 'print usage message and exit' ],
);
if( $opt->help ) {
    say $usage->text; 
    exit; 
}

my $repodir = path($opt->from);

say "Repo path: $repodir";
my $repo = Emailish::Repo->new(prefix => $repodir);
my @messages =  map { $repo->fetch($_)           } 
                map { path($_)->parent->basename }
                $repo->repos;

my $message_count;
say '________________________';
foreach my $message ( @messages ) {
    say "Message: " . ++$message_count;
    print "\tStore:"    . $repodir->child($message->content_id) . "\n";
    print "\tRef ID: "  . $message->content_id                  . "\n";
    print "\tFrom: "    . $message->mime_entity->get('From');
    print "\tSubject: " . $message->mime_entity->get('Subject');
}
