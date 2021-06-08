//
//  VideoPlayerViewController.m
//  FOAM
//
//  Created by Robert Nagtegaal on 12/02/2019.
//  Copyright © 2019 GPL v3

#import "KodiConfig.h"
#import "VideoPlayerViewController.h"
#import <MobileVLCKit/MobileVLCKit.h>

@interface VideoPlayerViewController () <VLCMediaPlayerDelegate>

// @property (nonatomic, strong) VLCMediaPlayer *mediaPlayer;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSTimer *timerControlsFade;
@property (nonatomic, strong) NSTimer *placeResumeOnKodiButtonTimer;
@property (nonatomic, copy) NSDictionary *metaDictionary;
@property (nonatomic, strong) UIView *playerView;
@property (strong, nonatomic) IBOutlet UISlider *timeSlider;
@property (strong, nonatomic) UIImage *playImage;
@property (strong, nonatomic) UIImage *pauseImage;
@property (strong, nonatomic) UIButton *playPauseButton;
@property (strong, nonatomic) UIButton *backButton;
@property (strong, nonatomic) UIButton *audioLanguageButton;
@property (strong, nonatomic) UIButton *subtitleLanguageButton;
@property (strong, nonatomic) UIButton *resumeOnKodiButton;
@property (strong, nonatomic) UILabel *mediaTrackInfo;
@property (strong, nonatomic) UILabel *contentTime;
@property (strong, nonatomic) UIView *controlsView;
@property (nonatomic) int audioTrack;
@property (nonatomic) int subtitleTrack;
@end

@implementation VideoPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    self.playerView = [[UIView alloc] initWithFrame:self.mainView.bounds];
    self.mediaPlayer = [[VLCMediaPlayer alloc] initWithOptions:@[@"--network-caching=1000"]];
    self.mediaPlayer.delegate = self;
    self.mediaPlayer.drawable = self.playerView;
    [self.mainView addSubview:self.playerView];
    
    if (@available(iOS 11.0, *)) {
        [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    }
}

-(BOOL)prefersHomeIndicatorAutoHidden{
    return true;
}

- (NSArray *)audioStreamNames {
    NSArray *streams = self.mediaPlayer.audioTrackNames;
    return streams;
}

- (NSArray *)subtitleStreamNames {
    NSArray *streams = self.mediaPlayer.videoSubTitlesNames;
    return streams;
}

- (NSArray *)audioStreams {
    NSArray *streams = self.mediaPlayer.audioTrackIndexes;
    return streams;
}

- (NSArray *)subtitleStreams {
    NSArray *streams = self.mediaPlayer.videoSubTitlesIndexes;
    return streams;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.videoUrl != nil) {
        @try {
            self.mediaPlayer.media = [VLCMedia mediaWithURL:self.videoUrl];
            [self.mediaPlayer play];
            self.audioTrack = self.mediaPlayer.currentAudioTrackIndex;
            self.subtitleTrack = self.mediaPlayer.currentVideoSubTitleIndex;
            [self setupControlsView];
            [self.mediaPlayer.media parseWithOptions:VLCMediaParseLocal];
            self.metaDictionary = self.mediaPlayer.media.metaDictionary;
        }
        @catch (NSException * e) {
            NSLog(@"Exception: %@", e);
        }
        @finally {
            NSLog(@"finally");
        }
    } else {
        NSLog(@"Nothing to play");
    }
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)fadeInControls {
    [UIView animateWithDuration:0.5 animations:^{
        self.backButton.alpha = 1;
        self.playPauseButton.alpha = 1;
        self.timeSlider.alpha = 1;
        self.audioLanguageButton.alpha = 1;
        self.subtitleLanguageButton.alpha = 1;
        self.resumeOnKodiButton.alpha = 1;
        self.contentTime.alpha = 1;
    }];
    NSLog(@"Got gesture");
}

- (void)timerControlsFadeOut {
    [UIView animateWithDuration:0.5 animations:^{
        self.backButton.alpha = 0;
        self.playPauseButton.alpha = 0;
        self.timeSlider.alpha = 0;
        self.audioLanguageButton.alpha = 0;
        self.subtitleLanguageButton.alpha = 0;
        self.mediaTrackInfo.alpha = 0;
        self.resumeOnKodiButton.alpha = 0;
        self.contentTime.alpha = 0;
    }];
}

