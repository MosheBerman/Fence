//
//  MBViewController.m
//  geofencer
//
//  Created by Moshe Berman on 5/5/12.
//  Copyright (c) 2012 Moshe Berman. All rights reserved.
//

#import "MBViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "MBMultifingerTapGestureRecognizer.h"

@interface MBViewController () <UIGestureRecognizerDelegate>

@property (strong, nonatomic) NSMutableArray *geofences;
@property (strong, nonatomic) MBGeofence *workingGeofence;

@property (strong, nonatomic) NSMutableArray *annotations;
@property (strong, nonatomic) NSMutableArray *overlays;

@property(assign, nonatomic) BOOL isDragging;


@end

@implementation MBViewController

/*
 TODO: List...
 
 - App Icon
 √ Rename fence
 - Set export filename
 - Export via email
 √ Persist fences
 - Instructions
 √ Import fences
 - Import UI
 - Randomly named and colored fences (except red, which is editing)
 √ Set the map type 
 √ Pins drag on initial tap, not after second tap
 √ Edit modes
 - Crowdsource fences & Game Center Achievements
 
 */


#pragma mark - View Life Cycle

/*
 
 TODO: Gestures
 
 Tap to add point - While editing a fence. Long press ends editing and saves.
 
 */

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        
        _geofences = [@[] mutableCopy];
        _annotations = [@[] mutableCopy];
        _isDragging = NO;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[self mapView] setDelegate:self];
    
    NSString *title = NSLocalizedString(@"Fence", @"Fence");
    [self setTitle:title];
    
    [self configureButtons];
    
    NSTimer *aTimer  = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(autosave) userInfo:nil repeats:YES];
    [self setSaveTimer:aTimer];
    
    [self configureGestures];
    
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    //
    //  Save the changes
    //
    
    //  TODO: This could potentially be a performance killer if there are a lot of points.
    [self saveIndividualFencesToCachesDirectory];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return YES;
}

#pragma mark - Gesture Handlers

- (void)newFenceWithGesture:(UITapGestureRecognizer *)gestureRecognizer{
    
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded){
        return;
    }
    
    [self newFence];
    
    for (NSInteger i = 0; i < 3; i++) {
        
        CGPoint touch = [gestureRecognizer locationOfTouch:i inView:[self view]];
        [self addPointToActiveFenceAtPoint:touch];
    }

    [self renderAnnotations];
}

- (void)addPointToActiveFenceFromGesture:(UITapGestureRecognizer *)gestureRecognizer{
    
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded || [self isDragging]){
        return;
    }
    
    if ([[[self workingGeofence] points] count] >= 20) {
        return;
    }
    
    [self addPointToActiveFenceAtPoint:[gestureRecognizer locationOfTouch:0 inView:self.view]];
    [self renderAnnotations];
}

#pragma mark - New Fence 

- (void) newFenceInMap{
    
    [self newFence];
    
    const float kLengthOfSide = 96.0;
    
    const float kWorkingAngle = 90;
    
    const int kNumberOfSidesInNewFence = 4;
    
    for(int i=0; i< kNumberOfSidesInNewFence; i++){
        
        float workingAngle = kWorkingAngle * i;
        
        float adjustedAngle = workingAngle*3/2;
        
        //  Convert to radians
        CGFloat angleInRadians = adjustedAngle*(M_PI/180);
        
        CGPoint point = CGPointZero;
        
        //  Calculate the x and Y coordinates
        point.x = sin(angleInRadians);
        point.y = cos(angleInRadians);
        
        //  Apply the scale factor
        point.x *= kLengthOfSide;
        point.y *= kLengthOfSide;
        
        //  Offset to the center
        point.x += [[self mapView] frame].size.width/2;
        point.y += [[self mapView] frame].size.height/2;
        
        [self addPointToActiveFenceAtPoint:point];
    }
    
    [self renderAndSave];
    
}

#pragma mark - Pin Actions

