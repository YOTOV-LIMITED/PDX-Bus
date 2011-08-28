//
//  MapLinesView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/3/09.
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

#import "MapLinesView.h"
#import "MapPinColor.h"
#import "debug.h"
#import "LegShapeParser.h"

@implementation MapLinesDrawView

@synthesize annotations = _annotations;
@synthesize mapView = _mapView;

- (void)dealloc {
	self.annotations = nil;
	self.mapView = nil;
    [super dealloc];
}


- (id)init 
{
	if ((self = [super init]))
	{
		[self setBackgroundColor:[UIColor clearColor]];
		self.clipsToBounds = NO;
	}
	return self;
	
}

- (void)drawRect:(CGRect)rect 
{
	if(!self.hidden && nil != self.annotations && self.annotations.count > 0)
	{
		// static CGFloat dash [] = { 5.0, 5.0 };
		CGContextRef context = UIGraphicsGetCurrentContext(); 
		
		CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
		CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 1.0);
		// CGContextSetLineDash (context, 5.0, dash, 2);
		CGContextSetLineWidth(context, 3.0);
		
		bool moveLine = true;
		
		for(int i = 0; i < self.annotations.count; i++)
		{
			ShapeCoord *shapeCoord  = [self.annotations objectAtIndex:i];
			CLLocationCoordinate2D coord;
			
			if (!shapeCoord.end)
			{
				coord.latitude = shapeCoord.latitude;
				coord.longitude = shapeCoord.longitude;
			
				CGPoint point = [self.mapView convertCoordinate:coord toPointToView:self];
			
				DEBUG_LOG(@"Point %d %f %f\n", i, point.x, point.y);
			
				if(moveLine)
				{
					moveLine = false;
					CGContextMoveToPoint(context, point.x, point.y);
				}
				else
				{
					CGContextAddLineToPoint(context, point.x, point.y);
				}
			}
			else 
			{
				moveLine = true;
			}

			
		}
		
		CGContextStrokePath(context);
	}
}


@end


@implementation MapLinesView;
@synthesize mapView   = _mapView;
@synthesize annotations    = _annotations;
@synthesize drawView = _drawView;

- (void)dealloc {
	self.annotations = nil;
	self.mapView = nil;
	self.drawView = nil;
    [super dealloc];
}

-(id) initWithAnnotations:(NSArray*)routePoints mapView:(MKMapView*)mapView
{
	CGRect frame = CGRectMake(0, 0, mapView.frame.size.width, mapView.frame.size.height);
	
	if (self = [super initWithFrame:frame])
	{
		[self setBackgroundColor:[UIColor clearColor]];
		
		[self setMapView:mapView];
		[self setAnnotations:routePoints];
		
		self.clipsToBounds = NO;
		
		self.drawView = [[[MapLinesDrawView alloc] init] autorelease];
		self.drawView.mapView = self.mapView;
		self.drawView.annotations = self.annotations;
		self.drawView.hidden = NO;
		self.drawView.frame = frame;
		[self addSubview:self.drawView];
	
	// [self.mapView addSubview:self];
	}
	
	return self;
}

- (void)hide:(bool)hide
{
	if (hide)
	{
		self.hidden = YES;
	}
	else 
	{
		self.hidden = NO;
	}
	[self setNeedsDisplay];
}

-(void) setMapView:(MKMapView*) mapView
{
	[_mapView release];
	_mapView = [mapView retain];
	
	// [self regionChanged];
}

-(void) regionChanged
{	
	// move the internal route view. 
	CGPoint origin = CGPointMake(0, 0);
	origin = [self.mapView convertPoint:origin toView:self];
	
	DEBUG_LOG(@"origin: %f %f\n", origin.x, origin.y);
	
	(@"eh", 1);
	
	self.drawView.frame = CGRectMake(origin.x, origin.y, self.mapView.frame.size.width, self.mapView.frame.size.height);
	[self.drawView setNeedsDisplay];
	
}


@end
