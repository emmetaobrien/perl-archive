#!/usr/bin/perl
#
#  vcf_patient_column_parse.pl - parse .VCF files from QPN and output subsets by patient
#             - EOB - May 11 2020
#
# usage: perl vcf_patient_column_parse.pl $input_file_location $output_directory
#
########################################

use strict;
use warnings;

my $input_file_location   = $ARGV[0];
my $output_directory      = $ARGV[1];

my $input_filename = (split(/\//,$input_file_location))[-1]; # extract everything after the last /
$input_filename =~ /^(.*?)\.vcf$/;
my $input_filename_trimmed = $1;

open (INPUT_VCF, $input_file_location) || die "Cannot open $input_filename for input";

my @header_rows       = ();
my @patient_ids       = ();
my @patient_posns     = ();
my @column_headers    = ();
my $column_count      = 0;
my $patient_count     = 0;
my $header_row_count  = 0;
my $intake_line       = <INPUT_VCF>;

# retrieve file header lines and print to a header file

my $output_header_filename = $output_directory.$input_filename_trimmed."_header.vcf";
open (OUTPUT_HEADER, ">$output_header_filename") || die "Cannot open $output_header_filename for output";

until ($intake_line =~ /^\#CHROM/) {        # column header line
	print OUTPUT_HEADER $intake_line;
	$intake_line = <INPUT_VCF>;
}

close OUTPUT_HEADER;

print "Header information written to $output_header_filename\n";


# extract non-patient-ID columns

my $output_fixedcol_filename = $output_directory.$input_filename_trimmed."_fixedcolumns.vcf";
open (OUTPUT_FIXED,">$output_fixedcol_filename") || die "Cannot open $output_fixedcol_filename for output";

# split column header line and extract all column headers

@columns = split(/\t/, $intake_line);			# split header line at tabs
print "File contains scalar(@columns) columns\n";

while ($column_count < scalar(@columns)) {
	if ($columns[$column_count] > 9) {    #do we need to check patient ID format here
		$patient_ids[$patient_count] = $1;
		$patient_posns[$patient_count] = $column_count;
		++$patient_count;
	}
	++$column_count;
}

# write out the first nine columns to a reference file

$outline = join ("\t",@columns[0..8])."\n";     # concatenate fields 0 to 8
print OUTPUT_FIXED $outline;

while($intake_line = <INPUT_VCF>) {
	@columns = split(/\t/, $intake_line);			# split header line at tabs
	$outline = join ("\t",@columns[0..8])."\n";     # concatenate fields 0 to 8
	print OUTPUT_FIXED $outline;
}

close OUTPUT_FIXED;

print "First nine columns written to $output_fixedcol_filename\n";


close INPUT_VCF;

# extract and generate one file per column 

for(my $n = 0;$n < 5; ++$n) {

	open (INPUT_VCF, $input_file_location) || die "Cannot open $input_file_location for input";

	$intake_line = <INPUT_VCF>;
	while ($intake_line =~ /^\#/) {		# skip through headers
		$intake_line = <INPUT_VCF>
	}

	my @extract_column = ();
	my $row_count = 0;
	while ($intake_line = <INPUT_VCF>) {
		my @templine = split(/\t/,$intake_line);
		$extract_column[$row_count] = $templine[$patient_posns[$n]];
		++$row_count;
	}

	print "retrieved $row_count data values for column $patient_ids[$n] $patient_posns[$n]\n";

	close INPUT_VCF;

	# write out data 

	print "writing out column $n $patient_ids[$n] ";
	my $output_filename = $output_directory.$input_filename_trimmed."_".$patient_ids[$n].".vcf";
	print "to $output_filename\n";
	open (OUTFILE, ">$output_filename") || die "Cannot open $output_filename for output";

	# print data lines

	my $d = 0;
	while($d < $row_count) {
		print OUTFILE $extract_column[$d];
		++$d;
	}

	close OUTFILE;

}

exit();