- (void)addPointToActiveFenceAtPoint:(CGPoint)point{
    
    CLLocationCoordinate2D touchMapCoordinate = [_mapView convertPoint:point toCoordinateFromView:self.mapView];
    
    //
    //  Add a location to the working geofence
    //
    
    [self.workingGeofence addLocation:touchMapCoordinate];
    
    [[self workingGeofence] reorganizeByDistance];
}

#pragma mark - UI Setup

//
//  Set up the buttons for the navigation bar
//

- (void)configureButtons{
    
    //
    //  Create the action button
    //
    //
    
    if (![self actionButton]) {
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionSheet)];
        [self setActionButton:button];
    }
    
    //
    //  Create the New Fence button
    //
    
    UIBarButtonItem *newFenceButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(newFenceInMap)];
    
    [[self navigationItem] setRightBarButtonItems:@[[self actionButton], newFenceButton] animated:YES];
    
    //
    //  Set up a map type segmented control
    //
    
    NSArray *mapTypes = @[NSLocalizedString(@"Standard", @"Standard"), NSLocalizedString(@"Satellite", @"Satellite"), NSLocalizedString(@"Hybrid", @"Hybrid")];
    
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:mapTypes];
    [segmentedControl setSegmentedControlStyle:UISegmentedControlStyleBar];
    [segmentedControl setSelectedSegmentIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"mapType"]];
    [segmentedControl addTarget:self action:@selector(changeAndSaveMapType:) forControlEvents:UIControlEventValueChanged];
    
    UIBarButtonItem *mapTypeButton = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
    
    [[self navigationItem] setLeftBarButtonItems:@[mapTypeButton] animated:YES];
    
}

- (void) configureGestures{
    
    //
    //  Set up a gesture recognizer for placing fences.
    //  See this StackOverflow question for more: http://stackoverflow.com/questions/4317810/how-to-capture-tap-gesture-on-mkmapview
    //
    
    UITapGestureRecognizer *threeFingerTouch = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(newFenceWithGesture:)];
    [threeFingerTouch setNumberOfTouchesRequired:3];
    [threeFingerTouch setDelegate:self];
    
    for (UIGestureRecognizer *gesture in [[self mapView] gestureRecognizers]) {
        [gesture requireGestureRecognizerToFail:threeFingerTouch];
    }
    
    [[self mapView] addGestureRecognizer:threeFingerTouch];
    
    UILongPressGestureRecognizer*tapGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(addPointToActiveFenceFromGesture:)];
    [tapGesture setNumberOfTouchesRequired:1];
    [tapGesture setMinimumPressDuration:0.3f];
    [tapGesture setDelegate:self];
    [[self mapView] addGestureRecognizer:tapGesture];
    
}

- (void)showActionSheet{
    if (![self actionSheet]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil, nil];

        [actionSheet addButtonWithTitle:NSLocalizedString(@"Export to iTunes", @"Export to iTunes")];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Share via Email", @"Share via Email")];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Import Fence", @"Import Fence")];
        
        [self setActionSheet:actionSheet];
    }   
    
    [[self actionSheet] showFromBarButtonItem:(self.navigationItem.rightBarButtonItems)[0] animated:YES];
}