- (void)setupControlsView {
    self.controlsView = [[UIView alloc] initWithFrame:self.mainView.bounds];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fadeInControls)];
    [self.controlsView addGestureRecognizer:tapGestureRecognizer];
    
    self.timerControlsFade = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(timerControlsFadeOut) userInfo:nil repeats:YES];
    
    [self.mainView addSubview:self.controlsView];
    
    // Device width (the size of the canvas!)
    CGFloat width = self.controlsView.frame.size.width;
    CGFloat height = self.controlsView.frame.size.height;
    
    // Set Back Button
    if (width == 1024) {
        self.backButton = [[UIButton alloc] initWithFrame:CGRectMake((width) - 80, 0, 70, 70)];
    } else {
        self.backButton = [[UIButton alloc] initWithFrame:CGRectMake((width) - 60, 0, 50, 50)];
    }
    [self.backButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    UIImage *backButtonImage = [UIImage imageNamed:@"back3.png"];
    [self.backButton setImage:backButtonImage forState:UIControlStateNormal];
    [self.controlsView addSubview:self.backButton];
    
    // Set timeSlider
    _timeSlider = [[UISlider alloc] initWithFrame:CGRectMake(50, height - 25 , width - 70, 10)];
    [[UISlider appearance] setThumbImage:[self imageWithImage:[UIImage imageNamed:@"blue_slider_thumb.png"] scaledToSize:CGSizeMake(20, 20)] forState:UIControlStateNormal];
    _timeSlider.minimumTrackTintColor = [UIColor colorWithRed:0.0f/255.0f green:178.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
    [_timeSlider setContinuous: YES];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(timeSliderCurrentTime) userInfo:nil repeats:YES];
    [_timeSlider addTarget:self action:@selector(timeSliderValueChanged:forEvent:) forControlEvents:UIControlEventValueChanged];
    [self.controlsView addSubview:_timeSlider];
    
    // Set ContentTime
    _contentTime = [[UILabel alloc] initWithFrame:CGRectMake(50, height - 11, width - 70, 10)];
    [[UISlider appearance] setThumbImage:[self imageWithImage:[UIImage imageNamed:@"blue_slider_thumb.png"] scaledToSize:CGSizeMake(20, 20)] forState:UIControlStateNormal];
    _contentTime.font = [UIFont fontWithName:@"HelveticaNeue" size:8];
    _contentTime.textColor = [UIColor colorWithRed:0.0f/255.0f green:178.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
    [self.controlsView addSubview:_contentTime];
    
    // Set play pause button
    self.playPauseButton = [[UIButton alloc] initWithFrame:CGRectMake(15, height - 30, 20, 20)];
    [self.playPauseButton addTarget:self action:@selector(playPauseAction:) forControlEvents:UIControlEventTouchUpInside];
    self.playImage = [self imageWithImage:[UIImage imageNamed:@"play_big.png"] scaledToSize:CGSizeMake(20, 20)];
    self.pauseImage = [self imageWithImage:[UIImage imageNamed:@"pause_big.png"] scaledToSize:CGSizeMake(20, 20)];
    [self.playPauseButton setImage:self.pauseImage forState:UIControlStateNormal];
    [self.controlsView addSubview:self.playPauseButton];
    
    // Set audioLanguageButton
    self.audioLanguageButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 0, 55, 55)];
    [self.audioLanguageButton setImage:[self imageWithImage:[UIImage imageNamed:@"AudioChannel.png"] scaledToSize:CGSizeMake(55, 55)] forState:UIControlStateNormal];
    [self.audioLanguageButton addTarget:self action:@selector(nextAudioTrack) forControlEvents:UIControlEventTouchUpInside];
    [self.controlsView addSubview:self.audioLanguageButton];
    
    // Set subtitleLanguageButton
    self.subtitleLanguageButton = [[UIButton alloc] initWithFrame:CGRectMake(60, 7, 45, 45)];
    [self.subtitleLanguageButton setImage:[self imageWithImage:[UIImage imageNamed:@"Subtitles.png"] scaledToSize:CGSizeMake(35, 35)] forState:UIControlStateNormal];
    [self.subtitleLanguageButton addTarget:self action:@selector(nextSubtitleTrack) forControlEvents:UIControlEventTouchUpInside];
    [self.controlsView addSubview:self.subtitleLanguageButton];

    // Label for showing audio and subtitle info
    self.mediaTrackInfo = [[UILabel alloc] initWithFrame:CGRectMake(115, 15, width - 230, 20)];
    [self.mediaTrackInfo setTextColor:[UIColor colorWithRed:0.0f/255.0f green:178.0f/255.0f blue:238.0f/255.0f alpha:1.0f]];
    [self.mediaTrackInfo setTextAlignment:NSTextAlignmentCenter];
    [self.controlsView addSubview:self.mediaTrackInfo];
    
    // Label for showing resume on kodi button
    if (self.kodiIsAvailable) {
        [self placeResumeOnKodiButton];
    } else {
        self.placeResumeOnKodiButtonTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(placeResumeOnKodiButton) userInfo:nil repeats:YES];
    }
}

