//
//  PhotoTweet.m
//  WMEdit
//
//  Created by Androidicus Maximus on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "PhotoTweet.h"
#import "TweetServerCommunicator.h"
#import "UIImage+Resize.h"

@implementation PhotoTweet
@synthesize tweet, image;

- (unsigned long long)twitterId {
    return [[tweet valueForKey:@"msg_twid"] unsignedLongLongValue];
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    NSData *data = [request responseData];
    UIImage *photoImage = [UIImage imageWithData:data];
    self.image = photoImage;

    [[TweetServerCommunicator commmunicator] photoTweetGotImage:self];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSError *error = [request error];
    DLog([error localizedDescription]);
    [[TweetServerCommunicator commmunicator] photoTweetFailedToGetImage:self];
}


+ (PhotoTweet *)photoTweetWithDictionary:(NSMutableDictionary *)d {
    return [[[PhotoTweet alloc] initWithDictionary:d] autorelease];
}

- (PhotoTweet *)initWithDictionary:(NSMutableDictionary *)d {
    self = [super init];
    if (d) self.tweet = [NSMutableDictionary dictionaryWithDictionary:d];
    return self;
}


- (NSString *)photoIDAfterQuestion:(NSString *)twit {
	NSRange r = [twit rangeOfString:@"?"];
	if (r.length) {
		return [twit substringFromIndex:NSMaxRange(r)];
	}
	return nil;
}


- (NSMutableArray *)photoLinksIn:(NSArray *)urls {
	NSMutableArray *a = [NSMutableArray array];
    
    
    //    // but there may be more!
    //    // support for Twitter Media tag:
    //    NSArray *media = [[d valueForKey:@"entities"] valueForKey:@"media"];
    //    if (!media.count) media = [[[d valueForKey:@"retweeted_status"] valueForKey:@"entities"] valueForKey:@"media"];
    //    
    //    if (media.count) {
    //        for (NSDictionary *mdict in media) {
    //            
    //            // do we connect with the TCO?
    //            // or better the expanded url?
    //            // what are we displaying?
    //            NSString *url = [mdict valueForKey:@"url"];
    //            // or do we want to place the visible name here:
    //            NSString *display = [mdict valueForKey:@"display_url"];
    //            if (display) {
    //                if (![display hasPrefix:@"http"]) display = [NSString stringWithFormat:@"http://%@",display];
    //            }
    //            
    //            NSString *media_url = [mdict valueForKey:@"media_url"]; // optionally add :medium :large etc
    //            
    //            NSString *type = [mdict valueForKey:@"type"];
    //            
    //            // question: are we going to redundantly load this because it's in URL's?
    //            // first we'll just try adding this one first:
    //            
    //            if ([type isEqualToString:@"photo"] && url.length && media_url.length) {
    //                NSMutableArray *b = [NSMutableArray array];
    //                [b addObject:url];
    //                [b addObject:media_url];
    //                [a addObject:b];
    //            }
    //        }
    //        
    //    }
    
    
    
    
	for(NSString *urlString in urls) {
		NSMutableArray *b = [NSMutableArray array];
		[b addObject:urlString];
        if ([urlString hasPrefix:@"http://twitpic.com"]) {
            NSString *last = [urlString lastPathComponent];
            if ([last isEqualToString:@"full"]) last = [[urlString stringByDeletingLastPathComponent] lastPathComponent];
            [b addObject:[NSString stringWithFormat:@"http://twitpic.com/show/iphone/%@",last]];
        } else if ([urlString hasPrefix:@"http://instagr.am/p"]) {
            [b addObject:[NSString stringWithFormat:@"http://instagr.am/p/%@/media/?size=m",[urlString lastPathComponent]]];
        } else if ([urlString hasPrefix:@"http://pk.gd"]) {
            [b addObject:[NSString stringWithFormat:@"http://img.pikchur.com/pic_%@_l.jpg",[urlString lastPathComponent]]];
        } else if ([urlString hasPrefix:@"http://twitgoo.com"]) {
            [b addObject:[NSString stringWithFormat:@"http://twitgoo.com/%@/img",[urlString lastPathComponent]]];
        }  else if ([urlString hasPrefix:@"http://img.ly/"]) {
            [b addObject:[NSString stringWithFormat:@"http://img.ly/show/medium/%@",[urlString lastPathComponent]]];
        }   else if ([urlString hasPrefix:@"http://movapic.com/pic"]) {
            [b addObject:[NSString stringWithFormat:@"http://image.movapic.com/pic/m_%@.jpeg",[urlString lastPathComponent]]];
        }  else if ([urlString hasPrefix:@"http://pic.gd/"] || [urlString hasPrefix:@"http://tweetphoto.com/"] || [urlString hasPrefix:@"http://plixi.com/"] || [urlString hasPrefix:@"http://lockerz.com/"]) {
            // http://TweetPhotoAPI.com/api/TPAPI.svc/json/imagefromurl?size=medium&url=http://www.pic.gd/0f53e6
            [b addObject:[NSString stringWithFormat:@"http://api.plixi.com/api/TPAPI.svc/json/imagefromurl?size=medium&url=%@",urlString]];
        } else if ([urlString hasPrefix:@"http://yfrog.com"]) {
            // yfrog video should open in our browser mp4, flv, swf, pdf
            if (!([urlString hasSuffix:@"z"] || [urlString hasSuffix:@"f"]|| [urlString hasSuffix:@"s"]|| [urlString hasSuffix:@"d"]))
                [b addObject:[NSString stringWithFormat:@"http://yfrog.com/%@:iphone",[urlString lastPathComponent]]];
        } else if ([urlString hasPrefix:@"http://twitlens.com"]) {
            NSString *justTiny = [self photoIDAfterQuestion:urlString];
            if (justTiny.length)
                [b addObject:[NSString stringWithFormat:@"http://twitlens.com/look.cgi?type=full&tid=%@",justTiny]];
        } else if ([urlString hasPrefix:@"http://mobypicture.com"]) {
            NSString *justTiny = [self photoIDAfterQuestion:urlString];
            if (justTiny.length) {
                [b addObject:[NSString stringWithFormat:@"http://mobypicture.com/view/medium/%@",justTiny]];
            }
        } else if ([urlString hasPrefix:@"http://moby.to"]) {
            NSString *justTiny = [urlString lastPathComponent];
            
            if (justTiny.length) {
                [b addObject:[NSString stringWithFormat:@"http://mobypicture.com/view/medium/%@",justTiny]];
            }
        } 
		if (b.count == 2) [a addObject:b];
	}    
    return a;
    
}

- (NSString *)exactURLForMediumImageFromPhotoServiceURL:(NSString *)url {
    NSArray *urls = [self photoLinksIn:[NSArray arrayWithObject:url]];
    
    if ([urls count]) return [[urls objectAtIndex:0] objectAtIndex:1];
    return nil;
}

- (NSString *)photoImageMediumURLString;
{
    return [self exactURLForMediumImageFromPhotoServiceURL:[tweet valueForKey:@"image_url"]];
}

- (BOOL)hasImage {
    return image != nil;
}
- (UIImage *)photoImage {
    return image;
}

- (NSString *)cleanText {
    NSString *sender = [tweet
                        valueForKey:@"user"];
    NSString *clean = [tweet valueForKey:@"text"];
    return [NSString stringWithFormat:@"%C%@ %@",'@',sender ? sender : @"twittelator", clean ? clean : @""];
}

- (void)dealloc {
    self.tweet = nil;
    [super dealloc];
}

@end
