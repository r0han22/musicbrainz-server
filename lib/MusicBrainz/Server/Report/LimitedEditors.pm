package MusicBrainz::Server::Report::LimitedEditors;
use Moose;

use MusicBrainz::Server::Constants qw( $EDITOR_MODBOT );

with 'MusicBrainz::Server::Report::QueryReport';

sub query { "
SELECT id, name, email, website, bio, member_since, email_confirm_date,
       last_login_date, last_updated, deleted,
       row_number() OVER (ORDER BY id DESC)
  FROM editor eor
 WHERE id != $EDITOR_MODBOT
   AND NOT deleted
   AND   ( email_confirm_date IS NULL
        OR member_since < NOW() - INTERVAL '2 weeks'
        OR (SELECT COUNT(*) FROM edit WHERE eor.id = edit.editor AND edit.status = 2 AND edit.autoedit = 0) < 10
         )";
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 MetaBrainz Foundation

This file is part of MusicBrainz, the open internet music database,
and is licensed under the GPL version 2, or (at your option) any
later version: http://www.gnu.org/licenses/gpl-2.0.txt

=cut
