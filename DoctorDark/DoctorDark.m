//
//  drdark.m
//  drdark
//
//  Created by Wolfgang Baird on 6/29/16.
//  Copyright © 2015 - 2016 Wolfgang Baird. All rights reserved.
//

@import AppKit;

#import "ZKSwizzle.h"
#import <objc/runtime.h>

#define APP_BLACKLIST @[@"com.apple.loginwindow", @"com.apple.iTunes", @"com.apple.Terminal",\
                        @"com.sublimetext.2", @"com.sublimetext.3", @"com.googlecode.iterm2",\
                        @"com.google.Chrome.canary", @"com.google.Chrome", @"com.jriver.MediaCenter21",\
                        @"com.teamspeak.TeamSpeak3", @"com.cocoatech.PathFinder", @"com.apple.ActivityMonitor",\
                        @"com.github.GitHub"]

#define CLS_BLACKLIST @[@"NSStatusBarWindow", @"BookmarkBarFolderWindow", @"TShrinkToFitWindow", @"QLFullscreenWindow", @"QLPreviewPanel"]

@interface drdark : NSObject
@end

drdark           *plugin;
NSMutableArray   *itemBlacklist;
NSDictionary     *sharedDict = nil;
static void      *dd_isActive = &dd_isActive;

@implementation drdark

/* Shared instance of this plugin so we can call it's methods elsewhere */
+ (drdark*) sharedInstance {
    static drdark* plugin = nil;
    if (plugin == nil)
        plugin = [[drdark alloc] init];
    return plugin;
}

- (NSAppearance *)darkAppearance {
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
    NSInteger osx_ver = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    if (osx_ver >= 9) {
        /* Check if our current bundleIdentifier is blacklisted */
        [plugin dd_initializePrefs];
        if (![itemBlacklist containsObject:[[NSBundle mainBundle] bundleIdentifier]]) {
            /* Loop through all our windows and set their appearance */
            for (NSWindow *win in [[NSApplication sharedApplication] windows])
                [plugin dd_applyDarkAppearanceToWindow:win];
            
            /* Add an observer to set the appearence of all new windows we make that become a key window */
            [[NSNotificationCenter defaultCenter] addObserver:plugin
                                                     selector:@selector(dd_WindowDidBecomeKey:)
                                                         name:NSWindowDidBecomeKeyNotification
                                                       object:nil];
            
            NSLog(@"%@ loaded into %@ on macOS 10.%ld", [self class], [[NSBundle mainBundle] bundleIdentifier], (long)osx_ver);
        } else {
            NSLog(@"winBuddy is blocked in this application because of issues");
        }
    } else {
        NSLog(@"winBuddy is blocked in this application because of your version of macOS is too old");
    }
}

/* Recieved a notification saying a window became the key window */
- (void)dd_WindowDidBecomeKey:(NSNotification *)notification {
    /* Call dd_setNSAppearance assuming the notification object is a NSWindow */
    [plugin dd_applyDarkAppearanceToWindow:[notification object]];
}

/* Set a windows appearance */
- (void)dd_applyDarkAppearanceToWindow:(NSWindow *)window {
    if ([self shouldApply:[window className]]) {
        if (![objc_getAssociatedObject(window, dd_isActive) boolValue]) {
            /* Set the appearence to NSAppearanceNameVibrantDark */
            [window setAppearance:[plugin darkAppearance]];
            [plugin dd_updateDarkModeStateForTreeStartingAtView:window.contentView];
            
            /* Store a value in the window saying we've already set it's appearance */
            objc_setAssociatedObject(window, dd_isActive, [NSNumber numberWithBool:true], OBJC_ASSOCIATION_RETAIN);
        }
    }
}

/* Update all subviews */
- (void)dd_updateDarkModeStateForTreeStartingAtView:(__kindof NSView *)rootView {
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
        
        if ([view isKindOfClass:NSClassFromString(@"TStatusBarStackView")]) {
            
        }
        
        if ([view respondsToSelector:@selector(setTitleFontColor:)]) {
            [view performSelector:@selector(setTitleFontColor:) withObject:[NSColor whiteColor]];
        }
        
        if ([view respondsToSelector:@selector(setTextColor:)]) {
            [(NSTextView*)view setTextColor:[NSColor whiteColor]];
            [view display];
        }
        
        if (view.subviews.count > 0) [self dd_updateDarkModeStateForTreeStartingAtView:view];
    }
    
    //    [rootView.window displayIfNeeded];
}

