//
//  drdark.m
//  drdark
//
//  Created by Wolfgang Baird on 6/29/16.
//  Copyright © 2015 - 2016 Wolfgang Baird. All rights reserved.
//

@import AppKit;
#import <objc/runtime.h>

@interface drdark : NSObject
@end

drdark           *plugin;
NSDictionary     *sharedDict = nil;
static void      *dd_isActive = &dd_isActive;

@implementation drdark

/* Shared instance of this plugin so we can call it's methods elsewhere */
+ (drdark*) sharedInstance
{
    static drdark* plugin = nil;
    if (plugin == nil)
        plugin = [[drdark alloc] init];
    return plugin;
}

- (NSAppearance *)darkAppearance
{
    static NSAppearance *dark;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dark = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
    });
    return dark;
}

/* Called when the plugin first loads */
+ (void)load {
    /* Initialize an instance of our plugin */
    plugin = [drdark sharedInstance];
    
    /* Check if we're running 10.10 or above */
    NSInteger osx_ver = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    if (osx_ver > 9) {
        
        /* Initialize the preferences */
        [plugin dd_initializePrefs];
        
        /* Check if our current bundleIdentifier is blacklisted */
        if (![sharedDict objectForKey:[[NSBundle mainBundle] bundleIdentifier]])
        {
            /* Loop through all our windows and set their appearance */
            for (NSWindow *win in [[NSApplication sharedApplication] windows])
                [plugin dd_applyDarkAppearanceToWindow:win];
            
            /* Add an observer to set the appearence of all new windows we make that become a key window */
            [[NSNotificationCenter defaultCenter] addObserver:plugin
                                                     selector:@selector(dd_WindowDidBecomeKey:)
                                                         name:NSWindowDidBecomeKeyNotification
                                                       object:nil];
            
            /* Notify that we've loading in logs */
            NSLog(@"OS X 10.%ld, Dr. Dark loaded...", (long)osx_ver);
        }
    }
}

/* Recieved a notification saying a window became the key window */
- (void)dd_WindowDidBecomeKey:(NSNotification *)notification {
    /* Call dd_setNSAppearance assuming the notification object is a NSWindow */
    [plugin dd_applyDarkAppearanceToWindow:[notification object]];
}

/* Set a windows appearance */
- (void)dd_applyDarkAppearanceToWindow:(NSWindow *)window
{
    if (![objc_getAssociatedObject(window, dd_isActive) boolValue])
    {
        /* Set the appearence to NSAppearanceNameVibrantDark */
        [window setAppearance:[plugin darkAppearance]];
        [plugin dd_updateDarkModeStateForTreeStartingAtView:window.contentView];
        
        /* Store a value in the window saying we've already set it's appearance */
        objc_setAssociatedObject(window, dd_isActive, [NSNumber numberWithBool:true], OBJC_ASSOCIATION_RETAIN);
    }
}

/* Update all subviews */
- (void)dd_updateDarkModeStateForTreeStartingAtView:(__kindof NSView *)rootView
{
    for (NSView *view in rootView.subviews) {
        view.appearance = [plugin darkAppearance];
        
        if ([view isKindOfClass:[NSVisualEffectView class]]) {
            [(NSVisualEffectView *)view setMaterial:NSVisualEffectMaterialDark];
        }
        
        if ([view isKindOfClass:[NSClipView class]] ||
            [view isKindOfClass:[NSScrollView class]] ||
            [view isKindOfClass:[NSMatrix class]] ||
            [view isKindOfClass:[NSTextView class]] ||
            [view isKindOfClass:NSClassFromString(@"TBrowserTableView")] ||
            [view isKindOfClass:NSClassFromString(@"TIconView")]) {
            [view performSelector:@selector(setBackgroundColor:) withObject:[NSColor colorWithCalibratedWhite:0.1 alpha:1.0]];
        }
        
        if (view.subviews.count > 0) [self dd_updateDarkModeStateForTreeStartingAtView:view];
    }
    
    //    [rootView.window displayIfNeeded];
}

/* Load and setup our bundles preferences */
-(void)dd_initializePrefs {
    /* Load existing preferences for our bundle */
    NSUserDefaults *sharedPrefs = [[NSUserDefaults alloc] initWithSuiteName:@"org.w0lf.drdark"];
    sharedDict = [sharedPrefs dictionaryRepresentation];
    
    /* Hardcoded blacklisted applications */
    NSArray *blacklist = @[ @"com.apple.iTunes",
                            @"com.apple.Terminal",
                            @"com.sublimetext.2",
                            @"com.sublimetext.3",
                            @"com.apple.dt.Xcode",
                            @"com.apple.notificationcenterui",
                            @"com.google.Chrome.canary",
                            @"com.google.Chrome",
                            @"com.jriver.MediaCenter21",
                            @"com.teamspeak.TeamSpeak3",
                            @"com.apple.systemuiserver",
                            @"com.cocoatech.PathFinder",
                            @"com.apple.ActivityMonitor",
                            @"com.github.GitHub" ];
    
    /* Loop through blacklist and add all items to preferences if they don't already exist */
    for (id item in blacklist)
        if ([sharedPrefs objectForKey:item] == nil)
            [sharedPrefs setInteger:0 forKey:item];
    
    /* Syncronize preferences */
    sharedDict = [sharedPrefs dictionaryRepresentation];
    [sharedPrefs synchronize];
}

@end
