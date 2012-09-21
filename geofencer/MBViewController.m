//
//  MBViewController.m
//  geofencer
//
//  Created by Moshe Berman on 5/5/12.
//  Copyright (c) 2012 Moshe Berman. All rights reserved.
//

#import "MBViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "MBGeofenceCollection.h"
#import "MBSaveManager.h"

#import "MBFileManagerViewController.h"


#define kImportFencesTitle NSLocalizedString(@"Import", @"The title for the import button.")
#define kExportFencesTitle NSLocalizedString(@"Export", @"The title for the export button.")
#define kOpenFenceTitle NSLocalizedString(@"Open", @"The title for the import button.")

@interface MBViewController () <UIGestureRecognizerDelegate>

@property (strong, nonatomic) MBGeofenceCollection *fences;
@property (strong, nonatomic) MBSaveManager *saveManager;

@property (strong, nonatomic) NSMutableArray *annotations;
@property (strong, nonatomic) NSMutableArray *overlays;

@property (assign, nonatomic) BOOL isDragging;
@property (assign, nonatomic) BOOL isNamingNewFence;

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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        
        _fences = [[MBGeofenceCollection alloc] init];
        _saveManager = [[MBSaveManager alloc] init];
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
    
    [self configureGestures];
    [self configureButtonsWithAnimation:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didHideFileManagerWithNotification:) name:kDidHideFileManagerNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated{
    [self deactivateActiveFence];
    [super viewWillDisappear:animated];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return YES;
}

#pragma mark - UIGestureRecognizer Delegate

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


#pragma mark - Custom Gesture Handler

- (void)newFenceWithGesture:(UITapGestureRecognizer *)gestureRecognizer{
    
    if ([gestureRecognizer state] != UIGestureRecognizerStateEnded){
        return;
    }
    
    [[self fences] newFence];
    
    for (NSInteger i = 0; i < 3; i++) {
        
        CGPoint touch = [gestureRecognizer locationOfTouch:i inView:[self view]];
        [self addPointToActiveFenceAtPoint:touch];
    }

    [self renderAnnotations];
    [self configureButtonsWithAnimation:NO];
}

- (void)addPointToActiveFenceFromGesture:(UITapGestureRecognizer *)gestureRecognizer{
    
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded || [self isDragging]){
        return;
    }
    
    if ([[self fences] workingFencesHasMaximumNumberOfCoordinates]) {
        return;
    }
    
    [self addPointToActiveFenceAtPoint:[gestureRecognizer locationOfTouch:0 inView:self.view]];
    [self renderAnnotations];
}

- (void) deactivateActiveFenceWithGesture:(UIGestureRecognizer *)gestureRecognizer{
    if ([gestureRecognizer state] != UIGestureRecognizerStateEnded) {
        return;
    }
    
    [self deactivateActiveFence];
}

- (void) deactivateActiveFence{
    [[self saveManager] saveFenceToLibrary:[[self fences] workingGeofence]];
    [[self fences] deactivateActiveFence];
    [self configureButtonsWithAnimation:NO];
    [self setIsDragging:NO];
    [self renderAnnotations];
}

#pragma mark - UI Setup

//
//  Set up the buttons for the navigation bar
//

