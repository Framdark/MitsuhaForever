#import "Tweak.h"
#import <MediaRemote/MediaRemote.h>
#import <notify.h>

bool moveIntoPanel = false;
static MSHFConfig *mshConfig;

%group MitsuhaVisuals

%hook SBMediaController

-(void)setNowPlayingInfo:(id)arg1 {
    %orig;
    MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef information) {
        NSDictionary *dict = (__bridge NSDictionary *)information;

        if (dict && dict[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtworkData]) {
            [mshConfig colorizeView:[UIImage imageWithData:[dict objectForKey:(__bridge NSString*)kMRMediaRemoteNowPlayingInfoArtworkData]]];
        }
    });
}

%end

%hook SBHomeScreenView

%property (nonatomic, strong) MSHFView *mshfView;

-(void)willMoveToSuperview:(UIView*)newSuperview {
    %orig;
    mshConfig.waveOffsetOffset = self.bounds.size.height - 200;

    if (![mshConfig view]) [mshConfig initializeViewWithFrame:self.frame];
    self.mshfView = [mshConfig view];
    [self addSubview:self.mshfView];
    [self sendSubviewToBack:self.mshfView];
    [self.mshfView start];
}

-(void)didMoveToWindow {
    %orig;
    [[mshConfig view] start];
}

-(void)didMoveToSuperview {
    %orig;
    
    if (!self.superview) {
        [[mshConfig view] stop];
    } else {
        [[mshConfig view] start];
    }
}

-(void)viewDidDisappear:(BOOL)animated{
    %orig;
    
}

%end

%end

static void screenDisplayStatus(CFNotificationCenterRef center, void* o, CFStringRef name, const void* object, CFDictionaryRef userInfo) {
    uint64_t state;
    int token;
    notify_register_check("com.apple.iokit.hid.displayStatus", &token);
    notify_get_state(token, &state);
    notify_cancel(token);
    if ([mshConfig view]) {
        if (state) {
            [[mshConfig view] start];
        } else {
            [[mshConfig view] stop];
        }
    }
}

%ctor{
    mshConfig = [MSHFConfig loadConfigForApplication:@"HomeScreen"];
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)screenDisplayStatus, (CFStringRef)@"com.apple.iokit.hid.displayStatus", NULL, (CFNotificationSuspensionBehavior)kNilOptions);
    %init(MitsuhaVisuals);
}
