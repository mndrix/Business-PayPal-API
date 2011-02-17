use Test::More;
if( ! $ENV{WPP_TEST} || ! -f $ENV{WPP_TEST} ) {
    plan skip_all => 'No WPP_TEST env var set. Please see README to run tests';
}
else {
    plan tests => 8;
}

use_ok( 'Business::PayPal::API::ExpressCheckout' );
#########################

require 't/API.pl';

my %args = do_args();

## we're passing more to new() than we normally would because we're
## using %args elsewhere below. See documentation for the correct
## arguments.
my $pp = new Business::PayPal::API::ExpressCheckout( %args );

##
## set checkout info
##
#$Business::PayPal::API::Debug = 1;
my %response = $pp->SetExpressCheckout
  ( OrderTotal => '55.43',
    ReturnURL  => 'http://www.google.com/',
    CancelURL  => 'http://www.google.com/', 
    Custom     => "This field is custom. Isn't that great?",
    PaymentAction => 'Order',
    BuyerEmail => $args{BuyerEmail},   ## from %args
  );
#$Business::PayPal::API::Debug = 0;

my $token = $response{Token};

ok( $token, "Got token" );

die "No token from PayPal! Check your authentication information and try again."
  unless $token;

my $pp_url = "https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token=$token";

print STDERR <<"_TOKEN_";

Now paste the following URL into your browser (you will need to have
another browser window already logged into the PayPal developer site):

  $pp_url

Login to PayPal as the Buyer you specified in '$ENV{WPP_TEST}' and
proceed to checkout (this authorizes the transaction represented by
the token). When finished, PayPal will redirect you to a non-existent
URL:

  http://localhost/return.html?token=$token&PayerID=XXXXXXXXXXXXX

Notice the *PayerID* URL argument (XXXXXXXXXXXXX) on the redirect from
PayPal.
Once completed, The Payer account and Payee account can be checked for an order,
authorization, and void.
_TOKEN_

print STDERR "\nType or paste that PayerID here and hit Enter: \n";

my $payerid = <STDIN>; chomp $payerid;

die "Need a PayerID.\n" unless $payerid;

##
## get checkout details
##
my %details = $pp->GetExpressCheckoutDetails($token);
is( $details{Token}, $token, "details ok" );

#use Data::Dumper;
#print STDERR Dumper \%details;

$details{PayerID} = $payerid;

my %payment = ( Token          => $details{Token},
		PaymentAction  => 'Order',
		PayerID        => $details{PayerID},
		OrderTotal     => '55.43',
	      );

##
## do checkout
##
#$Business::PayPal::API::Debug = 1;
my %payinfo = $pp->DoExpressCheckoutPayment(%payment);
#$Business::PayPal::API::Debug = 0;
#If Order is successful then authorize it, then void it.

if(like( $payinfo{Ack}, qr/Success/ , "successful payment" )) {
    my $transid= $payinfo{TransactionID};
    my $amount= '25.43';
    use_ok('Business::PayPal::API::AuthorizationRequest');
    %args = do_args();
#$Business::PayPal::API::Debug = 1;
    $ppauth = new Business::PayPal::API::AuthorizationRequest(%args);
    my %resp = $ppauth->DoAuthorizationRequest( TransactionID => $transid,
                                   Amount    => $amount);
    like( $resp{Ack}, qr/Succes/ , 'Successful order authorization' );
    use_ok( 'Business::PayPal::API::VoidRequest' );
    %args = do_args();
    my $ppvoid= new Business::PayPal::API::VoidRequest( %args );
    %resp1= $ppvoid->DoVoidRequest( AuthorizationID => $transid,
                               Note          => 'Voided' );
                                                                                
  like( $resp1{Ack}, qr/Success/, 'Successful order void' );
    }
