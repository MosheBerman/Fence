//
//  MBSaveManager.m
//  Fence
//
//  Created by Moshe Berman on 9/19/12.
//
//

#import "MBSaveManager.h"

@implementation MBSaveManager


- (void) saveAsSingleFileToCachesDirectory:(MBGeofenceCollection*)fences{
    
    NSURL *url = [[self applicationCachesDirectory] URLByAppendingPathComponent:@"Fences.plist"];
    
    if(![[self serializeFences:fences] writeToURL:url atomically:NO]){
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Whoops",@"Whoops")
                                                        message:NSLocalizedString(@"Your fences have not been saved.",@"Your fences have not been saved.")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                              otherButtonTitles: nil];
        
        [alert show];
        
    }else{
        
        //
        //  Save went well.
        //
    }
}


- (void) saveIndividualFencesToCachesDirectory:(MBGeofenceCollection *)fences{
    
    BOOL failedToSaveAFence = NO;
    
    for (MBGeofence *fence in [fences geofences]) {
        NSString *name = [NSString stringWithFormat:@"%@.plist", fence.name];
        
        NSURL *url = [[self applicationCachesDirectory] URLByAppendingPathComponent:name ];
        
        if(![[fence asArray] writeToURL:url atomically:YES]){
            failedToSaveAFence = YES;
        }
    }
    
    if (failedToSaveAFence) {
        NSLog(@"There was an error saving one or more fences.");
    }
    
}

- (void)saveToDocumentsDirectory:(MBGeofenceCollection *)fences{
    NSURL *url = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Fences.plist"];
    
    if(![[self serializeFences:fences] writeToURL:url atomically:NO]){
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Whoops",@"Whoops")
                                                        message:NSLocalizedString(@"Your fences have not been exported.",@"Your fences have not been exported.")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                              otherButtonTitles: nil];
        
        [alert show];
        
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success",@"Success")
                                                        message:NSLocalizedString(@"Your fences have been exported to the documents directory. You can retrieve them in iTunes.",@"Your fences have been exported to the documents directory. You can retrieve them in iTunes.")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                              otherButtonTitles: nil];
        
        [alert show];
    }
}



#pragma mark - Serialized and Deserialize

//
//  Because geofences contain custom classes,
//  I need to convert those to NSDictionary representations.
//

- (NSArray *)serializeFences:(MBGeofenceCollection *)fences{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    for (NSInteger i=0; i<fences.geofences.count; i++) {
        [array addObject:[(fences.geofences)[i] asDictionary]];
    }
    
    return array;
}

- (NSArray *)deserializeFencesAtURL:(NSURL*)url{
    
    NSMutableArray *fences = [[NSMutableArray alloc] initWithContentsOfURL:url];
    
    if (!fences) {
        
        NSLog(@"Failed to import into an array. Try JSON?");
        
        return nil;
    }
    
    if (fences.count == 0) {
        NSLog(@"There are no fences to deserialize.");
        return nil;
    }
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    
    //
    //  Iterate the fences
    //
    
    for (NSInteger i = 0; i<fences.count; i++) {
        
        NSDictionary *dictionary = fences[i];
        MBGeofence *fence = [[MBGeofence alloc] initWithName:dictionary[@"name"]];
        
        NSArray *coords = dictionary[@"coordinates"];
        
        //
        //  Iterate the coordinates
        //
        
        for (NSInteger j =0; j<coords.count; j++) {
            NSDictionary *coordDict = coords[j];
            CLLocationCoordinate2D location = CLLocationCoordinate2DMake([coordDict[@"latitude"] doubleValue], [coordDict[@"longitude"] doubleValue]);
            [fence addLocation:location];
        }
        
        //
        //
        //
        
        [tempArray addObject:fence];
    }
    
    return tempArray;
}

#pragma mark - Significant Directories

//
// Returns the URL to the application's Documents directory.
//

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

//
// Returns the URL to the application's Documents directory.
//
- (NSURL *)applicationCachesDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
}


@end