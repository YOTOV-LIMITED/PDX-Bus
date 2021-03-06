//
//  XMLDepartures.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLDepartures.h"
#import "DepartureData.h"
#import "DepartureTrip.h"
#import "XMLDetour.h"
#import "DebugLogging.h"
#import "DepartureData.h"
#import "StringHelper.h"

static NSString *departuresURLString = @"arrivals/locIDs/%@/streetcar/true";


@implementation XMLDepartures

@synthesize distance = _distance;
@synthesize blockFilter = _blockFilter;
@synthesize queryTime = _queryTime;
@synthesize locDesc = _locDesc;
@synthesize locid = _locid;
@synthesize loc = _loc;
@synthesize locDir = _locDir;
@synthesize currentDepartureObject = _currentDepartureObject;
@synthesize currentTrip = _currentTrip;
@synthesize sectionTitle = _sectionTitle;
@synthesize streetcarData = _streetcarData;
@synthesize firstOnly = _firstOnly;

- (void)dealloc
{
	self.currentDepartureObject = nil;
	self.currentTrip = nil;
    
	
	self.locDesc = nil;
	self.loc = nil;
	self.locid = nil;
	self.blockFilter = nil;
	
	self.distance = nil;
	self.locDir = nil;
	self.sectionTitle = nil;
    self.streetcarData = nil;
	
	[super dealloc];
}


- (double)getDouble:(NSString *)str
{
	double d = 0.0;
	NSScanner *scanner = [NSScanner scannerWithString:str];	
	[scanner scanDouble:&d];
	return d;
}


- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	
}

#pragma mark Initiate parsing 

- (void)reload
{
	[self startParsing:[NSString stringWithFormat:departuresURLString, self.locid]
        cacheAction:TriMetXMLUseShortTermCache];
		
    NSMutableArray *locs = [StringHelper arrayFromCommaSeparatedString:self.locid];
	
    int nStops = (int)locs.count;
	
	if (nStops > 1)
	{
		self.locDesc = [ NSString stringWithFormat:@"Stop Ids:%@", self.locid];
		self.loc = nil;
	}
    
    NSArray *sorted = [self.itemArray sortedArrayUsingSelector:@selector(compareUsingTime:)];
    
    [self.itemArray removeAllObjects];
    [self.itemArray addObjectsFromArray:sorted];
	
}

- (BOOL)getDeparturesForLocation:(NSString *)location
{	
	self.distance = nil;
	self.locid = location;
	[self reload];
	return YES;
}

- (BOOL)getDeparturesForLocation:(NSString *)location block:(NSString*)block
{	
	self.distance = nil;
	self.locid = location;
	self.blockFilter = block;
	[self reload];
	return YES;
}

#pragma mark Parser callbacks

