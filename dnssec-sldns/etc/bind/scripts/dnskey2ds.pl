#!/usr/bin/perl
#$Id$

#	A little util to convert DNSKEY records to DS records
#	from stdin to stdout
#
#	Author: Miek Gieben, NLnetLabs
#	Source: https://www.net-dns.org/svn/net-dns-sec/release/1.02/demo/key2ds


use strict;
use Net::DNS::SEC;
use Net::DNS::ZoneFile;

my $handle = \*STDIN;
my $source = new Net::DNS::ZoneFile($handle);
while ( my $keyrr = $source->read ) {
	next unless $keyrr->isa('Net::DNS::RR::DNSKEY');

	foreach my $digtype (qw(SHA256 SHA1)) {
		my $ds = create Net::DNS::RR::DS( $keyrr, digtype => $digtype );
		$ds->print;
	}
}

exit 0;

=head1 NAME

key2ds - Utility to create DS records from DNSKEY RRs read from stdin.

=head1 SYNOPSIS

	key2ds <keys.txt >ds.txt

=head1 DESCRIPTION

C<key2ds> reads the key data from STDIN and prints the corresponding
DS record on STDOUT.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut


0;
