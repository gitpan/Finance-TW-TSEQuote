package Finance::TW::TSEQuote;
$VERSION = '0.1';

use strict;
use LWP::Simple ();
eval { require 'Encode::compat' };
use Encode 'from_to';
use URI::Escape;

sub resolve {
    my $self = shift if ref($_[0]) eq __PACKAGE__;
    shift if $_[0] eq __PACKAGE__;
    my $name = shift;

    from_to($name, 'utf-8', 'big5');

    $name = uri_escape($name);

    my $content = LWP::Simple::get("http://mops.tse.com.tw/server-java/t05st49_1?step=1&kinds=sii&colorchg=1&type=01&nick_name=$name");

    my ($id, $fullname, $engname) = $content =~ m|<td>(\d+)&nbsp;</td><td>(.*?)&nbsp;</td><td>(.*?)&nbsp;</td></tr>|;

    die "can't resolve symbol: $name" unless $id;

    from_to($fullname, 'big5', 'utf-8');

    @{$self}{qw/id fullname engname/} = ($id, $fullname, $engname);

    return $id;

}

sub new {
    my ($class, $target) = @_;
    my $self = bless {}, $class;

    $self->resolve($target)
	unless $target =~ /^\d+$/;

    $self->{id} ||= $target;

    return $self;
}

sub get {
    my $self = shift if ref($_[0]) eq __PACKAGE__;
    shift if $_[0] eq __PACKAGE__;
    my $stockno = $self ? $self->{id} : shift;
    my $content = LWP::Simple::get("http://mis.tse.com.tw/Quotes/Best5?StkNo=$stockno");
    my $result;

    undef $self->{quote} if $self;

    while ($content =~ s/id="(\w+)"\>(?:<font.*?\/font>)?(.*?)\<//) {
	my ($key, $value) = ($1, $2);
	$value = '' if $value eq '&nbsp';
	if ($key =~ m/(Buy|Sell)(\w+)(\d)/) {
	    $result->{Bid}{$1}[$3-1]{$2} = $value;# if $value;
	}
	else {
	    $result->{$1} = $2;
	}
    }

    $self->{quote} = $result if $self;

    return $result;
}


1;
