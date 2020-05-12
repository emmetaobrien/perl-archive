#!/usr/bin/perl
#
#  qpn_vcf.pl - parse .VCF files from QPN and output subsets by patient
#             - EOB - May 11 2020
#
# usage: perl qpn_vcf.pl $input_file_location $output_directory
#
########################################

use strict;
use warnings;

my $input_file_location   = $ARGV[0];
my $output_directory      = $ARGV[1];

my $input_filename = (split(/\//,$input_file_location))[-1]; # everything after the last /
$input_filename =~ /^(.*?)\.vcf$/;
my $input_filename_trimmed = $1;

open (INPUT_VCF, $input_file_location) || die "Cannot open $input_filename for input";

my @header_rows       = ();
my @patient_ids       = ();
my @patient_posns     = ();
my @column_headers    = ();
my $patient_count     = 0;
my $header_row_count  = 0;
my $intake_line       = <INPUT_VCF>;

# retrieve header lines

until ($intake_line =~ /^\#CHROM/) {        # header line
	$header_rows[$header_row_count] = $intake_line;
	++$header_row_count;
	$intake_line = <INPUT_VCF>;
}

chomp($intake_line);

# retrieve column headers and extract patient IDs

@column_headers = split(/\t/, $intake_line);			# split header line at tabs
my $c = scalar(@column_headers);

print "retrieved $c column headers \n";

my $column_count = 0;
while ($column_count < scalar(@column_headers)) {
	if ($column_headers[$column_count] =~ /(PD[0-9]{5}_PD[0-9]{5})/) {    #check format of each column header
		$patient_ids[$patient_count] = $1;
		$patient_posns[$patient_count] = $column_count;
		++$patient_count;
	}
	++$column_count;
}

close INPUT_VCF;

# read rest of data into memory, preformatting as much as possible

for(my $n = 0;$n < 3; ++$n) {

	open (INPUT_VCF, $input_file_location) || die "Cannot open $input_file_location for input";

	$intake_line = <INPUT_VCF>;
	while ($intake_line =~ /^\#/) {		# skip through headers
		$intake_line = <INPUT_VCF>
	}

	my @data_column    = ();
	my $dataline_count = 0;
	my @invariant      = ();
	while ($intake_line = <INPUT_VCF>) {
		my @templine = split(/\t/,$intake_line);
    	my $t = 0;
		$invariant[$dataline_count] = '';
		while ($t < 9) {
			$invariant[$dataline_count] .= $templine[$t]."\t";
		    ++$t;
		}
		$data_column[$dataline_count] = $templine[$patient_posns[$n]];
		++$dataline_count;
	}

	print "retrieved $dataline_count data values for column $patient_ids[$n] $patient_posns[$n]\n";

	close INPUT_VCF;

	# write out data 

	print "writing out column $n $patient_ids[$n] ";
	my $output_filename = $output_directory.$input_filename_trimmed."_".$patient_ids[$n].".vcf";
	print "to $output_filename\n";
	open (OUTFILE, ">$output_filename") || die "Cannot open $output_filename for output";

	# print header lines

	my $h = 0;
	while($h < $header_row_count) {
		print OUTFILE $header_rows[$h];
		++$h;
	}

	my $column_line = "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t$patient_ids[$n]\n";
	print OUTFILE $column_line;
	my $d = 0;
	while ($d < $dataline_count) {
		my $outline = $invariant[$d]."\t".$data_column[$d]."\n";
		print OUTFILE $outline;
		++$d;
	}
	close OUTFILE;
}

exit();

