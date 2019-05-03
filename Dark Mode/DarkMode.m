//
//  darkmode.m
//  darkmode
//
//  Created by Wolfgang Baird on 6/29/16.
//  Copyright © 2015 - 2016 Wolfgang Baird. All rights reserved.
//

@import AppKit;

#import "ZKSwizzle.h"
#import <objc/runtime.h>

//blacklist and whitelist
#define APP_BLACKLIST @[@"com.apple.loginwindow", @"com.apple.iTunes", @"com.apple.Terminal",\
                        @"com.sublimetext.2", @"com.sublimetext.3", @"com.googlecode.iterm2",\
                        @"com.google.Chrome.canary", @"com.google.Chrome", @"com.jriver.MediaCenter21",\
                        @"com.teamspeak.TeamSpeak3", @"org.mozilla.firefox", @"com.bombich.ccc*",\
                        @"org.winehq.wine-stable.wine", @"org.winehq.wine-devel.wine", @"org.winehq.wine-staging.wine",\
                        @"com.urgesoftware.wineskin.wineskin", @"org.kronenberg.WineBottler", @"com.cocoatech.PathFinder",\
                        @"com.github.GitHub", @"com.apple.ActivityMonitor"]

#define APP_WHITELIST @[@"com.apple.finder", @"com.apple.systempreferences", @"com.apple.iChat", @"com.urgesoftware.wineskin.wineskinwinery"]

#define CLS_BLACKLIST @[@"NSStatusBarWindow", @"BookmarkBarFolderWindow", @"TShrinkToFitWindow",\
                        @"QLFullscreenWindow", @"QLPreviewPanel", @"TDesktopWindow",\
                        @"TDesktopIcon", @"TDesktopTitleBubbleView", @"TIconSelectionView",\
                        @"TNewIconView", @"TBasicImageView", @"TDesktopIconSelectionView",\
                        @"TDesktopIconView"]

@interface darkmode : NSObject
@end

darkmode          *plugin;
BOOL            resizing;
BOOL            useWhitelist;
NSMutableArray  *itemBlacklist;
NSMutableArray  *itemWhitelist;
NSDictionary    *sharedDict = nil;
static void     *dd_isActive = &dd_isActive;
SEL             setTFC;

@implementation darkmode

/* Shared instance of this plugin so we can call it's methods elsewhere */
+ (darkmode*) sharedInstance {
    static darkmode* plugin = nil;
    if (plugin == nil)
        plugin = [[darkmode alloc] init];
    return plugin;
}

- (NSAppearance *)darkAppearance {
    static NSAppearance *dark;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ dark = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]; });
    return dark;
}

