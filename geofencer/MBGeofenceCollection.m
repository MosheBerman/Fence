//
//  MBGeofenceCollection.m
//  Fence
//
//  Created by Moshe Berman on 9/15/12.
//
//

#import "MBGeofenceCollection.h"

@implementation MBGeofenceCollection

- (id) init{
    self = [super init];
    
    if (self) {
        _geofences = [@[] mutableCopy];
    }
    
    return self;
}


#pragma mark - Add and Remove fences

- (MBGeofence *) newFence{
    return [self newFenceWithName:@"New Fence"];
}

- (MBGeofence *) newFenceWithName:(NSString *)name{
    MBGeofence *fence = [[MBGeofence alloc] initWithName:name];
    [self addFence:fence andMakeActive:YES];
    return fence;
}

- (void)setActiveFenceWithIndex:(NSInteger)index{
    if (self.geofences.count > index && index >= 0) {
        MBGeofence *fence = [self geofences][index];
        [self setWorkingGeofence:fence];
    }
}

- (void)deleteFenceAtIndex:(NSInteger)index{    
    if([[self geofences] count] > 0 && [[self geofences] count] > index){
        [[self geofences] removeObjectAtIndex:index];
    }
}

- (void) addFence:(MBGeofence *)fence andMakeActive:(BOOL)newFenceShouldBecomeActive{
    [[self geofences] addObject:fence];
    
    if (newFenceShouldBecomeActive) {
        [self setWorkingGeofence:fence];
    }
}

- (void) deleteActiveFence{
    [[self geofences] removeObject:self.workingGeofence];
    [[self workingGeofence] removeAllObjects];
    [self setWorkingGeofence:nil];
}


#pragma mark - Active Fence

- (void)deactivateActiveFence{
    [self setWorkingGeofence:nil];
}

#pragma mark - Bounds Checking

- (BOOL)workingFencesHasMaximumNumberOfCoordinates{
    return [[[self workingGeofence] points] count] >= 20;
}

- (BOOL) workingFencesHasMinimumNumberOfCoordinates{
    return [[[self workingGeofence] points] count] == 3;
}

#pragma mark - Fence Manipulation

- (void) addPointToWorkingFence:(CLLocationCoordinate2D)point{
    [[self workingGeofence] addLocation:point];
    [[self workingGeofence] reorganizeByDistance];
}

- (void) removePointFromWorkingFence:(CLLocationCoordinate2D)point{
    
    if ([self workingFencesHasMinimumNumberOfCoordinates]) {
        return;
    }
    
    [[self workingGeofence] removeLocation:point];
    [[self workingGeofence] reorganizeByDistance];
}

#pragma mark - Fence Count

- (NSInteger) numberOfFences{
    return [[self geofences] count];
}

#pragma mark - Geofence Containment Checking


//
//  This function is taken from StackOverflow:
//
//  http://stackoverflow.com/questions/217578/point-in-polygon-aka-hit-test
//
//  It's based upon this:
//
//  http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html
//


int pnpoly(int nvert, double *vertx, double *verty, double testx, double testy)
{
    int i, j, c = 0;
    for (i = 0, j = nvert-1; i < nvert; j = i++) {
        if ( ((verty[i]>testy) != (verty[j]>testy)) &&
            (testx < (vertx[j]-vertx[i]) * (testy-verty[i]) / (verty[j]-verty[i]) + vertx[i]) )
            c = !c;
    }
    return c;
}

//
//  Returns the fence containing a given location
//

- (MBGeofence *)fenceContainingPoint:(CLLocationCoordinate2D)location{
    
    MBGeofence *f = nil;
    
    for (MBGeofence *fence in self.geofences) {
        
        const int count = fence.polygonRepresentation.pointCount;
        
        double vertx[count];
        double verty[count];
        
        for (int i=0; i<count; i++) {
            
            CLLocationCoordinate2D coord = [(fence.points)[i] CLLocationCoordinate2DRepresentation];
            
            vertx[i] = coord.latitude;
            verty[i] = coord.longitude;
            
        }
        
        int result = pnpoly(count, vertx, verty, location.latitude, location.longitude);
        
        if (result == 1) {
            f = fence;
        }
    }
    
    //    NSLog(@"Result is:%@", [f.name description]);
    
    return f;
}

@end
