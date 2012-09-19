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
    [[self points] addObject:coordinate];
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
    
    dictionary[@"coordinates"] = @[[self asArray]];
    dictionary[@"type"] = @"MultiPolygon";
    return dictionary;
    
}

//
//  Detect which coordinate is the closest to the supplied coordinate
//

- (MBCoordinate *) coordinateClosestToCoordinate:(MBCoordinate *)coordinate{
    
    if (![self points] || [[self points] count] < 2) {
        return nil;
    }

    MBCoordinate *closestCoordinate = nil;

    CGPoint closestDistance;

    for(NSInteger  i = 0; i < [[self points] count]; i++){
        
        if(coordinate == [self points][i]){
            continue;
        }
        
        if(!closestCoordinate){
            closestCoordinate = [self points][i];
            closestDistance = [self distanceBetweenCoordinate:coordinate andCoordinate:closestCoordinate];
        }
        
        CGPoint nextDistance = [self distanceBetweenCoordinate:[self points][i] andCoordinate:closestCoordinate];
        
        if(nextDistance.x < closestDistance.x && nextDistance.y < closestDistance.y){
            nextDistance = closestDistance;
            closestCoordinate = [self points][i];
        }
        
    }

    return closestCoordinate;
}

//
//  Determines the distance between two coordinates
//

- (CGPoint) distanceBetweenCoordinate:(MBCoordinate *)coordinate andCoordinate:(MBCoordinate *)anotherCoordinate{
    
    CGFloat xDistance, yDistance;
    
    xDistance = abs(coordinate.latitude-anotherCoordinate.latitude);
    yDistance = abs(coordinate.longitude-anotherCoordinate.longitude);
    
    return CGPointMake(xDistance, yDistance);
    
}

//
//  Reorganizes the points based on closest distance
//
//  FIXME: Make this algorithm work.
//

- (void) reorganizeByDistance{

    return;
    
    if ([[self points] count] < 3) {
        return;
    }
    
    id nextCoordinate = [self points][0];
    
    [[self points] sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
       
        CGPoint distanceBetweenOriginalAndFirst = [self distanceBetweenCoordinate:obj1 andCoordinate:nextCoordinate];
        CGPoint distanceBetweenOriginalAndSecond = [self distanceBetweenCoordinate:obj2 andCoordinate:nextCoordinate];
        
        __block id nextCoordinate;
        
        nextCoordinate = obj1;
        
        NSComparisonResult result = NSOrderedAscending;
        
        if (distanceBetweenOriginalAndFirst.x > distanceBetweenOriginalAndSecond.x && distanceBetweenOriginalAndFirst.y > distanceBetweenOriginalAndSecond.y) {
            result = NSOrderedDescending;
        }else if (distanceBetweenOriginalAndFirst.x == distanceBetweenOriginalAndSecond.x && distanceBetweenOriginalAndFirst.y == distanceBetweenOriginalAndSecond.y) {
            result = NSOrderedSame;
        }
        
        //
        return result;
    }];
    
    [self touch];
}

- (void) touch{
    [self setModifiedDate:[NSDate date]];
}

@end
