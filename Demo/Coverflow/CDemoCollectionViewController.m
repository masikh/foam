#import "CDemoCollectionViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "MediaPlayer/MediaPlayer.h"
#import "CDemoCollectionViewCell.h"
#import "CCoverflowTitleView.h"
#import "CCoverflowCollectionViewLayout.h"
#import "CReflectionView.h"
#import "UIImageAverageColorAddition.h"
#import "UIImageBurnColorAddition.h"
#import "UIImageView+WebCache.h"
#import "KodiConfig.h"
#import "KodiControls.h"
#import "MetaDataViewMovies.h"
#import "MetaDataViewTVShows.h"
#import "FetchContentData.h"
#import <AVFoundation/AVFoundation.h>
#import <SDWebImageManager.h>
#import <unistd.h>
#import "VideoPlayerViewController.h"
#import <ReplayKit/ReplayKit.h>
#import "HapticHelper.h"
#import "YTPlayerView.h"
#import "isReachable.h"
#import <AutoScrollLabel/CBAutoScrollLabel.h>

@interface NSURLRequest (DummyInterface)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@interface CDemoCollectionViewController () <SDWebImageManagerDelegate, RPPreviewViewControllerDelegate, RPScreenRecorderDelegate, YTPlayerViewDelegate>
@property (readwrite, nonatomic, assign) NSInteger cellCount;
@property (readwrite, nonatomic, strong) NSArray *assets;                       // strong
@property (readwrite, nonatomic, strong) NSArray *metadata;                     // strong
@property (readwrite, nonatomic, weak) CCoverflowTitleView *titleView;          // weak
@property (weak, nonatomic) CDemoCollectionViewCell *theCell;                   // weak
@property (readwrite, nonatomic) NSInteger *lastindex;
@property (readwrite, nonatomic) NSUInteger *currentindex;
@property (assign, nonatomic) NSUInteger maxMemoryCost;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic) BOOL isFiltered;
@property (nonatomic) BOOL isKeyboardActive;
@property (nonatomic) BOOL playOnKodi;
@property (nonatomic) BOOL metadataserver;
@property (strong, atomic)UITextField *textfield;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic) NSString *kodiRPCResult;
@property (nonatomic) BOOL kodiIsAvailable;
@property (nonatomic) BOOL metadataserverIsAvailable;
@property (nonatomic) UIView *block;
@property (nonatomic) UIActivityIndicatorView *spinner;
@property (nonatomic) UIImage *kodiStatusImage;
@property (nonatomic) UIImage *metadataserverStatusImage;
@property (nonatomic) UIImage *kodiStatusImage2;
@property (nonatomic) UIImage *remoteKODI;
@property (nonatomic) UIButton *remoteKODIButton;
@property (nonatomic) UIButton *kodiIsAvailableButton;
@property (nonatomic) UIImage *metadataserverStatusImage2;
@property (nonatomic) UIImage *ContextMovieImage;
@property (nonatomic) UIImage *ContextTVShowImage;
@property (nonatomic) UIImage *ContextLiveTVImage;
@property (nonatomic) UIImageView *statusView;
@property (nonatomic) NSString *mediaServer;
@property (nonatomic) NSString *defaultStreamLanguage;
@property (nonatomic) NSString *defaultLanguage;
@property (nonatomic) NSString *tvheadend_username;
@property (nonatomic) NSString *tvheadend_password;
@property (nonatomic) NSString *kodiHostname;
@property (nonatomic) NSString *kodiUsername;
@property (nonatomic) NSString *kodiPassword;
@property (nonatomic) NSURL *currentTVShowURL;
@property (nonatomic) NSTimer *getKodiAvailablityTimer;
@property (nonatomic) VideoPlayerViewController *videoPlayer;
@property (nonatomic) FetchContentData *fetchContentData;
@property (nonatomic) BOOL ssl;
@property (nonatomic) BOOL context_movies;
@property (nonatomic) BOOL context_tvshow;
@property (nonatomic) BOOL context_livetv;
@property (nonatomic) BOOL remoteKODIButtonActive;
@property (nonatomic) BOOL KodiConfigViewDismissed;
@property (nonatomic, strong) NSArray *youTubeVideoArray;
@property (strong, nonatomic) RPScreenRecorder *screenRecorder;
@property (strong, nonatomic) AVAssetWriter *assetWriter;
@property (strong, nonatomic) AVAssetWriterInput *assetWriterInput;
@property (nonatomic) CVPixelBufferRef pixelBuffer;
@property(nonatomic, strong) IBOutlet YTPlayerView *trailerView;
@property(nonatomic, readonly) BOOL prefersStatusBarHidden;
@end

@implementation CDemoCollectionViewController;
@synthesize FilteredMovieMetaDataObject;
@synthesize FilteredTVShowMetaDataObject;
@synthesize FilteredLiveTVMetaDataObject;
@synthesize currentindex;
@synthesize responseData;
@synthesize kodiRPCResult;
@synthesize kodiIsAvailable;
@synthesize metadataserverIsAvailable;
@synthesize kodiStatusImage;
@synthesize kodiIsAvailableButton;
@synthesize metadataserverStatusImage;
@synthesize kodiStatusImage2;
@synthesize remoteKODI;
@synthesize remoteKODIButton;
@synthesize metadataserverStatusImage2;
@synthesize ContextMovieImage;
@synthesize ContextTVShowImage;
@synthesize ContextLiveTVImage;
@synthesize statusView;
@synthesize mediaServer;
@synthesize tvheadend_username;
@synthesize tvheadend_password;
@synthesize kodiHostname;
@synthesize kodiUsername;
@synthesize kodiPassword;
@synthesize defaultStreamLanguage;
@synthesize defaultLanguage;
@synthesize ssl;
@synthesize currentTVShowURL;
@synthesize context_movies;
@synthesize context_tvshow;
@synthesize context_livetv;
@synthesize youTubeVideoArray;
@synthesize remoteKODIButtonActive;
@synthesize KodiConfigViewDismissed;
@synthesize getKodiAvailablityTimer;
@synthesize videoPlayer;
@synthesize fetchContentData;
@synthesize screenRecorder;
@synthesize assetWriter;
@synthesize assetWriterInput;
//@synthesize session;
@synthesize pixelBuffer;
@synthesize block;
@synthesize spinner;

- (void)registerDefaultsFromSettingsBundle {
    // this function writes default settings as settings
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    if(!settingsBundle) {
        NSLog(@"Could not find Settings.bundle");
        return;
    }
    
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
    
    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
    for(NSDictionary *prefSpecification in preferences) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if(key) {
            [defaultsToRegister setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            
            // Authenticator Email and Password
            if ([defaults objectForKey:@"AuthEmail"] == NULL) {
                fetchContentData.AuthEmail = @"admin@omniyon.com";
            } else {
                fetchContentData.AuthEmail = [defaults objectForKey:@"AuthEmail"];
            }
            if ([defaults objectForKey:@"AuthPassword"] == NULL) {
                fetchContentData.AuthPassword = @"Avatar3d";
            } else {
                fetchContentData.AuthPassword = [defaults objectForKey:@"AuthPassword"];
            }
            
            // Default Omniyon OMM server
            if ([defaults objectForKey:@"MetaDataServer"] == NULL) {
                self.mediaServer = @"omniyon.masikh.org";
            } else {
                self.mediaServer = [defaults objectForKey:@"MetaDataServer"];
            }
            
            // Tvheadend
            if ([defaults objectForKey:@"tvheadendUsername"] == NULL) {
                self.tvheadend_username = @"media";
            } else {
                self.tvheadend_username = [defaults objectForKey:@"tvheadendUsername"];
            }
            if ([defaults objectForKey:@"tvheadendPassword"] == NULL) {
                self.tvheadend_password = @"Bhu89ol.";
            } else {
                self.tvheadend_password = [defaults objectForKey:@"tvheadendPassword"];
            }
            // Kodi
            if ([defaults objectForKey:@"kodiHostname"] == NULL) {
                self.kodiHostname = @"nuc-i9.masikh.org";
            } else {
                self.kodiHostname = [defaults objectForKey:@"kodiHostname"];
            }
            if ([defaults objectForKey:@"tvheadendUsername"] == NULL) {
                self.kodiUsername = @"kodi";
            } else {
                self.kodiUsername = [defaults objectForKey:@"kodiUsername"];
            }
            if ([defaults objectForKey:@"kodiPassword"] == NULL) {
                self.kodiPassword = @"kodi";
            } else {
                self.kodiPassword = [defaults objectForKey:@"kodiPassword"];
            }
        }
    }
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister];
}

