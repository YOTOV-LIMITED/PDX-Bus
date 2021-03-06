//
//  BlockColorDb.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/25/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "BlockColorDb.h"
#import "DebugLogging.h"
#import <CoreGraphics/CoreGraphics.h>


@implementation BlockColorDb

@synthesize colorMap = _colorMap;
@synthesize file     = _file;

#define kKeyR   @"r"
#define kKeyG   @"g"
#define kKeyB   @"b"
#define kKeyA   @"a"
#define kKeyT   @"time"
#define kKeyD   @"desc"

#define blockFile @"blockcolors.plist"

- (void)writeToFile
{
    [self.file writeDictionary:self.colorMap];
}

- (void)openFile
{
    if (_colorMap == nil)
    {
        [self readFromFile];
    }
}

- (void)memoryWarning
{
    DEBUG_LOG(@"Releasing color map %p\n", (id)_colorMap);
    [_colorMap release];
    _colorMap = nil;
}

- (void)readFromFile
{
    
    if (self.file.urlToSharedFile !=nil)
    {
        self.colorMap = [[[NSMutableDictionary alloc] initWithContentsOfURL:self.file.urlToSharedFile] autorelease];
    }
    
    if (self.colorMap == nil)
    {
        self.colorMap = [[[NSMutableDictionary alloc] init] autorelease];
    }
}

- (id)init {
	if ((self = [super init]))
	{
        self.colorMap = [[[NSMutableDictionary alloc] init] autorelease];
        
        self.file = [[[SharedFile alloc] initWithFileName:blockFile initFromBundle:NO] autorelease];
        
        [MemoryCaches addCache:self];

        [self readFromFile];
    }
    return self;
}

- (void)clearAll
{
    [_colorMap release];
     _colorMap = [[NSMutableDictionary alloc] init];
    [self writeToFile];
}

- (void)dealloc
{
    self.colorMap = nil;
    self.file     = nil;
    
    [MemoryCaches removeCache:self];
    
    [super dealloc];
}

+ (BlockColorDb *)getSingleton
{
    static BlockColorDb *singleton = nil;
    
    if (singleton == nil)
    {
        singleton = [[BlockColorDb alloc] init];
    }
    
    return [[singleton retain] autorelease];
}

- (CGFloat) getComponent:(NSString*)key fromDict:(NSDictionary *)dict
{
    [self openFile];
    return (CGFloat) [(NSNumber*)[dict objectForKey:key] floatValue];
}

- (UIColor *) colorForBlock:(NSString *)block
{
    [self openFile];
    
    if (block == nil)
    {
        return [UIColor clearColor];
    }
    
    NSDictionary *item = [_colorMap objectForKey:block];
    
    if (item == nil)
    {
        return nil;
    }
    
    return [UIColor colorWithRed:[self getComponent:kKeyR fromDict:item]
                           green:[self getComponent:kKeyG fromDict:item]
                            blue:[self getComponent:kKeyB fromDict:item]
                           alpha:[self getComponent:kKeyA fromDict:item]];
}

- (void)addColor:(UIColor *)color forBlock:(NSString *)block description:(NSString*)desc
{
    [self openFile];
    
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    
    
    if (color == nil)
    {
        [_colorMap removeObjectForKey:block];
        [self writeToFile];
        return;
    }
    
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    NSMutableDictionary *item = [[[NSMutableDictionary alloc] init] autorelease];
    
    [item setObject:[NSNumber numberWithFloat:red]      forKey:kKeyR];
    [item setObject:[NSNumber numberWithFloat:green]    forKey:kKeyG];
    [item setObject:[NSNumber numberWithFloat:blue]     forKey:kKeyB];
    [item setObject:[NSNumber numberWithFloat:alpha]    forKey:kKeyA];
    [item setObject:desc forKey:kKeyD];
    
    NSMutableDictionary *oldItem = [_colorMap objectForKey:block];
    
    if (oldItem == nil)
    {
    
        [item setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSinceReferenceDate]]
                                            forKey:kKeyT];
    }
    else
    {
        [item setObject:[oldItem objectForKey:kKeyT] forKey:kKeyT];
    }
    

    while (_colorMap.count > 20)
    {
        // Find the oldest item
        double oldestTime = MAXFLOAT;
        NSString *oldestKey = nil;
        
        NSEnumerator *i = [_colorMap keyEnumerator];
        NSString *key;
        double time;
        
        for (key = i.nextObject; key!=nil; key = i.nextObject)
        {
            NSDictionary *dict = [_colorMap objectForKey:key];
            
            time = [(NSNumber*)[dict objectForKey:kKeyT] doubleValue];
            
            if (time <= oldestTime)
            {
                oldestTime = time;
                oldestKey  = key;
            }
        }
        
        if (oldestKey == nil)
        {
            // bad!
            break;
        }
        
        [_colorMap removeObjectForKey:oldestKey];
    }

    
    [_colorMap setObject:item forKey:block];
    
    
    [self writeToFile];
}

- (NSArray *)keys
{
    [self openFile];
    
    return [_colorMap allKeys];
}

- (NSString *)descForBlock:(NSString *)block
{
    [self openFile];
    
    NSDictionary *item = [_colorMap objectForKey:block];
    
    if (item==nil)
    {
        return nil;
    }
    
    return [item objectForKey:kKeyD];
}

- (NSDate *)timeForBlock:(NSString *)block
{
    [self openFile];
    
    NSDictionary *item = [_colorMap objectForKey:block];
    
    if (item==nil)
    {
        return nil;
    }
    
    NSNumber *time = [item objectForKey:kKeyT];
    
    return [NSDate dateWithTimeIntervalSinceReferenceDate:[time floatValue]];

}


+ (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 20.0f, 20.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


@end
