//
//  AppDelegate.m
//  zestyWin-GUI
//
//  Created by Wolfgang Baird on 1/5/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

#import "AppDelegate.h"

NSUserDefaults *sharedPrefs;
NSDictionary *sharedDict;

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    [self.window setTitle:@"Dark Mode Blacklister"];
    
    //
    [self getAPPList];
    [self setScrollView];
    
    // display the window
    [_mainWindow makeKeyAndOrderFront:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)setScrollView {
    // create the scroll view so that it fills the entire window
    // to do that we'll grab the frame of the window's contentView
    // theWindow is an outlet connected to a window instance in Interface Builder
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:
                                [[_mainWindow contentView] frame]];
    
    // the scroll view should have both horizontal
    // and vertical scrollers
    [scrollView setHasVerticalScroller:YES];
    //    [scrollView setHasHorizontalScroller:YES];
    
    // configure the scroller to have no visible border
    [scrollView setBorderType:NSNoBorder];
    
    // set the autoresizing mask so that the scroll view will
    // resize with the window
    [scrollView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    
    // set theImageView as the documentView of the scroll view
    [scrollView setDocumentView:_mainView];
    
    // scroll to the top
    [scrollView.contentView scrollToPoint:NSMakePoint(0, ((NSView*)scrollView.documentView).frame.size.height - scrollView.contentSize.height)];
    
    // set the scrollView as the window's contentView
    // this replaces the existing contentView and retains
    // the scrollView, so we can release it now
//    [_mainWindow setContentView:scrollView];
    [[_mainWindow contentView] addSubview:scrollView];
}

- (void)readFolder:(NSString *)str :(NSMutableDictionary *)dict {
    NSArray *appFolderContents = [[NSArray alloc] init];
    appFolderContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:str error:nil];
    for (NSString *app in appFolderContents) {
        if ([app containsString:@".app"])
        {
            NSString *appName = [[app lastPathComponent] stringByDeletingPathExtension];
            NSString *appPath = [NSString stringWithFormat:@"%@/%@", str, app];
            NSString *appBundle = [[NSBundle bundleWithPath:appPath] bundleIdentifier];
//            NSLog(@"%@ -- %@", appPath, appBundle);
            NSArray *jumboTron = [NSArray arrayWithObjects:appName, appPath, appBundle, nil];
            [dict setObject:jumboTron forKey:appName];
        }
    }
}

- (void)getAPPList {
    NSMutableDictionary *myDict = [[NSMutableDictionary alloc] init];
    
    [self readFolder:@"/Applications" :myDict];
    [self readFolder:@"/Applications/Utilities" :myDict];
    [self readFolder:@"/System/Library/CoreServices" :myDict];
    [self readFolder:[NSString stringWithFormat:@"%@/Applications", NSHomeDirectory()] :myDict];
    
    NSArray *keys = [myDict allKeys];
    NSArray *sortedKeys = [keys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    sortedKeys = [[sortedKeys reverseObjectEnumerator] allObjects];
    
    sharedPrefs = [[NSUserDefaults alloc] initWithSuiteName:@"org.w0lf.darkmode"];
    sharedDict = [sharedPrefs dictionaryRepresentation];
    
    CGRect frame = _mainView.frame;
    frame.size.height = 0;
    int count = 0;
    for (NSString *app in sortedKeys)
    {
        NSArray *myApp = [myDict valueForKey:app];
        if ([myApp count] == 3)
        {
            CGRect buttonFrame = CGRectMake(10, (25 * count), 150, 22);
            NSButton *newButton = [[NSButton alloc] initWithFrame:buttonFrame];
            [newButton setButtonType:NSSwitchButton];
            [newButton setTitle:[myApp objectAtIndex:0]];
            [newButton sizeToFit];
            [newButton setAction:@selector(toggleItem:)];
            if ([sharedDict valueForKey:[myApp objectAtIndex:2]] == [NSNumber numberWithUnsignedInteger:0]) {
                //                NSLog(@"\n\nApplication: %@\nBundle ID: %@\n\n", app, bundleString);
                [newButton setState:NSOnState];
            } else {
                [newButton setState:NSOffState];
            }
            [_mainView addSubview:newButton];
            count += 1;
            frame.size.height += 25;
        }
    }
    [_mainView setFrame:frame];
    
    NSLog(@"%@", myDict);
}

- (IBAction)toggleItem:(NSButton*)btn {
    if ([sharedPrefs isEqual:nil])
    {
        sharedPrefs = [[NSUserDefaults alloc] initWithSuiteName:@"org.w0lf.darkmode"];
        sharedDict = [sharedPrefs dictionaryRepresentation];
    }
    
    NSArray *pathS = [NSArray arrayWithObjects:@"/Applications", @"/Applications/Utilities", @"/System/Library/CoreServices", [NSString stringWithFormat:@"%@/Applications", NSHomeDirectory()], nil];
    for (NSString *items in pathS)
    {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@.app", items, btn.title];
//        NSLog(@"%@", fullPath);
        if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath])
        {
            NSBundle *bundle = [NSBundle bundleWithPath:fullPath];
            NSString *bundleString = [bundle bundleIdentifier];
            
            NSLog(@"%@ -- %@", fullPath, bundleString);
            
            if (btn.state == NSOnState)
            {
                // Add application to blacklist if it doesn't already exist
                NSLog(@"Adding key: %@", bundleString);
                [sharedPrefs setInteger:0 forKey:bundleString];
            } else {
                NSLog(@"Deleting key: %@", bundleString);
                [sharedPrefs setInteger:1 forKey:bundleString];
            }
            
            [sharedPrefs synchronize];
            break;
        }
    }
}

@end
