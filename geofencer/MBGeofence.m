//
//  MBGeofence.m
//  geofencer
//
//  Created by Moshe Berman on 5/5/12.
//  Copyright (c) 2012 Moshe Berman. All rights reserved.
//

#import "MBGeofence.h"

@implementation MBGeofence

- (id)init{
    self = [super init];
    
    if (self) {
        _creationDate = [NSDate date];        
        _name = [@"Unnamed Fence" mutableCopy];
        _points = [@[] mutableCopy];
        _modifiedDate = [NSDate date];
    }
    
    return self;
}

- (id) initWithName:(NSString*)name{
    self = [self init];
    
    if (self) {
        _name = name;
    }
    
    return self;
}

- (void) addLocation:(CLLocationCoordinate2D)location{
    MBCoordinate *coordinate = [[MBCoordinate alloc] initWithLatitude:location.latitude andLongitude:location.longitude];
    [self insertCoordinateBetweenClosestNeighbors:coordinate];
    [self touch];
}

- (void) removeLocation:(CLLocationCoordinate2D)location{
    
    MBCoordinate *coordinate = [[MBCoordinate alloc] initWithLatitude:location.latitude andLongitude:location.longitude];
    
    NSMutableArray *discardedCoordinates = [[NSMutableArray alloc] init];
    
    for (MBCoordinate *storedCoordinate in [self points]) {
        if ([storedCoordinate isEqual:coordinate]) {
            [discardedCoordinates addObject:storedCoordinate];
        }
    }
    
    [[self points] removeObjectsInArray:discardedCoordinates];
    [self touch];
}

- (void) removeAllObjects{
    
    [[self points] removeAllObjects];
    [self touch];
}

#pragma mark - Polygon Methods

- (MKPolygon*) polygonRepresentation{
    
    const int numberOfPoints = self.points.count;
    
    CLLocationCoordinate2D locations[numberOfPoints];
    
    for (NSInteger i = 0; i<numberOfPoints; i++) {
        locations[i] = [(self.points)[i] CLLocationCoordinate2DRepresentation];
    }
    
    MKPolygon *polygon = [MKPolygon polygonWithCoordinates:locations count:numberOfPoints];
    //    [polygon setTitle:[NSString stringWithFormat:@"Fence %i",self.tag]];
    
    //    NSLog(@"Polygon representation: %@", [polygon description]);
    return polygon;
}


- (BOOL) matchesPolygon:(MKPolygon *)polygon{
    if([[self polygonRepresentation] pointCount] != [polygon pointCount]){
        return NO;
    }
    
    for (int i=0; i<self.polygonRepresentation.pointCount; i++) {
        if([[self polygonRepresentation] points][i].x != [polygon points][i].x || [[self polygonRepresentation] points][i].y != [polygon points][i].y){
            return  NO;
        }
    }
    
    return YES;
}
#pragma mark - Serialization Methods

//
//  Override the default description method
//

- (NSString *)description{
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    for (MBCoordinate *coord in self.points) {
        [temp addObject:[coord description]];
    }
    return [temp description];
}

//
//  Pull out each point as a Dictionary and add it to an array.
//
//  We do this because MBGeofences are made of MBCoordinates.
//  MBCoordinates contain location and other app data. (Specifically,
//  MBCoordinates also track if a given coordinate is dragging, so we
//  can adjust it when it's finished dragging. Naturally, we don't
//  need this data in the exported dataset, so we don't use it.)
//

- (NSArray *)asArray{
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    for (NSInteger i=0; i <self.points.count;i++) {
        MBCoordinate *coord = [self points][i];
        [temp addObject:[coord asDictionary]];
    }
    return temp;
}

//
//  Return the geofence as a dictionary containing
//  the name of fence and its coordinates.
//

- (NSDictionary*) asDictionary{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    dictionary[@"coordinates"] = @[[[self asArray] mutableCopy]];
    dictionary[@"type"] = @"MultiPolygon";
    return dictionary;
    
}

//
//  Returns a dictionary, where the
//  first and last point match as per
//  the GeoJSON spec via Apple.
//

