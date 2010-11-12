package MusicBrainz::Server::Edit::Label::Create;
use Moose;

use MooseX::Types::Moose qw( Int Str );
use MooseX::Types::Structured qw( Dict Optional );
use Moose::Util::TypeConstraints qw( subtype find_type_constraint );
use MusicBrainz::Server::Constants qw( $EDIT_LABEL_CREATE );
use MusicBrainz::Server::Edit::Types qw( Nullable PartialDateHash );
use MusicBrainz::Server::Entity::Types;
use MusicBrainz::Server::Data::Utils qw( partial_date_from_row );
use MusicBrainz::Server::Translation qw( l ln );

extends 'MusicBrainz::Server::Edit::Generic::Create';

sub edit_name { l('Add label') }
sub edit_type { $EDIT_LABEL_CREATE }
sub _create_model { 'Label' }
sub label_id { shift->entity_id }

has '+data' => (
    isa => Dict[
        name => Str,
        sort_name => Str,
        type_id => Nullable[Int],
        label_code => Nullable[Int],
        begin_date => Nullable[PartialDateHash],
        end_date => Nullable[PartialDateHash],
        country_id => Nullable[Int],
        comment => Nullable[Str],
    ]
);

sub foreign_keys
{
    my $self = shift;

    return {
        LabelType => [ $self->data->{type_id} ],
        Country   => [ $self->data->{country_id} ],
    };
}

sub build_display_data
{
    my ($self, $loaded) = @_;

    my $data = {
        name       => $self->data->{name},
        sort_name  => $self->data->{sort_name},
        type       => $loaded->{LabelType}->{ $self->data->{type_id} },
        label_code => $self->data->{label_code},
        country    => $loaded->{Country}->{ $self->data->{country_id} },
        comment    => $self->data->{comment},
        begin_date => partial_date_from_row($self->data->{begin_date}),
        end_date   => partial_date_from_row($self->data->{end_date}),
    };
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