- (void)placeResumeOnKodiButton {
    self.resumeOnKodiButton = [[UIButton alloc] initWithFrame:CGRectMake(110, 7, 45, 45)];
    [self.resumeOnKodiButton setImage:[self imageWithImage:[UIImage imageNamed:@"playOnKodiActive.png"] scaledToSize:CGSizeMake(35, 35)] forState:UIControlStateNormal];
    [self.resumeOnKodiButton addTarget:self action:@selector(resumeOnKodi) forControlEvents:UIControlEventTouchUpInside];
    [self.controlsView addSubview:self.resumeOnKodiButton];
    [self.placeResumeOnKodiButtonTimer invalidate];
}

- (void)placeResumeOnKodiButton:(UIView*)controlsView {
    self.resumeOnKodiButton = [[UIButton alloc] initWithFrame:CGRectMake(110, 7, 45, 45)];
    [self.resumeOnKodiButton setImage:[self imageWithImage:[UIImage imageNamed:@"playOnKodiActive.png"] scaledToSize:CGSizeMake(35, 35)] forState:UIControlStateNormal];
    [self.resumeOnKodiButton addTarget:self action:@selector(resumeOnKodi) forControlEvents:UIControlEventTouchUpInside];
    [controlsView addSubview:self.resumeOnKodiButton];
}

- (void)resumeOnKodi {
    NSDictionary *dict = @{@"position": [NSNumber numberWithFloat:self.mediaPlayer.position], @"url": self.videoUrl};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"resumeOnKodi" object:nil userInfo:dict];
    [self dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"resumeOnKodi");
}

- (void)nextAudioTrack {
    @try {
        [self.timerControlsFade invalidate];
        [UIView animateWithDuration:0.5 animations:^{
            self.mediaTrackInfo.alpha = 1.0f;
        }];
        if (self.mediaPlayer.numberOfAudioTracks != 0) {
            if (self.audioTrack + 1 == self.mediaPlayer.numberOfAudioTracks) {
                self.audioTrack = 0;
                [self.mediaPlayer setCurrentAudioTrackIndex:[self.mediaPlayer.audioTrackIndexes[self.audioTrack] intValue]];
            } else {
                self.audioTrack += 1;
                [self.mediaPlayer setCurrentAudioTrackIndex:[self.mediaPlayer.audioTrackIndexes[self.audioTrack] intValue]];
            }
            if ([self.mediaPlayer.audioTrackNames[self.audioTrack] length] == 0) {
                NSString *track = [NSString stringWithFormat:@"Audio track %i", self.audioTrack];
                [self.mediaTrackInfo setText:track];
            } else {
                if ([self.mediaPlayer.audioTrackNames[self.audioTrack] isEqualToString:@"Disable"]) {
                    [self.mediaTrackInfo setText:@"Audio muted"];
                } else {
                    [self.mediaTrackInfo setText:self.mediaPlayer.audioTrackNames[self.audioTrack]];
                }
            }
        }
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
    }
    @finally {
        self.timerControlsFade = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(timerControlsFadeOut) userInfo:nil repeats:YES];
    }
}

- (void)nextSubtitleTrack {
    @try {
        [self.timerControlsFade invalidate];
        [UIView animateWithDuration:0.5 animations:^{
            self.mediaTrackInfo.alpha = 1.0f;
        }];
        if (self.mediaPlayer.numberOfSubtitlesTracks != 0) {
            if (self.subtitleTrack + 1 == self.mediaPlayer.numberOfSubtitlesTracks) {
                self.subtitleTrack = 0;
                [self.mediaPlayer setCurrentVideoSubTitleIndex:[self.mediaPlayer.videoSubTitlesIndexes[self.subtitleTrack] intValue]];
            } else {
                self.subtitleTrack += 1;
                [self.mediaPlayer setCurrentVideoSubTitleIndex:[self.mediaPlayer.videoSubTitlesIndexes[self.subtitleTrack] intValue]];
            }
            if ([self.mediaPlayer.videoSubTitlesNames[self.subtitleTrack] length] == 0) {
                NSString *track = [NSString stringWithFormat:@"Subtitle track %i", self.subtitleTrack];
                [self.mediaTrackInfo setText:track];
            } else {
                if ([self.mediaPlayer.videoSubTitlesNames[self.subtitleTrack] isEqualToString:@"Disable"]) {
                    [self.mediaTrackInfo setText:@"Subtitles disabled"];
                } else {
                    [self.mediaTrackInfo setText:self.mediaPlayer.videoSubTitlesNames[self.subtitleTrack]];
                }
            }
        } else {
            [self.mediaTrackInfo setText:@"No subtitles available"];
        }
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
    }
    @finally {
        self.timerControlsFade = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(timerControlsFadeOut) userInfo:nil repeats:YES];
    }
}