- (void)getCachedMetaData
{
    // Load the MovieMetaData from 'cache' or download if no cache available
    NSUserDefaults *JSONMovieList = [NSUserDefaults standardUserDefaults];
    NSData *Moviedata = [JSONMovieList objectForKey:@"MovieMetaDataObject"];
    
    // Load the TVShowMetaData from 'cache' or download if no cache available
    NSUserDefaults *JSONTVShowList = [NSUserDefaults standardUserDefaults];
    NSData *TVShowdata = [JSONTVShowList objectForKey:@"TVShowMetaDataObject"];
    
    // Load the MovieMetaData from 'cache' or download if no cache available
    NSUserDefaults *JSONLiveTVList = [NSUserDefaults standardUserDefaults];
    NSData *LiveTVdata = [JSONLiveTVList objectForKey:@"LiveTVMetaDataObject"];
    
    NSKeyedUnarchiver* unarchiverMovies = [[NSKeyedUnarchiver alloc] initForReadingFromData:Moviedata error:nil];
    unarchiverMovies.requiresSecureCoding = NO;
    fetchContentData.MovieData = [unarchiverMovies decodeTopLevelObjectForKey:NSKeyedArchiveRootObjectKey error:nil];
    if (!fetchContentData.MovieData) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadMetaDataComplete) name:@"downloadMetaDataComplete" object:nil];
        [fetchContentData downloadMovieData :self.ssl :self.mediaServer];
    }
    
    NSKeyedUnarchiver* unarchiverTVShow = [[NSKeyedUnarchiver alloc] initForReadingFromData:TVShowdata error:nil];
    unarchiverTVShow.requiresSecureCoding = NO;
    fetchContentData.TVShowData = [unarchiverTVShow decodeTopLevelObjectForKey:NSKeyedArchiveRootObjectKey error:nil];
    if (!fetchContentData.TVShowData) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadMetaDataComplete) name:@"downloadMetaDataComplete" object:nil];
        [fetchContentData downloadTVShowData :self.ssl :self.mediaServer];
    }
    
    NSKeyedUnarchiver* unarchiverLiveTV = [[NSKeyedUnarchiver alloc] initForReadingFromData:LiveTVdata error:nil];
    unarchiverLiveTV.requiresSecureCoding = NO;
    fetchContentData.LiveTVData = [unarchiverLiveTV decodeTopLevelObjectForKey:NSKeyedArchiveRootObjectKey error:nil];
    if (!fetchContentData.LiveTVData) {
        @try {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadMetaDataComplete) name:@"downloadMetaDataComplete" object:nil];
            [fetchContentData downloadLiveTVData :self.ssl :self.mediaServer :self.tvheadend_username :self.tvheadend_password];
        }
        @catch (NSException * e) {
           NSLog(@"Exception: %@", e);
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    fetchContentData = [[FetchContentData alloc] init];
    [self registerDefaultsFromSettingsBundle];
    
    // Create Movie/TVShow/LiveTV selectors 1024/568x768/320
    self.ContextMovieImage = [UIImage imageNamed:@"movies-active.png"];
    self.ContextTVShowImage = [UIImage imageNamed:@"tvshow-inactive.png"];
    self.ContextLiveTVImage = [UIImage imageNamed:@"livetv-inactive.png"];
    UIButton *ContextMovie = [[UIButton alloc] init];
    UIButton *ContextTVShow = [[UIButton alloc] init];
    UIButton *ContextLiveTV = [[UIButton alloc] init];
    
    self.kodiStatusImage2 = [UIImage imageNamed:@"playOnKodiInActive.png"];
    UIButton *playOnKodiButton = [[UIButton alloc]initWithFrame:CGRectMake(10, 15, 40, 40)];
    
    [playOnKodiButton setImage:self.kodiStatusImage2 forState:UIControlStateNormal];
    [playOnKodiButton addTarget:self action:@selector(KodiButton:) forControlEvents:UIControlEventTouchUpInside];
    playOnKodiButton.tag = 1;
    self.playOnKodi = FALSE;
    self.remoteKODIButtonActive = FALSE;
    self.KodiConfigViewDismissed = TRUE;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(KodiIsAvailableObserverNoView:) name:@"KodiIsAvailable" object:nil];
    self.getKodiAvailablityTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(getKodiAvailablity) userInfo:nil repeats:YES];
    
    // Show Splash image
    UIImageView *imageView=[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"SplashScreen.png"]];
    imageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    [self.view addSubview:imageView];
    [self.view bringSubviewToFront:imageView];
    
    // Create a reload button
    UIImage *ReloadButtonImage = [UIImage imageNamed:@"cloud-reload.png"];
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat width;
    if (screenBounds.size.width > screenBounds.size.height) {
        width = screenBounds.size.width;
    } else {
        width = screenBounds.size.height;
    }
    UIButton *ReloadButton = [[UIButton alloc]initWithFrame:CGRectMake(width - 50, 15, 40, 40)];
    
    [ReloadButton setImage:ReloadButtonImage forState:UIControlStateNormal];
    [ReloadButton addTarget:self action:@selector(ReloadMetaData) forControlEvents:UIControlEventTouchUpInside];
    
    // Filter content
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 3, 15, self.view.frame.size.width / 3, 44)];
    self.searchBar.delegate = (id)self;
    self.searchBar.keyboardType = UIKeyboardAppearanceDark;
    self.searchBar.keyboardType = UIKeyboardTypeASCIICapable;
    [self.searchBar setBackgroundImage:[UIImage imageNamed:@"black.gif"]];
    [self.searchBar setTranslucent:NO];
    self.searchBar.placeholder = [NSMutableString stringWithString:@"Search by title"];
    [[UITextField appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setTextColor:[UIColor lightGrayColor]];
    //now fade out splash image and add buttons...
    [UIView transitionWithView:imageView duration:2.0f options:UIViewAnimationOptionTransitionNone animations:^(void){imageView.alpha=0.0f;} completion:^(BOOL finished){
        [imageView removeFromSuperview];
        
        [self.view addSubview:self.searchBar];
        [self.view addSubview:ContextMovie];
        [self.view addSubview:ContextTVShow];
        [self.view addSubview:ContextLiveTV];
        [self.view addSubview:playOnKodiButton];
        [self.view addSubview:ReloadButton];
    }];
    
    self.ssl = FALSE;
    
    // Set initial context to Movies
    self.context_movies = TRUE;
    self.context_tvshow = FALSE;
    self.context_livetv = FALSE;
    
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([CCoverflowTitleView class]) bundle:NULL] forSupplementaryViewOfKind:@"title" withReuseIdentifier:@"title"];
    
    if (width == 1024) {
        [ContextMovie setFrame:CGRectMake(width - 100, 15, 40, 40)];
        [ContextTVShow setFrame:CGRectMake(width - 150, 15, 40, 40)];
        [ContextLiveTV setFrame:CGRectMake(width - 200, 15, 40, 40)];
    } else {
        [ContextMovie setFrame:CGRectMake(width - 95, 15, 40, 40)];
        [ContextTVShow setFrame:CGRectMake(width - 140, 15, 40, 40)];
        [ContextLiveTV setFrame:CGRectMake(width - 185, 15, 40, 40)];
    }
    
    ContextMovie.tag = 20;
    ContextTVShow.tag = 21;
    ContextLiveTV.tag = 22;
    [ContextMovie setImage:self.ContextMovieImage forState:UIControlStateNormal];
    [ContextTVShow setImage:self.ContextTVShowImage forState:UIControlStateNormal];
    [ContextLiveTV setImage:self.ContextLiveTVImage forState:UIControlStateNormal];
    [ContextMovie addTarget:self action:@selector(SetContentContext:) forControlEvents:UIControlEventTouchUpInside];
    [ContextTVShow addTarget:self action:@selector(SetContentContext:) forControlEvents:UIControlEventTouchUpInside];
    [ContextLiveTV addTarget:self action:@selector(SetContentContext:) forControlEvents:UIControlEventTouchUpInside];
    
    [KodiConfig isKodiAvailable:self.kodiUsername :self.kodiPassword :self.kodiHostname];
    [self checkKodiStatusButtonTimer];
    self.lastindex = 0;
    if (@available(iOS 11.0, *)) {
        [self setNeedsUpdateOfHomeIndicatorAutoHidden];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotLanguageID) name:@"gotLanguageID" object:nil];
    [fetchContentData getLanguageID:self.ssl :self.mediaServer];
    self.defaultStreamLanguage = self.defaultLanguage;
    while (fetchContentData.languageID == nil) {
        NSLog(@"waiting for languageID");
        [NSThread sleepForTimeInterval:1.0f];
    }
    
    [self getCachedMetaData];
    [self init_cells];
    
}

