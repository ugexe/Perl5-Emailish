use strict;
use warnings;


package Emailish::Message {
    use Moose;
    use namespace::autoclean;

    use Email::Abstract;
    use Function::Parameters;
    use Digest::SHA1 qw( sha1_hex );


    has '_abstract' => (
        is      => 'ro',
        isa     => 'Email::Abstract',
        handles => qr/.*/,
    );

    has 'mime_entity' => (
        is      => 'ro',
        builder => '_build_mime_entity',
        lazy    => 1,
    );

    around BUILDARGS => fun($orig, $class, @args) {
        return $class->$orig(_abstract => Email::Abstract->new(@args));
    };

    method _build_mime_entity { $self->cast('MIME::Entity') }


    method content_id {
        return sha1_hex($self->mime_entity->get('Message-ID') || $self->as_string);
    }

    method _as_body_html {
        my $mime = $self->mime_entity;
        return unless $mime->parts(0) || $mime->parts(1);
        return $mime->parts(0)->body_as_string
            if $mime->parts(0)->mime_type =~ /html/;
        return $mime->parts(1)->body_as_string
            if $mime->parts(1)->mime_type =~ /html/;
    }

    method _as_body_text {
        my $mime = $self->mime_entity;
        return unless $mime->parts(0) || $mime->parts(1);
        return $mime->parts(0)->body_as_string
            if $mime->parts(0)->mime_type =~ /text/;
        return $mime->parts(1)->body_as_string
            if $mime->parts(1)->mime_type =~ /text/;
    }

    method _as_header_kv {
        map { $_ => $self->mime_entity->get($_) }
        $self->mime_entity->head->tags;
    }


    __PACKAGE__->meta->make_immutable;
}

=pod
package Emailish::Abstract {
    use MooseX::Interface;

    # Provided by Email::Abstract
    requires 'get_header';
    requires 'set_header';
    requires 'get_body';
    requires 'set_body';
    requires 'as_string';
    requires 'cast';
    requires 'object';

    # Provided by Emailish::Message
    requires 'content_id';
    requires 'mime_entity';
    requires '_as_header_kv';

    one;
}
=cut
