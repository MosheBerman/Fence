//
//  
//  geofencer
//
//  Created by Moshe Berman on 5/5/12.
//  Copyright (c) 2012 Moshe Berman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "MBCoordinate.h"

@interface MBGeofence : NSObject

@property (nonatomic, strong) NSMutableArray *points;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, readonly, strong) NSDate *creationDate;
@property (nonatomic, strong) NSDate *modifiedDate;

- (id) initWithName:(NSString*)name;

- (void) addLocation:(CLLocationCoordinate2D)location;
- (void) removeLocation:(CLLocationCoordinate2D)location;

- (MKPolygon*) polygonRepresentation;
- (BOOL) matchesPolygon:(MKPolygon *)polygon;

//
//  Export methods
//

- (NSArray *)asArray;
- (NSDictionary*) asDictionary;


- (void) removeAllObjects;

@end
