use strict;
use warnings;

package Emailish::Repo {
    use Moose;
    use MooseX::Types::Path::Tiny qw/Path Paths/;
    use namespace::autoclean;

    use Emailish::Message;
    use Function::Parameters;
    use YAML::Tiny;
    use Digest::SHA1 qw( sha1_hex );


    has 'prefix' => ( is => 'rw', isa => Path, coerce => 1, );

    # Kit/Mailbox folder layout and structure
    # $prefix/                                     # Root of mailbox
    # $prefix/$content_id                          # Sha1 hash of entity as string (!)
    # $prefix/$content_id/.manifest.yml            # The content_id for the head and body parts (depth first order)
    # $prefix/$content_id/.header.yml              # Store the header as a key-value
    # $prefix/$content_id/content/<content files>  # File names are from the sha1 hashes in .manifest.yml
    # $prefix/$content_id/body.txt (Optional)      # A copy of the text of the message body (if found)
    # $prefix/$content_id/body.htm (Optional)      # A copy of the html of the message body (if found)

    method commit(Emailish::Message $email) {
        my $repo_dir    = $self->repo_dir($email);
        my $content_dir = $self->content_dir($email);

        # Write header to its own structured file
        my @headers = $email->_as_header_kv;
        my $header_yml  = YAML::Tiny->new({
            head => _commit_header($email, dir => $content_dir),
            id   => $repo_dir->basename, # digest of entire message
        })->write_string;
        $repo_dir->child('.header.yml')->spew_utf8($header_yml);

        # Depth first; (first item is always the primary message part with `parts_DFS`)
        # XXX: Not sure if this is handled correctly, but currently you will
        # notice we shift off into $primary but never use it. I've done this
        # because I think the body of parts_DFS(0) is redundant against
        # the body of the remaining parts
        my @parts   = $email->mime_entity->parts_DFS;
        my $primary = shift(@parts);

        # Write each part to its own file (sha1 of content) to $repo_id/content/<sha1>
        # XXX: These are not the optimizations you were looking for...
        my $manifest_yml = YAML::Tiny->new;
        foreach my $part ( @parts ) {
            push @$manifest_yml, { 
                head      => _commit_header_part($part, dir => $content_dir),
                body      => _commit_body_part($part, dir => $content_dir),
                filename  => $part->head->recommended_filename,
                #size     => xxx,
            };
        }
        $manifest_yml->write( $content_dir->parent->child('.manifest.yml') );

        return $email;
    }

    around 'commit' => fun($orig, $self, @args) {
        my $email    = $self->$orig(@args);
        my $repo_dir = $self->repo_dir($email);
        my $text  = $email->_as_body_text; # I cheated and did not index these in the manifest
        my $html  = $email->_as_body_html; # because these parts are also saved in the content store
        $repo_dir->child('body.txt')->spew_utf8($text) if $text && $text ne '';
        $repo_dir->child('body.htm')->spew_utf8($html) if $html && $text ne '';
        return $email;
    };


    # Build message from multiple parts/files
    # This doesn't get passed $email like everything else because i'm not sure how
    # well I can rely on the sha1 to stay consistent after getting put through some number
    # of message/entity transformations.
    # Also it concats the files as strings from a slurp_raw... Demonstrational purposes only!!1
    method fetch($repo_id) {
        my $repo_dir      = $self->prefix->child($repo_id);
        my $content_dir   = $repo_dir->child('content');
        my $header_id_yml = YAML::Tiny->read( $repo_dir->child('.header.yml')   )->[0];
        my $manifest_yaml = YAML::Tiny->read( $repo_dir->child('.manifest.yml') );

        my $build_header_from =  $content_dir->child($header_id_yml->{head})->slurp_raw;
        my @build_body_from =
            map { $content_dir->child($_->{head})->slurp_raw
                . $content_dir->child($_->{body})->slurp_raw
            } (@{ $manifest_yaml });

        # ...
        my $build_from = join "\n", $build_header_from, @build_body_from;
        return Emailish::Message->new($build_from);
    }


    # List of subdirectories of $self->prefix that contain a .manifest.yml (a repo)
    method repos {
        grep { $_->exists                 }
        map  { $_->child('.manifest.yml') }
        grep { $_->is_dir                 }
        $self->prefix->children;
    }


    # ! The following methods would fit better in a Email/Message class
    # ! as they rely on the digest of the message content in some way.

    # Centralize path handling routines
    method repo_dir(Emailish::Message $email) {
        my $repo_dir = $self->prefix->child($email->content_id);
        $repo_dir->mkpath(0, 700);
        return $repo_dir;
    }
    method content_dir(Emailish::Message $email) {
        my $content_dir = $self->repo_dir($email)->child('content');
        $content_dir->mkpath(0, 0700);
        return $content_dir;
    }
    method manifest_filename(Emailish::Message $email) {
        return $self->repo_dir($email)->child('.manifest.yml');
    }
    method meta_filename(Emailish::Message $email) {
        return $self->repo_dir($email)->child('.manifest.yml');
    }
    # This is the file the raw header is stored. Right now this is redundant
    # with the fields saved in the `meta_filename`, and just makes it easier
    # to "combine all these files in this order"
    method header_filename(Emailish::Message $email) {
        return $self->repo_dir($email)->child('.manifest.yml');
    }


    fun _commit_header($email, :$dir) {
        my $temp = Path::Tiny->tempfile;
        $email->mime_entity->print_header($temp->openw);
        my $id   = $temp->digest;
        my $file = $dir->child($id);
        $temp->copy( $file );
        chmod 0600, $file;
        return $id;
    }
    fun _commit_header_part($part, :$dir) {
        my $temp = Path::Tiny->tempfile;
        $part->print_header($temp->openw);
        my $id   = $temp->digest;
        my $file = $dir->child($id);
        $temp->copy( $file );
        chmod 0600, $file;
        return $id;
    }
    # like _commit_header_part, but calls `->bodyhandle`
    fun _commit_body_part($part, :$dir) {
        my $temp = Path::Tiny->tempfile;
        $part->bodyhandle->print($temp->openw) if $part->bodyhandle;
        my $id   = $temp->digest;
        my $file = $dir->child($id);
        $temp->copy( $file );
        chmod 0600, $file;
        return $id;
    }


    __PACKAGE__->meta->make_immutable;
}
