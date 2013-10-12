//
//  TheMovieDbSearch.m
//  MetaZ
//
//  Created by Brian Olsen on 30/12/11.
//  Copyright 2011 Maven-Group. All rights reserved.
//

#import "TheMovieDbSearch.h"
#import "Access.h"
#import "TheMovieDbPlugin.h"

@implementation TheMovieDbSearch

+ (id)searchWithProvider:(id)provider delegate:(id<MZSearchProviderDelegate>)delegate queue:(NSOperationQueue *)queue
{
    return [[[self alloc] initWithProvider:provider delegate:delegate queue:queue] autorelease];
}

- (id)initWithProvider:(id)theProvider delegate:(id<MZSearchProviderDelegate>)theDelegate queue:(NSOperationQueue *)theQueue
{
    self = [super init];
    if(self)
    {
        provider = theProvider;
        delegate = [theDelegate retain];
        queue = [theQueue retain];
        _parser = [[SBJsonParser alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [delegate release];
    [queue release];
    [_parser release];
    [super dealloc];
}

@synthesize provider;
@synthesize delegate;

- (void)cancel
{
    [delegate searchFinished];
    [delegate release];
    delegate = nil;
    [super cancel];
}

- (void)queueOperation:(NSOperation *)operation
{
    [self addOperation:operation];
    [queue addOperation:operation];
}

- (void)operationsFinished
{
    [delegate searchFinished];
}

- (NSString*)getSearchApiFor:(NSString*)query
{
    return [NSString stringWithFormat:
             @"http://api.themoviedb.org/3/search/movie?api_key=%@&query=%@&include_adult=%@",
             THEMOVIEDB_API_KEY,
             [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
             (NO ? @"true" : @"false") /*look into adding an option to search adult titles?*/
            ];
}
- (NSString*)getMovieApiFor:(NSNumber*)movieId
{
    // we have to add releases to get the certification (age rating) information
    // and the casts to get cast/crew and the images to get the posters
    return [NSString stringWithFormat:
            @"http://api.themoviedb.org/3/movie/%@?api_key=%@&append_to_response=releases,casts,images",
            movieId,
            THEMOVIEDB_API_KEY];
}
- (NSString*)getImagePrefix
{
    if (baseImageUrl==nil) {
//        NSString* url = [NSString stringWithFormat:
//                         @"http://api.themoviedb.org/3/configuration?api_key=%@",
//                         THEMOVIEDB_API_KEY];
//        MZHTTPRequest* request = [[MZHTTPRequest alloc] initWithURL:[NSURL URLWithString:url]];
//        [request addRequestHeader:@"Accept" value:@"application/json"];
//        [request startSynchronous];
//        
//        int status = [request responseStatusCode];
//        if(status == 200) {
//            NSDictionary* dictionary = [NSJSONSerialization JSONObjectWithData:[request responseData] options:0 error:NULL];
//            baseImageUrl = [[dictionary objectForKey:@"images"] objectForKey:@"base_url"];
//        } else {
            // try assuming it's the old default
            baseImageUrl = @"http://d3gtl9l2a4fn1j.cloudfront.net/t/p/";
//        }
    }
    return baseImageUrl;
}

- (void)fetchMovieSearch:(NSString *)name
{
    NSString* url = [self getSearchApiFor:name];

    NSLog(@"Sending request to %@", url);
    MZHTTPRequest* request = [[MZHTTPRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [request addRequestHeader:@"Accept" value:@"application/json"];
    [request setDelegate:self];
    request.didFinishBackgroundSelector = @selector(fetchMovieSearchCompleted:);
    request.didFailSelector = @selector(fetchMovieSearchFailed:);

    [self addOperation:request];
    [request release];
}

- (void)fetchMovieSearchCompleted:(id)request;
{
    ASIHTTPRequest* theRequest = request;
    int status = [theRequest responseStatusCode];
    if(status >= 400) {
        [self fetchMovieSearchFailed:request];
        return;
    }
    NSLog(@"Got response from cache %@", [theRequest didUseCachedResponse] ? @"YES" : @"NO");
    
    NSDictionary* dictionary = [_parser objectWithData:[theRequest responseData]];
    
    // if we were using the 10.8 sdk we'd have
    // [NSJSONSerialization JSONObjectWithData:[theRequest responseData] options:0 error:NULL];
    
    /*  dictionary structure
     *  {
     *      "page": anNSNumber
     *      "results": anNSArray of NSDictionaries each with keys:
     *          "adult": false <<< representation of booleans???
     *          "backdrop_path": anNSString (image path)
     *          "id": anNSNumber
     *          "original_title": anNSString
     *          "release_date": anNSString formatted "YYYY-MM-DD"
     *          "poster_path": anNSString (image path)
     *          "popularity": anNSNumber (floating point)
     *          "title": anNSString
     *          "vote_average": anNSNumber (floating point)
     *          "vote_count": anNSNumber
     *      "total_pages": anNSNumber
     *      "total_results": anNSNumber
     *  }
     */
    
    NSLog(@"Got TheMovieDb results %@", [dictionary objectForKey:@"total_results"]);
    
    // Let's assume we just want page 1 of the results for now
    NSArray* results = [dictionary objectForKey:@"results"];
    for (NSDictionary* result in results) {
        NSNumber *movieId = [result objectForKey:@"id"];
        [self fetchMovieInfo:movieId];
    }
}

- (void)fetchMovieSearchFailed:(id)request;
{
    ASIHTTPRequest* theRequest = request;
    NSLog(@"Request failed with status code %d", [theRequest responseStatusCode]);
}



- (void)fetchMovieInfo:(NSNumber *)movieId;
{
    NSString* url = [self getMovieApiFor:movieId];
    
    NSLog(@"Sending request to %@", url);
    MZHTTPRequest* request = [[MZHTTPRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [request addRequestHeader:@"Accept" value:@"application/json"];
    [request setDelegate:self];
    request.didFinishBackgroundSelector = @selector(fetchMovieInfoCompleted:);
    request.didFailSelector = @selector(fetchMovieInfoFailed:);

    [self queueOperation:request];
    [request release];
}

- (void)fetchMovieInfoCompleted:(id)request;
{

    @try {
        ASIHTTPRequest* theRequest = request;
        int status = [theRequest responseStatusCode];
        if(status >= 400) {
            [self fetchMovieInfoFailed:request];
            return;
        }
        
        NSLog(@"Got response from cache %@", [theRequest didUseCachedResponse] ? @"YES" : @"NO");
        
        NSDictionary* top_level = [_parser objectWithData:[theRequest responseData]];
             // [NSJSONSerialization JSONObjectWithData:[theRequest responseData] options:0 error:NULL];
        
        /*
         anNSDictionary with keys:
             "adult": false,
             "backdrop_path": anNSString (image path)
             "belongs_to_collection": anNSDictionary (or null)
             "budget": anNSNumber
             "genres": anNSArray of NSDictionaries with keys:
                 "id": anNSNumber
                 "name": anNSString
             "homepage": anNSString
             "id": anNSNumber
             "imdb_id": anNSString
             "original_title": anNSString
             "overview": anNSString
             "popularity": anNSNumber (floating point)
             "poster_path": anNSString (image path)
             "production_companies": anNSArray of NSDictionaries with keys:
                 "name": anNSString
                 "id": anNSNumber
             "production_countries": anNSArray of NSDictionaries with keys:
                 "iso_3166_1": anNSString
                 "name": anNSString
             "release_date": anNSString formatted "YYYY-MM-DD"
             "revenue": anNSNumber
             "runtime": anNSNumber
             "spoken_languages": anNSArray of NSDictionaries with keys:
                 "iso_639_1": anNSString
                 "name": anNSString
             "status": anNSString
             "tagline": anNSString
             "title": anNSString
             "vote_average": anNSNumber (floating point)
             "vote_count": anNSNumber
         AND BECAUSE WE ASKED FOR THEM
             "casts": anNSDictionary with keys:
                 "cast": anNSArray of NSDictionaries with keys:
                     "id": anNSNumber
                     "name": anNSString
                     "character": anNSString
                     "order": anNSNumber
                     "cast_id": anNSNumber
                     "profile_path": anNSString (image path) or null
                 "crew": anNSArray of NSDictionaries with keys:
                     "id": anNSNumber
                     "name": anNSString
                     "department": anNSString
                     "job": anNSString
                     "profile_path": anNSString (image path) or null
             "releases": anNSDictionary with keys
                 "countries": anNSArray of NSDictionaries with keys:
                 "iso_3166_1": anNSString
                 "certification": anNSString
                 "release_date": anNSString formatted "YYYY-MM-DD"
             "images": anNSDictionary with keys
                 "backdrops": anNSArray of NSDictionaries with keys like posters
                 "posters": anNSArray of NSDictionaries with keys
                     "file_path": anNSString (image path)
                     "width": anNSNumber
                     "height": anNSNumber
                     "iso_639_1": anNSString
                     "aspect_ratio": anNSNumber (floating point)
                     "vote_average": anNSNumber (floating point)
                     "vote_count": anNSNumber
         */
        
        NSMutableDictionary* dict = [NSMutableDictionary dictionary];
        
        id title = [top_level objectForKey:@"title"];
        if(title && [title respondsToSelector:@selector(length)] && [title length] > 0)
        {
            MZTag* tag = [MZTag tagForIdentifier:MZTitleTagIdent];
            [dict setObject:[tag objectFromString:title] forKey:MZTitleTagIdent];
        }
        
        NSNumber* ident = [top_level objectForKey:@"id"];
        MZTag* identTag = [MZTag tagForIdentifier:TMDbIdTagIdent];
        [dict setObject:[identTag objectFromString:[ident stringValue]] forKey:TMDbIdTagIdent];
        
        id url = [top_level objectForKey:@"homepage"];
        if(url && [url respondsToSelector:@selector(length)] && [url length] > 0) {
            MZTag* urlTag = [MZTag tagForIdentifier:TMDbURLTagIdent];
            [dict setObject:[urlTag objectFromString:url] forKey:TMDbURLTagIdent];
        }
        
        id imdbId = [top_level objectForKey:@"imdb_id"];
        if(imdbId && [imdbId respondsToSelector:@selector(length)] && [imdbId length] > 0)
        {
            MZTag* imdbTag = [MZTag tagForIdentifier:MZIMDBTagIdent];
            [dict setObject:[imdbTag objectFromString:imdbId] forKey:MZIMDBTagIdent];
        }
        
        // need to pick a certification if there is more than one...
        NSDictionary* releases = [top_level objectForKey:@"releases"];
        NSArray* releaseCountries = [releases objectForKey:@"countries"];
        
        if ([releaseCountries count]>0) {
            NSString* rating = [[releaseCountries objectAtIndex:0] objectForKey:@"certification"];
            MZTag* ratingTag = [MZTag tagForIdentifier:MZRatingTagIdent];
            NSNumber* ratingNr = [ratingTag objectFromString:rating];
            if([ratingNr intValue] != MZNoRating)
                [dict setObject:ratingNr forKey:MZRatingTagIdent];
        }
        
        id description = [top_level objectForKey:@"overview"];
        if(description && [description respondsToSelector:@selector(length)] && [description length] > 0)
        {
            [dict setObject:description forKey:MZShortDescriptionTagIdent];
            [dict setObject:description forKey:MZLongDescriptionTagIdent];
        }
        
        NSString* release = [top_level objectForKey:@"release_date"];
        if( release && [release respondsToSelector:@selector(length)] && [release length] > 0 )
        {
            NSDateFormatter* format = [[[NSDateFormatter alloc] init] autorelease];
            format.dateFormat = @"yyyy-MM-dd";
            NSDate* date = [format dateFromString:release];
            if(date)
                [dict setObject:date forKey:MZDateTagIdent];
            else
                MZLoggerError(@"Unable to parse release date '%@'", release);
        }
        
        
        NSMutableArray* directorsArray = [NSMutableArray array];
        NSMutableArray* writersArray = [NSMutableArray array];
        NSMutableArray* actorsArray = [NSMutableArray array];
        NSMutableArray* producersArray = [NSMutableArray array];
        
        NSDictionary* casts = [top_level objectForKey:@"casts"];
        NSArray* crew = [casts objectForKey:@"crew"];
        NSArray* cast = [casts objectForKey:@"cast"];

        for (NSDictionary* crewMember in crew) {
            NSString *job  = [crewMember objectForKey:@"job"];
            NSString *name = [crewMember objectForKey:@"name"];
            if      ([job isEqualToString:@"Director"])   [directorsArray addObject:name];
            else if ([job isEqualToString:@"Screenplay"]) [writersArray   addObject:name];
            else if ([job isEqualToString:@"Producer"])   [producersArray addObject:name];
        }
        for (NSDictionary* castMember in cast) {
            NSString *name = [castMember objectForKey:@"name"];
            [actorsArray addObject:name];
        }
        
        NSString* directors = [directorsArray componentsJoinedByString:@", "];
        NSString* writers   = [writersArray   componentsJoinedByString:@", "];
        NSString* actors    = [actorsArray    componentsJoinedByString:@", "];
        NSString* producers = [producersArray componentsJoinedByString:@", "];
        
        if(directors) [dict setObject:directors forKey:MZDirectorTagIdent];
        if(writers)   [dict setObject:writers forKey:MZScreenwriterTagIdent];
        if(actors) {
            [dict setObject:actors forKey:MZActorsTagIdent];
            [dict setObject:actors forKey:MZArtistTagIdent];
        }
        if(producers) [dict setObject:producers forKey:MZProducerTagIdent];
        
        NSArray* genres = [top_level objectForKey:@"genres"];
        if ([genres count]>0) {
            NSString* genre = [[genres objectAtIndex:0] objectForKey:@"name"];
            if(genre) [dict setObject:genre forKey:MZGenreTagIdent];
        }
        
        NSMutableArray* imagesArray = [NSMutableArray array];
        for (NSDictionary* image in [[top_level objectForKey:@"images"] objectForKey:@"posters"]) {
            NSString* path = [image objectForKey:@"file_path"];
            NSString* full_path = [[[self getImagePrefix] stringByAppendingString:@"original"] stringByAppendingString:path];
            MZRemoteData* data = [MZRemoteData imageDataWithURL:[NSURL URLWithString:full_path]];
            [imagesArray addObject:data];
            [data loadData];
        }
        if([imagesArray count] > 0) [dict setObject:[NSArray arrayWithArray:imagesArray] forKey:MZPictureTagIdent];
        
        MZSearchResult* result = [MZSearchResult resultWithOwner:provider dictionary:dict];
        [self performSelectorOnMainThread:@selector(providedResult:) withObject:result waitUntilDone:NO];
    } @catch (NSException* e) {
        NSLog(@"%@",[e description]);
    }
    
}

- (void)providedResult:(MZSearchResult *)result
{
    [delegate searchProvider:provider result:[NSArray arrayWithObject:result]];
}

- (void)fetchMovieInfoFailed:(id)request;
{
    ASIHTTPRequest* theRequest = request;
    NSLog(@"Request failed with status code %d", [theRequest responseStatusCode]);
}

@end
