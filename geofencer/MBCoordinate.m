//
//  MBCoordinate.m
//  geofencer
//
//  Created by Moshe Berman on 5/5/12.
//  Copyright (c) 2012 Moshe Berman. All rights reserved.
//

#import "MBCoordinate.h"


@implementation MBCoordinate

- (id) initWithLatitude:(double)latitude andLongitude:(double)longitude{
    self = [super init];
    
    if (self) {
        _latitude = latitude;
        _longitude = longitude;
        _isDragging = NO;
    }
    
    return self;
}

- (CLLocationCoordinate2D)CLLocationCoordinate2DRepresentation{
    return CLLocationCoordinate2DMake([self latitude], [self longitude]);
}

- (BOOL)isEqual:(id)object{
    if ([object respondsToSelector:@selector(latitude)] && [object respondsToSelector:@selector(longitude)]) {
        return [object latitude] == [self latitude] && [object longitude] == [self longitude];
    }
    
    return NO;
}

- (NSString *)description{
    return [NSString stringWithFormat:@"{%f, %f}", self.latitude, self.longitude];
}

- (NSDictionary *)asDictionary{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    dictionary[@"latitude"] = @([self latitude]);
    dictionary[@"longitude"] = @([self longitude]);
    return dictionary;
}

@end