- (void)configureButtonsWithAnimation:(BOOL)animated{
    
    //
    //  Create the action button
    //
    
    if (![self actionButton]) {
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showImportExportActionSheet)];
        [self setActionButton:button];
    }
    
    //
    //  Create the New Fence button if we're not editing a fence,
    //  otherwise, add a "done" button.
    //
    //
    
    
    UIBarButtonItem *newOrDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(newFenceInMap)];
    
    if ([[self fences] workingGeofence]) {
        newOrDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(deactivateActiveFence)];
    }
    
    [[self navigationItem] setRightBarButtonItems:@[[self actionButton], newOrDoneButton] animated:animated];
    
    //
    //  Set up a map type button
    //
    
    NSArray *mapTypes = @[NSLocalizedString(@"Standard", @"Standard"), NSLocalizedString(@"Satellite", @"Satellite"), NSLocalizedString(@"Hybrid", @"Hybrid")];
    
    NSInteger mapType = [[NSUserDefaults standardUserDefaults] integerForKey:@"mapType"];
    

    
    //
    //  On iPhone, show a button, on iPad, show a segmented control.
    //
    
    UIBarButtonItem *mapTypeButton = [[UIBarButtonItem alloc] initWithTitle:mapTypes[mapType] style:UIBarButtonItemStyleBordered target:self action:@selector(showMapTypeActionSheet)];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        
        UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:mapTypes];
        [segmentedControl setSegmentedControlStyle:UISegmentedControlStyleBar];
        [segmentedControl setSelectedSegmentIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"mapType"]];
        [segmentedControl addTarget:self action:@selector(changeAndSaveMapTypeWithSegmentedControl:) forControlEvents:UIControlEventValueChanged];
        mapTypeButton = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
        
    }
    
    [[self navigationItem] setLeftBarButtonItems:@[mapTypeButton] animated:animated];
    
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
    
    //
    //  The gesture for adding points.
    //
    
    UILongPressGestureRecognizer*tapGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(addPointToActiveFenceFromGesture:)];
    [tapGesture setNumberOfTouchesRequired:1];
    [tapGesture setMinimumPressDuration:0.3f];
    [tapGesture setDelegate:self];
    [[self mapView] addGestureRecognizer:tapGesture];
    
    //
    //  Deselect the active fence.
    //
    
    UITapGestureRecognizer *twoFingerGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(deactivateActiveFenceWithGesture:)];
    [twoFingerGestureRecognizer setNumberOfTapsRequired:2];
    [twoFingerGestureRecognizer setNumberOfTouchesRequired:2];
    [twoFingerGestureRecognizer setCancelsTouchesInView:YES];
    
    for (UIGestureRecognizer *gesture in [[self mapView] gestureRecognizers]) {
        [gesture requireGestureRecognizerToFail:twoFingerGestureRecognizer];
    }
    
    [[self mapView] addGestureRecognizer:twoFingerGestureRecognizer];
    
    
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
        
        MBLabelAnnotationView *annotationView = (MBLabelAnnotationView*)[[self mapView] dequeueReusableAnnotationViewWithIdentifier:reuse];
        
        //
        //  Prepare to set up the label
        //
        
        const int kVerticalPadding = 20;
        
        
        NSString *title = [annotation title];
        
        //TODO: Show how many points are in fence here...
        
        NSString *labelText = title;
        
        UIFont *labelFont = [UIFont boldSystemFontOfSize:15];
        
        CGSize size = [labelText sizeWithFont:labelFont constrainedToSize:CGSizeMake(100, 25) lineBreakMode:UILineBreakModeClip];
        CGFloat width = size.width+(kVerticalPadding*2);
        
        //
        //  Instantiate the view as necessary
        //
        
        if(!annotationView){
            annotationView = [[MBLabelAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuse];
            
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
            [infoButton setShowsTouchWhenHighlighted:NO];
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
        MBPointAnnotationView *pin = (MBPointAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
        
        if (!pin) {
            pin = [[MBPointAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
            
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
        
        if([[self fences] workingFencesHasMinimumNumberOfCoordinates]){
            [pin setRightCalloutAccessoryView:nil];
        }else{
            [pin setRightCalloutAccessoryView:deleteButton];
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
        
        for (MBCoordinate *coordinate in [[self fences] workingGeofence].points) {
            
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
            
            
            if ([[[self fences  ]workingGeofence] matchesPolygon:polygonView.polygon]) {
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
        
        for (MBCoordinate *coordinate in [[[self fences] workingGeofence] points]) {
            if ([coordinate isEqual:tempCoordinate]) {
                [coordinate setIsDragging:YES];
            }
        }
        
    }else if(newState == MKAnnotationViewDragStateEnding){
        
        //  Store the new location and tell the annotation it's done
        
        for (MBCoordinate *coordinate in [[[self fences] workingGeofence] points]) {
            if ([coordinate isDragging]) {
                [coordinate setIsDragging:NO];
                coordinate.latitude = annotationCoordinate.latitude;
                coordinate.longitude = annotationCoordinate.longitude;
                break;
            }
        }
        
    }else if(newState == MKAnnotationViewDragStateNone && oldState == MKAnnotationViewDragStateEnding){
        [self renderAnnotations];
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
        for (MBGeofence *fence in [[self fences] geofences]) {
            
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
                if ([fence isEqual:[[self fences]workingGeofence]])return;
                
                [[self fences] setWorkingGeofence: fence];
                [self configureButtonsWithAnimation:NO];
                [self renderAnnotations];
                
                return;
            }
        }
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control{
    
    if ([[view annotation] isKindOfClass:[MKPolygon class]]) {
        
        if ([[view leftCalloutAccessoryView] isEqual:control]) {
            
            [self promptForDelete];
            
        }else if([[view rightCalloutAccessoryView] isEqual:control]){
            
            //
            //  Show rename box
            //
            
            [self showRenameAlert];
        }
    }else{
        [[self fences] removePointFromWorkingFence:[[view annotation] coordinate]];
        [self renderAnnotations];
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    
    MBGeofence *fence = [[self fences] fenceContainingPoint:userLocation.location.coordinate];
    NSString *string = [fence name] ? [fence name] : @"No fence";
//    NSLog(@"User is in fence called: %@", string);

}


#pragma mark - Render and Save

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
    
    for (NSInteger i=0;i<[[self fences] numberOfFences];i++) {
        MBGeofence *fence = [[self fences] geofences][i];
        MKPolygon *polygon = [fence polygonRepresentation];
        polygon.title = [fence name];
        [self.mapView addAnnotation:polygon];
        [self.mapView addOverlay:polygon];
        [self.overlays addObject:polygon];
        [self.annotations addObject:polygon];
    }
    
    for (MBCoordinate *coordinate in [[[self fences] workingGeofence] points]) {
        
        NSString *locationAsString = [NSString stringWithFormat:@"%f, %f", coordinate.latitude, coordinate.longitude];
        MKPointAnnotation *mapPointAnnotation = [[MKPointAnnotation alloc] init];
        mapPointAnnotation.coordinate = [coordinate CLLocationCoordinate2DRepresentation];
        mapPointAnnotation.title = locationAsString;
        [self.mapView addAnnotation:mapPointAnnotation];  
        [self.annotations addObject:mapPointAnnotation];
    }
}

#pragma mark - Actions


//
//  Use some fancy gemoetry to create a
//  shiny new fence at the center of the scren
//
//

- (void) newFenceInMap{
    
    [[self fences]newFence];
    
    const float kLengthOfSide = 128.0;
    
    const float kWorkingAngle = 90;
    
    const int kNumberOfSidesInNewFence = 3;
    
    for(int i=0; i< kNumberOfSidesInNewFence; i++){
        
        float workingAngle = kWorkingAngle * i;
        
        float adjustedAngle = workingAngle+(kWorkingAngle);
        
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
    
    [self configureButtonsWithAnimation:NO];
    [self renderAnnotations];
    
    [self setIsNamingNewFence:YES];
    [self showRenameAlert];
}

- (void)addPointToActiveFenceAtPoint:(CGPoint)point{
    
    CLLocationCoordinate2D touchMapCoordinate = [_mapView convertPoint:point toCoordinateFromView:self.mapView];
    
    //
    //  Add a location to the working geofence
    //
    
    [[self fences] addPointToWorkingFence:touchMapCoordinate];
}

- (void)showImportExportActionSheet{
    
    if (![self importExportActionSheet]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil, nil];
        
        [actionSheet addButtonWithTitle:kOpenFenceTitle];
        [actionSheet addButtonWithTitle:kExportFencesTitle];
        [actionSheet addButtonWithTitle:kImportFencesTitle];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel button title")];
        
        [actionSheet setDelegate:self];
        [actionSheet setCancelButtonIndex:3];
        
        [self setImportExportActionSheet:actionSheet];
    }
    
    [[self importExportActionSheet] showFromBarButtonItem:[[self navigationItem] rightBarButtonItems][0] animated:YES];
}

- (void) showMapTypeActionSheet{
    if (![self mapTypeActionSheet]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil, nil];
        
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Standard", @"Standard")];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Satellite", @"Satellite")];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Hybrid", @"Hybrid")];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel button title")];
        
        [actionSheet setDelegate:self];
        [actionSheet setCancelButtonIndex:3];
        
        [self setMapTypeActionSheet:actionSheet];
    }
    
    [[self mapTypeActionSheet] showFromBarButtonItem:[[self navigationItem] leftBarButtonItems][0] animated:YES];
}


#pragma mark - UIActionSheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    
    
    if ([actionSheet isEqual:[self mapTypeActionSheet]] ) {
        if (buttonIndex < 3) {
            [self changeAndPersistMapType:buttonIndex];
            [self configureButtonsWithAnimation:NO];
            return;
        }
    }
    
    NSString *tappedButton = [actionSheet buttonTitleAtIndex:buttonIndex];

    if ([tappedButton isEqualToString:kOpenFenceTitle]) {
        
        [self showOpenView];
        
    }else if ([tappedButton isEqualToString:kExportFencesTitle]) {
        
        [self showExportView];
        
    }else if([tappedButton isEqualToString:kImportFencesTitle]){
        
        [self showImportView];
        
    }
    
    [actionSheet setDelegate:nil];
    [self setImportExportActionSheet:nil];
    [self setMapTypeActionSheet:nil];
}

- (void) promptForDelete{
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete or Close?", @"A title for the prompt offering to delete or close a fence.")
                                                        message:NSLocalizedString(@"Would you like to close the fence or also delete it? Closed fences are saved so they can be opened again.", @"A message asking the user if they want to delete or also close the geofence")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", @"A title for a cancel button")
                                              otherButtonTitles:NSLocalizedString(@"Close", @"A title for the button that closes a fence"), NSLocalizedString(@"Delete", @"A title for the button that closes a fence and deletes the backing file."), nil];
    [alertView show];
    
}

- (void) closeFence{
    [[self fences] closeActiveFence];
    [self configureButtonsWithAnimation:NO];
    [self renderAnnotations];
}

- (void) deleteFence{
    NSString *name = [[[self fences] workingGeofence] name];
    [self closeFence];
    [[self saveManager] deleteFenceNamed:name];
}

#pragma mark - Import/Export/Open views

- (void) showOpenView{
    [self showFileManagerWithMode:kFileOpen];
}

- (void) showExportView{
    [self showFileManagerWithMode:kFileExport];
}

- (void) showImportView{
    [self showFileManagerWithMode:kFileImport];
}

- (void) showFileManagerWithMode:(FileMode)mode{
    MBFileManagerViewController *importViewController = [[MBFileManagerViewController alloc] initWithFences:[self fences] andMode:mode];
    UINavigationController *importNavController = [[UINavigationController alloc] initWithRootViewController:importViewController];
    
    [importNavController setModalPresentationStyle:UIModalPresentationFormSheet];
    
    [self presentViewController:importNavController animated:YES completion:nil];
}

- (void) didHideFileManagerWithNotification:(NSNotification*)notification{
    MBGeofenceCollection *fences = [notification object];
    
    if (fences) {
        [self setFences:fences];        
        [self renderAnnotations];
    }
}

#pragma mark - Alert View Delegate

- (void) showRenameAlert{
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Name Fence", @"Name Fence")
                                                    message:NSLocalizedString(@"Enter a name for this Fence.", @"Enter a name for this Fence.")
                                                   delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") otherButtonTitles:@"OK", nil];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[alert textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeWords];
    [[alert textFieldAtIndex:0] setText:[[[self fences] workingGeofence] name]];
    [[alert textFieldAtIndex:0] setClearButtonMode:UITextFieldViewModeAlways];
    [alert show];
}


-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if ([title isEqualToString:NSLocalizedString(@"Close", @"A title for the button that closes a fence")]) {
        [self closeFence];
    }else if([title isEqualToString:NSLocalizedString(@"Delete", @"A title for the button that closes a fence and deletes the backing file.")]){
        [self deleteFence];
    }else if (buttonIndex != [alertView cancelButtonIndex]) {
        if ([alertView textFieldAtIndex:0] && [alertView textFieldAtIndex:0].text.length == 0) {
            [self showRenameAlert];
        }else if ([alertView textFieldAtIndex:0]){
            [[[self fences] workingGeofence] setName:[alertView textFieldAtIndex:0].text];
            [self renderAnnotations];
            [self setIsNamingNewFence:NO];
        }
    }else if([self isNamingNewFence]){
        [self deleteFence];
    }
}

- (void) changeAndSaveMapTypeWithSegmentedControl:(UISegmentedControl *)sender{
    [self changeAndPersistMapType:[sender selectedSegmentIndex]];
}

- (void)changeAndPersistMapType:(NSInteger)mapType{
    
    [[NSUserDefaults standardUserDefaults] setInteger:mapType forKey:@"mapType"];
    
    [[self mapView] setMapType:mapType];
    
    [self configureButtonsWithAnimation:NO];
    
}


@end