- (void)gotLanguageID {
    self.defaultLanguage = fetchContentData.languageID;
}

- (bool)prefersHomeIndicatorAutoHidden{
    return true;
}

-(BOOL)prefersStatusBarHidden{
    return YES;
}

- (bool)childViewControllerForHomeIndicatorAutoHidden: UIViewController {
    return true;
}

-(void)getKodiAvailablity {
    [KodiConfig isKodiAvailable:self.kodiUsername :self.kodiPassword :self.kodiHostname];
    self.videoPlayer.kodiIsAvailable = self.kodiIsAvailable;
}

- (void)checkKodiStatusButtonTimer {
    if (![NSThread isMainThread]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSTimer scheduledTimerWithTimeInterval:0.1
                                             target:self
                                           selector:@selector(setKodiRemoteControlButton)
                                           userInfo:nil
                                            repeats:YES];
        });
    }
    else{
        [NSTimer scheduledTimerWithTimeInterval:0.1
                                         target:self
                                       selector:@selector(setKodiRemoteControlButton)
                                       userInfo:nil
                                        repeats:YES];
    }
}

- (void)setKodiRemoteControlButton {
    if (self.playOnKodi) {
        // REMOTE CONTROL BUTTON
        if (self.remoteKODIButtonActive == FALSE && self.KodiConfigViewDismissed == TRUE) {
            self.remoteKODI = [UIImage imageNamed:@"remoteKODI.png"];
            self.remoteKODIButton = [[UIButton alloc] initWithFrame:CGRectMake(50, 15, 40, 40)];
            self.remoteKODIButton.tag = 343;
            [self.view addSubview:self.remoteKODIButton];
            
            [self.remoteKODIButton setImage:self.remoteKODI forState:UIControlStateNormal];
            [self.remoteKODIButton addTarget:self action:@selector(remoteControlKODIView) forControlEvents:UIControlEventTouchUpInside];
            self.remoteKODIButtonActive = TRUE;
        }
    } else {
        if (self.remoteKODIButtonActive == TRUE) {
            UIButton *button = (UIButton *)[self.view viewWithTag:343];
            [button removeFromSuperview];
            [self.view setNeedsDisplay];
            self.remoteKODIButtonActive = FALSE;
        }
    }
}

/* BEGIN: Context Observers (switch between Movies/TVShows/LiveTV
 */
- (IBAction)SetContentContext:(id)sender
{
    UIButton *ContextMovieButton = (UIButton *)[self.view viewWithTag:20];
    UIButton *ContextTVShowButton = (UIButton *)[self.view viewWithTag:21];
    UIButton *ContextLiveTVButton = (UIButton *)[self.view viewWithTag:22];
    
    if ([sender tag] == 20) {
        if (! self.context_movies) {
            self.context_movies = TRUE;
            self.context_tvshow = FALSE;
            self.context_livetv = FALSE;
            [ContextMovieButton setImage:[UIImage imageNamed:@"movies-active.png"] forState:UIControlStateNormal];
            [ContextTVShowButton setImage:[UIImage imageNamed:@"tvshow-inactive.png"] forState:UIControlStateNormal];
            [ContextLiveTVButton setImage:[UIImage imageNamed:@"livetv-inactive.png"] forState:UIControlStateNormal];
        }
    }
    if ([sender tag] == 21) {
        if (! self.context_tvshow) {
            self.context_movies = FALSE;
            self.context_tvshow = TRUE;
            self.context_livetv = FALSE;
            [ContextMovieButton setImage:[UIImage imageNamed:@"movies-inactive.png"] forState:UIControlStateNormal];
            [ContextTVShowButton setImage:[UIImage imageNamed:@"tvshow-active.png"] forState:UIControlStateNormal];
            [ContextLiveTVButton setImage:[UIImage imageNamed:@"livetv-inactive.png"] forState:UIControlStateNormal];
        }
    }
    if ([sender tag] == 22) {
        if (! self.context_livetv) {
            self.context_movies = FALSE;
            self.context_tvshow = FALSE;
            self.context_livetv = TRUE;
            [ContextMovieButton setImage:[UIImage imageNamed:@"movies-inactive.png"] forState:UIControlStateNormal];
            [ContextTVShowButton setImage:[UIImage imageNamed:@"tvshow-inactive.png"] forState:UIControlStateNormal];
            [ContextLiveTVButton setImage:[UIImage imageNamed:@"livetv-active.png"] forState:UIControlStateNormal];
        }
    }
    
    [self init_cells];
    [self.collectionView reloadData];
    [self scrollViewDidScroll:self.collectionView];
    [self.view setNeedsDisplay];
}

/* BEGIN: Kodi Observers
 
 These observers watches the result from a JSON-RPC call
 to a KODI-client. Depending on the result, the boolean 'self.kodiIsAvailable'
 will be set to TRUE or FALSE. This will influence the KodiConfig button.
 
 */
