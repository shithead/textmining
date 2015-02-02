package Textmining::Module;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(camelize decode) ;
use Mojo::Asset::File;
use Mojo::ByteStream;
use Mojo::JSON;
use File::Glob ':globally';

# This action will render a template
sub module {
    my $self    = shift;
    my $course  = $self->stash('course');
    my $module  = $self->stash('module');
    my $pagenr  = 0;

    my $course_meta_struct  = $self->struct->load_struct(
            $self->struct->get_public_path($course));

    my $page_path   = $self->struct->get_public_page_path($course_meta_struct, $module);
    my @navbar      = $self->struct->get_public_navbar($course_meta_struct, $module);

    unless (defined $page_path && defined $navbar[0]) {
        $self->app->log->error('page_path or navbar empty');
        print STDERR "page_path or navbar empty\n";
        $self->redirect_to('/course') ;
    } else {
        $pagenr = 0 if ($pagenr >= (@{$page_path} - 1));
        $pagenr = @{$page_path} - $pagenr - 2 if ($pagenr < 0);

        # Render template "module/module.html.ep"
        $self->render(
            course        =>  $course,
            module        =>  $module,
            navbar        =>  \@navbar,
            pagenr        =>  $pagenr,
            page_path     =>  $page_path,
            meta          =>  $course_meta_struct->{$module}->{meta}
        );
    }
}

our $USERS;
use Data::Printer;
sub ws {
    my $self = shift;
    my $c = $self;
    my $tx = $self->tx;
    Mojo::IOLoop->stream($tx->connection)->timeout(0);

    # Opened
    $c->app->log->debug('User connected');
    $c->app->log->debug('WebSocket opened.');
    my $msg = {type => 'status'};
    my $id;
    defined $msg->{user} ? $id = $msg->{user} : $id = $tx->connection;
    $msg->{user} = $id;
    #$msg{color} = ;
    $msg->{status} = "refresh";
    $USERS->{$id} = $msg;
    _send_message($c, $msg);
    # Incoming message
    $c->on(message => \&onMessage);
    # Closed
    $c->on(finish => sub {
        my ($c, $code, $reason) = @_;
        $c->app->log->debug("WebSocket closed with status $code.");
        my $msg = {type => 'status'};
        if (defined $msg->{user}) {
            #   $msg{color} = ;
            $msg->{message}->{text} = "logout";
            $msg->{time} = time();
            _send_message($c, $msg);
        }
    });
}

sub onMessage {
    my ($c, $message) = @_;
    my $res = {};
    my $json = Mojo::JSON->new();
    my $req->{message} = $json->decode($message);
    my $id;
    defined $req->{message}->{user} ?
    $id = $req->{message}->{user} : $id = $c->tx->connection;
    #$c->app->log->debug("User $id send message: " . $message);

    if (defined $req->{message}->{type}){
        if ($req->{message}->{type} =~ m/page/) {
            $res->{type} = 'page';
            my $msg = $req->{message}->{message};
            my $course_meta_struct  = $c->struct->load_struct(
                $c->struct->get_public_path($msg->{course}));
            my $message = _get_page($msg, $course_meta_struct);
            $res->{message} = $message;
            $res->{message}->{sendtime} = $req->{message}->{sendtime};

            $res->{user} = $id;
            #p $res;
            _send_message($c, $res);
            my $navbar = _get_navbar(
                $message->{pagenr},
                $course_meta_struct->{$msg->{module}}
            );
            $res->{type} = 'navbar';
            $res->{message} = undef;
            $res->{message}->{content} = $navbar;
            $res->{message}->{sendtime} = $req->{message}->{sendtime};
            _send_message($c, $res);
        }
        if ($req->{message}->{type} =~ m/corpus/) {
            my ($token, $windowsize, $search, $course, $corpus); #must have
            my ($min_collo, $min_freq, $stat); # optional
            $res->{type} = 'corpus';
            my $msg = $req->{message}->{message};
            $res->{form}->{id} = $req->{message}->{id};
            $res->{user} = $id;
            $res->{message} = {content => undef};
            unless (defined $msg->{course} &&
                    defined $msg->{corpus}) {
                    $res->{message}->{content} = '<p>Course or Corpus not filled</p>';
                    _send_message($c, $res);
            } else {
                unless ($msg->{course} =~ m/^\w+/) {
                    $res->{message}->{content} = '<p>Coursename is a not valid word</p>';
                    _send_message($c, $res);
                }
                unless ($msg->{corpus} =~ m/^\w+/) {
                    $res->{message}->{content} = '<p>Corpusname is a not valid word</p>';
                    _send_message($c, $res);
                }
                $course = $msg->{course};
                $corpus = $msg->{corpus};
            }
            unless ( defined $msg->{search} &&
                        defined $msg->{windowsize} &&
                        defined $msg->{token}) {
                    $res->{message}->{content} = '<p>Search or windowsize or token not filled</p>';
                    _send_message($c, $res);
            } else {
                unless ($msg->{windowsize} =~ m/^(\d{1,2})$/) {
                    $res->{message}->{content} = '<p>Windowsize is not a Number</p>';
                    _send_message($c, $res);
                }
                unless ($msg->{token} ~~ ['wordforms', 'pos', 'lemma']) {
                    $res->{message}->{content} = '<p>Token is not valid</p>';
                    _send_message($c, $res);
                }
                unless ($msg->{search} =~ m/^\w+$/) {
                    $res->{message}->{content} = '<p>Only one Word for searching</p>';
                    _send_message($c, $res);
                }
                if (defined $msg->{stat}) {
                    if ( $msg->{stat} ~~ ['mi', 'mi3', 'tscore', 'zscore']) {
                        $res->{message}->{content} = '<p>Static value not supported</p>';
                        _send_message($c, $res);
                    }
                    if ( $msg->{stat} ~~ ['chi2', 'llr', 'frequence']) {
                        $stat = $msg->{stat}; 
                    } else {
                        $res->{message}->{content} = '<p>Static value not valid</p>';
                        _send_message($c, $res);
                    }
                }
                $windowsize = $msg->{windowsize};
                $search = $msg->{search};
                $token  = $msg->{token};
            }

            my $sources = {};
            $sources = $json->decode( $c->app->ua->get("/course/corpus/$course/$corpus")->res->dom->text);
            unless (defined $sources->{sources}) {
                        $res->{message}->{content} = '<p>No Corpus found</p>';
                        _send_message($c, $res);
            }
            #p $res;
            #p $sources;
            #_send_message($c, $res);
        }
    }
    ##$USERS->{$req->{message}->{user}} = $res->{message} 
    ##        if(defined $req->{message}->{user});
}