#pragma mark - Map View Delegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation{
    
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    if([annotation isKindOfClass:[MKPolygon class]]){
        
        static NSString *reuse = @"reuse";
        
        //
        //  Make a view for the annotation title
        //
        
        MBAnnotationView *annotationView = (MBAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:reuse];
        
        //
        //  Prepare to set up the label
        //
        
        const int kVerticalPadding = 20;
        
        NSString *labelText = [annotation title];
        
        UIFont *labelFont = [UIFont boldSystemFontOfSize:15];
        
        CGSize size = [labelText sizeWithFont:labelFont constrainedToSize:CGSizeMake(100, 25) lineBreakMode:UILineBreakModeClip];
        CGFloat width = size.width+(kVerticalPadding*2);
        
        //
        //  Instantiate the view as necessary
        //
        
        if(!annotationView){
            annotationView = [[MBAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuse];
            
            //
            //  Set up a title label
            //
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, size.height)];
            [label setTextColor:[UIColor whiteColor]];
            [label setTextAlignment:NSTextAlignmentCenter];
            [[label layer] setBorderColor:[UIColor darkGrayColor].CGColor];
            [[label layer] setBorderWidth:1.0];
            [label setBackgroundColor:[[UIColor darkGrayColor] colorWithAlphaComponent:0.7]];
            [[label layer] setCornerRadius: 5.0];
            [label setText:labelText];
            [label setFont:labelFont];
            
            label.tag = 37;
            
            [annotationView addSubview:label];
            
            //
            //  Create a remove button
            //
            
            UIButton *deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
            [deleteButton setBackgroundImage:[UIImage imageNamed:@"delete.png"] forState:UIControlStateNormal];
            [annotationView setLeftCalloutAccessoryView:deleteButton];
            
            [annotationView setBackgroundColor:[UIColor clearColor]];
            
            
            //
            //
            //
            
            UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
            [annotationView setRightCalloutAccessoryView:infoButton];
        }                
        
        
        ((UILabel *)[annotationView viewWithTag:37]).text = [annotation title];
        
        ((UILabel *)[annotationView viewWithTag:37]).frame = CGRectMake(0, 0, width, 25);
        [annotationView setFrame:CGRectMake(0, 0, width, 25)];
        
        
        
        annotationView.canShowCallout = YES;
        
        //
        //
        //
        
        return annotationView;
        
    }else{
        //
        //  Create or dequeue a pin as necessary
        //
        
        static NSString *annotationIdentifier = @"annotation";
        MKPinAnnotationView *pin = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
        
        if (!pin) {
            pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
            
            pin.pinColor = MKPinAnnotationColorRed;
            pin.canShowCallout = YES;
            pin.draggable = YES;
        }
        
        [pin setSelected:YES animated:YES];
        
        //
        //  Create a remove button
        //
        
        const int kVerticalPadding = 10;
        
        NSString *labelText = NSLocalizedString(@"Remove", @"Remove");
        
        UIFont *labelFont = [UIFont boldSystemFontOfSize:15];
        
        CGFloat width = [labelText sizeWithFont:labelFont constrainedToSize:CGSizeMake(60, 25) lineBreakMode:UILineBreakModeClip].width+(kVerticalPadding*2);
        
        UIButton *deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(1, 0, width, 25)];
        
        [deleteButton setBackgroundImage:[[UIImage imageNamed:@"delete_button.png"]
                                          stretchableImageWithLeftCapWidth:8.0f
                                          topCapHeight:0.0f]
                                forState:UIControlStateNormal];
        
        [deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [[deleteButton titleLabel] setFont: labelFont];
        [[deleteButton titleLabel] setShadowColor: [UIColor lightGrayColor]];
        [[deleteButton titleLabel] setShadowOffset: CGSizeMake(0, -1)];
        [deleteButton setTitle:labelText forState:UIControlStateNormal];
        
        
        //
        // TODO: Add numbers to the pins
        //
        
        // TODO: Custom annotation to support this? ... 
        
        //
        //
        //
        
        if([[[self workingGeofence] points] count] > 3){
            [pin setRightCalloutAccessoryView:deleteButton];
        }else{
            [pin setRightCalloutAccessoryView:nil];
        }
        
        return pin;
    }
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay{
    
    MKPolygonView *polygonView = [[MKPolygonView alloc] initWithPolygon:(MKPolygon *)overlay];
    
    polygonView.fillColor = [[UIColor greenColor] colorWithAlphaComponent:0.4];
    polygonView.strokeColor = [[UIColor greenColor] colorWithAlphaComponent:1.0];
    polygonView.lineWidth = 2.0;
    polygonView.lineJoin = kCGLineJoinRound;
    
    return polygonView;
}


