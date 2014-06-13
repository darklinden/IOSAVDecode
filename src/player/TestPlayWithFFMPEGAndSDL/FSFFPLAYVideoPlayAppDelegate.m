//
//  FSVideoPlayAppDelegate.m
//  TestPlayWithFFMPEGAndSDL
//
//  Created by  on 12-12-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "FSFFPLAYVideoPlayAppDelegate.h"

//#import "FSVideoPlayViewController.h"
#import "FSFFPLAYViewController.h"

@implementation FSFFPLAYVideoPlayAppDelegate

@synthesize window = _window;
//@synthesize viewController = _viewController;
@synthesize fsFFPLAYViewController;
- (void)dealloc
{
    [_window release];
//    [_viewController release];
    [fsFFPLAYViewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
//    self.viewController = [[[FSVideoPlayViewController alloc] initWithNibName:@"FSVideoPlayViewController" bundle:nil] autorelease];
    self.fsFFPLAYViewController = [[[FSFFPLAYViewController alloc] initWithNibName:@"FSFFPLAYViewController" bundle:nil] autorelease];
//    self.window.rootViewController = self.viewController;
    self.window.rootViewController = self.fsFFPLAYViewController;

    [self.window makeKeyAndVisible];
    return YES;
}

@end
