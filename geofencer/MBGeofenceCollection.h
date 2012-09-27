//
//  MBGeofenceCollection.h
//  Fence
//
//  Created by Moshe Berman on 9/15/12.
//
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

#import "MBGeofence.h"

@interface MBGeofenceCollection : NSObject

@property (strong, nonatomic) NSMutableArray *geofences;
@property (strong, nonatomic) MBGeofence *workingGeofence;

- (MBGeofence *) newFence;
- (void) addFence:(MBGeofence *)fence andMakeActive:(BOOL)newFenceShouldBecomeActive;
- (void) closeActiveFence;

- (void) deactivateActiveFence;

- (BOOL) workingFencesHasMaximumNumberOfCoordinates;
- (BOOL) workingFencesHasMinimumNumberOfCoordinates;

- (void) addPointToWorkingFence:(CLLocationCoordinate2D)point;
- (void) removePointFromWorkingFence:(CLLocationCoordinate2D)point;

- (NSInteger) numberOfFences;

- (MBGeofence *)fenceContainingPoint:(CLLocationCoordinate2D)location;

- (void) reorganizeAllFences;
- (void) reorganizeFence:(MBGeofence *)fence;

@end
