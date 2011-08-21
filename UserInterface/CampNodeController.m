//
//  CampNodeController.m
//  TrailTracker
//
//  Created by Anna Hentzel on 5/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CampNodeController.h"
#import "ThemeCamp.h"
#import "iBurnAppDelegate.h"
#import "util.h"
#import "CJSONDeserializer.h"

@implementation CampNodeController

- (void) importDataFromFile {
	NSString *path = [[NSBundle mainBundle] pathForResource:@"camps" ofType:@"json"];
	NSData *fileData = [NSData dataWithContentsOfFile:path];
	NSArray *campArray = [[[CJSONDeserializer deserializer] deserialize:fileData error:nil]retain];
	NSLog(@"The camp array is %@", campArray);
  CLLocationCoordinate2D dummy = {0,0};
  NSArray *knownCamps = [self getObjectsForType:@"ThemeCamp" 
																				 names:[self getNamesFromDicts:campArray] 
																		 upperLeft:dummy 
																		lowerRight:dummy];
  [self createAndUpdate:knownCamps
            withObjects:campArray 
           forClassName:@"ThemeCamp"
							 fromFile:YES];
}


- (NSString *)getUrl {
 	NSString *theString;
	theString = @"http://playaevents.burningman.com/api/0.2/2011/camp/";
	// theString = @"http://earth.burningman.com/api/0.1/2010/camp/";	
	return theString;
}



- (void) updateObjectFromFile:(ThemeCamp*)camp withDict:(NSDictionary*)dict {
  
  camp.name = [self nullStringOrString:[dict objectForKey:@"Name"]];
                           
  camp.simpleName = [ThemeCamp createSimpleName:camp.name];                        
  NSLog(@"name %@ simple name %@", camp.name, camp.simpleName);
	camp.latitude = [dict objectForKey:@"Latitude"];
	camp.longitude = [dict objectForKey:@"Longitude"];
}


- (void) updateObject:(ThemeCamp*)camp withDict:(NSDictionary*)dict {
  camp.bm_id = N([[self nullOrObject:[dict objectForKey:@"id"]] intValue]);
  camp.name = [self nullStringOrString:[dict objectForKey:@"name"]];
  camp.contactEmail = [self nullStringOrString:[dict objectForKey:@"contact_email"]];
  camp.desc = [self nullStringOrString:[dict objectForKey:@"description"]];
  camp.url = [self nullStringOrString:[dict objectForKey:@"url"]];
  NSDictionary *locPoint = [self getLocationDictionary:dict];
  if (locPoint) {
    NSArray *coordArray = [locPoint objectForKey:@"coordinates"];
    camp.latitude = [coordArray objectAtIndex:1];
    camp.longitude = [coordArray objectAtIndex:0];
    NSLog(@"%1.5f, %1.5f", [camp.latitude floatValue], [camp.longitude floatValue]);
  }
}


- (void) getNodesFromJson:(NSObject*) jsonNodes {
  NSMutableArray* camps = [NSMutableArray arrayWithArray:(NSArray*)jsonNodes];
  CLLocationCoordinate2D dummy = {0,0};
  NSArray *knownCamps = [self getObjectsForType:@"ThemeCamp" 
                                          names:[self getNamesFromDicts:camps] 
                                      upperLeft:dummy 
                                     lowerRight:dummy];
  [self createAndUpdate:knownCamps
            withObjects:camps 
           forClassName:@"ThemeCamp"
							fromFile:NO];
	[self importDataFromFile];
}


- (void) createAndUpdate:(NSArray*)knownObjects 
             withObjects:(NSArray*)objects 
            forClassName:(NSString*)className 
								fromFile:(BOOL)fromFile {
 	iBurnAppDelegate *t = (iBurnAppDelegate *)[[UIApplication sharedApplication] delegate];
  NSManagedObjectContext *moc = [t bgMoc];
  for (NSDictionary *dict in objects) {
    id matchedCamp = nil;
    NSString* name = [self nullOrObject:[dict objectForKey:@"title"]];
    NSString * simpleName = [ThemeCamp createSimpleName:name];
		NSLog(@"The title is %@", [dict objectForKey:@"title"]);
    for (ThemeCamp * c in knownObjects) {
      if ([[c bm_id] isEqual:[self nullOrObject:[dict objectForKey:@"id"]]]
					|| [c.simpleName isEqual:simpleName]) {
        matchedCamp = c;
        break;
      }
    }
    if (!matchedCamp) {
      NSLog(@"unmatch camp name %@ %@", name, simpleName);
      matchedCamp = [NSEntityDescription insertNewObjectForEntityForName:className
                                                  inManagedObjectContext:moc];      
    }
		if (fromFile) {
      [self updateObjectFromFile:matchedCamp withDict:[dict retain]];
		} else {
      [self updateObject:matchedCamp withDict:[dict retain]];
		}
    [dict release];
  }
  [self saveObjects:knownObjects];
}  


@end