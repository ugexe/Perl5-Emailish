use strict;
use warnings; 
use ExtUtils::MakeMaker;

WriteMakefile (  
    NAME           => 'Emailish',
    ABSTRACT       => 'A mdbox style mail storage prototype',
    AUTHOR         => '<ugexe@cpan.org>',
    LICENSE        => 'perl',
    MIN_PERL_VERSION => '5.014',
    PREREQ_PM      => {
        'Getopt::Long::Descriptive' => 0,
        'Email::Abstract'           => 0,
        'MIME::Entity'              => 0,
        'YAML::Tiny'                => 0,
        'Moose'                     => 0,
        'MooseX::Types::Path::Tiny' => 0,
        'Path::Tiny'                => 0,
        'namespace::autoclean'      => 0,
        'Digest::SHA1'              => 0,
        'Function::Parameters'      => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    META_MERGE => {
        provides => {
            'Emailish::Message' => {
                file    => 'lib/Emailish/Message.pm',
            },
            'Emailish::Repo' => {
                file    => 'lib/Emailish/Repo.pm',
            },
        },
    },
);
