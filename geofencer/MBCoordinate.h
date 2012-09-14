//
//  MBCoordinate.h
//  geofencer
//
//  Created by Moshe Berman on 5/5/12.
//  Copyright (c) 2012 Moshe Berman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface MBCoordinate : NSObject

@property double latitude;
@property double longitude;
@property bool isDragging;

- (id) initWithLatitude:(double)latitude andLongitude:(double)longitude;
- (CLLocationCoordinate2D)CLLocationCoordinate2DRepresentation;

- (NSDictionary *)asDictionary;
@end