/* Load and setup our bundles preferences */
-(void)dd_initializePrefs {
    /* Load existing preferences for our bundle */
    itemBlacklist = [[NSMutableArray alloc] initWithArray:APP_BLACKLIST];
    
    NSUserDefaults *sharedPrefs = [[NSUserDefaults alloc] initWithSuiteName:@"org.w0lf.drdark"];
    sharedDict = [sharedPrefs dictionaryRepresentation];
    
    /* Loop through blacklist and add all items to preferences if they don't already exist */
    
    /* Syncronize preferences */
    sharedDict = [sharedPrefs dictionaryRepresentation];
    [sharedPrefs synchronize];
}

-(BOOL)shouldApply:(NSString*) class {
    BOOL result = true;
    if ([itemBlacklist containsObject:class])
        result = false;
    if ([APP_BLACKLIST containsObject:[[NSBundle mainBundle] bundleIdentifier]])
        result = false;
    return result;
}

@end

ZKSwizzleInterface(wbdd_NSCell, NSCell, NSObject)
@implementation wbdd_NSCell

- (void)drawWithFrame:(struct CGRect)arg1 inView:(id)arg2 {
    ZKOrig(void, arg1, arg2);
//    NSLog(@"wbdd - nscell - %@", self.className);
}

@end

ZKSwizzleInterface(wbdd_TView, TView, NSView)
@implementation wbdd_TView

- (void)setFrameSize:(struct CGSize)arg1 {
//    NSLog(@"wbdd - tview - %@", self.className);
    ZKOrig(void, arg1);
    if ([plugin shouldApply:[self className]]) {
        Boolean apply = true;
        NSArray *bl = @[@"TDesktopIcon", @"TDesktopTitleBubbleView", @"TIconSelectionView", @"TNewIconView"];
        for (NSString *cls in bl) {
            if ([self isKindOfClass:NSClassFromString(cls)]) {
                apply = false;
                break;
            }
        }
        
        if ([self isKindOfClass:NSClassFromString(@"TNewIconView")]) {
            [self performSelector:@selector(setTitleFontColor:) withObject:[NSColor whiteColor]];
        }
        
        if (apply) {
            [self performSelector:@selector(setBackgroundColor:) withObject:[NSColor colorWithCalibratedWhite:0.1 alpha:1.0]];
            [plugin dd_updateDarkModeStateForTreeStartingAtView:self];
        }
    }
}

@end

ZKSwizzleInterface(wbdd_TBrowserTableView, TBrowserTableView, NSTableView)
@implementation wbdd_TBrowserTableView

- (void)reloadData {
//    NSLog(@"wbdd - tbrowsertableview - %@", self.className);
    ZKOrig(void);
    if ([plugin shouldApply:[self className]]) {
        [self performSelector:@selector(setBackgroundColor:) withObject:[NSColor colorWithCalibratedWhite:0.1 alpha:1.0]];
    }
}

@end

ZKSwizzleInterface(wbdd_NSView, NSView, NSObject)
@implementation wbdd_NSView

- (void)setFrameSize:(struct CGSize)arg1 {
//    NSLog(@"wbdd - nsview - %@", self.className);
    ZKOrig(void, arg1);
    if ([plugin shouldApply:[self className]]) {
        Boolean apply = true;
        NSArray *bl = @[@"TDesktopIcon", @"TDesktopTitleBubbleView", @"TIconSelectionView", @"TNewIconView"];
        for (NSString *cls in bl) {
            if ([self isKindOfClass:NSClassFromString(cls)]) {
                apply = false;
                break;
            }
        }
        
        if ([self isKindOfClass:NSClassFromString(@"TNewIconView")]) {
            [self performSelector:@selector(setTitleFontColor:) withObject:[NSColor whiteColor]];
        }
        
        if (apply) {
            [plugin dd_updateDarkModeStateForTreeStartingAtView:(NSView*)self];
        }
    }
}

@end
