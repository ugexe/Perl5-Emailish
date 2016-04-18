use strict;
use warnings;
use Emailish::Repo;
use Emailish::Message;
use Getopt::Long::Descriptive;
use Path::Tiny;
use feature "say";

my ($opt, $usage) = describe_options(
  "$0 %o",
    [ 'from|f=s', 'Path to Maildir',     {required => 1} ],
    [ 'to|o:s',   'Path to output repo', {required => 1} ],
    [],
    [ 'help', 'print usage message and exit'             ],
);
if( $opt->help ) {
    say $usage->text; 
    exit; 
}

my $maildir = path($opt->from);
my $repodir = path($opt->to);

say "Maildir path: $maildir";
say "Repo path: $repodir";

my @mdir_emails = map { Emailish::Message->new($_) }
                  map { $_->slurp                  }
                  $maildir->children;
my $repo = Emailish::Repo->new(prefix => $repodir);

say "Storing messages from [" . $maildir->basename . "] to [" . $repodir->basename . "]";
$repo->commit($_) for @mdir_emails;
