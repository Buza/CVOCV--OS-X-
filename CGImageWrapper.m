/*
 *  CGImageWrapper.m
 *
 *  Created by buza on 1/15/09.
 *
 *  Brought to you by buzamoto. http://buzamoto.com
 */

#import "CGImageWrapper.h"

@implementation CGImageWrapper

@synthesize theImage;

-(id) initWithCGImage:(CGImageRef)img
{
    if(self = [super init]) {
        theImage = img;
    }
    
    return self;
}

-(void) dealloc
{
    CGImageRelease(theImage);
    [super dealloc];
}

@end
