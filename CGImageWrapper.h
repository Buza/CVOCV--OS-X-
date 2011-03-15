/*
 *  CGImageWrapper.h
 *
 *  Created by buza on 1/15/09.
 *
 *  Brought to you by buzamoto. http://buzamoto.com
 */

#import <Cocoa/Cocoa.h>

@interface CGImageWrapper : NSObject 
{
    @public
        CGImageRef theImage;
}

@property CGImageRef theImage;

-(id) initWithCGImage:(CGImageRef)img;

@end
