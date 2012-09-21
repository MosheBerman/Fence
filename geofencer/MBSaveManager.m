//
//  MBSaveManager.m
//  Fence
//
//  Created by Moshe Berman on 9/19/12.
//
//

#import "MBSaveManager.h"

@implementation MBSaveManager

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

#pragma mark - Fence From Name

- (MBGeofence *) fenceWithNameInLibrary:(NSString *)name{

    NSString *fileName = [NSString stringWithFormat:@"%@", name];
    NSURL *url = [[self applicationLibraryDirectory] URLByAppendingPathComponent:fileName];
    
    return [self fenceWithName:name inDirectory:url];
}

- (MBGeofence *) fenceWithNameInDocumentsDirectory:(NSString *)name{
    NSString *fileName = [NSString stringWithFormat:@"%@", name];
    NSURL *url = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:fileName];
    
    return [self fenceWithName:name inDirectory:url];   
}

- (MBGeofence *) fenceWithName:(NSString *)name inDirectory:(NSURL *)url{
    
    
    
    NSData *data = [NSData dataWithContentsOfURL:[url filePathURL]];
    
    if (!data) {
        return nil;
    }
    
    
    
    NSError *error = nil;
    
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
    if (error) {
        
        return nil;
    }
    
    MBGeofence *fence = [[MBGeofence alloc] initWithName:dictionary[@"name"]];
    
    NSArray *coords = dictionary[@"coordinates"];
    
    //
    //  Iterate the coordinates
    //
    
    for (NSInteger j =0; j<coords.count; j++) {
        NSDictionary *coordDict = coords[j][0];
        CLLocationCoordinate2D location = CLLocationCoordinate2DMake([coordDict[@"latitude"] doubleValue], [coordDict[@"longitude"] doubleValue]);
        [fence addLocation:location];
    }
    
    return fence;
}

#pragma mark - Save Methods

- (BOOL) saveFenceToLibrary:(MBGeofence *)fence {
    return [self saveFence:fence toDirectory:[self applicationLibraryDirectory] asJSON:YES];
}

- (BOOL) saveFenceToDocumentsDirectory:(MBGeofence *)fence {
    return [self saveFence:fence toDirectory:[self applicationDocumentsDirectory] asJSON:YES];
}

- (BOOL) saveFence:(MBGeofence *)fence toDirectory:(NSURL *)directory asJSON:(BOOL)useJSON{
    
    
    if (!fence) {
        return NO;
    }
    
    NSString *suffix = useJSON ? @"geojson" : @"plist";
    
    NSString *fileName = [NSString stringWithFormat:@"%@.%@", [fence name], suffix];
    NSURL *url = [directory URLByAppendingPathComponent:fileName];
    
    NSArray *fenceArray = [fence asArray];
    
    NSDictionary *fenceDictionary = [fence asDictionary];
    
    if(useJSON){
        
        NSError *error = nil;
        if(![[NSJSONSerialization dataWithJSONObject:fenceDictionary options:0 error:&error] writeToFile:[url path] atomically:NO]){
            
            //
            //  There's an error.
            //
        }
        
        return error == nil;
    }
    
    return [fenceArray writeToURL:url atomically:NO];
}

- (BOOL) saveFences:(MBGeofenceCollection *)fences toDirectory:(NSURL *)directory{
    
    NSURL *url = [directory URLByAppendingPathComponent:@"Fences.plist"];
    
    if(![[self serializeFences:fences] writeToURL:url atomically:NO]){
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Whoops",@"Whoops")
                                                        message:NSLocalizedString(@"Your fences have not been saved.",@"Your fences have not been saved.")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                              otherButtonTitles: nil];
        
        [alert show];
        
        return NO;
        
    }else{
        
        //
        //  Save went well.
        //
        
        return YES;
    }
}

#pragma mark - Delete Fence Method

- (BOOL) deleteFenceNamed:(NSString *)name{

    NSString *nameWithPLISTExtension = [NSString stringWithFormat:@"%@.plist",name];
    
    NSURL *url = [[self applicationLibraryDirectory] URLByAppendingPathComponent:nameWithPLISTExtension];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        
        NSError *error = nil;
        return [[NSFileManager defaultManager] removeItemAtPath:[url path] error:&error];
    }else{
        return NO;
    }
}

#pragma mark - Significant Directories

- (NSURL *)applicationDocumentsDirectory{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL *)applicationCachesDirectory{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL *)applicationLibraryDirectory{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - File Import Methods

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path{

    
    NSError *error = nil;
    
    NSArray *results = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    
    if (error) {
        return nil;
    }
    
    return results;
}

- (NSArray *) JSONFilesAvailableForImport{
    
    NSString *applicationDocuments = [[self applicationDocumentsDirectory] path];
    
    NSArray *unfilteredResults = [self contentsOfDirectoryAtPath:applicationDocuments];
    
    NSPredicate *containsJSON = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        
        return [evaluatedObject rangeOfString:@".geojson"].location != NSNotFound;
        
    }];
    
    return [unfilteredResults filteredArrayUsingPredicate:containsJSON];
}

- (NSArray *) JSONFilesAvailableForExport{
    NSString *applicationDocuments = [[self applicationLibraryDirectory] path];
    
    NSArray *unfilteredResults = [self contentsOfDirectoryAtPath:applicationDocuments];
    
    NSPredicate *containsJSON = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        
        return [evaluatedObject rangeOfString:@".geojson"].location != NSNotFound;
        
    }];
    
    return [unfilteredResults filteredArrayUsingPredicate:containsJSON];
}

- (NSArray *) JSONFilesAvailableForOpen{
    return [self JSONFilesAvailableForExport];
}

- (NSUInteger) numberOfJSONFilesAvailableForImport{
    return [[self JSONFilesAvailableForImport] count];
}

- (NSUInteger) numberOfJSONFilesAvailableForExport{
    return [[self JSONFilesAvailableForExport] count];
}

- (NSUInteger) numberOfJSONFilesAvailableForOpen{
    return [[self JSONFilesAvailableForOpen] count];
}




@end
