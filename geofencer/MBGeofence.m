//
//  MBGeofence.m
//  geofencer
//
//  Created by Moshe Berman on 5/5/12.
//  Copyright (c) 2012 Moshe Berman. All rights reserved.
//

#import "MBGeofence.h"

@implementation MBGeofence

@synthesize points;
@synthesize name = _name;

- (id)init{
    self = [super init];
    
    if (self) {
        self.name = [@"Unnamed Fence" mutableCopy];
        self.points = [[NSMutableArray alloc]init];
    }
    
    return self;
}

- (id) initWithName:(NSString*)name{
    self = [super init];
    
    if (self) {
        
        if (name == nil) {
            name = @"Unnamed Fence";
        }
        
        self.points = [[NSMutableArray alloc] init];
        self.name = [name mutableCopy];
    }
    
    return self;
    
}

- (void) addLocation:(CLLocationCoordinate2D)location{
    MBCoordinate *coordinate = [[MBCoordinate alloc] initWithLatitude:location.latitude andLongitude:location.longitude];
    [self.points addObject:coordinate];
}

- (void) removeLocation:(CLLocationCoordinate2D)location{
    
    MBCoordinate *coordinate = [[MBCoordinate alloc] initWithLatitude:location.latitude andLongitude:location.longitude];
    
    NSMutableArray *discardedCoordinates = [[NSMutableArray alloc] init];
    
    for (MBCoordinate *storedCoordinate in self.points) {
        if ([storedCoordinate isEqual:coordinate]) {
            [discardedCoordinates addObject:storedCoordinate];
        }
    }
    
    [self.points removeObjectsInArray:discardedCoordinates];
}

- (void) removeAllObjects{
    
    [self.points removeAllObjects];
    
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
    if(self.polygonRepresentation.pointCount != polygon.pointCount){
        return NO;
    }
    
    for (int i=0; i<self.polygonRepresentation.pointCount; i++) {
        if((self.polygonRepresentation.points[i].x != polygon.points[i].x) || (self.polygonRepresentation.points[i].y != polygon.points[i].y)){
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
    
    dictionary[@"coordinates"] = [self asArray];
    dictionary[@"name"] = self.name;
    
    return dictionary;
    
}

@end