- (IBAction)KodiButton:(id)sender
{
    [KodiConfig isKodiAvailable:self.kodiUsername :self.kodiPassword :self.kodiHostname];
    
    // Open the pop-up window if ~both~ Kodi is unreachable  and we switch 'ON' playOnKodi
    if (self.playOnKodi == NO && self.kodiIsAvailable == NO)
    {
        self.KodiConfigViewDismissed = FALSE;
        // Register observers for the response on KodiIs(Un)Available
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(KodiIsAvailableObserver:) name:@"KodiIsAvailable" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(KodiIsUnAvailableObserver:) name:@"KodiIsUnAvailable" object:nil];
    }
    
    // Flip the button (only if kodi is reachable we switch the button 'ON')
    if (self.playOnKodi == YES) { self.playOnKodi = NO; } else { if (self.kodiIsAvailable) { self.playOnKodi = YES; } }
    
    // Change the button Image according to its state and Set remote control KODI button
    self.kodiIsAvailableButton = (UIButton*)sender;
    if (self.kodiIsAvailable && self.playOnKodi ) {
        self.kodiStatusImage2 = [UIImage imageNamed:@"playOnKodiActive.png"];
    } else {
        self.kodiStatusImage2 = [UIImage imageNamed:@"playOnKodiInActive.png"];
    }
    [self.kodiIsAvailableButton setImage:self.kodiStatusImage2 forState:UIControlStateNormal];
}

- (void)remoteControlKODIView {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeOnTablet:) name:@"resumeOnTablet" object:nil];
    [KodiControls KodiControlView:self.view :self.kodiUsername :self.kodiPassword :self.kodiHostname];
    NSLog(@"remoteControlKODIView");
}

- (void)resumeOnTablet:(NSNotification*)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"resumeOnTablet" object:nil];
    NSLog(@"resumeOnTablet: %@", notification.userInfo);
    self.playOnKodi = FALSE;
    NSURL *url = [NSURL URLWithString:[notification.userInfo objectForKey:@"url"]];
    float position = [[notification.userInfo objectForKey:@"position"] floatValue];
    [self playContent:url :position];
}

- (void)KodiIsAvailableObserver:(NSNotification *)notif {
    self.kodiIsAvailable = TRUE;
    self.playOnKodi = TRUE;
    [self.statusView setImage:[UIImage imageNamed:@"checkPass.png"]];
    self.kodiStatusImage2 = [UIImage imageNamed:@"playOnKodiActive.png"];
    UIButton *button=(UIButton *)[self.view viewWithTag:1];
    [button setImage:self.kodiStatusImage2 forState:UIControlStateNormal];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"KodiIsAvailable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(KodiIsAvailableObserver:) name:@"KodiIsAvailable" object:nil];
}

- (void)KodiIsAvailableObserverNoView:(NSNotification *)notif {
    self.kodiIsAvailable = TRUE;
    // self.playOnKodi = TRUE;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"KodiIsAvailable" object:nil];
}


- (void)KodiIsUnAvailableObserver:(NSNotification *)notif {
    self.kodiIsAvailable = FALSE;
    self.playOnKodi = FALSE;
    [self.statusView setImage:[UIImage imageNamed:@"checkFail.png"]];
    self.kodiStatusImage2 = [UIImage imageNamed:@"playOnKodiInActive.png"];
    UIButton *button=(UIButton *)[self.view viewWithTag:1];
    [button setImage:self.kodiStatusImage2 forState:UIControlStateNormal];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"KodiIsUnAvailable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(KodiIsUnAvailableObserver:) name:@"KodiIsUnAvailable" object:nil];
}

/* END: Kodi Observers */

-(void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)text
{
    self.isKeyboardActive = TRUE;
    // The user clicked the [X] button or otherwise cleared the text.
    if(text.length == 0) {
        self.isFiltered = FALSE;
    } else {
        self.isFiltered = TRUE;
        self.isKeyboardActive = TRUE;
        
        if (self.context_movies) {
            FilteredMovieMetaDataObject = [[NSMutableArray alloc] init];
            for (NSDictionary *metaData in fetchContentData.MovieData)
            {
                NSRange titleRange = [metaData[@"title"] rangeOfString:text options:NSCaseInsensitiveSearch];
                if (titleRange.location != NSNotFound)
                {
                    [FilteredMovieMetaDataObject addObject:metaData];
                }
            }
        } else if (self.context_tvshow) {
            FilteredTVShowMetaDataObject = [[NSMutableArray alloc] init];
            for (NSDictionary *metaData in fetchContentData.TVShowData)
            {
                NSRange titleRange = [metaData[@"title"] rangeOfString:text options:NSCaseInsensitiveSearch];
                if (titleRange.location != NSNotFound)
                {
                    [FilteredTVShowMetaDataObject addObject:metaData];
                }
            }
        } else {
            FilteredLiveTVMetaDataObject = [[NSMutableArray alloc] init];
            for (NSDictionary *metaData in fetchContentData.LiveTVData)
            {
                NSRange titleRange = [metaData[@"name"] rangeOfString:text options:NSCaseInsensitiveSearch];
                if (titleRange.location != NSNotFound)
                {
                    [FilteredLiveTVMetaDataObject addObject:metaData];
                }
            }
        }
    }
    
    [self init_cells];
    [self.collectionView reloadData];
    [self scrollViewDidScroll:self.collectionView];
    
    if (! self.isKeyboardActive) [self dismissKeyboard];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    [self dismissKeyboard];
}

- (void)dismissKeyboard
{
    [self.searchBar performSelector: @selector(resignFirstResponder)
                         withObject: nil];
    self.isKeyboardActive = FALSE;
}

- (void)closeAlertview
{
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)preloadImage:(NSInteger)index
{
    BOOL gotimage;
    @try {
        NSArray *metadata;
        if (self.context_movies) {
            metadata = fetchContentData.MovieData;
        } else if (self.context_tvshow) {
            metadata = fetchContentData.TVShowData;
        } else {
            metadata = fetchContentData.LiveTVData;
        }
        gotimage = false;
        NSURL *thumb_url = [NSURL URLWithString:[[metadata objectAtIndex:(NSUInteger)index] objectForKey:@"thumb"]];
        NSURL *fanart_url = [NSURL URLWithString:[[metadata objectAtIndex:(NSUInteger)index] objectForKey:@"fanart"]];
        
        NSArray *images = @[thumb_url, fanart_url];
        
        // Check if thumbnail is cached
        for (int i = 0; i < [images count]; i++) {
            NSString *imageId;
            @try {
                NSURL *imageURL = [images objectAtIndex: i];
                imageId = [[[[imageURL.absoluteString componentsSeparatedByString:@"id="] objectAtIndex:1] componentsSeparatedByString:@"&"] objectAtIndex:0];
            } @catch (NSException *exception) {
                NSLog(@"%@", exception);
            }
            
            if ([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:imageId]) {
                [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:imageId];
                NSLog(@"Got image from mem-cache: %@", imageId);
                gotimage = true;
            } else {
                @try {
                    if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:imageId])
                    {
                        // Set cached thumbnail image on imageview
                        [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:imageId];
                        NSLog(@"Got image from disk-cache: %@", imageId);
                        gotimage = true;
                    }
                } @catch (NSException *exception) {
                }
            }
            
            if (!gotimage) {
                UIImage *loading = [UIImage imageNamed:@"loading.png"];
                
                [_theCell.imageViewCoverflow sd_setImageWithURL:thumb_url placeholderImage:loading completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL)
                 {
                    @try {
                        UIImage *transformedImage = [self imageManager:(SDWebImageManager *)image transformDownloadedImage:image withURL:imageURL];
                        [[SDImageCache sharedImageCache] storeImage:transformedImage forKey:imageId toDisk:YES];
                        NSLog(@"Got image from url: %@", imageId);
                    } @catch (NSException *exception) {
                    }
                 }
                 ];
                [_theCell.imageViewCoverflow sd_setImageWithURL:fanart_url placeholderImage:loading completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL)
                {
                    @try {
                        UIImage *transformedImage = [self imageManager:(SDWebImageManager *)image transformDownloadedImage:image withURL:imageURL];
                        [[SDImageCache sharedImageCache] storeImage:transformedImage forKey:imageId toDisk:YES];
                        NSLog(@"Got image from url: %@", imageId);
                    } @catch (NSException *exception) {
                    }
                }
                ];
            }
        }
    }
    
    @catch (NSException *exception) {
        // deal with the exception
        _theCell.backgroundColor = [UIColor clearColor];
    }
}

