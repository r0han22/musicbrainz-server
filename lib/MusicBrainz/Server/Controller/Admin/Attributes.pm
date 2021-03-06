package MusicBrainz::Server::Controller::Admin::Attributes;
use Moose;

no if $] >= 5.018, warnings => "experimental::smartmatch";

BEGIN { extends 'MusicBrainz::Server::Controller' };

my @models = qw(
    AreaType
    ArtistType
    CollectionType
    CoverArtType
    EventType
    Gender
    InstrumentType
    LabelType
    Language
    MediumFormat
    PlaceType
    ReleaseGroupType
    ReleaseGroupSecondaryType
    ReleaseStatus
    ReleasePackaging
    Script
    SeriesType
    WorkType
    WorkAttributeType
);
# Missing: Alias types, WorkAttributeTypeAllowedValue

sub index : Path('/admin/attributes') Args(0) RequireAuth(account_admin) {
    my ($self, $c) = @_;

    $c->stash(
        current_view => 'Node',
        component_path => 'admin/attributes/Index.js',
        component_props => {models => \@models}
    );
}

sub attribute_base : Chained('/') PathPart('admin/attributes') CaptureArgs(1) RequireAuth(account_admin) {
    my ($self, $c, $model) = @_;

    $c->detach('/error_404') unless $model ~~ @models;

    $c->stash->{model} = $model;
}

sub attribute_index : Chained('attribute_base') PathPart('') RequireAuth(account_admin) {
    my ($self, $c) = @_;
    my $model = $c->stash->{model};
    my @attr = $c->model($model)->get_all();

    my %component_paths = (
        Language => "admin/attributes/Language.js",
        Script => "admin/attributes/Script.js"
    );
    my $component_path = $component_paths{$model} // "admin/attributes/Attribute.js";

    $c->stash(
        current_view => 'Node',
        component_path => $component_path,
        component_props => {attributes => \@attr, model => $model}
    );
}

sub create : Chained('attribute_base') RequireAuth(account_admin) SecureForm {
    my ($self, $c) = @_;
    my $model = $c->stash->{model};

    my %forms = (
        Language => "Admin::Attributes::Language",
        Script => "Admin::Attributes::Script"
    );
    my $form_name = $forms{$model} // "Admin::Attributes";
    my $form = $c->form( form => $form_name );

    if ($c->form_posted_and_valid($form)) {
        $c->model('MB')->with_transaction(sub {
            $c->model($model)->insert({ map { $_->name => $_->value } $form->edit_fields });
        });

        $c->response->redirect($c->uri_for('/admin/attributes', $model));
        $c->detach;
    }
}

sub edit : Chained('attribute_base') Args(1) RequireAuth(account_admin) SecureForm {
    my ($self, $c, $id) = @_;
    my $model = $c->stash->{model};
    my $attr = $c->model($model)->get_by_id($id);

    my %forms = (
        Language => "Admin::Attributes::Language",
        Script => "Admin::Attributes::Script"
    );
    my $form_name = $forms{$model} // "Admin::Attributes";
    my $form = $c->form( form => $form_name, init_object => $attr );

    if ($c->form_posted_and_valid($form)) {
        $c->model('MB')->with_transaction(sub {
            $c->model($model)->update($id, { map { $_->name => $_->value } $form->edit_fields });
        });

        $c->response->redirect($c->uri_for('/admin/attributes', $model));
        $c->detach;
    }
}

sub delete : Chained('attribute_base') Args(1) RequireAuth(account_admin) SecureForm {
    my ($self, $c, $id) = @_;
    my $model = $c->stash->{model};
    my $attr = $c->model($model)->get_by_id($id);
    my $form = $c->form(form => 'SecureConfirm');
    $c->stash->{attribute} = $attr;

    if ($c->model($model)->in_use($id)) {
        $c->stash->{template} = 'admin/attributes/in_use.tt';
        $c->detach;
    }

    if ($c->form_posted_and_valid($form)) {
        $c->model('MB')->with_transaction(sub {
            $c->model($model)->delete($id);
        });

        $c->response->redirect($c->uri_for('/admin/attributes', $model));
        $c->detach;
    }
}

1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 MetaBrainz Foundation

This file is part of MusicBrainz, the open internet music database,
and is licensed under the GPL version 2, or (at your option) any
later version: http://www.gnu.org/licenses/gpl-2.0.txt

=cut
