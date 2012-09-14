//
//  MBViewController.h
//  geofencer
//
//  Created by Moshe Berman on 5/5/12.
//  Copyright (c) 2012 Moshe Berman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MBGeofence.h"
#import "MBAnnotationView.h"


@interface MBViewController : UIViewController <MKMapViewDelegate, UIAlertViewDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) IBOutlet MKMapView    *mapView;
@property (strong, nonatomic) NSMutableArray *geofences;
@property (strong, nonatomic) MBGeofence *workingGeofence;

@property (strong, nonatomic) NSMutableArray *annotations;
@property (strong, nonatomic) NSMutableArray *overlays;

@property (strong, nonatomic) NSTimer *saveTimer;

@property (strong, nonatomic) UIActionSheet *actionSheet;

@property (strong, nonatomic) UIBarButtonItem *modeButton;
@property (strong, nonatomic) UIBarButtonItem *actionButton;

@end
