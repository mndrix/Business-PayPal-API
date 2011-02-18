package Business::PayPal::API::GetBalance;

use 5.008001;
use strict;
use warnings;

use SOAP::Lite 0.67;
use Business::PayPal::API ();

our @ISA = qw(Business::PayPal::API);
our $VERSION = '0.12';
our $CVS_VERSION = '$Id: GetBalance.pm,v 1.5 2009/07/28 18:00:59 scott Exp $';
our @EXPORT_OK = qw(GetBalance);  ## fake exporter

sub GetBalance {
    my $self = shift;
    my %args = @_;

    my @trans =
      (
       $self->version_req,
       SOAP::Data->name( ReturnAllCurrencies => $args{ReturnAllCurrencies} )->type( 'xs:string' ),
      );

    my $request = SOAP::Data->name
      ( GetBalanceRequest => \SOAP::Data->value( @trans ) )
	->type("ns:GetBalanceRequestType");

    my $som = $self->doCall( GetBalanceReq => $request )
      or return;

    my $path = '/Envelope/Body/GetBalanceResponse';

    my %response = ();
    unless( $self->getBasic($som, $path, \%response) ) {
        $self->getErrors($som, $path, \%response);
        return %response;
    }

    $self->getFields($som, $path, \%response,
                     { Balance             => '/Balance',
                     }
                    );

    return %response;
}

1;
__END__

=head1 NAME

Business::PayPal::API::GetBalance - PayPal GetBalance API

=head1 SYNOPSIS

  use Business::PayPal::API::GetBalance;
  my $pp = new Business::PayPal::API::GetBalance ( ... );

or

  ## see Business::PayPal::API documentation for parameters
  use Business::PayPal::API qw(GetBalance);
  my $pp = new Business::PayPal::API( ... );

  my %response = $pp->GetBalance( ReturnAllCurrencies => 0, );

=head1 DESCRIPTION

B<Business::PayPal::API::GetBalance> implements PayPal's
B<GetBalance> API using SOAP::Lite to make direct API calls to
PayPal's SOAP API server. It also implements support for testing via
PayPal's I<sandbox>. Please see L<Business::PayPal::API> for details
on using the PayPal sandbox.

=head2 GetBalance

Implements PayPal's B<GetBalance> API call. Supported
parameters include:

  ReturnAllCurrencies

as described in the PayPal "Web Services API Reference" document.

Returns a hash containing the transaction details, including these fields:

  Balance

Example:

  my %resp = $pp->GetBalance( ReturnAllCurrencies => 0 );
  print "Balance: $resp{Balance}\n";

=head2 ERROR HANDLING

See the B<ERROR HANDLING> section of B<Business::PayPal::API> for
information on handling errors.

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<https://developer.paypal.com/en_US/pdf/PP_APIReference.pdf>

=head1 AUTHOR

Scot Wiersdorf E<lt>scott@perlcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Scott Wiersdorf

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