- (void)dumpDict:(NSDictionary *)dict
{
#ifdef DEBUGLOGGING
    for (NSString *key in dict)
    {
        DEBUG_LOG(@"Key %@ value %@\n", key, [dict valueForKey:key]);
    }
#endif
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if ([NSThread currentThread].isCancelled)
	{
		[parser abortParsing];
		return;
	}
    
    [super parser:parser didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict];
	
    if (qName) {
        elementName = qName;
    }
	
	if ([elementName isEqualToString:@"resultSet"]) {
		self.queryTime = [self getTimeFromAttribute:attributeDict valueForKey:@"queryTime"];	
		[self initArray];
		hasData = YES;
	}
	
	if ([elementName isEqualToString:@"location"] && self.locDesc == nil) {
		self.locDesc = [self safeValueFromDict:attributeDict valueForKey:@"desc"];
        
        NSString *lat = [attributeDict valueForKey:@"lat"];
        NSString *lng = [attributeDict valueForKey:@"lng"];
        
        if (lat!=nil && lng!=nil)
        {
            self.loc = [[[CLLocation alloc] initWithLatitude:lat.doubleValue longitude:lng.doubleValue] autorelease];
        }
		self.locDir  = [self safeValueFromDict:attributeDict valueForKey:@"dir"];
	}
	
	if ([elementName isEqualToString:@"errorMessage"]) {
		self.currentDepartureObject = [[[DepartureData alloc] init] autorelease];
		self.contentOfCurrentProperty = [NSMutableString string];
	}	
		
    if ([elementName isEqualToString:@"arrival"]) {
		
		NSString *block = [self safeValueFromDict:attributeDict valueForKey:@"block"];
		if (((self.blockFilter==nil) || ([self.blockFilter isEqualToString:block])) &&
                ((!self.firstOnly || self.safeItemCount < 1)))
		{
        
			self.currentDepartureObject = [[[DepartureData alloc] init] autorelease];
            
            // Streetcar arrivals have an implicit block
			self.currentDepartureObject.hasBlock = [self getBoolFromAttribute:attributeDict valueForKey:@"streetCar"];
			
            self.currentDepartureObject.cacheTime = self.cacheTime;
            
            // Adjust the query time based on the cache time
            
           
            
            self.currentDepartureObject.queryTime = self.queryTime;
            
            [self.currentDepartureObject extrapolateFromNow];
			
			self.currentDepartureObject.route =			[self safeValueFromDict:attributeDict valueForKey:@"route"];
			self.currentDepartureObject.fullSign =		[self safeValueFromDict:attributeDict valueForKey:@"fullSign"];
			self.currentDepartureObject.routeName =		[self safeValueFromDict:attributeDict valueForKey:@"shortSign"];
			self.currentDepartureObject.block =         block;
			self.currentDepartureObject.dir =			[self safeValueFromDict:attributeDict valueForKey:@"dir"];
			
			self.currentDepartureObject.locationDesc =	self.locDesc;
			self.currentDepartureObject.locid		 =  self.locid;
			self.currentDepartureObject.locationDir  =  self.locDir;
			self.currentDepartureObject.stopLocation =  self.loc;
			
			NSString *status = [self safeValueFromDict:attributeDict valueForKey:@"status"];
			
			if ([status isEqualToString:@"estimated"])
			{
				self.currentDepartureObject.departureTime = [self getTimeFromAttribute:attributeDict valueForKey:@"estimated"];
				self.currentDepartureObject.status = kStatusEstimated;
			}
			else 
			{
				self.currentDepartureObject.departureTime = [self getTimeFromAttribute:attributeDict valueForKey:@"scheduled"];	
		
				if ([status isEqualToString:@"scheduled"])
				{
					[self.currentDepartureObject setStatus:kStatusScheduled];
				} 
				else if ([status isEqualToString:@"delayed"])
				{
					[self.currentDepartureObject setStatus:kStatusDelayed];
				} 
				else if ([status isEqualToString:@"canceled"])
				{
					[self.currentDepartureObject setStatus:kStatusCancelled];
				}
			}
            
			self.currentDepartureObject.scheduledTime = [self getTimeFromAttribute:attributeDict valueForKey:@"scheduled"];	
            self.currentDepartureObject.detour =  [self getBoolFromAttribute:attributeDict valueForKey:@"detour"];
			self.currentDepartureObject.nextBusFeedInTriMetData = [self getBoolFromAttribute:attributeDict valueForKey:@"nextBusFeed"];
            self.currentDepartureObject.streetcar = [self getBoolFromAttribute:attributeDict valueForKey:@"streetCar"];
            
            
            // DEBUG_LOG(@"Nextbusfeed:%d %@\n", self.currentDepartureObject.nextBusFeedInTriMetData, [self safeValueFromDict:attributeDict valueForKey:@"nextbusfeed"])	;
            // [self dumpDict:attributeDict];
        }
		else
		{
			self.currentDepartureObject=nil;
		}
    }
	
	if ([elementName isEqualToString:@"blockPosition"] && self.currentDepartureObject!=nil) {
		self.currentDepartureObject.blockPositionAt     = [self getTimeFromAttribute:attributeDict valueForKey:@"at"];

        NSString *lat = [attributeDict valueForKey:@"lat"];
        NSString *lng = [attributeDict valueForKey:@"lng"];
        
        if (lat !=nil && lng!=nil)
        {
            self.currentDepartureObject.blockPosition = [[[CLLocation alloc] initWithLatitude:lat.doubleValue longitude:lng.doubleValue] autorelease];
        }
        
		self.currentDepartureObject.blockPositionFeet   = [self getDistanceFromAttribute:attributeDict valueForKey:@"feet"];
        self.currentDepartureObject.blockPositionHeading= [self safeValueFromDict:attributeDict valueForKey:@"heading"];
        
		self.currentDepartureObject.hasBlock = true;
	}
	
	if ([elementName isEqualToString:@"trip"] && self.currentDepartureObject!=nil)
	{
		self.currentTrip = [[[DepartureTrip alloc] init] autorelease];
		self.currentTrip.name = [self safeValueFromDict:attributeDict valueForKey:@"desc"];
		self.currentTrip.distance = (unsigned long)[self getDistanceFromAttribute:attributeDict valueForKey:@"destDist"];
		self.currentTrip.progress  =  (unsigned long)[self getDistanceFromAttribute:attributeDict valueForKey:@"progress"];
		
		if (self.currentTrip.distance > 0)
		{
			[self.currentDepartureObject.trips addObject:self.currentTrip];
		}
	}
	
	if ([elementName isEqualToString:@"layover"] && self.currentDepartureObject!=nil)
	{
		self.currentTrip = [[[DepartureTrip alloc] init] autorelease];
		self.currentTrip.startTime = [self getTimeFromAttribute:attributeDict valueForKey:@"start"];
		self.currentTrip.endTime =   [self getTimeFromAttribute:attributeDict valueForKey:@"end"];
		[self.currentDepartureObject.trips addObject:self.currentTrip];
	}
	
	if ([elementName isEqualToString:@"location"] && self.currentDepartureObject!=nil && self.locDesc != nil)
	{
		self.currentTrip.name = [self safeValueFromDict:attributeDict valueForKey:@"desc"];	
	}
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{   
	if ([NSThread currentThread].isCancelled)
	{
		[parser abortParsing];
		return;
	}
    
    [super parser:parser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
	
    if (qName) {
        elementName = qName;
    }
		
	if ([elementName isEqualToString:@"errorMessage"] && self.currentDepartureObject!=nil) {
		self.currentDepartureObject.errorMessage = [self contentOfCurrentProperty];	
		_contentOfCurrentProperty = nil;
		
		[self addItem:self.currentDepartureObject];
		self.currentDepartureObject = nil;
	}
	
	if ([elementName isEqualToString:@"arrival"] && self.currentDepartureObject!=nil) {
		[self addItem:self.currentDepartureObject];
		self.currentDepartureObject = nil;
	}
}

#pragma mark  Cached detours 

static NSMutableDictionary *cachedDetours = nil;

+ (void)clearCache
{
	if (cachedDetours !=nil)
	{
		[cachedDetours release];
		cachedDetours = nil;
	}
}

-(bool)checkForDetour:(NSString *)route
{
	bool hasDetour = false;

	if (cachedDetours == nil)
	{
		cachedDetours = [[NSMutableDictionary alloc] init];
	}
	
	XMLDetour *detour = [cachedDetours objectForKey:route];
	
	if (detour == nil)
	{
		detour = [[XMLDetour alloc] init];
		[detour getDetourForRoute:route];
		[cachedDetours setObject:detour forKey:route];
		[detour release];
	}
	
	hasDetour = ([detour safeItemCount] > 0);
	return hasDetour;
}




@end
