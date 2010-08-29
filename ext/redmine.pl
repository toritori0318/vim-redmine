package Issue;
use parent 'ActiveResource::Base';
__PACKAGE__->site("http://localhost:3000");
__PACKAGE__->user("user");
__PACKAGE__->password("password");

use Data::Dumper;
use Lingua::EN::Inflect qw(PL);
use LWP::UserAgent;

sub search {
    my ($class, $where) = @_;

    $class->connection->$_ = $class->$_ for qw(site user password);

    my $resource_name = PL lc(ref($class) || $class);
    my $path = $class->collection_path("", $where);
    #my $response = $class->get($path);
    my $response = $class->connection->get($path);
    unless ($response->is_success) {
        die "${class}->find FAIL. With HTTP Status: @{[ $response->status_line ]}\n";
    }

    my $record_xml = $response->content;
    return unless $record_xml;

    my @records;
    my $hash = $class->format->decode($record_xml);
    my (undef, $attr) = each %$hash;
    if($attr->{type} eq 'array'){
        my $a = {};
        my $issues = $attr->{issue};
        $issues = [$issues] if ref $issues ne 'ARRAY';
        foreach my $issue (@$issues){
            my $record = $class->new;
            $record->load($issue);
            push @records, $record;
        }
    }else{
        my $record = $class->new;
        $record->load($attr);
        push @records, $record;
    }
    return \@records;
}

no warnings 'redefine';
*ActiveResource::Connection::url  = sub {
    my $self = shift;
    my $path = shift;

    my $user = $self->user;
    my $pass = $self->password;
    my $url = URI->new($self->site);

    if ($user && $pass) {
        $url->userinfo("${user}:${pass}");
    }
    # bug?
    #$url->path($path);
    return $url.$path;
};


package main;
use Getopt::Long;
my $mode      = "v";  # v:view e:edit d:delete
my $condition;
GetOptions (
   'mode=s' => \$mode,
  ,'condition=s' => \$condition) or die $!;

use Encode;
use URI;
use utf8;

my $uri = URI->new("http://hoge.org/?$condition"); 
my %where = $uri->query_form;

# Find existing ticket
my $issues = Issue->search( \%where );

foreach my $issue (@$issues){
    print "#",$issue->id," ",encode_utf8($issue->description),"\n" if $issue->id;
}