sub _get_page($$) {
    my $msg = shift;
    my $struct = shift;

    my $pagenr = $msg->{pagenr};
    my $page_path   = _get_page_path($struct, $msg->{module});
    $pagenr = 0 if ($pagenr >= (@{$page_path} - 1));
    $pagenr = @{$page_path} - $pagenr - 2 if ($pagenr < 0);
    my $stream = _get_page_content($page_path->[$pagenr]);

    my $message = {};
    $message->{content} = $stream;
    $message->{pagenr} = $pagenr;
    return $message;
}

sub _get_page_path ($$$) {
    my $course_meta_struct
                = shift || return undef;
    my $module  = shift || return undef;

    return $course_meta_struct->{$module} ?
             $course_meta_struct->{$module}->{pages} : undef;
}

sub _get_page_content($$$) {
    my $path = shift;

    my $file      = Mojo::Asset::File->new(path => $path);
    my $stream    = Mojo::ByteStream->new($file->slurp)->decode('UTF-8');
    return $stream->to_string;
}

sub _get_module () {
    my $module = << 'EOT';
    <div>
        <div class="col-sm-2">
            <div id="progress" class="progress progress-striped">
            </div>
            <ul id="navbar" class="nav nav-pills nav-stacked" style="max-width: 300px;">
            </ul>
        </div>
        <div class="bs-component col-lg-10">
            <ul class="pager">
                <li class="previous">
                <a href="javascript:get_prev_page();">← Vorhergehende</a>
                </li>
                <li class="next">
                <a href="javascript:get_next_page();">Nächste →</a>
                </li>
            </ul>
            <div id="page">
            </div>
        </div>
    </div>
EOT
    return $module;

}
sub _message_to_json {
    my $message = shift;

    my $json = Mojo::JSON->new;
    return decode('UTF-8',$json->encode($message));
}

sub _send_message {
    my $self = shift;
    my $res = shift;
    $res->{time} = time();
    $self->send(_message_to_json($res));
}

sub _get_navbar ($$$) {
    my $pagenr  = shift;
    my $module  = shift || return undef;

    return undef unless (defined $module->{sub});
    my $navbar = {};
    my @navbar;
    my $pagecnt = 0;
    my $title = undef;
    for my $c (values @{$module->{sub}}) {
        if (defined $title) {
            $navbar->{$title}->{end} = $pagecnt - 1;
        }
        $title = camelize($c->{id});
        $navbar->{$title} = { begin => $pagecnt };
        $pagecnt = $pagecnt + $c->{pagecnt};
        push @navbar, $title;
    }
    $navbar->{$title}->{end} = @{$module->{pages}};

    my $navigation = "";
    for my $title (values @navbar) {
        my $begin = $navbar->{$title}->{begin};
        if ($pagenr >= $begin and $pagenr <= $navbar->{$title}->{end}) {
            $navigation .= "<li class=\"active\">";
        } else {
            $navigation .= "<li>";
        }
        $navigation .= "<a href=\"javascript:get_page($begin);\">$title</a></li>\n";
    }

    return $navigation;
}

1;