- (void)init_cells
{
    NSMutableArray *theAssets = [NSMutableArray array];
    NSMutableArray *theMetadata = [NSMutableArray array];
    
    @try {
        if (self.isFiltered) {
            if (self.context_movies) {
                for (NSDictionary *theURL in FilteredMovieMetaDataObject) {
                    [theAssets addObject:[theURL objectForKey:@"thumb"]];
                    [theMetadata addObject:[theURL objectForKey:@"plot"]];
                    
                }
            } else if (self.context_tvshow) {
                for (NSDictionary *theURL in FilteredTVShowMetaDataObject) {
                    [theAssets addObject:[theURL objectForKey:@"poster"]];
                    NSArray *plotArray = [theURL valueForKeyPath:@"TVShowdetail.locale_data.plot"];
                    [theMetadata addObject:plotArray[0]];
                }
            } else if (self.context_livetv) {
                for (NSDictionary *theURL in FilteredLiveTVMetaDataObject) {
                    [theAssets addObject:[theURL objectForKey:@"logo"]];
                    [theMetadata addObject:[theURL objectForKey:@"url"]];
                }
            }
        } else {
            if (self.context_movies) {
                for (NSDictionary *theURL in fetchContentData.MovieData) {
                    [theAssets addObject:[theURL objectForKey:@"thumb"]];
                    [theMetadata addObject:[theURL objectForKey:@"plot"]];
                    
                }
            } else if (self.context_tvshow) {
                for (NSDictionary *theURL in fetchContentData.TVShowData) {
                    [theAssets addObject:[theURL objectForKey:@"poster"]];
                    NSArray *plotArray = [theURL valueForKeyPath:@"TVShowdetail.locale_data.plot"];
                    [theMetadata addObject:plotArray[0]];
                }
            } else if (self.context_livetv) {
                for (NSDictionary *theURL in fetchContentData.LiveTVData) {
                    [theAssets addObject:[theURL objectForKey:@"logo"]];
                    [theMetadata addObject:[theURL objectForKey:@"url"]];
                }
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"init_cells %@", exception);
    }
    
    self.assets = theAssets;
    self.metadata = theMetadata;
    self.cellCount = self.assets.count;
}

- (void)ReloadMetaData
{
    @try {
        block = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        block.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7f];
        [self.view addSubview:block];
        
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        spinner.center = self.view.center;
        spinner.color = [UIColor colorWithRed:0.0f/255.0f green:178.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
        [block addSubview:spinner];
        [spinner startAnimating];
        
        // how we stop refresh from freezing the main UI thread
        dispatch_queue_t downloadQueue = dispatch_queue_create("downloader", NULL);
        dispatch_async(downloadQueue, ^{
            // do our long running process here
            @try {
                NSLog(@"Downloading JSON data from server.");
                [self registerDefaultsFromSettingsBundle];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadMetaDataComplete) name:@"downloadMetaDataComplete" object:nil];
                if (self.context_movies) {
                    [fetchContentData downloadMovieData :self.ssl :self.mediaServer];
                } else if (self.context_tvshow) {
                    [fetchContentData downloadTVShowData :self.ssl :self.mediaServer];
                } else {
                    [fetchContentData downloadLiveTVData :self.ssl :self.mediaServer :self.tvheadend_username :self.tvheadend_password];
                }
            }
            @catch (NSException * e) {
                NSLog(@"Exception: %@", e);
            }
            @finally {
            }
        });
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
}

- (void) downloadMetaDataComplete {
    [self init_cells];
    // Dowloading is done, remove garbage from view
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self.spinner stopAnimating];
        [self.spinner removeFromSuperview];
        [self.block removeFromSuperview];
        @try {
            NSIndexPath *changedRow = [NSIndexPath indexPathForRow:self.cellCount - 1 inSection:0];
            [self.collectionView setContentOffset:CGPointMake(changedRow.row * ((CCoverflowCollectionViewLayout*)self.collectionView.collectionViewLayout).cellSpacing, 0) animated:YES];
            [self updateTitle:changedRow];
            [self.collectionView reloadData];
            [self scrollViewDidScroll:self.collectionView];
        }
        @catch (NSException * e) {
            NSLog(@"Exception: %@", e);
        }
        @finally {
        }
    });
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    @try {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FishCell" forIndexPath:indexPath];
        
        // Configure the cell...
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FishCell"];
        }
        
        if (self.isFiltered) {
            if (self.context_movies) {
                [cell.textLabel setText:[[FilteredMovieMetaDataObject objectAtIndex:indexPath.row] objectForKey:@"name"] ];
                [cell.detailTextLabel setText:[[FilteredMovieMetaDataObject objectAtIndex:indexPath.row] objectForKey:@"created"]];
            } else if (self.context_tvshow) {
                [cell.textLabel setText:[[FilteredTVShowMetaDataObject objectAtIndex:indexPath.row] objectForKey:@"name"] ];
                [cell.detailTextLabel setText:[[FilteredTVShowMetaDataObject objectAtIndex:indexPath.row] objectForKey:@"created"]];
            } else if (self.context_livetv) {
                [cell.textLabel setText:[[FilteredLiveTVMetaDataObject objectAtIndex:indexPath.row] objectForKey:@"name"] ];
                [cell.detailTextLabel setText:[[FilteredLiveTVMetaDataObject objectAtIndex:indexPath.row] objectForKey:@"created"]];
            }
        } else {
            if (self.context_movies) {
                [cell.textLabel setText:[[fetchContentData.MovieData objectAtIndex:indexPath.row] objectForKey:@"name"] ];
                [cell.detailTextLabel setText:[[fetchContentData.MovieData objectAtIndex:indexPath.row] objectForKey:@"created"]];
            } else if (self.context_tvshow) {
                [cell.textLabel setText:[[fetchContentData.TVShowData objectAtIndex:indexPath.row] objectForKey:@"name"] ];
                [cell.detailTextLabel setText:[[fetchContentData.TVShowData objectAtIndex:indexPath.row] objectForKey:@"created"]];
            } else if (self.context_livetv) {
                [cell.textLabel setText:[[fetchContentData.LiveTVData objectAtIndex:indexPath.row] objectForKey:@"name"] ];
                [cell.detailTextLabel setText:[[fetchContentData.LiveTVData objectAtIndex:indexPath.row] objectForKey:@"created"]];
            }
        }
        
        return cell;
    }
    @catch (NSException *exception) {
        return nil;
    }
}

