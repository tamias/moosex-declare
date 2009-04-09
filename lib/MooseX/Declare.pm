use strict;
use warnings;

package MooseX::Declare;

use MooseX::Method::Signatures;
use aliased 'MooseX::Declare::Syntax::Keyword::Class', 'ClassKeyword';
use aliased 'MooseX::Declare::Syntax::Keyword::Role',  'RoleKeyword';

use namespace::clean;

our $VERSION = '0.19';

sub import {
    my ($class, %args) = @_;

    my $caller = caller();

    strict->import;
    warnings->import;

    for my $keyword ($class->keywords) {
        $keyword->setup_for($caller, %args);
    }

    MooseX::Method::Signatures->setup_for($caller)
}

sub keywords {
    ClassKeyword->new(identifier => 'class'),
    RoleKeyword->new(identifier => 'role'),
}

1;

__END__

=head1 NAME

MooseX::Declare - Declarative syntax for Moose

=head1 SYNOPSIS

    use MooseX::Declare;

    class BankAccount {
        has 'balance' => ( isa => 'Num', is => 'rw', default => 0 );

        method deposit (Num $amount) {
            $self->balance( $self->balance + $amount );
        }

        method withdraw (Num $amount) {
            my $current_balance = $self->balance();
            ( $current_balance >= $amount )
                || confess "Account overdrawn";
            $self->balance( $current_balance - $amount );
        }
    }

    class CheckingAccount extends BankAccount {
        has 'overdraft_account' => ( isa => 'BankAccount', is => 'rw' );

        before withdraw (Num $amount) {
            my $overdraft_amount = $amount - $self->balance();
            if ( $self->overdraft_account && $overdraft_amount > 0 ) {
                $self->overdraft_account->withdraw($overdraft_amount);
                $self->deposit($overdraft_amount);
            }
        }
    }

=head1 DESCRIPTION

This module provides syntactic sugar for Moose, the postmodern object system
for Perl 5. When used, it sets up the C<class> and C<role> keywords.

=head1 KEYWORDS

=head2 class

    class Foo { ... }

    my $anon_class = class { ... };

Declares a new class. The class can be either named or anonymous, depending on
whether or not a classname is given. Within the class definition Moose and
L<MooseX::Method::Signatures> are set up automatically in addition to the other
keywords described in this document. At the end of the definition the class
will be made immutable. namespace::clean is injected to clean up Moose for you.

Because of the way the options are parsed, you cannot have a class named "is",
"with" or "extends".

It's possible to specify options for classes:

=over 4

=item extends

    class Foo extends Bar { ... }

Sets a superclass for the class being declared.

=item with

    class Foo with Role { ... }

Applies a role to the class being declared.

=item is mutable

    class Foo is mutable { ... }

Causes the class not to be made immutable after its definition.

Options can also be provided for anonymous classes using the same syntax:

    my $meta_class = class with Role;

=back

=head2 role

    role Foo { ... }

    my $anon_role = role { ... };

Declares a new role. The role can be either named or anonymous, depending on
wheter or not a name is given. Within the role definition Moose::Role and
MooseX::Method::Signatures are set up automatically in addition to the other
keywords described in this document. Again, namespace::clean is injected to
clean up Moose::Role and for you.

It's possible to specify options for roles:

=over 4

=item with

    role Foo with Bar { ... }

Applies a role to the role being declared.

=back

=head2 before / after / around / override / augment

    before   foo ($x, $y, $z) { ... }
    after    bar ($x, $y, $z) { ... }
    around   baz ($x, $y, $z) { ... }
    override moo ($x, $y, $z) { ... }
    augment  kuh ($x, $y, $z) { ... }

Add a method modifier. Those work like documented in L<Moose|Moose>, except for
the slightly nicer syntax and the method signatures, which work like documented
in L<MooseX::Method::Signatures|MooseX::Method::Signatures>.

For the C<around> modifier an additional argument called C<$orig> is
automatically set up as the invocant for the method.

=head2 clean

When creating a class with MooseX::Declare like:

    use MooseX::Declare;
    class Foo { ... }

What actually happens is something like this:

    {
        package Foo;
        use Moose;
        use namespace::clean -except => 'meta';
        ...
        __PACKAGE__->meta->mate_immutable();
        1;
    }

So if you declare imports outside the class, the symbols get imported into the
C<main::> namespace, not the class' namespace. The symbols then cannot be called
from within the class:

    use MooseX::Declare;
    use Data::Dump qw/dump/;
    class Foo {
        method dump($value) { return dump($value) } # Data::Dump::dump IS NOT in Foo::
        method pp($value)   { $self->dump($value) } # an alias for our dump method
    }

Furthermore, any imports will not be cleaned up by L<namespace::clean> after
compilation since the class knows nothing about them! The temptation to do this
may stem from wanting to keep all your import declarations in the same place.

The solution is two-fold. First, only import MooseX::Declare outside the class
definition (because you have to). Make all other imports inside the class definition
and clean up with the C<clean> keyword:

    use MooseX::Declare;
    class Foo {
        use Data::Dump qw/dump/;
        clean;
        method dump($value) { return dump($value) } # Data::Dump::dump IS in Foo::
        method pp($value)   { $self->dump($value) } # an alias for our dump method
    }

    Foo->new->dump($some_value);
    Foo->new->pp($some_value);

B<NOTE> that the import C<Data::Dump::dump()> and the method C<Foo::dump()>,
although having the same name, do not conflict with each other.

=head1 SEE ALSO

L<Moose>

L<Moose::Role>

L<MooseX::Method::Signatures>

L<namespace::clean>

=head1 AUTHOR

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

With contributions from:

=over 4

=item Ash Berlin E<lt>ash@cpan.orgE<gt>

=item Hans Dieter Pearcey E<lt>hdp@cpan.orgE<gt>

=item Nelo Onyiah E<lt>nelo.onyiah@gmail.comE<gt>

=item Piers Cawley E<lt>pdcawley@bofh.org.ukE<gt>

=item Tomas Doran E<lt>bobtfish@bobtfish.netE<gt>

=item Yanick Champoux E<lt>yanick@babyl.dyndns.orgE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008, 2009  Florian Ragwitz

Licensed under the same terms as perl itself.

=cut
