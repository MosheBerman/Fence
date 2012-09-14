//
//  MBAppDelegate.h
//  geofencer
//
//  Created by Moshe Berman on 5/5/12.
//  Copyright (c) 2012 Moshe Berman. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MBViewController;

@interface MBAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) MBViewController *viewController;

@end
