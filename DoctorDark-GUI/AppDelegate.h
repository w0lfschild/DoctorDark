//
//  AppDelegate.h
//  zestyWin-GUI
//
//  Created by Wolfgang Baird on 1/5/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSWindow *mainWindow;
@property (weak) IBOutlet NSView *mainView;
@property (weak) IBOutlet NSButton *swaggA;

@end

