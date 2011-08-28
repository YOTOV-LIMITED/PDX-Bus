//
//  TripPlannerLocatingView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/4/09.
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "LocatingTableView.h"
#import "XMLTrips.h"


@interface TripPlannerLocatingView : LocatingTableView  {
	XMLTrips *_tripQuery;
	TripEndPoint  *_currentEndPoint;
	UINavigationController *_backgroundTaskController;
	bool _backgroundTaskForceResults;
	UIInterfaceOrientation _cachedOrientation;
	bool _useCachedOrientation;
}

@property (nonatomic, retain) XMLTrips *tripQuery;
@property (nonatomic, retain) TripEndPoint  *currentEndPoint;
@property (nonatomic, retain) UINavigationController *backgroundTaskController;
@property (nonatomic) bool backgroundTaskForceResults;



- (id)init;

-(void)nextScreen:(UINavigationController *)controller forceResults:(bool)forceResults postQuery:(bool)postQuery 
	  orientation:(UIInterfaceOrientation)orientation
	taskContainer:(BackgroundTaskContainer *)taskContainer;
-(void)fetchAndDisplay:(UINavigationController *)controller forceResults:(bool)forceResults
		 taskContainer:(BackgroundTaskContainer *)taskContainer;


@end
