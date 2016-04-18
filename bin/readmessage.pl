use strict;
use warnings;
use Emailish::Repo;
use Emailish::Message;
use Getopt::Long::Descriptive;
use Path::Tiny;
use feature "say";


my ($opt, $usage) = describe_options(
  "$0 %o",
    [ 'from|f=s', 'Path to repo dir (directory containing repo directories)',            {required => 1} ],
    [ 'id|f=s', 'Reference ID of message to output to stdout (get ID from readrepo.pl)', {required => 1} ],
    [],
    [ 'help', 'print usage message and exit' ],
);
if( $opt->help ) {
    say $usage->text; 
    exit; 
}

my $repodir = path($opt->from);

say "Message path: " . $repodir->child($opt->id);
my $repo = Emailish::Repo->new(prefix => $repodir);
my $message = $repo->fetch($opt->id);
say $message->as_string;