/* Called when the plugin first loads */
+ (void)load {
    /* Initialize an instance of our plugin */
    plugin = [darkmode sharedInstance];
    NSInteger osx_ver = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    setTFC = NSSelectorFromString(@"setTitleFontColor:");
    if (osx_ver >= 9) {
        /* Check if our current bundleIdentifier is blacklisted */
        [plugin dd_initializePrefs];
        
        if ([plugin shouldApply:@""]) {
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
    }
    if (osx_ver <= 13) {
        /* Check if our current bundleIdentifier is blacklisted */
        [plugin dd_initializePrefs];
        
        if ([plugin shouldApply:@""]) {
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
    }
    else {
        NSLog(@"winBuddy is blocked in this application because of your version of macOS is too old or new");
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
        
//        if ([view isKindOfClass:NSClassFromString(@"TStatusBarStackView")]) {
//
//        }
        
        if ([view respondsToSelector:setTFC]) {
            [view performSelector:setTFC withObject:[NSColor whiteColor]];
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
    itemWhitelist = [[NSMutableArray alloc] init];
    itemBlacklist = [[NSMutableArray alloc] init];
    useWhitelist = true;
    
    [itemBlacklist addObjectsFromArray:APP_BLACKLIST];
    
    NSMutableDictionary *pluginPrefs = [NSMutableDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/org.w0lf.darkmode.plist"]];
    NSArray *addItems;
    addItems = [pluginPrefs objectForKey:@"bundleWhitelist"];
    [itemWhitelist addObjectsFromArray:addItems];
    [itemWhitelist addObjectsFromArray:APP_WHITELIST];
    addItems = [pluginPrefs objectForKey:@"bundleBlacklist"];
    [itemBlacklist addObjectsFromArray:addItems];
    [itemBlacklist addObjectsFromArray:APP_BLACKLIST];
    useWhitelist = ![[pluginPrefs objectForKey:@"useBlacklist"] boolValue];
    
    /* Loop through blacklist and add all items to preferences if they don't already exist */
//    NSLog(@"wb_ %@", pluginPrefs);
//    NSLog(@"wb_ %@", itemWhitelist);
//    NSLog(@"wb_ %@", itemBlacklist);
}

-(BOOL)shouldApply:(NSString*) class {
    if (useWhitelist)
        if (![itemWhitelist containsObject:[[NSBundle mainBundle] bundleIdentifier]])
            return false;
    if ([itemBlacklist containsObject:class])
        return false;
    if ([APP_BLACKLIST containsObject:[[NSBundle mainBundle] bundleIdentifier]])
        return false;
    if ([CLS_BLACKLIST indexOfObject:class] != NSNotFound)
        return false;
    return true;
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
    ZKOrig(void, arg1);
    if (!resizing) {
        if ([plugin shouldApply:[self className]]) {
            NSLog(@"wbdd - tview - %@ - %@", self.className, NSStringFromSelector(_cmd));
            
            Boolean apply = true;
            for (NSString *cls in CLS_BLACKLIST) {
                if ([self isKindOfClass:NSClassFromString(cls)]) {
                    apply = false;
                    break;
                }
            }
            
            if ([self isKindOfClass:NSClassFromString(@"TNewIconView")]) {
                [self performSelector:setTFC withObject:[NSColor whiteColor]];
            }
            
            if (apply) {
                [self performSelector:@selector(setBackgroundColor:) withObject:[NSColor colorWithCalibratedWhite:0.1 alpha:1.0]];
                [plugin dd_updateDarkModeStateForTreeStartingAtView:self];
            }
        }
    }
}

@end

ZKSwizzleInterface(wbdd_TBrowserTableView, TBrowserTableView, NSTableView)
@implementation wbdd_TBrowserTableView

- (void)reloadData {
    NSLog(@"wbdd - TBrowserTableView - %@ - %@", self.className, NSStringFromSelector(_cmd));
    ZKOrig(void);
    if ([plugin shouldApply:[self className]]) {
        [self performSelector:@selector(setBackgroundColor:) withObject:[NSColor colorWithCalibratedWhite:0.1 alpha:1.0]];
    }
}

@end

ZKSwizzleInterface(wbdd_NSView, NSView, NSObject)
@implementation wbdd_NSView

- (void)setFrameSize:(struct CGSize)arg1 {
    ZKOrig(void, arg1);
    if (!resizing) {
        if ([plugin shouldApply:[self className]]) {
            NSLog(@"wbdd - nsview - %@", self.className);
            Boolean apply = true;
            for (NSString *cls in CLS_BLACKLIST) {
                if ([self isKindOfClass:NSClassFromString(cls)]) {
                    apply = false;
                    break;
                }
            }
            
            if ([self isKindOfClass:NSClassFromString(@"TNewIconView")]) {
                [self performSelector:setTFC withObject:[NSColor whiteColor]];
            }
            
            if (apply) {
                [plugin dd_updateDarkModeStateForTreeStartingAtView:(NSView*)self];
            }
        }
    }
}

@end

ZKSwizzleInterface(wbdd_NSWindow, NSWindow, NSObject)
@implementation wbdd_NSWindow

- (BOOL)_inLiveResize {
    resizing = ZKOrig(BOOL);
    return ZKOrig(BOOL);
}

@end
