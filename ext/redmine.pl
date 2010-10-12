package RedmineBase;
use base 'ActiveResource::Base';
use Lingua::EN::Inflect qw(PL);

sub new {
    my $class = shift;
    my $args = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    $class->site($args->{site}) if $args->{site};
    $class->user($args->{user}) if $args->{user};
    $class->password($args->{pass}) if $args->{pass};
    return $class->SUPER::new(@_);
}

sub search {
    my ($class, $where) = @_;

    $class->connection->$_ = $class->$_ for qw(site user password);

    my $resource_name = PL lc(ref($class) || $class);
    my $path = $class->collection_path("", $where);
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
        (my $attr_name = $resource_name) =~ s/s$//;
        my $rows = $attr->{$attr_name};
        $rows = [$rows] if ref $rows ne 'ARRAY';
        foreach my $row (@$rows){
            my $record = $class->new;
            $record->load($row);
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

package Project;
use base 'RedmineBase';

package Issue;
use base 'RedmineBase';



package main;
use Getopt::Long;
my $mode      = "i";  # i:issue p:project
my $condition;
GetOptions (
   'mode=s' => \$mode,
   'site=s' => \$site,
   'user=s' => \$user,
   'pass=s' => \$pass,
   'key=s'  => \$key,
   'condition=s' => \$condition) or die $!;

use Encode;
use URI;
use utf8;

my $info = {
    site => $site,
    user => $user,
    pass => $pass,
    #key  => $key,
};

sub view_project {
    my $where = shift;
    # Find existing project
    my $c = Project->new($info);
    my $projects = $c->search( $where );

    foreach my $project (@$projects){
        print "#",$project->id," ",encode_utf8($project->name),"\n" if $project->id;
    }
}

sub view_issue {
    my $where = shift;
    # Find existing ticket
    my $c = Issue->new($info);
    my $issues = $c->search( $where );

    foreach my $issue (@$issues){
        print "#",$issue->id," ",encode_utf8($issue->description),"\n" if $issue->id;
    }
}

my $uri = URI->new("http://hoge.org/?$condition"); 
my %where = $uri->query_form;
$where{key} = $key if $key;

if($mode eq 'i'){
    view_issue(\%where);
}
elsif($mode eq 'p'){
    view_project(\%where);
}