- (void)updateTitle:(NSIndexPath*)theIndexPath
{
    @try {
        NSDictionary *theURL;
        if (theIndexPath == NULL)
        {
            self.titleView.titleLabel.text = @"No content found!";
        } else {
            if (self.isFiltered) {
                if (self.context_movies) {
                    if (FilteredMovieMetaDataObject.count == 0) {
                        self.titleView.titleLabel.text = @"No content found!";
                    } else {
                        theURL = [FilteredMovieMetaDataObject objectAtIndex:theIndexPath.row];
                    }
                } else if (self.context_tvshow) {
                    if (FilteredTVShowMetaDataObject.count == 0) {
                        self.titleView.titleLabel.text = @"No content found!";
                    } else {
                        theURL = [FilteredTVShowMetaDataObject objectAtIndex:theIndexPath.row];
                    }
                } else if (self.context_livetv) {
                    if (FilteredLiveTVMetaDataObject.count == 0) {
                        self.titleView.titleLabel.text = @"No content found!";
                    } else {
                        theURL = [FilteredLiveTVMetaDataObject objectAtIndex:theIndexPath.row];
                    }
                }
            } else {
                if (self.context_movies) {
                    theURL = [fetchContentData.MovieData objectAtIndex:theIndexPath.row];
                } else if (self.context_tvshow) {
                    theURL = [fetchContentData.TVShowData objectAtIndex:theIndexPath.row];
                } else if (self.context_livetv) {
                    theURL = [fetchContentData.LiveTVData objectAtIndex:theIndexPath.row];
                }
            }
            NSString *str = [[NSString alloc] init];
            if (self.context_movies) {
                str = [NSString stringWithFormat:@"%@, ", [theURL objectForKey:@"title"]];
                str = [str stringByAppendingString:[NSString stringWithFormat:@"%@", (NSNumber *)[theURL objectForKey:@"year"]]];
            } else if (self.context_tvshow) {
                NSArray *titleArray = [theURL valueForKeyPath:@"TVShowdetail.locale_data.title"];
                str = [NSString stringWithFormat:@"%@", titleArray[0]];
            } else if (self.context_livetv) {
                str = [NSString stringWithFormat:@"%@", [theURL objectForKey:@"name"]];
            }
            
            if (! [str isEqualToString:self.titleView.titleLabel.text]) {
                [HapticHelper generateFeedback:FeedbackType_Impact_Light];
            }
            self.titleView.titleLabel.text = str;
            self.titleView.titleLabel.textColor = [UIColor colorWithRed:0.0f/255.0f green:178.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"updateTitle %@", exception);
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
{
    int rowCount;
    if(self.isFiltered) {
        if (self.context_movies) {
            rowCount = (int)FilteredMovieMetaDataObject.count;
        } else if (self.context_tvshow) {
            rowCount = (int)FilteredTVShowMetaDataObject.count;
        } else {
            rowCount = (int)FilteredLiveTVMetaDataObject.count;
        }
    } else {
        if (self.context_movies) {
            rowCount = (int)fetchContentData.MovieData.count;
        } else if (self.context_tvshow) {
            rowCount = (int)fetchContentData.TVShowData.count;
        } else {
            rowCount = (int)fetchContentData.LiveTVData.count;
        }
    }
    self.cellCount = rowCount;
    return rowCount;
    
    // return(self.cellCount);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    SDWebImageManager.sharedManager.delegate = self;
    _theCell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"DEMO_CELL" forIndexPath:indexPath];
    
    if (_theCell.gestureRecognizers.count == 0)
    {
        [_theCell addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapCell:)]];
    }
    
    _theCell.backgroundColor = [UIColor colorWithHue:(CGFloat)indexPath.row / (CGFloat)self.cellCount saturation:0.333f brightness:1.0 alpha:1.0];
    
    if (indexPath.row < self.assets.count)
    {
        NSProcessInfo *info = [NSProcessInfo processInfo];
        
        // Compute total cost limit in bytes
        NSUInteger totalCostLimit = (NSUInteger)(info.physicalMemory * 0.35); // Use 15% of available RAM
        [SDImageCache sharedImageCache].maxMemoryCost = totalCostLimit / 4; // Divide totalCostLimit in bytes by number of bytes per pixel
        UIImage *thisImage;
        
        @try {
            NSURL *theURL = [NSURL URLWithString: [self.assets objectAtIndex:indexPath.row]];
            // Check if thumbnail is cached
            [self preloadImage:indexPath.row];
            thisImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:@"\(theURL)"];
            _theCell.imageViewCoverflow.image = thisImage;
            [_theCell.imageViewCoverflow sd_setImageWithURL:theURL placeholderImage:[UIImage imageNamed:@"loading.gif"]];
            [_theCell.reflectionImageView setImage:_theCell.imageViewCoverflow.image];
        }
        
        @catch (NSException *exception) {
            // deal with the exception
            _theCell.backgroundColor = [UIColor clearColor];
        }
    }
    
    _theCell.backgroundColor = [UIColor clearColor];
    return(_theCell);
}

- (UIImage *)imageManager:(SDWebImageManager *)imageManager transformDownloadedImage:(UIImage *)image withURL:(NSURL *)imageURL
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat width;
    if (screenBounds.size.width < screenBounds.size.height) {
        width = screenBounds.size.height;
    } else {
        width = screenBounds.size.width;
    }
    
    CGSize resizedImageSize;
    
    switch ((int)width) {
        case 1024:
            resizedImageSize = CGSizeMake(426, 569);
            break;
        case 568:
            resizedImageSize = CGSizeMake(200, 300);
            break;
        default:
            resizedImageSize = CGSizeMake(216, 288);
            break;
    }
    
    UIGraphicsBeginImageContextWithOptions(resizedImageSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, resizedImageSize.width, resizedImageSize.height)];
    UIImage* resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    image = resizedImage;
    return image;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    CCoverflowTitleView *theView = [self.collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"title" forIndexPath:indexPath];
    self.titleView = theView;
    
    @try {
        NSIndexPath *theIndexPath = ((CCoverflowCollectionViewLayout *)self.collectionView.collectionViewLayout).currentIndexPath;
        [self updateTitle:theIndexPath];
    }
    @finally {
        return(theView);
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    [self dismissKeyboard];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSIndexPath *theIndexPath = ((CCoverflowCollectionViewLayout *)self.collectionView.collectionViewLayout).currentIndexPath;
    [self updateTitle:theIndexPath];
    [self.view setNeedsDisplay];
    [self.theCell.contentView setNeedsDisplay];
    [self.theCell.reflectionImageView setNeedsDisplay];
}

- (void)clearMemory
{
    [[SDImageCache sharedImageCache] clearMemory];
    [[SDImageCache sharedImageCache] setValue:nil forKey:@"memCache"];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    NSLog(@"applicationDidReceiveMemoryWarning");
    [self clearMemory];
}

- (void)playContent:(NSURL*)url
{
    if (self.kodiIsAvailable && self.playOnKodi) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"resumeOnKodi" object:nil];
        NSString *thisURL = [url absoluteString];
        NSString *postData = [NSString stringWithFormat: @"{\"jsonrpc\":\"2.0\",\"id\":\"1\",\"method\":\"Player.Open\",\"params\":{\"item\":{\"file\":\"%@\"}}}", thisURL];
        NSURL *kodiPlayer = [NSURL URLWithString: [NSString stringWithFormat:@"http://%@:%@@%@:8080/jsonrpc", self.kodiUsername, self.kodiPassword, self.kodiHostname]];
        NSLog(@"curl -s --data-binary '%@' -H 'content-type: application/json;' %@", postData, [NSString stringWithFormat:@"http://%@:%@@%@:8080/jsonrpc", self.kodiUsername, self.kodiPassword, self.kodiHostname]);
        [KodiConfig requestToKodi:kodiPlayer :postData];
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeOnKodi:) name:@"resumeOnKodi" object:nil];
        self.videoPlayer = [self.storyboard instantiateViewControllerWithIdentifier:@"videoPlayer"];
        self.videoPlayer.videoUrl = url;
        self.videoPlayer.kodiIsAvailable = self.kodiIsAvailable;
        [self presentViewController:self.videoPlayer animated:YES completion:nil];
    }
}