- (NSDictionary *) asGeoJSON{
    NSDictionary *geoJSON = [self asDictionary];
    
    //Add that first point to the proper array
    MBCoordinate *coordinate = [[geoJSON[@"coordinates"][0] lastObject] copy];
    [geoJSON[@"coordinates"][0] insertObject:coordinate atIndex:0];
    
    return geoJSON;
}

//
//  Detect which coordinate is the closest to the supplied coordinate
//

- (void) insertCoordinateBetweenClosestNeighbors:(MBCoordinate *)coordinate{
    
    if (![self points] || [[self points] count] < 3) {
        [[self points] addObject:coordinate];
        return;
    }

    NSMutableSet *pointSet = [NSMutableSet setWithArray:[self points]];
    
    MBCoordinate *closestCoordinate = [self closestCoordinateToCoordinate:coordinate inSet:pointSet];
    [pointSet removeObject:closestCoordinate];
    
    MBCoordinate *nextClosestCoordinate = [self closestCoordinateToCoordinate:coordinate inSet:pointSet];
   
    NSUInteger indexOfClosestCoordinate, indexOfSecondClosestCoordinate, insertionIndex;
    
    
    for (NSUInteger i=0; i < [[self points] count]; i++) {
        
        if ([[self points][i] isEqual:closestCoordinate]) {
            indexOfClosestCoordinate = i;
        }
        
        if ([[self points][i] isEqual:nextClosestCoordinate]) {
            indexOfSecondClosestCoordinate = i;
        }
    }
    
    if(indexOfSecondClosestCoordinate == indexOfClosestCoordinate-1){
        insertionIndex = indexOfSecondClosestCoordinate+1;
    }else{
        insertionIndex = indexOfClosestCoordinate+1;
    }
    
    [[self points] insertObject:coordinate atIndex:insertionIndex];
     
     /*
    [[self points] addObject:coordinate];
    [self sortPointsByDistance];
     */
}

- (void) sortPointsByDistance{
    
    //
    //  TODO: Sort all of the points based upon their distance from the previous point.
    //
    
    NSMutableSet *unsortedPoints = [NSMutableSet setWithArray:[self points]];
    
    NSMutableArray *sortedPoints = [@[] mutableCopy];
    
    MBCoordinate *workingCoordinate = [self points][0];
    [sortedPoints addObject:workingCoordinate];
    
    while([unsortedPoints count] > 0){
    
        MBCoordinate *closestCoordinate = [self closestCoordinateToCoordinate:workingCoordinate inSet:unsortedPoints];

        [sortedPoints addObject:closestCoordinate];
        [unsortedPoints removeObject:closestCoordinate];
        
        workingCoordinate = closestCoordinate;        
    }
    
    [self setPoints:sortedPoints];
}

- (MBCoordinate *) closestCoordinateToCoordinate:(MBCoordinate *)coordinate inSet:(NSSet *)aSet{

    MBCoordinate *closest = nil;
    CGFloat closestDistance;
    
    for (MBCoordinate *coordinateInSet in aSet) {
        
        if ([coordinateInSet isEqual:coordinate]) {
            continue;
        }
        
        if (!closest) {
            closest = coordinateInSet;
            closestDistance = [self distanceBetweenCoordinate:coordinate andCoordinate:coordinateInSet];
        }
        
        CGFloat distanceBetweenPoints = [self distanceBetweenCoordinate:coordinate andCoordinate:coordinateInSet];
        
        if (distanceBetweenPoints < closestDistance) {
            closest = coordinateInSet;
            closestDistance = distanceBetweenPoints;
        }
        
        
    }
    
    return closest;
}

//
//  Determines the distance between two coordinates
//

- (CGFloat) distanceBetweenCoordinate:(MBCoordinate *)coordinate andCoordinate:(MBCoordinate *)anotherCoordinate{
    
    CGFloat xDistance, yDistance;
    
    xDistance = coordinate.latitude-anotherCoordinate.latitude;
    yDistance = coordinate.longitude-anotherCoordinate.longitude;

    float distance = xDistance/yDistance;
    
    //
    //  Absolute value of floats...
    //
    
    
    if (distance < 0) {
        distance *= -1;
    }
    
    return distance;
    
}


- (void) touch{
    [self setModifiedDate:[NSDate date]];
}

@end
