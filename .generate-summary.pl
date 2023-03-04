#!/usr/bin/env perl -n
use Encode;
use utf8;
use open ':encoding(UTF-8)', ':std';

# This stupid function makes to decode only the first file.
# If I don't do this, perl is not doing it by himself and I don't know why.
# Even the headers of this file are telling to use utf8 encoding!
# But does not do it in the first file that reads.
# And you do it in all the files it inverts to only be ok in the first file. PFFF
# Two hours of research is enough!
# At least... The function is pure!!
sub decode_if_is_file {
  my ($first_file, $line) = @_;
  return ($ARGV eq $first_file) ? decode_utf8($line) : $line;
}

BEGIN {
  print "# Sumario\n\n";
}

# Trim whitespace
s/^\s+|\s+$//g;

# Print headlines
if (/^# (.*)/) {
  $headline = decode_if_is_file("README.md", $1);
  print "* [$headline]($ARGV)\n";
}

# Print subheadlines
if (/^## (.*)/) {
  $subheadline = decode_if_is_file("README.md", $1);
  my $anchor = lc $subheadline;

  # Remove all but word characters and whitespace
  $anchor =~ s/[^\wö ]//g;
  # Replace whitespace with dashes
  $anchor =~ tr/ /-/d;

  print "  * [$subheadline]($ARGV#$anchor)\n";
}