- (void)playContent:(NSURL*)url :(float)position
{
    if (self.kodiIsAvailable && self.playOnKodi) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"resumeOnKodi" object:nil];
        NSString *thisURL = [url absoluteString];
        NSString *postData = [NSString stringWithFormat: @"{\"jsonrpc\":\"2.0\",\"id\":\"1\",\"method\":\"Player.Open\",\"params\":{\"item\":{\"file\":\"%@\"}}}", thisURL];
        NSURL *kodiPlayer = [NSURL URLWithString: [NSString stringWithFormat:@"http://%@:%@@%@:8080/jsonrpc", self.kodiUsername, self.kodiPassword, self.kodiHostname]];
        NSLog(@"curl -s --data-binary '%@' -H 'content-type: application/json;' %@", postData, [NSString stringWithFormat:@"http://%@:%@@%@:8080/jsonrpc", self.kodiUsername, self.kodiPassword, self.kodiHostname]);
        [KodiConfig requestToKodi:kodiPlayer :postData];
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeOnKodi:) name:@"resumeOnKodi" object:nil];
        self.videoPlayer = [self.storyboard instantiateViewControllerWithIdentifier:@"videoPlayer"];
        self.videoPlayer.videoUrl = url;
        self.videoPlayer.kodiIsAvailable = self.kodiIsAvailable;

        [self presentViewController:self.videoPlayer animated:YES completion:^{
            NSLog(@"Set postion to: %f", position);
            self.videoPlayer.mediaPlayer.position = position;
        }];
    }
}

- (void)resumeOnKodi:(NSNotification*)notification {
    NSLog(@"resumeOnKodi: selector");
    NSDictionary *dict = notification.userInfo;
    NSString *thisURL = [[dict objectForKey:@"url"] absoluteString];
    NSString *postData = [NSString stringWithFormat: @"{\"jsonrpc\":\"2.0\",\"id\":\"1\",\"method\":\"Player.Open\",\"params\":{\"item\":{\"file\":\"%@\"}}}", thisURL];
    NSURL *kodiPlayer = [NSURL URLWithString: [NSString stringWithFormat:@"http://%@:%@@%@:8080/jsonrpc", self.kodiUsername, self.kodiPassword, self.kodiHostname]];
    NSLog(@"curl -s --data-binary '%@' -H 'content-type: application/json;' %@", postData, [NSString stringWithFormat:@"http://%@:%@@%@:8080/jsonrpc", self.kodiUsername, self.kodiPassword, self.kodiHostname]);
    [self.videoPlayer killVideoPlayer];
    [KodiConfig resumeOnKodi:kodiPlayer :postData :dict :self.kodiHostname :self.kodiUsername :self.kodiPassword];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (void)startTrailerContent
{
    NSIndexPath *theIndexPath = ((CCoverflowCollectionViewLayout *)self.collectionView.collectionViewLayout).currentIndexPath;
    NSArray *Trailers;
    if (self.context_movies) {
        Trailers = [fetchContentData.MovieData[theIndexPath.item] objectForKey:@"trailers"];
    } else {
        Trailers = [fetchContentData.TVShowData[theIndexPath.item] valueForKeyPath:@"TVShowdetail.trailers"];
    }
    
    if (self.isFiltered) {
        if (self.context_movies) {
            Trailers = [FilteredMovieMetaDataObject[theIndexPath.item] objectForKey:@"trailers"];
        } else {
            Trailers = [FilteredTVShowMetaDataObject[theIndexPath.item] valueForKeyPath:@"TVShowdetail.trailers"];
        }
    }
    if (Trailers.count > 0) {
        self.trailerView = [[YTPlayerView alloc] initWithFrame:self.view.bounds];
        self.trailerView.delegate = self;
        
        NSString *trailerKey = @"";
        NSString *tmp;
        int num = 0;
        for (int i = 0; i < Trailers.count; i++) {
            tmp = [NSString stringWithFormat:@"%@", [Trailers[i] objectForKey:@"name"]];
            if ([tmp localizedCaseInsensitiveContainsString:@"official"] && [tmp localizedCaseInsensitiveContainsString:@"trailer"]) {
                trailerKey = [NSString stringWithFormat:@"%@", [Trailers[i] objectForKey:@"key"]];
                num = i;
            } else {
            if ([tmp localizedCaseInsensitiveContainsString:@"official"]) {
                trailerKey = [NSString stringWithFormat:@"%@", [Trailers[i] objectForKey:@"key"]];
                num = i;
            } else {
            if ([tmp localizedCaseInsensitiveContainsString:@"original"]  && [tmp localizedCaseInsensitiveContainsString:@"trailer"]) {
                trailerKey = [NSString stringWithFormat:@"%@", [Trailers[i] objectForKey:@"key"]];
                num = i;
            } else {
            if ([tmp localizedCaseInsensitiveContainsString:@"trailer"]) {
                trailerKey = [NSString stringWithFormat:@"%@", [Trailers[i] objectForKey:@"key"]];
                num = i;
            } else {
            if ([tmp localizedCaseInsensitiveContainsString:@"teaser"]) {
                trailerKey = [NSString stringWithFormat:@"%@", [Trailers[i] objectForKey:@"key"]];
                num = i;
            } else {
            if ([tmp localizedCaseInsensitiveContainsString:@"theatrical"]) {
                trailerKey = [NSString stringWithFormat:@"%@", [Trailers[i] objectForKey:@"key"]];
                num = i;
            }}}}}}
        }
        if ([trailerKey isEqualToString:@""]) {
            trailerKey = [NSString stringWithFormat:@"%@", [Trailers[Trailers.count - 1] objectForKey:@"key"]];
            num = (int)Trailers.count - 1;
        }
        
        NSLog(@"TrailerID: %@ name: %@", trailerKey, [Trailers[num] objectForKey:@"name"]);
        NSDictionary *playerVars = @{
            @"controls" : @1,
            @"playsinline" : @0,
            @"showinfo" : @1,
            @"autoplay" : @1,
            @"modestbranding" : @0
        };
        
        [self.trailerView loadWithVideoId:trailerKey playerVars:playerVars];
        [self.view addSubview:self.trailerView];
        [CATransaction flush];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedPlaybackStartedNotification:)
                                                     name:@"Playback started"
                                                   object:nil];
    } else {
        NSLog(@"No trailers available");
    }
}

- (void)receivedPlaybackStartedNotification:(NSNotification *) notification {
    NSLog(@"TRAILER: %@", notification.name);
}

-(void)playerViewDidBecomeReady:(YTPlayerView *)playerView {
    [self.trailerView playVideo];
}

- (void)playerView:(YTPlayerView *)ytPlayerView didChangeToState:(YTPlayerState)state {
    NSString *message = [NSString stringWithFormat:@"%ld", (long)state];
    NSLog(@"TRAILER: %@", message);
    if (state == 5) {
        [self.trailerView playVideo];
    }
    if (state == 0 || state == 1 || state == 3) {
        NSLog(@"TRAILER: play finished");
        [self.trailerView removeWebView];
        [self.trailerView removeFromSuperview];
    }
}

- (void)startTVShow:(NSNotification*) notification
{
    NSDictionary *message = notification.userInfo;
    NSURL *url = [message valueForKey:@"url"];
    NSLog(@"currentTVShowURL: %@", url);
    [self playContent: url];
}