//
//  After we add the overlay views, recolor the active one. 
//

- (void)mapView:(MKMapView *)mapView didAddOverlayViews:(NSArray *)overlayViews{
    for(MKPolygonView *polygonView in overlayViews){        
        
        for (MBCoordinate *coordinate in self.workingGeofence.points) {
            
            /*
             
             //  See this StackOverflow question for more info 
             //  on detecting if a point is in a polygon:
             //
             //  http://stackoverflow.com/questions/4354130/how-to-determine-if-an-annotation-is-inside-of-mkpolygonview-ios
             //
             //  Note that now I use a brute force method, of checking point for point.
             //  This seems to be the most accurate waty to run the check.
             //
             //
             
             MKMapPoint mapPoint = MKMapPointForCoordinate([coordinate CLLocationCoordinate2DRepresentation]);
             CGPoint point = [polygonView pointForMapPoint:mapPoint];
             BOOL drawingActivePolygon = CGPathContainsPoint(polygonView.path, NULL, point, NO);
             */
            
            //
            //  Recolor the active overlay. 
            //  Doing this in the viewForOverlay method
            //  causes a weird positioning bug, so do it here.
            //
            
            
            if ([self.workingGeofence matchesPolygon:polygonView.polygon]) {
                polygonView.fillColor = [[UIColor redColor] colorWithAlphaComponent:0.4];
                polygonView.strokeColor =  [[UIColor redColor] colorWithAlphaComponent:0.8];
                polygonView.lineWidth = 4.0;
                break;
            }
            
        }        
        
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState{
    
    CLLocationCoordinate2D annotationCoordinate = [view.annotation coordinate];
    
    MBCoordinate *tempCoordinate = [[MBCoordinate alloc] initWithLatitude:annotationCoordinate.latitude andLongitude:annotationCoordinate.longitude];
    
    if (newState == MKAnnotationViewDragStateStarting) {
        
        [self setIsDragging:YES];
        
        // Tell the appropriate MBCoordinate that it's time to drag
        
        for (MBCoordinate *coordinate in self.workingGeofence.points) {
            if ([coordinate isEqual:tempCoordinate]) {
                [coordinate setIsDragging:YES];
            }
        }
        
    }else if(newState == MKAnnotationViewDragStateEnding){
        
        //  Store the new location and tell the annotation it's done
        
        for (MBCoordinate *coordinate in self.workingGeofence.points) {
            if ([coordinate isDragging]) {
                [coordinate setIsDragging:NO];
                coordinate.latitude = annotationCoordinate.latitude;
                coordinate.longitude = annotationCoordinate.longitude;
                break;
            }
        }
        
    }else if(newState == MKAnnotationViewDragStateNone && oldState == MKAnnotationViewDragStateEnding){
        [self renderAndSave];
        [self setIsDragging:NO];
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view{
    
    //
    //  TODO: Possible optimization:
    //
    //
    //  Swap and rerender colors instead of looping through all 
    //
    //
    
    if ([[view annotation] isKindOfClass:[MKPolygon class]]) {
        for (MBGeofence *fence in self.geofences) {
            
            //
            //  When a fence annotation is tapped,
            //  look through our stored fences (MBGeofence)
            //  and compare the points manually.
            //
            //  If we have a direct match, check if the
            //  selected fence is the working one. If it is,
            //  return. If not, make it so and reload
            //  the annotations and overlays.
            //
            
            if ([fence matchesPolygon:((MKPolygon *)[view annotation])]) {
                if ([fence isEqual:self.workingGeofence])return;
                
                self.workingGeofence = fence;
                [self renderAnnotations];
                
                return;
            }
        }
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control{
    
    if ([[view annotation] isKindOfClass:[MKPolygon class]]) {
        
        if ([[view leftCalloutAccessoryView] isEqual:control]) {
            
            [self.geofences removeObject:self.workingGeofence];
            [self.workingGeofence removeAllObjects];            
            self.workingGeofence = nil;
            
            if(self.geofences.count == 0){
                [self newFence];
                [self renderAndSave];
            }
            
            [self renderAndSave];
            
        }else if([[view rightCalloutAccessoryView] isEqual:control]){
            
            //
            //  Show rename box
            //
            
            [self showRenameAlert];
        }
    }else{
        [self.workingGeofence removeLocation:[view.annotation coordinate]];
        [self renderAndSave];
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    
    MBGeofence *fence = [self fenceContainingPoint:userLocation.location.coordinate];
    NSString *string = [fence name] ? [fence name] : @"No fence";
//    NSLog(@"User is in fence called: %@", string);

}

#pragma mark - Gesture Recognizer

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    
    for (UIView *subview in [[self mapView] subviews]) {
        
        if ([[subview class] conformsToProtocol:@protocol(MKAnnotation) ]) {
            
            if (CGRectContainsPoint([subview frame], [touch locationInView:[self view]])) {
             
                
                
                return NO;
                
            }
        }
    }
    
    return YES;
}

- (void) handleGesture: (UIGestureRecognizer *) gestureRecognizer{
    
    
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {

        NSInteger numberOfTouches = [gestureRecognizer numberOfTouches];
        
        MBGeofence *fence = [[MBGeofence alloc] initWithName:@"New Fence"];
        
        for (NSInteger i = 0; i < numberOfTouches; i++) {
            
            CGPoint point = [gestureRecognizer locationOfTouch:i inView:[self mapView]];
            
            CLLocationCoordinate2D touchMapCoordinate = [_mapView convertPoint:point toCoordinateFromView:self.mapView];
            
            [fence addLocation:touchMapCoordinate];
        }
        
        [self.geofences addObject:fence];
        self.workingGeofence = fence;
    }
}



#pragma mark - Render and Save

- (void) renderAndSave{
    [self saveIndividualFencesToCachesDirectory];
    [self renderAnnotations];
}

- (void)renderAnnotations{
    
    if (self.annotations== nil) {
        self.annotations = [[NSMutableArray alloc] init];
    }
    
    if (self.overlays == nil) {
        self.overlays = [[NSMutableArray alloc] init];
    }    
    
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.overlays removeAllObjects];
    
    //
    //  Don't remove the user location annotation ever
    //
    
    for (id <MKAnnotation>object in [self.mapView.annotations copy]) {
        if ([object conformsToProtocol:@protocol(MKAnnotation)]) {
            if (![object isKindOfClass:[MKUserLocation class]]) {
                [self.mapView removeAnnotation:object];
                [self.annotations removeObject:object];
            }
        }
    }
    
    for (NSInteger i=0;i<self.geofences.count;i++) {
        MBGeofence *fence = (self.geofences)[i];
        MKPolygon *polygon = [fence polygonRepresentation];
        polygon.title = [fence name];
        [self.mapView addAnnotation:polygon];
        [self.mapView addOverlay:polygon];
        [self.overlays addObject:polygon];
        [self.annotations addObject:polygon];
    }
    
    for (MBCoordinate *coordinate in self.workingGeofence.points) {
        
        NSString *locationAsString = [NSString stringWithFormat:@"%f, %f", coordinate.latitude, coordinate.longitude];
        MKPointAnnotation *mapPointAnnotation = [[MKPointAnnotation alloc] init];
        mapPointAnnotation.coordinate = [coordinate CLLocationCoordinate2DRepresentation];
        mapPointAnnotation.title = locationAsString;
        [self.mapView addAnnotation:mapPointAnnotation];  
        [self.annotations addObject:mapPointAnnotation];
    }
}

#pragma mark - Actions

- (void) showRenameAlert{
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Name Fence", @"Name Fence")
                                                    message:NSLocalizedString(@"Enter a name for this Fence.", @"Enter a name for this Fence.")
                                                   delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") otherButtonTitles:@"OK", nil];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[alert textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeWords];
    [[alert textFieldAtIndex:0] setText:self.workingGeofence.name];
    [[alert textFieldAtIndex:0] setClearButtonMode:UITextFieldViewModeAlways];
    [alert show];
}

- (void) showExportView{
    [self saveToDocumentsDirectory];
}

#pragma mark - Alert View Delegate

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex != [alertView cancelButtonIndex]) {
        if ([alertView textFieldAtIndex:0].text.length == 0) {
            [self showRenameAlert];
        }else{
            [self.workingGeofence setName:[alertView textFieldAtIndex:0].text];
            [self renderAndSave];
        }
    }
}

- (void)changeAndSaveMapType:(UISegmentedControl *)sender{
    
    [[NSUserDefaults standardUserDefaults] setInteger:sender.selectedSegmentIndex forKey:@"mapType"];
    
    self.mapView.mapType = sender.selectedSegmentIndex;
    
}

#pragma mark - Add and Remove fences

- (void)newFence{
    
    //  Don't allow the user to create a new fence 
    //  if the current one is empty, since there's no point
    if (self.workingGeofence != nil && self.workingGeofence.points.count == 0) {
        return;
    }
    
    MBGeofence *fence = [[MBGeofence alloc] init];
    [self.geofences addObject:fence];   
    self.workingGeofence = fence;
    
}

- (void)setActiveFenceWithIndex:(NSInteger)index{
    if (self.geofences.count > index && index >= 0) {
        self.workingGeofence = (self.geofences)[index];
    }
}

- (void)deleteFenceAtIndex:(NSInteger)index{
    /*
     //  Add a new fence if we're the current fence. This avoids having zero fences.
     if ([self.workingGeofence isEqual:[self.geofences objectAtIndex:index]]) {
     [self newFence];
     }
     */
    
    if(self.geofences.count > 0 && self.geofences.count > index){
        [self.geofences removeObjectAtIndex:index];
    }
    
    NSLog(@"Fences: %@", [self.geofences description]);
}


#pragma mark - Save Functionality

- (void) saveAsSingleFileToCachesDirectory{
    
    NSURL *url = [[self applicationCachesDirectory] URLByAppendingPathComponent:@"Fences.plist"];
    
    if(![[self serializeFences] writeToURL:url atomically:NO]){
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Whoops",@"Whoops")
                                                        message:NSLocalizedString(@"Your fences have not been saved.",@"Your fences have not been saved.") 
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                              otherButtonTitles: nil];
        
        [alert show];        
        
    }else{
        
    }     
}

- (void) saveIndividualFencesToCachesDirectory{
    
    BOOL failedToSaveAFence = NO;
    
    for (MBGeofence *fence in self.geofences) {
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
- (void)saveToDocumentsDirectory{
    NSURL *url = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Fences.plist"];
    
    if(![[self serializeFences] writeToURL:url atomically:NO]){
        
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

- (void) autosave{
    
    //
    //  Save the changes
    //
    
    //  TODO: This could potentially be a performance killer if there are a lot of points.
    
    [self saveIndividualFencesToCachesDirectory];
}

#pragma mark - Serialized and Deserialize

//
//  Because geofences contain custom classes,
//  I need to convert those to NSDictionary representations.
//

- (NSArray *)serializeFences{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    for (NSInteger i=0; i<self.geofences.count; i++) {
        [array addObject:[(self.geofences)[i] asDictionary]];
    }
    
    return array;
}

- (NSArray *)deserializeFencesAtURL:(NSURL*)url{
    
    NSMutableArray *fences = [[NSMutableArray alloc] initWithContentsOfURL:url];
    
    if (!fences) {
        
        NSLog(@"Failed to import.");
        
        return nil;
    }
    
    if (fences.count == 0) {
        NSLog(@"Zero fences.");
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
