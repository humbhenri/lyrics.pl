#!/usr/bin/perl

# Display lyrics of songs played by Rhythmbox
# Humberto H. C. Pinheiro Seg, 03 Out 2011

use strict;
use warnings;
use LWP::UserAgent;
use HTML::TreeBuilder;
use Wx;
use Wx::Html;
use Wx::Timer;
use Wx::Event qw(EVT_TIMER);
use Net::DBus;
#use Net::DBus::Reactor;

package GetLyrics;

use base 'Wx::App';

sub get_lyrics{
    my ($song, $artist)   = @_;
    my $lyrics            = '';

    # requirements of the lyrics site
    sub prepare{
        my ($song, $artist) = @_;
        for ($song, $artist) {
            s/\s/-/g;
            s/[\(\)]//g;
            s/'//g;
        }
        return ($song, $artist);
    }

    ($song, $artist) = prepare $song, $artist;

    # Set User agent
    my $ua  = new LWP::UserAgent;
    $ua->agent("Mozilla/8.0");

    # Download the lyrics
    print "http://www.lyrics.com/$song-lyrics-$artist.html\n";
    my $req               = new HTTP::Request 'GET' => "http://www.lyrics.com/$song-lyrics-$artist.html";
    $req->header('Accept' => 'text/html');
    my $res               = $ua->request($req);
    return $res->status_line unless ($res->is_success);

    # Build a parser for the HTML
    my $tree = HTML::TreeBuilder->new;
    $tree->parse($res->content);
    $tree->eof();

    # Add lyrics text
    my ($lyricsDiv) = $tree->look_down('id', 'lyric_space');
    return '' unless ($lyricsDiv);
    $lyrics        .= $lyricsDiv->as_HTML;

    # Cleanup
    $lyricsDiv->delete;
    $tree->delete;

    # Returns the lyrics content as HTML
    return $lyrics;
}

sub OnInit{
    our $songName    = '';
    our $artist      = '';
    our $windowsSize = [300,600];
    our $frame       = Wx::Frame->new(undef, -1, 'Lyrics', [-1,-1],$windowsSize);
    our $htmlWindow  = Wx::HtmlWindow->new($frame, -1, [-1,-1],[-1,-1]);

#    if ( $rhythmbox ){
        #my $player = $rhythmbox->get_object('/org/gnome/Rhythmbox/Player');
        #$player->connect_to_signal('playingUriChanged', \&update_rhythmbox_song);
    #}
    #else {
        #print 'Error';
    #}

    $frame->Show(1);
}


sub set_lyrics{
    my ($title, $artist) = @_;
    $GetLyrics::htmlWindow->SetPage("Getting lyrics for $artist - $title<br>");
    my $lyrics = get_lyrics ($title, $artist);
    $lyrics = "No lyrics for $artist - $title<br>" if ($lyrics eq '');
    $GetLyrics::htmlWindow->Refresh();
    $GetLyrics::htmlWindow->Update();
    $GetLyrics::htmlWindow->SetPage($lyrics);
    $GetLyrics::htmlWindow->Refresh();
    $GetLyrics::htmlWindow->Update();
    $GetLyrics::frame->SetTitle("$title - $artist ");
    $GetLyrics::frame->Refresh();
    $GetLyrics::frame->Update();
}


sub update_song{
    our $rhythmbox  = Net::DBus->session->get_service('org.gnome.Rhythmbox');
    my $player = $GetLyrics::rhythmbox->get_object('/org/gnome/Rhythmbox/Player');
    my $shell  = $GetLyrics::rhythmbox->get_object('/org/gnome/Rhythmbox/Shell');
    return unless($player->getPlaying);
    my $song   = $shell->getSongProperties( $player->getPlayingUri );
    if ( $song->{'artist'} ne $GetLyrics::artist
      || $song->{'title'}  ne $GetLyrics::songName ) {
        $GetLyrics::artist   = $song->{'artist'};
        $GetLyrics::songName = $song->{'title'};
        set_lyrics $GetLyrics::songName, $GetLyrics::artist ;
    }
}



package main;

my $app = GetLyrics->new;
my $timerId = 666;
my $timer = Wx::Timer->new($app, $timerId);
$timer->Start( 1000 );
EVT_TIMER( $app, $timerId, sub {$app->update_song});

$app->MainLoop;
#my $reactor = Net::DBus::Reactor->main();
#$reactor->run();