- (void)startContent
{
    NSIndexPath *theIndexPath = ((CCoverflowCollectionViewLayout *)self.collectionView.collectionViewLayout).currentIndexPath;
    NSString *thisContent;
    
    if (self.isFiltered) {
        if (self.context_movies) {
            thisContent = [FilteredMovieMetaDataObject[theIndexPath.item] objectForKey:@"url"];
        } else if (self.context_tvshow) {
            thisContent = [FilteredTVShowMetaDataObject[theIndexPath.item] objectForKey:@"url"];
        } else {
            [self getUrlFromEXTM3U:[fetchContentData.LiveTVData[theIndexPath.item] objectForKey:@"url"] completionHandler:^(NSURL *urlWithTicket) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self playContent: urlWithTicket];
                });
            }];
        }
    } else {
        if (self.context_movies) {
            thisContent = [fetchContentData.MovieData[theIndexPath.item] objectForKey:@"url"];
        } else if (self.context_tvshow) {
            thisContent = [fetchContentData.TVShowData[theIndexPath.item] objectForKey:@"url"];
        } else {
            [self getUrlFromEXTM3U:[fetchContentData.LiveTVData[theIndexPath.item] objectForKey:@"url"] completionHandler:^(NSURL *urlWithTicket) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self playContent: urlWithTicket];
                });
            }];
        }
    }
    NSLog(@"startContent %@", thisContent);
    [self playContent: [[NSURL alloc] initWithString:thisContent]];
}

- (void)getUrlFromEXTM3U:(NSString *)url completionHandler:(void (^)(NSURL *url))Completion {
    url = [NSMutableString stringWithFormat:@"http://%@:%@@%@:9981%@", self.tvheadend_username, self.tvheadend_password, self.mediaServer, url];
    [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:url];
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSURLSession *session = [NSURLSession sharedSession];

    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString *EXTM3U = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSArray *lines = [EXTM3U componentsSeparatedByString: @"\r\n"];
        NSURL *urlWithTicket;
        for (int i = 0; i < lines.count; i++) {
            if ([lines[i] containsString:@"ticket"]) {
                urlWithTicket = [[NSURL alloc] initWithString:lines[i]];
            }
        }
        Completion(urlWithTicket);
    }];
    [dataTask resume];
}

- (CAGradientLayer *)flavescentGradientLayer
{
    UIColor *bottomColor = [UIColor colorWithRed:0.14f green:0.5f blue:0.68f alpha:0.75f];
    UIColor *topColor = [UIColor colorWithRed:0.1f green:0.0f blue:0.1f alpha:0.45f];
    
    NSArray *gradientColors = [NSArray arrayWithObjects:(id)topColor.CGColor, (id)bottomColor.CGColor, nil];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = gradientColors;
    gradientLayer.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.6f], [NSNumber numberWithFloat:1.0f], nil];
    
    return gradientLayer;
}

-(IBAction)closeMovieMetaDataView
{
    for (UIView *subview in [self.view subviews]) {
        // Only remove the subviews with tag not equal to 1
        if (subview.tag == 69) {
            [subview removeFromSuperview];
        }
    }
    [self.view setNeedsDisplay];
}

- (void)DestroyContentMetaDataView:(NSNotification *)notif {
    for (UIView *subview in [self.view subviews]) {
        // Only remove the subviews with tag not equal to 1
        if (subview.tag == 70) {
            [subview removeFromSuperview];
        }
    }
    for (UITableView *subview in [self.view subviews]) {
        // Only remove the subviews with tag not equal to 1
        if (subview.tag == 70) {
            [subview removeFromSuperview];
        }
    }
    [self.view setNeedsDisplay];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)tapCell:(UITapGestureRecognizer *)inGestureRecognizer
{
    @try {
        if ([self.searchBar isFirstResponder]) {
            [self dismissKeyboard];
            self.isKeyboardActive = FALSE;
        } else {
            NSIndexPath *theIndexPath = ((CCoverflowCollectionViewLayout *)self.collectionView.collectionViewLayout).currentIndexPath;
            NSIndexPath *pressedIndexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)inGestureRecognizer.view];
            
            // Prevent every tile to spawn an event, just the 'middle' (focused) one.
            if (theIndexPath.row == pressedIndexPath.row) {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startContent) name:@"startMovie" object:nil];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTrailerContent) name:@"startTrailerMovie" object:nil];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTrailerContent) name:@"startTrailerTVShow" object:nil];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTVShow:) name:@"startTVShow" object:nil];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteControlKODIView) name:@"remoteControlKODIView" object:nil];
                
                if (self.isFiltered) {
                    if (self.context_movies) {
                        [MetaDataViewMovies ContentMetaDataViewMovies:self.view :self.theCell :pressedIndexPath :theIndexPath :self.FilteredMovieMetaDataObject];
                    } else if (self.context_tvshow) {
                        [MetaDataViewTVShows ContentMetaDataViewTVShows:self.view :self.theCell :pressedIndexPath :theIndexPath :self.FilteredTVShowMetaDataObject :self.mediaServer :self.ssl :self.currentTVShowURL];
                    } else {
                        [self startContent];
                    }
                } else {
                    if (self.context_movies) {
                        [MetaDataViewMovies ContentMetaDataViewMovies:self.view :self.theCell :pressedIndexPath :theIndexPath :fetchContentData.MovieData];
                    } else if (self.context_tvshow) {
                        [MetaDataViewTVShows ContentMetaDataViewTVShows:self.view :self.theCell :pressedIndexPath :theIndexPath :fetchContentData.TVShowData :self.mediaServer :self.ssl :self.currentTVShowURL];
                    } else {
                        [self startContent];
                    }
                }
                // END
            } else {
                if (labs(pressedIndexPath.row - theIndexPath.row) == 1) {
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startContent) name:@"startMovie" object:nil];
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTrailerContent) name:@"startTrailerMovie" object:nil];
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTrailerContent) name:@"startTrailerTVShow" object:nil];
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTVShow:) name:@"startTVShow" object:nil];
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteControlKODIView) name:@"remoteControlKODIView" object:nil];

                    NSIndexPath *changedRow = [NSIndexPath indexPathForRow:pressedIndexPath.row inSection:0];
                    [self.collectionView setContentOffset:CGPointMake(changedRow.row * ((CCoverflowCollectionViewLayout*)self.collectionView.collectionViewLayout).cellSpacing, 0) animated:YES];
                    [self.collectionView reloadData];
                    [self scrollViewDidScroll:self.collectionView];
                    
                    if (self.isFiltered) {
                        if (self.context_movies) {
                            [MetaDataViewMovies ContentMetaDataViewMovies:self.view :self.theCell :changedRow :changedRow :self.FilteredMovieMetaDataObject];
                        } else if (self.context_tvshow) {
                            [MetaDataViewTVShows ContentMetaDataViewTVShows:self.view :self.theCell :changedRow :changedRow :self.FilteredTVShowMetaDataObject :self.mediaServer :ssl :self.currentTVShowURL];
                        } else {
                            [self startContent];
                            
                        }
                    } else {
                        if (self.context_movies) {
                            [MetaDataViewMovies ContentMetaDataViewMovies:self.view :self.theCell :changedRow :changedRow :fetchContentData.MovieData];
                        } else if (self.context_tvshow) {
                            [MetaDataViewTVShows ContentMetaDataViewTVShows:self.view :self.theCell :changedRow :changedRow :fetchContentData.TVShowData :self.mediaServer :ssl :self.currentTVShowURL];
                        } else {
                            [self startContent];
                        }
                    }
                    // END
                }
                // Nothing happens, it means someone 'miss-tapped' the cell. (left or right)
            }
            // Register observers for KodiConfigView dismiss button
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(DestroyContentMetaDataView:) name:@"DestroyContentMetaDataView" object:nil];
        }
    }
    @catch (NSException *exception) {
        printf("error caught ");
    }
}

@end
