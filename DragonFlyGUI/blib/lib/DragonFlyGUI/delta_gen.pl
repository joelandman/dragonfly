#!/opt/scalable/bin/perl

use strict;
no strict 'refs';

my $sleep_interval		= 1;
my $bw_output_file		= "/tmp/BW.data";
my $avg_bw_output_file_5s	= "/tmp/BW_avg-5s.data";
my $avg_bw_output_file_60s      = "/tmp/BW_avg-60s.data";
my $avg_bw_output_file_1440s	= "/tmp/BW_avg-1440s.data";
my $cumulative_IO_output_file	= "/tmp/cumulative_io";
my $cumulative_IO_output_file_60s = "/tmp/cumulative_io_60s";
my $cumulative_IO_output_file_1440s = "/tmp/cumulative_io_1440s";
my $iop_output_file		= "/tmp/IOP.data";
my $dir				= `/bin/ls /sys/block`;
my $sector_size			= 512;
my $wrap			= 2**32;

my ($blockdev,$fh,$bwfh,$iofh,@devs,@dev_list,$i,@proc,$line);
my ($dev_last,$dev_current,$dev_delta,@_tmp,$path,$bldfh,$iopfh);
my ($major,$minor,@vals);

#get the disk devices
@devs	= split(/\n/,$dir);
chomp(@devs);
foreach (@devs)
 {
  @_tmp	= split(/\s+/,$_);
  push @dev_list,(pop @_tmp);
 }
 
undef $dev_last;
while(1)
 {    
  open ($bldfh,"< /proc/diskstats") or next;
  chomp(@proc	= <$bldfh>);
  close($bldfh);
  foreach $line (@proc)
    {
      $line =~ s/^\s+//;
      ($major,$minor,$blockdev,@vals) = split(/\s+/,$line);
      next if ($blockdev =~ /\S+\d+/);
      for($i=0;$i<11;$i++)
        {
         $dev_current->{$blockdev}->{$i} = $vals[$i];
         $dev_last->{$blockdev}->{$i} -= $wrap if ($dev_current->{$blockdev}->{$i} < $dev_last->{$blockdev}->{$i} ); # handle the case of 32 bit numbers wrapping
        }
      for($i=0;$i<10;$i++)
       {
        $dev_delta->{$blockdev}->{$i}=($dev_current->{$blockdev}->{$i}-$dev_last->{$blockdev}->{$i});
       }
    }
 
 $dev_last=$dev_current;
 undef $dev_current;
 open($bwfh,">".$bw_output_file);
 foreach $blockdev (keys %{$dev_delta})
  {
    printf $bwfh "%s,%f,%f\n",$blockdev,$dev_delta->{$blockdev}->{2}*$sector_size/$sleep_interval,$dev_delta->{$blockdev}->{6}*$sector_size/$sleep_interval;
  }
 close($bwfh);
 
 open($iopfh,">".$iop_output_file);
  foreach $blockdev (keys %{$dev_delta})
  {
    printf $iopfh "%s,%i,%i\n",$blockdev,
			       $dev_delta->{$blockdev}->{0}/$sleep_interval,
			       $dev_delta->{$blockdev}->{4}/$sleep_interval;
  }

 close($iopfh); 
 sleep($sleep_interval); 
 }