- (void)timeSliderCurrentTime {
    _timeSlider.value = self.mediaPlayer.position;
    _contentTime.text = [self formatProgressTime];
}

- (NSString*)formatProgressTime {
    NSString *currentTime = [NSString stringWithFormat:@"%@", self.mediaPlayer.time];
    NSString *totalTime = [NSString stringWithFormat:@"%@", self.mediaPlayer.media.length];
    if (currentTime.length < 6) {
        currentTime = [NSString stringWithFormat:@"00:%@", currentTime];
    }
    if (currentTime.length < 8) {
        currentTime = [NSString stringWithFormat:@"0%@", currentTime];
    }
    if (totalTime.length < 8) {
        totalTime = [NSString stringWithFormat:@"0%@", totalTime];
    }
    return [NSString stringWithFormat:@"%@ / %@", currentTime, totalTime];
}

- (NSString*)formattedTime:(long)hours :(long)minutes :(long)seconds {
    NSString *stringHours = [NSString stringWithFormat:@"%lu", hours];
    if (hours < 10) {
        stringHours = [NSString stringWithFormat:@"0%lu", hours];
    }
    NSString *stringMinutes = [NSString stringWithFormat:@"%lu", minutes];
    if (minutes < 10) {
        stringMinutes = [NSString stringWithFormat:@"0%lu", minutes];
    }
    NSString *stringSeconds = [NSString stringWithFormat:@"%lu", seconds];
    if (seconds < 10) {
        stringSeconds = [NSString stringWithFormat:@"0%lu", seconds];
    }
    return [NSString stringWithFormat:@"%@:%@:%@", stringHours, stringMinutes, stringSeconds];
}

- (NSString*)timeSliderPositionToFormattedTime {
    VLCTime *totalTime = self.mediaPlayer.media.length;
    long totalTimeInSeconds = (long)totalTime.intValue/1000;
    long currentTimeInSeconds = (long)((float)totalTimeInSeconds * _timeSlider.value);
    long hours = (currentTimeInSeconds - (currentTimeInSeconds % 3600)) / 3600;
    currentTimeInSeconds = currentTimeInSeconds - (hours * 3600);
    long minutes = (currentTimeInSeconds - (currentTimeInSeconds % 60)) / 60;
    long seconds = currentTimeInSeconds - (minutes * 60);
    return [self formattedTime:hours :minutes :seconds];
}

- (void)timeSliderValueChanged:(UISlider*)slider forEvent:(UIEvent*)event {
    UITouch *touchEvent = [[event allTouches] anyObject];
    [self.timer invalidate];
    [self.timerControlsFade invalidate];
    NSString *totalTime = [NSString stringWithFormat:@"%@", self.mediaPlayer.media.length];
    if (totalTime.length < 8) {
        totalTime = [NSString stringWithFormat:@"0%@", totalTime];
    }
    switch (touchEvent.phase) {
        case UITouchPhaseEnded:
            NSLog(@"newTime (ended) = %f", slider.value);
            [self.mediaPlayer setPosition:slider.value];
            self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(timeSliderCurrentTime) userInfo:nil repeats:YES];
            self.timerControlsFade = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(timerControlsFadeOut) userInfo:nil repeats:YES];
            break;
        default:
            _contentTime.text = [NSString stringWithFormat:@"%@ / %@", [self timeSliderPositionToFormattedTime], totalTime];
            break;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.mediaPlayer stop];
    self.mediaPlayer.media = nil;
    self.mediaPlayer.delegate = nil;
    self.mediaPlayer.drawable = nil;
}

- (void)killVideoPlayer
{
    [super viewWillDisappear:YES];
    [self.mediaPlayer stop];
    self.mediaPlayer.media = nil;
    self.mediaPlayer.delegate = nil;
    self.mediaPlayer.drawable = nil;
}

- (IBAction)backButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)playPauseAction:(id)sender {
    if ([self.mediaPlayer isPlaying]) {
        [self.mediaPlayer pause];
        [self.playPauseButton setImage:self.playImage forState:UIControlStateNormal];
    } else {
        [self.mediaPlayer play];
        [self.playPauseButton setImage:self.pauseImage forState:UIControlStateNormal];
    }
}

#pragma mark VLCMediaPlayerDelegate

@end
